import 'dart:math';

import 'package:flixer/global/variables.dart';
import 'package:flixer/src/apiFunctions/catalog.dart';

/// What the group agreed to look at before voting.
class MesaFilters {
  String mediaType = 'movie';
  Set<int> genreIds = {};
  Set<int> providerIds = {};
  double minRating = 0;
  int? maxRuntime;
  int? fromYear;
  int deckSize = 20;

  Map<String, String> toParams() {
    final dateField =
        mediaType == 'movie' ? 'primary_release_date' : 'first_air_date';
    return {
      'sort_by': 'popularity.desc',
      // Skips titles nobody knows, which make poor group picks.
      'vote_count.gte': '50',
      // '|' means OR: any of the picked genres or platforms.
      if (genreIds.isNotEmpty) 'with_genres': genreIds.join('|'),
      if (providerIds.isNotEmpty) ...{
        'watch_region': region,
        'with_watch_providers': providerIds.join('|'),
        'with_watch_monetization_types': 'flatrate|free|ads',
      },
      if (minRating > 0) 'vote_average.gte': '$minRating',
      if (mediaType == 'movie' && maxRuntime != null)
        'with_runtime.lte': '$maxRuntime',
      if (fromYear != null) '$dateField.gte': '$fromYear-01-01',
    };
  }
}

/// Picks [MesaFilters.deckSize] titles from the first popular pages so the
/// deck mixes well-known titles without always being the same ones.
Future<List<Map>> buildDeck(MesaFilters filters) async {
  final query =
      CatalogQuery('', '/discover/${filters.mediaType}', filters.toParams());
  final first = await fetchCatalogPage(query, 1);
  final pages = [for (var p = 2; p <= min(first.totalPages, 5); p++) p]
    ..shuffle();
  final List pool = [...first.items];
  for (final page in pages) {
    if (pool.length >= filters.deckSize * 2) break;
    pool.addAll((await fetchCatalogPage(query, page)).items);
  }

  final seen = <int>{};
  final deck = <Map>[];
  for (final item in pool..shuffle()) {
    if (deck.length == filters.deckSize) break;
    if (seen.add(item['id'])) deck.add(deckCard(item));
  }
  return deck;
}

/// Only what the cards and the detail page need; this is what gets synced.
Map<String, dynamic> deckCard(Map item) => {
      for (final field in const [
        'id',
        'media_type',
        'title',
        'name',
        'poster_path',
        'vote_average',
        'vote_count',
        'release_date',
        'first_air_date',
      ])
        if (item[field] != null) field: item[field],
    };

enum MesaStatus { lobby, voting, done }

class MesaMember {
  final String id;
  final String name;
  final bool done;
  const MesaMember(this.id, this.name, {this.done = false});
}

/// Snapshot of a table: the deck, who is in and how each one voted.
class MesaState {
  final String code;
  final MesaStatus status;
  final List<Map> deck;
  final List<MesaMember> members;

  /// Member id -> deck index -> liked.
  final Map<String, Map<int, bool>> votes;

  const MesaState({
    required this.code,
    required this.status,
    required this.deck,
    required this.members,
    required this.votes,
  });

  int likes(int index) =>
      members.where((m) => votes[m.id]?[index] == true).length;

  int votedCount(String memberId) => votes[memberId]?.length ?? 0;

  bool isDone(MesaMember member) =>
      member.done || votedCount(member.id) >= deck.length;

  bool get everyoneDone => members.isNotEmpty && members.every(isDone);

  /// Titles every member liked.
  List<int> get matches => [
        for (var i = 0; i < deck.length; i++)
          if (members.isNotEmpty && likes(i) == members.length) i
      ];

  /// Titles with at least one like, most liked first.
  List<int> get ranking {
    final liked = [
      for (var i = 0; i < deck.length; i++)
        if (likes(i) > 0) i
    ];
    liked.sort((a, b) => likes(b).compareTo(likes(a)));
    return liked;
  }
}
