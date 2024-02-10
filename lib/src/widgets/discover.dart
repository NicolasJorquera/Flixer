// ignore_for_file: must_be_immutable

import 'package:flixer/src/widgets/movieInfo.dart';
import 'package:flutter/material.dart';

class Discover extends StatefulWidget {
  List list = [];
  Function onRefresh;
  Discover({super.key, required this.list, required this.onRefresh});

  @override
  State<Discover> createState() => _DiscoverState(list, onRefresh);
}

class _DiscoverState extends State<Discover>
    with SingleTickerProviderStateMixin {
  List list;
  Function onRefresh;

  _DiscoverState(this.list, this.onRefresh) {
    this.list = list;
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
            child: SingleChildScrollView(
              child: Row(
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
                            return getImage(widget.list, index * 2);
                          },
                          itemCount: (widget.list.length / 2).ceil()),
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
                            return getImage(widget.list, (index * 2) + 1);
                          },
                          itemCount: (widget.list.length / 2).ceil()),
                    ),
                  )
                ],
              ),
            )));
  }

  Widget getImage(List list, int index) {
    return Padding(
      padding: EdgeInsets.only(
          bottom:
              index == list.length - 1 || index == list.length - 2 ? 0 : 10),
      child: SizedBox(
        height: (MediaQuery.of(context).size.width / 3) * 2,
        child: ClipRRect(
            clipBehavior: Clip.hardEdge,
            borderRadius: BorderRadius.circular(10),
            child: list.isNotEmpty
                ? list.length > index
                    ? list[index]['poster_path'] != null
                        ? GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MovieInfoPage(
                                          movie: list[index],
                                        )),
                              );
                            },
                            child: Image.network(
                              'https://image.tmdb.org/t/p/w500' +
                                  list[index]['poster_path'],
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Container(
                                  width: 200,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                );
                              },
                              fit: BoxFit.cover,
                            ),
                          )
                        : const SizedBox.shrink()
                    : const SizedBox.shrink()
                : Container(
                    width: 200,
                    color: Theme.of(context).colorScheme.secondary,
                  )),
      ),
    );
  }
}
