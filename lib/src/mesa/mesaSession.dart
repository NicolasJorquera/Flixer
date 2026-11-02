import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'package:flixer/firebase_options.dart';
import 'package:flixer/src/mesa/mesaModels.dart';

/// How a table syncs votes. The screens only talk to this, so a table on one
/// phone and a table shared over Firebase look the same to them.
abstract class MesaSession {
  ValueListenable<MesaState?> get state;
  bool get isHost;

  /// The member voting on this device right now. On one phone it changes as
  /// the phone is passed around.
  String? get currentMemberId;

  /// True when the table was closed by the host or deleted.
  bool get closed;

  Future<void> start();
  Future<void> vote(int index, bool like);

  /// The current member finished the deck.
  Future<void> finish();

  /// Host only: show results to everyone now.
  Future<void> end();
  Future<void> leave();
}

class MesaUnavailable implements Exception {
  final String reason;
  MesaUnavailable(this.reason);
  @override
  String toString() => 'MesaUnavailable: $reason';
}

/// Everyone votes on the same phone, one after another. Works offline.
class LocalMesaSession implements MesaSession {
  final ValueNotifier<MesaState?> _state;
  int _turn = 0;

  LocalMesaSession(List<String> names, List<Map> deck)
      : _state = ValueNotifier(MesaState(
          code: '',
          status: MesaStatus.voting,
          deck: deck,
          members: [
            for (var i = 0; i < names.length; i++) MesaMember('$i', names[i])
          ],
          votes: {},
        ));

  @override
  ValueListenable<MesaState?> get state => _state;
  @override
  bool get isHost => true;
  @override
  bool get closed => false;
  @override
  String? get currentMemberId => _state.value!.members[_turn].id;

  @override
  Future<void> start() async {}

  @override
  Future<void> vote(int index, bool like) async {
    final s = _state.value!;
    final votes = {
      for (final e in s.votes.entries) e.key: Map.of(e.value),
    };
    (votes[currentMemberId!] ??= {})[index] = like;
    _state.value = MesaState(
        code: s.code,
        status: s.status,
        deck: s.deck,
        members: s.members,
        votes: votes);
  }

  @override
  Future<void> finish() async {
    final s = _state.value!;
    final members = [
      for (final m in s.members)
        m.id == currentMemberId ? MesaMember(m.id, m.name, done: true) : m
    ];
    final last = _turn == s.members.length - 1;
    if (!last) _turn++;
    _state.value = MesaState(
        code: s.code,
        status: last ? MesaStatus.done : s.status,
        deck: s.deck,
        members: members,
        votes: s.votes);
  }

  @override
  Future<void> end() async {
    final s = _state.value!;
    _state.value = MesaState(
        code: s.code,
        status: MesaStatus.done,
        deck: s.deck,
        members: s.members,
        votes: s.votes);
  }

  @override
  Future<void> leave() async {}
}

/// A table shared over Firebase Realtime Database (free Spark plan). Layout:
/// mesas/{code}/{hostUid, createdAt, status, mediaType, deck, members/{slot},
/// votes/{slot}/{index}}. Limits are enforced in database.rules.json.
class FirebaseMesaSession implements MesaSession {
  final String code;
  final String uid;
  final String slot;
  @override
  final bool isHost;
  final ValueNotifier<MesaState?> _state = ValueNotifier(null);
  StreamSubscription? _subscription;
  bool _closed = false;

  FirebaseMesaSession._(this.code, this.uid, this.slot, this.isHost);

  static const maxMembers = 8;
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static DatabaseReference _ref(String code) =>
      FirebaseDatabase.instance.ref('mesas/$code');

  /// Firebase is only started when a table is used, and its connection is
  /// closed when leaving, so the rest of the app never uses up the free
  /// plan's 100 simultaneous connections.
  static Future<String> _connect() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }
      FirebaseDatabase.instance.goOnline();
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
      return user.uid;
    } on UnsupportedError {
      throw MesaUnavailable('not-configured');
    } on FirebaseException catch (e) {
      throw MesaUnavailable(e.code);
    }
  }

  static Future<FirebaseMesaSession> create(
      String name, String mediaType, List<Map> deck) async {
    final uid = await _connect();
    final random = Random.secure();
    for (var attempt = 0; attempt < 5; attempt++) {
      final code =
          List.generate(6, (_) => _alphabet[random.nextInt(_alphabet.length)])
              .join();
      try {
        // The rules reject writing over an existing table, so a taken code
        // fails here and another one is tried.
        await _ref(code).set({
          'hostUid': uid,
          'createdAt': ServerValue.timestamp,
          'status': 'lobby',
          'mediaType': mediaType,
          'deck': deck,
          'members': {
            '0': {'uid': uid, 'name': name}
          },
        });
        return FirebaseMesaSession._(code, uid, '0', true).._listen();
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') throw MesaUnavailable(e.code);
      }
    }
    throw MesaUnavailable('no-code');
  }

  /// Throws [MesaUnavailable] with 'not-found', 'started' or 'full'.
  static Future<FirebaseMesaSession> join(String code, String name) async {
    final uid = await _connect();
    final DataSnapshot snapshot;
    try {
      snapshot = await _ref(code).get();
    } on FirebaseException catch (e) {
      throw MesaUnavailable(e.code);
    }
    if (!snapshot.exists) throw MesaUnavailable('not-found');
    final data = Map.from(snapshot.value as Map);
    final members = _asMap(data['members']);

    for (final entry in members.entries) {
      if (entry.value['uid'] == uid) {
        return FirebaseMesaSession._(
            code, uid, entry.key, data['hostUid'] == uid)
          .._listen();
      }
    }
    if (data['status'] != 'lobby') throw MesaUnavailable('started');

    for (var slot = 0; slot < maxMembers; slot++) {
      if (members.containsKey('$slot')) continue;
      try {
        await _ref(code).child('members/$slot').set({'uid': uid, 'name': name});
        return FirebaseMesaSession._(code, uid, '$slot', false).._listen();
      } on FirebaseException {
        // Someone took this slot at the same time; try the next one.
        continue;
      }
    }
    throw MesaUnavailable('full');
  }

  /// RTDB returns keys 0..n as a list (with nulls for gaps) and other keys
  /// as a map; this always gives a map keyed by string.
  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is List) {
      return {
        for (var i = 0; i < value.length; i++)
          if (value[i] != null) '$i': value[i]
      };
    }
    if (value is Map) return value.map((k, v) => MapEntry('$k', v));
    return {};
  }

  void _listen() {
    _subscription = _ref(code).onValue.listen((event) {
      final value = event.snapshot.value;
      if (value == null) {
        _closed = true;
        _state.value = _state.value == null
            ? null
            : MesaState(
                code: code,
                status: MesaStatus.done,
                deck: _state.value!.deck,
                members: _state.value!.members,
                votes: _state.value!.votes);
        return;
      }
      final data = Map.from(value as Map);
      final members = _asMap(data['members']);
      final votes = _asMap(data['votes']);
      final slots = members.keys.toList()..sort();
      _state.value = MesaState(
        code: code,
        status: MesaStatus.values.byName(data['status']),
        deck: [
          for (final card
              in _asMap(data['deck']).entries.toList()
                ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key))))
            Map.from(card.value)
        ],
        members: [
          for (final s in slots)
            MesaMember(s, members[s]['name'], done: members[s]['done'] == true)
        ],
        votes: {
          for (final entry in votes.entries)
            entry.key: _asMap(entry.value)
                .map((i, like) => MapEntry(int.parse(i), like == true)),
        },
      );
    }, onError: (Object error) {
      debugPrint('Mesa listener error: $error');
      _closed = true;
    });
  }

  @override
  ValueListenable<MesaState?> get state => _state;
  @override
  String? get currentMemberId => slot;
  @override
  bool get closed => _closed;

  @override
  Future<void> start() => _ref(code).child('status').set('voting');

  @override
  Future<void> vote(int index, bool like) =>
      _ref(code).child('votes/$slot/$index').set(like);

  @override
  Future<void> finish() => _ref(code).child('members/$slot/done').set(true);

  @override
  Future<void> end() => _ref(code).child('status').set('done');

  /// The host deletes the table; others drop their seat while in the lobby.
  @override
  Future<void> leave() async {
    await _subscription?.cancel();
    try {
      if (isHost) {
        await _ref(code).remove();
      } else if (_state.value?.status == MesaStatus.lobby) {
        await _ref(code).child('members/$slot').remove();
      }
    } on FirebaseException catch (e) {
      debugPrint('Mesa leave failed: ${e.code}');
    } finally {
      FirebaseDatabase.instance.goOffline();
    }
  }
}
