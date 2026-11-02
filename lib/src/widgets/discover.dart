import 'package:flixer/global/strings.dart';
import 'package:flixer/src/widgets/movieInfo.dart';
import 'package:flutter/material.dart';

class Discover extends StatelessWidget {
  final List list;
  final Future<void> Function() onRefresh;
  const Discover({super.key, required this.list, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: onRefresh,
        child: Container(
            color: Theme.of(context).colorScheme.background,
            child: list.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 150),
                      Center(
                        child: Text(
                          tr('empty'),
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 10, bottom: 10, right: 5, left: 10),
                            child: ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemBuilder: (BuildContext context, int index) {
                                  return getImage(context, index * 2);
                                },
                                itemCount: (list.length / 2).ceil()),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 10, bottom: 10, right: 10, left: 5),
                            child: ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemBuilder: (BuildContext context, int index) {
                                  return getImage(context, (index * 2) + 1);
                                },
                                itemCount: (list.length / 2).floor()),
                          ),
                        )
                      ],
                    ),
                  )));
  }

  Widget getImage(BuildContext context, int index) {
    final item = list[index];
    return Padding(
      padding: EdgeInsets.only(
          bottom:
              index == list.length - 1 || index == list.length - 2 ? 0 : 10),
      child: SizedBox(
        height: (MediaQuery.of(context).size.width / 3) * 2,
        child: ClipRRect(
            clipBehavior: Clip.hardEdge,
            borderRadius: BorderRadius.circular(10),
            child: Semantics(
              button: true,
              label: item['title'] ?? item['name'],
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MovieInfoPage(
                              movie: item,
                            )),
                  );
                },
                child: Image.network(
                  'https://image.tmdb.org/t/p/w500' + item['poster_path'],
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Container(
                      width: 200,
                      color: Theme.of(context).colorScheme.secondary,
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            )),
      ),
    );
  }
}
