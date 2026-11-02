import 'package:flixer/ads/adaptativeBannerAd.dart';
import 'package:flixer/global/strings.dart';
import 'package:flixer/src/apiFunctions/catalog.dart';
import 'package:flixer/src/widgets/posterCard.dart';
import 'package:flixer/src/widgets/statusViews.dart';
import 'package:flutter/material.dart';

/// Full list behind a home section: a poster grid that loads more pages while
/// scrolling. Category sections (discover queries that are not already a
/// genre row) get genre chips; several genres can be picked.
class ExploreView extends StatefulWidget {
  final CatalogQuery query;
  final List genres;
  const ExploreView({super.key, required this.query, this.genres = const []});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  final ScrollController _scroll = ScrollController();
  final List items = [];
  int page = 0;
  int totalPages = 1;
  bool loading = false;
  bool failed = false;
  Set<int> genreIds = {};
  // Bumped when the genre changes so late pages of the old query are ignored.
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) loadMore();
    });
    loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  CatalogQuery get query {
    if (!showGenres || genreIds.isEmpty) return widget.query;
    // '|' means OR: titles in any of the picked genres.
    final params = {
      ...widget.query.params,
      'with_genres': (genreIds.toList()..sort()).join('|'),
    };
    return CatalogQuery(widget.query.title, widget.query.path, params);
  }

  Future<void> loadMore() async {
    if (loading || page >= totalPages) return;
    final version = _version;
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final result = await fetchCatalogPage(query, page + 1);
      if (!mounted || version != _version) return;
      setState(() {
        page++;
        totalPages = result.totalPages;
        // Popular lists shift between pages, so skip repeats.
        final ids = items.map((item) => item['id']).toSet();
        items.addAll(result.items.where((item) => !ids.contains(item['id'])));
        loading = false;
      });
    } on Exception {
      if (!mounted || version != _version) return;
      setState(() {
        loading = false;
        failed = true;
      });
    }
  }

  bool get showGenres =>
      widget.query.isDiscover &&
      !widget.query.params.containsKey('with_genres') &&
      widget.genres.isNotEmpty;

  /// null clears the selection ("All").
  void toggleGenre(int? id) {
    setState(() {
      if (id == null) {
        genreIds = {};
      } else if (!genreIds.remove(id)) {
        genreIds.add(id);
      }
      _version++;
      items.clear();
      page = 0;
      totalPages = 1;
      loading = false;
    });
    loadMore();
  }

  @override
  Widget build(BuildContext context) {
    const spacing = 8.0;
    final cardWidth =
        (MediaQuery.of(context).size.width - 20 - spacing * 2) / 3;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        iconTheme:
            IconThemeData(color: Theme.of(context).colorScheme.onBackground),
        title: Text(widget.query.title,
            style: Theme.of(context).textTheme.displayMedium),
        bottom: showGenres
            ? PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      for (final genre in [
                        {'id': null, 'name': tr('allGenres')},
                        ...widget.genres
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: genreChip(context, genre),
                        ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: items.isEmpty && failed
          ? ErrorView(onRetry: loadMore)
          : items.isEmpty && loading
              ? const LoadingView()
              : items.isEmpty
                  ? Center(
                      child: Text(tr('empty'),
                          style: Theme.of(context).textTheme.displayMedium))
                  : GridView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio:
                            cardWidth / PosterCard.heightFor(cardWidth),
                      ),
                      // One extra cell for the loading/retry footer.
                      itemCount: items.length + (page < totalPages ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < items.length) {
                          return PosterCard(
                              item: items[index], width: cardWidth);
                        }
                        return Center(
                          child: failed
                              ? IconButton(
                                  tooltip: tr('retry'),
                                  onPressed: loadMore,
                                  icon: Icon(Icons.refresh,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary),
                                )
                              : CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary),
                        );
                      },
                    ),
      bottomNavigationBar: Container(
          color: Theme.of(context).colorScheme.background,
          child: AdaptativeBannerAdWidget()),
    );
  }

  Widget genreChip(BuildContext context, Map genre) {
    final id = genre['id'];
    final selected = id == null ? genreIds.isEmpty : genreIds.contains(id);
    // Selected chips are inverted rather than red, like the platform bar.
    return FilterChip(
      label: Text(genre['name']),
      selected: selected,
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.onBackground,
      backgroundColor: Theme.of(context).colorScheme.surfaceTint,
      labelStyle: TextStyle(
          color: selected
              ? Theme.of(context).colorScheme.background
              : Theme.of(context).colorScheme.onBackground),
      onSelected: (_) => toggleGenre(id),
    );
  }
}
