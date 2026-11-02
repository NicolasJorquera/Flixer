import 'package:flixer/global/constants.dart';
import 'package:flixer/global/strings.dart';
import 'package:flixer/src/mesa/mesaModels.dart';
import 'package:flixer/src/mesa/mesaSession.dart';
import 'package:flixer/src/mesa/mesaWidgets.dart';
import 'package:flixer/src/widgets/movieInfo.dart';
import 'package:flixer/src/widgets/sectionRow.dart';
import 'package:flixer/src/widgets/statusViews.dart';
import 'package:flutter/material.dart';

/// Titles everyone liked, then the rest ranked by likes.
class MesaResultsView extends StatelessWidget {
  final MesaSession session;
  const MesaResultsView({super.key, required this.session});

  Future<void> leave(BuildContext context) async {
    await session.leave();
    if (context.mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave(context);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(tr('results'),
              style: Theme.of(context).textTheme.displayMedium),
        ),
        body: ValueListenableBuilder<MesaState?>(
          valueListenable: session.state,
          builder: (context, state, _) {
            if (state == null) return const LoadingView();
            final matches = state.matches;
            final ranking =
                state.ranking.where((i) => !matches.contains(i)).toList();
            return ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                if (matches.isNotEmpty)
                  SectionRow(
                    title: '🎉 ${tr('match')}',
                    items: [for (final i in matches) state.deck[i]],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(tr('noMatch'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium),
                  ),
                if (ranking.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 5),
                    child: sectionTitle(context, tr('mostVoted')),
                  ),
                  for (final i in ranking)
                    rankingTile(context, state.deck[i], state.likes(i),
                        state.members.length),
                ] else if (matches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(tr('noLikes'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                  child: MesaButton(
                    label: tr('leave'),
                    icon: Icons.home_outlined,
                    onPressed: () => leave(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget rankingTile(BuildContext context, Map item, int likes, int total) {
    return ListTile(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => MovieInfoPage(movie: item))),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(image_resize + item['poster_path'],
            width: 40, height: 60, fit: BoxFit.cover),
      ),
      title: Text(item['title'] ?? item['name'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.displaySmall),
      trailing: Text('$likes ${tr('of')} $total ❤',
          style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
    );
  }
}
