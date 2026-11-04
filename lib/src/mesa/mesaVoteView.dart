import 'dart:math';

import 'package:flixer/ads/interstitialAd.dart';
import 'package:flixer/global/constants.dart';
import 'package:flixer/global/strings.dart';
import 'package:flixer/src/mesa/mesaModels.dart';
import 'package:flixer/src/mesa/mesaResultsView.dart';
import 'package:flixer/src/mesa/mesaSession.dart';
import 'package:flixer/src/mesa/mesaWidgets.dart';
import 'package:flixer/src/widgets/movieInfo.dart';
import 'package:flixer/src/widgets/statusViews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

/// Tinder-style voting: swipe right (or ❤) for yes, left (or ✖) for no.
class MesaVoteView extends StatefulWidget {
  final MesaSession session;
  const MesaVoteView({super.key, required this.session});

  @override
  State<MesaVoteView> createState() => _MesaVoteViewState();
}

class _MesaVoteViewState extends State<MesaVoteView> {
  final CardSwiperController _swiper = CardSwiperController();
  final Set<int> _seenMatches = {};
  bool _navigated = false;
  bool _dialogOpen = false;

  /// On one phone, the player who confirmed they have the phone.
  String? _readyFor;

  MesaSession get session => widget.session;
  bool get onePhone => session is LocalMesaSession;

  @override
  void initState() {
    super.initState();
    _readyFor = session.currentMemberId;
    _seenMatches.addAll(session.state.value?.matches ?? []);
    session.state.addListener(onChange);
    InterstitialAdManager.instance.preload();
  }

  @override
  void dispose() {
    session.state.removeListener(onChange);
    _swiper.dispose();
    super.dispose();
  }

  void onChange() {
    final state = session.state.value;
    if (state == null || _navigated || !mounted) return;
    if (session.closed ||
        state.status == MesaStatus.done ||
        (!onePhone && state.everyoneDone)) {
      _navigated = true;
      if (_dialogOpen) Navigator.pop(context);
      // The end of a table is the app's one natural break for an ad.
      InterstitialAdManager.instance.showAtBreak();
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MesaResultsView(session: session)));
      return;
    }
    final newMatches =
        state.matches.where((i) => !_seenMatches.contains(i)).toList();
    _seenMatches.addAll(newMatches);
    if (newMatches.isNotEmpty && !_dialogOpen) {
      showMatch(state.deck[newMatches.first]);
    }
  }

  Future<void> showMatch(Map item) async {
    _dialogOpen = true;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceTint,
        title: Text(tr('match'),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('matchBody'),
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(image_resize + item['poster_path'],
                  height: 220, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(item['title'] ?? item['name'] ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('keepVoting'),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground))),
          if (session.isHost)
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  session.end();
                },
                child: Text(tr('seeResults'),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary))),
        ],
      ),
    );
    _dialogOpen = false;
  }

  Future<bool> onSwipe(
      int previous, int? current, CardSwiperDirection direction) async {
    await session.vote(previous, direction == CardSwiperDirection.right);
    if (current == null) await session.finish();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) confirmLeave(context, session);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: 0,
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.onBackground),
          title: Text(tr('mesa'),
              style: Theme.of(context).textTheme.displayMedium),
        ),
        body: SafeArea(
          top: false,
          child: ValueListenableBuilder<MesaState?>(
            valueListenable: session.state,
            builder: (context, state, _) {
              final me = session.currentMemberId;
              final member =
                  state?.members.where((m) => m.id == me).firstOrNull;
              if (state == null || member == null) return const LoadingView();
              if (onePhone && _readyFor != me) return passPhone(member);
              if (state.isDone(member)) return waiting(state);
              return voting(state, member);
            },
          ),
        ),
      ),
    );
  }

  Widget passPhone(MesaMember member) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_android,
              size: 60, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 15),
          Text(tr('passPhone'),
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 5),
          Text(member.name, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 30),
          MesaButton(
            label: tr('ready'),
            icon: Icons.check,
            onPressed: () => setState(() {
              _readyFor = member.id;
            }),
          ),
        ],
      ),
    );
  }

  Widget voting(MesaState state, MesaMember member) {
    final start = state.votedCount(member.id);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  onePhone ? member.name : tr('whatToWatch'),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              Text('${min(start + 1, state.deck.length)}/${state.deck.length}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary)),
            ],
          ),
        ),
        if (!onePhone) progress(state),
        Expanded(
          child: CardSwiper(
            // A new swiper per player on one phone, starting from scratch.
            key: ValueKey(member.id),
            controller: _swiper,
            cardsCount: state.deck.length,
            initialIndex: start,
            isLoop: false,
            numberOfCardsDisplayed: min(2, state.deck.length),
            allowedSwipeDirection:
                const AllowedSwipeDirection.only(left: true, right: true),
            onSwipe: onSwipe,
            cardBuilder: (context, index, dx, dy) =>
                card(state.deck[index], dx),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              voteButton(Icons.close, tr('no'), Colors.white70,
                  () => _swiper.swipe(CardSwiperDirection.left)),
              voteButton(
                  Icons.favorite,
                  tr('yes'),
                  Theme.of(context).colorScheme.primary,
                  () => _swiper.swipe(CardSwiperDirection.right)),
            ],
          ),
        ),
      ],
    );
  }

  /// Who is voting and how far along they are.
  Widget progress(MesaState state) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        children: [
          for (final m in state.members)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Chip(
                visualDensity: VisualDensity.compact,
                backgroundColor: Theme.of(context).colorScheme.surfaceTint,
                label: Text(
                  state.isDone(m)
                      ? '${m.name} ✓'
                      : '${m.name} ${state.votedCount(m.id)}/${state.deck.length}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onBackground),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget card(Map item, int dx) {
    final String date = item['release_date'] ?? item['first_air_date'] ?? '';
    final num votes = item['vote_count'] ?? 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            image_resize + item['poster_path'],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Theme.of(context).colorScheme.surfaceTint),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
          Positioned(
            left: 15,
            right: 15,
            bottom: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] ?? item['name'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  [
                    if (votes > 0)
                      '★ ${(item['vote_average'] as num).toStringAsFixed(1)}',
                    if (date.length >= 4) date.substring(0, 4),
                  ].join('   '),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              tooltip: tr('details'),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MovieInfoPage(movie: item))),
            ),
          ),
          if (dx.abs() > 10)
            Positioned(
              top: 30,
              left: dx > 0 ? 20 : null,
              right: dx < 0 ? 20 : null,
              child: Transform.rotate(
                angle: dx > 0 ? -0.3 : 0.3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: dx > 0 ? Colors.greenAccent : Colors.redAccent,
                        width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tr(dx > 0 ? 'yes' : 'no').toUpperCase(),
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: dx > 0 ? Colors.greenAccent : Colors.redAccent),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget voteButton(
      IconData icon, String label, Color color, VoidCallback onPressed) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceTint,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 70,
            height: 70,
            child: Icon(icon, size: 34, color: color),
          ),
        ),
      ),
    );
  }

  Widget waiting(MesaState state) {
    return ListView(
      padding: const EdgeInsets.all(30),
      children: [
        Icon(Icons.hourglass_top,
            size: 50, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 10),
        Text(tr('waitingOthers'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 20),
        for (final m in state.members)
          ListTile(
            title:
                Text(m.name, style: Theme.of(context).textTheme.displaySmall),
            trailing: state.isDone(m)
                ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                : Text('${state.votedCount(m.id)}/${state.deck.length}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary)),
          ),
        if (session.isHost) ...[
          const SizedBox(height: 20),
          MesaButton(
            label: tr('endNow'),
            icon: Icons.flag,
            onPressed: () => session.end(),
          ),
        ],
      ],
    );
  }
}
