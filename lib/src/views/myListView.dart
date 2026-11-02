import 'package:flixer/ads/adaptativeBannerAd.dart';
import 'package:flixer/global/strings.dart';
import 'package:flixer/src/apiFunctions/catalog.dart';
import 'package:flixer/src/myList.dart';
import 'package:flixer/src/widgets/posterCard.dart';
import 'package:flutter/material.dart';

/// Saved titles, with movies and series in separate tabs.
class MyListView extends StatelessWidget {
  /// Tab to open on: 'movie' or 'tv'.
  final String initialType;
  const MyListView({super.key, this.initialType = 'movie'});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialType == 'tv' ? 1 : 0,
      child: ValueListenableBuilder(
        valueListenable: MyList.items,
        builder: (context, items, _) {
          final movies =
              items.where((item) => mediaTypeOf(item) == 'movie').toList();
          final series =
              items.where((item) => mediaTypeOf(item) == 'tv').toList();

          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.background,
              elevation: 0,
              iconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onBackground),
              title: Text(tr('myList'),
                  style: Theme.of(context).textTheme.displayMedium),
              bottom: TabBar(
                labelStyle: Theme.of(context).textTheme.displaySmall,
                labelColor: Theme.of(context).colorScheme.onBackground,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: [
                  Tab(text: '${tr('movies')} (${movies.length})'),
                  Tab(text: '${tr('series')} (${series.length})'),
                ],
              ),
            ),
            body: TabBarView(
                children: [grid(context, movies), grid(context, series)]),
            bottomNavigationBar: Container(
                color: Theme.of(context).colorScheme.background,
                child: AdaptativeBannerAdWidget()),
          );
        },
      ),
    );
  }

  Widget grid(BuildContext context, List items) {
    const spacing = 8.0;
    final cardWidth =
        (MediaQuery.of(context).size.width - 20 - spacing * 2) / 3;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_border,
                  size: 50, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 10),
              Text(
                tr('myListEmpty'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: cardWidth / PosterCard.heightFor(cardWidth),
      ),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          PosterCard(item: items[index], width: cardWidth),
    );
  }
}
