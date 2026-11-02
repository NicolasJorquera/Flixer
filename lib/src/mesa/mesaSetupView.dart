import 'package:flixer/global/strings.dart';
import 'package:flixer/src/apiFunctions/catalog.dart';
import 'package:flixer/src/mesa/mesaLobbyView.dart';
import 'package:flixer/src/mesa/mesaModels.dart';
import 'package:flixer/src/mesa/mesaSession.dart';
import 'package:flixer/src/mesa/mesaVoteView.dart';
import 'package:flixer/src/mesa/mesaWidgets.dart';
import 'package:flixer/src/widgets/providerBar.dart';
import 'package:flutter/material.dart';

/// The table's agreement before voting: movies or series, genres, platforms
/// and a few limits. On one phone it also lists the players.
class MesaSetupView extends StatefulWidget {
  final bool online;
  final String name;
  const MesaSetupView({super.key, required this.online, required this.name});

  @override
  State<MesaSetupView> createState() => _MesaSetupViewState();
}

class _MesaSetupViewState extends State<MesaSetupView> {
  final MesaFilters filters = MesaFilters();
  final Map<String, List> genres = {};
  List providers = [];
  late final List<String> players = [widget.name];
  bool building = false;

  static const ratings = [6.0, 7.0, 8.0];
  static const runtimes = [90, 120, 150];
  static const years = [2000, 2010, 2020];

  @override
  void initState() {
    super.initState();
    loadOptions();
  }

  // Without genres or platforms those filters are just not shown.
  Future<void> loadOptions() async {
    try {
      final result = await Future.wait(
          [getGenres('movie'), getGenres('tv'), getProviders()]);
      if (!mounted) return;
      setState(() {
        genres['movie'] = result[0];
        genres['tv'] = result[1];
        providers = result[2];
      });
    } on Exception {
      return;
    }
  }

  Future<void> addPlayer() async {
    final controller = TextEditingController();
    final player = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceTint,
        title: Text(tr('addPlayer'),
            style: Theme.of(context).textTheme.displayMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          decoration: InputDecoration(hintText: tr('playerName')),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel'),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground))),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(tr('ready'),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary))),
        ],
      ),
    );
    if (player != null && player.isNotEmpty) {
      setState(() {
        players.add(player);
      });
    }
  }

  Future<void> start() async {
    if (!widget.online && players.length < 2) {
      showMessage(context, tr('needTwoPlayers'));
      return;
    }
    setState(() {
      building = true;
    });
    try {
      final deck = await buildDeck(filters);
      if (!mounted) return;
      if (deck.isEmpty) {
        showMessage(context, tr('emptyDeck'));
        return;
      }
      final MesaSession session = widget.online
          ? await FirebaseMesaSession.create(
              widget.name, filters.mediaType, deck)
          : LocalMesaSession(players, deck);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => widget.online
                ? MesaLobbyView(session: session)
                : MesaVoteView(session: session)),
      );
    } on MesaUnavailable catch (e) {
      if (mounted) showMessage(context, mesaErrorText(e));
    } on Exception {
      if (mounted) showMessage(context, tr('errorTitle'));
    } finally {
      if (mounted) {
        setState(() {
          building = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMovie = filters.mediaType == 'movie';
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        iconTheme:
            IconThemeData(color: Theme.of(context).colorScheme.onBackground),
        title: Text(tr(widget.online ? 'createMesa' : 'onePhone'),
            style: Theme.of(context).textTheme.displayMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(15, 5, 15, 20),
        children: [
          sectionTitle(context, tr('whatToWatch')),
          chips([
            MesaChip(
                label: tr('movies'),
                selected: isMovie,
                onTap: () => setState(() {
                      filters.mediaType = 'movie';
                      filters.genreIds = {};
                    })),
            MesaChip(
                label: tr('series'),
                selected: !isMovie,
                onTap: () => setState(() {
                      filters.mediaType = 'tv';
                      filters.genreIds = {};
                      filters.maxRuntime = null;
                    })),
          ]),
          if ((genres[filters.mediaType] ?? []).isNotEmpty) ...[
            sectionTitle(context, tr('genres')),
            chips([
              MesaChip(
                  label: tr('anyGenre'),
                  selected: filters.genreIds.isEmpty,
                  onTap: () => setState(() {
                        filters.genreIds = {};
                      })),
              for (final genre in genres[filters.mediaType]!)
                MesaChip(
                    label: genre['name'],
                    selected: filters.genreIds.contains(genre['id']),
                    onTap: () => setState(() {
                          if (!filters.genreIds.remove(genre['id'])) {
                            filters.genreIds.add(genre['id']);
                          }
                        })),
            ]),
          ],
          if (providers.isNotEmpty) ...[
            sectionTitle(context, tr('platforms')),
            ProviderBar(
              providers: providers,
              selectedIds: filters.providerIds,
              onChanged: (ids) => setState(() {
                filters.providerIds = ids;
              }),
            ),
            const SizedBox(height: 10),
          ],
          sectionTitle(context, tr('minRating')),
          chips([
            MesaChip(
                label: tr('any'),
                selected: filters.minRating == 0,
                onTap: () => setState(() {
                      filters.minRating = 0;
                    })),
            for (final rating in ratings)
              MesaChip(
                  label: '★ ${rating.toStringAsFixed(0)}+',
                  selected: filters.minRating == rating,
                  onTap: () => setState(() {
                        filters.minRating = rating;
                      })),
          ]),
          if (isMovie) ...[
            sectionTitle(context, tr('duration')),
            chips([
              MesaChip(
                  label: tr('any'),
                  selected: filters.maxRuntime == null,
                  onTap: () => setState(() {
                        filters.maxRuntime = null;
                      })),
              for (final minutes in runtimes)
                MesaChip(
                    label:
                        '${tr('upTo')} ${minutes ~/ 60}h${minutes % 60 == 0 ? '' : '${minutes % 60}'}',
                    selected: filters.maxRuntime == minutes,
                    onTap: () => setState(() {
                          filters.maxRuntime = minutes;
                        })),
            ]),
          ],
          sectionTitle(context, tr('releasedFrom')),
          chips([
            MesaChip(
                label: tr('any'),
                selected: filters.fromYear == null,
                onTap: () => setState(() {
                      filters.fromYear = null;
                    })),
            for (final year in years)
              MesaChip(
                  label: '$year',
                  selected: filters.fromYear == year,
                  onTap: () => setState(() {
                        filters.fromYear = year;
                      })),
          ]),
          if (!widget.online) ...[
            sectionTitle(context, tr('players')),
            chips([
              for (var i = 0; i < players.length; i++)
                // Chip, not InputChip: without onPressed it looks disabled.
                Chip(
                  label: Text(players[i]),
                  backgroundColor: Theme.of(context).colorScheme.surfaceTint,
                  labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground),
                  onDeleted: i == 0
                      ? null
                      : () => setState(() {
                            players.removeAt(i);
                          }),
                ),
              if (players.length < 8)
                ActionChip(
                  avatar: Icon(Icons.add,
                      size: 18,
                      color: Theme.of(context).colorScheme.onBackground),
                  label: Text(tr('addPlayer')),
                  backgroundColor: Theme.of(context).colorScheme.surfaceTint,
                  labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground),
                  onPressed: addPlayer,
                ),
            ]),
          ],
          const SizedBox(height: 25),
          MesaButton(
            label: tr('buildDeck'),
            icon: Icons.style,
            onPressed: building ? null : start,
          ),
          if (building)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Center(
                  child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary)),
            ),
        ],
      ),
    );
  }

  Widget chips(List<Widget> children) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 18),
        child: Wrap(spacing: 8, runSpacing: 8, children: children),
      );
}
