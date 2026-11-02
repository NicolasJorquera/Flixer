import 'package:flixer/global/strings.dart';
import 'package:flixer/src/apiFunctions/catalog.dart';
import 'package:flixer/src/myList.dart';
import 'package:flixer/src/views/exploreView.dart';
import 'package:flixer/src/views/myListView.dart';
import 'package:flixer/src/widgets/sectionRow.dart';
import 'package:flutter/material.dart';

/// Home tab for movies or series: "My list" and sections, limited to the
/// platforms picked in the shared bar above the tabs.
class HomeFeed extends StatefulWidget {
  final String mediaType;
  final Set<int> providerIds;
  final Future<void> Function() onRefresh;
  const HomeFeed(
      {super.key,
      required this.mediaType,
      required this.providerIds,
      required this.onRefresh});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed>
    with AutomaticKeepAliveClientMixin {
  List genres = [];
  // Part of each section's key, so pull-to-refresh reloads every row.
  int refreshCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadGenres();
  }

  // Without genres the feed still works, just without the genre rows.
  Future<void> loadGenres() async {
    try {
      final result = await getGenres(widget.mediaType);
      if (!mounted) return;
      setState(() {
        genres = result;
      });
    } on Exception {
      return;
    }
  }

  Future<void> refresh() async {
    clearCatalogCache();
    setState(() {
      refreshCount++;
    });
    await Future.wait([loadGenres(), widget.onRefresh()]);
  }

  void openExplore(CatalogQuery query) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ExploreView(query: query, genres: genres)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final sections = homeSections(widget.mediaType, genres, widget.providerIds);

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 15),
        children: [
          ValueListenableBuilder(
            valueListenable: MyList.items,
            builder: (context, saved, _) {
              final items = saved
                  .where((item) => mediaTypeOf(item) == widget.mediaType)
                  .toList();
              if (items.isEmpty) return const SizedBox.shrink();
              return SectionRow(
                title: tr('myList'),
                items: items,
                onSeeAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            MyListView(initialType: widget.mediaType))),
              );
            },
          ),
          for (final query in sections)
            FutureSectionRow(
              key: ValueKey('$refreshCount|${query.path}|${query.params}'),
              title: query.title,
              load: () => fetchCatalogPage(query, 1).then((page) => page.items),
              onSeeAll: () => openExplore(query),
            ),
        ],
      ),
    );
  }
}
