import 'package:flutter/material.dart';

class Discover extends StatefulWidget {
  List categories = [];
  Function onRefresh;
  Discover({super.key, required this.categories, required this.onRefresh});

  @override
  State<Discover> createState() => _DiscoverState(categories, onRefresh);
}

class _DiscoverState extends State<Discover>
    with SingleTickerProviderStateMixin {
  List categories;
  Function onRefresh;

  _DiscoverState(this.categories, this.onRefresh) {
    this.categories = categories;
    this.onRefresh = onRefresh;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: () {
          widget.onRefresh();
          return Future.delayed(const Duration(seconds: 1));
        },
        child: Container(
            color: Theme.of(context).colorScheme.background,
            child: ListView.separated(
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(0, index == 0 ? 5 : 0, 0,
                        index == widget.categories.length - 1 ? 10 : 0),
                    child: CategoryRow(
                      widget.categories[index],
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) => Divider(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                itemCount: widget.categories.length)));
  }

  Widget CategoryRow(Map category) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 0, 0, 5),
            child: Text(
              category.isNotEmpty ? category['name'] : 'Category',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.fromLTRB(
                        index == 0 ? 5 : 0,
                        0,
                        index == category.isNotEmpty
                            ? category[1].length - 1
                                ? 5
                                : 0
                            : 0,
                        0),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: category.containsKey('list')
                            ? category['list'][index]['poster_path'] != null
                                ? Image.network(
                                    'https://image.tmdb.org/t/p/w500' +
                                        category['list'][index]['poster_path'],
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return Container(
                                        width: 133,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      );
                                    },
                                  )
                                : const SizedBox.shrink()
                            : Container(
                                width: 133,
                                color: Theme.of(context).colorScheme.secondary,
                              )),
                  ),
              separatorBuilder: (context, index) => const SizedBox(width: 5),
              itemCount:
                  category.containsKey('list') ? category['list'].length : 10),
        )
      ]),
    );
  }
}
