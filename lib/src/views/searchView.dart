import 'dart:math';

import 'package:flixer/ads/adaptativeBannerAd.dart';
import 'package:flixer/src/widgets/movieInfo.dart';
import 'package:flixer/src/widgets/personInfo.dart';
import 'package:flutter/material.dart';
import 'package:flixer/src/apiFunctions/search.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  String searchString = '';
  List searchAllList = [];
  List searchMoviesList = [];
  List searchSeriesList = [];
  List searchPeopleList = [];
  late FocusNode focusNode;

  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3038495459046159/7990033984'
      : 'ca-app-pub-3940256099942544/3986624511';

  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;

  @override
  void initState() {
    super.initState();
    loadAd();

    focusNode = FocusNode();
    focusNode.requestFocus();
    getLists();
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
    _nativeAd?.dispose();
    _nativeAd = null;
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 4,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        BackButton(
                          color: Theme.of(context).colorScheme.onBackground,
                          style: const ButtonStyle(
                              iconSize: MaterialStatePropertyAll(1)),
                        ),
                        Expanded(
                            child: SearchBar(
                          shadowColor: const MaterialStatePropertyAll(
                              Colors.transparent),
                          focusNode: focusNode,
                          hintText: 'Search...',
                          hintStyle: MaterialStatePropertyAll(TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 17)),
                          backgroundColor: MaterialStatePropertyAll(
                              Theme.of(context).colorScheme.surface),
                          textStyle: MaterialStatePropertyAll(TextStyle(
                              decorationThickness: 0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 17)),
                          onChanged: (value) async {
                            setState(() {
                              searchString = value;
                            });

                            getLists();
                            // if (value == '') {
                            //   fetchTrendingMovies();
                            // }
                          },
                        ))
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TabBar(
                    labelColor: Theme.of(context).colorScheme.onBackground,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const <Widget>[
                      Tab(
                        text: 'All',
                      ),
                      Tab(
                        text: 'Movies',
                      ),
                      Tab(
                        text: 'Series',
                      ),
                      Tab(
                        text: 'People',
                      )
                    ],
                  ),
                  Divider(
                    height: 0,
                    thickness: 2,
                  ),
                  Expanded(
                      child: _nativeAdIsLoaded && searchString == ''
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 320, // minimum recommended width
                                    minHeight:
                                        320, // minimum recommended height
                                    maxWidth: 400,
                                    maxHeight: 400,
                                  ),
                                  child: AdWidget(ad: _nativeAd!),
                                ),
                                emptyList(),
                              ],
                            )
                          : TabBarView(children: [
                              showSearch(searchAllList),
                              showSearch(searchMoviesList),
                              showSearch(searchSeriesList),
                              showSearch(searchPeopleList)
                            ]))
                ],
              )),
        ),
      ),
    );
  }

  void loadAd() {
    _nativeAd = NativeAd(
        adUnitId: _adUnitId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            debugPrint('$NativeAd loaded.');
            setState(() {
              _nativeAdIsLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            // Dispose the ad here to free resources.
            debugPrint('$NativeAd failed to load: $error');
            ad.dispose();
          },
        ),
        request: const AdRequest(),
        // Styling
        nativeTemplateStyle: NativeTemplateStyle(
          // Required: Choose a template.
          templateType: TemplateType.medium,
        ));
    _nativeAd?.load();
  }

  void getLists() async {
    searchAllList = await searchAll(searchString);
    searchMoviesList = await searchMovies(searchString);
    searchSeriesList = await searchSeries(searchString);
    searchPeopleList = await searchPeople(searchString);
    setState(() {});
  }

  String generateRandomString(int len) {
    var r = Random();
    return String.fromCharCodes(
        List.generate(len, (index) => r.nextInt(33) + 89));
  }

  Widget emptyList() {
    return Center(
      child: Column(
        children: [
          SizedBox(
            height: 100,
          ),
          Icon(
            Icons.visibility_rounded,
            color: Theme.of(context).colorScheme.secondary,
            size: 50,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              searchString == ''
                  ? 'Write someting to search...'
                  : 'Nothing seems to match',
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.secondary),
            ),
          )
        ],
      ),
    );
  }

  Widget ItemInfoBuilder(Map item) {
    return GestureDetector(
        onTap: () {
          if (!item.containsKey('known_for')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MovieInfoPage(
                        movie: item,
                      )),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PersonInfoPage(personID: item['id'].toString())),
            );
          }
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 200,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 130,
                  child: ClipRRect(
                      clipBehavior: Clip.hardEdge,
                      borderRadius: BorderRadius.circular(10),
                      child: item['poster_path'] != null
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w500' +
                                  item['poster_path'],
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Container(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                );
                              },
                              fit: BoxFit.cover,
                            )
                          : item['profile_path'] != null
                              ? Image.network(
                                  'https://image.tmdb.org/t/p/w500' +
                                      item['profile_path'],
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    );
                                  },
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                )),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.containsKey('title')
                            ? item['title']
                            : item['name'],
                        style: Theme.of(context).textTheme.displayMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      item.containsKey('overview')
                          ? Text(
                              item['overview'],
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(fontSize: 15),
                              maxLines: 7,
                              overflow: TextOverflow.ellipsis,
                            )
                          : item.containsKey('known_for')
                              ? Text(
                                  knownFor(item['known_for']),
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(fontSize: 15),
                                  maxLines: 7,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : SizedBox.shrink()
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }

  String knownFor(List known_for) {
    String str = 'Known for ';
    for (var i = 0; i < known_for.length; i++) {
      Map item = known_for[i];

      if (item.containsKey('title')) {
        str = str +
            item['title'] +
            (i == known_for.length - 2
                ? ' and '
                : (i == known_for.length - 1 ? '' : ', '));
      }
      if (item.containsKey('name')) {
        str = str +
            item['name'] +
            (i == known_for.length - 2
                ? ' and '
                : (i == known_for.length - 1 ? '' : ', '));
      }
    }

    if (str == 'Known for ') {
      str = str + 'nothing yet';
    }
    return str;
  }

  Widget showSearch(List list) {
    return list.isNotEmpty
        ? ListView.separated(
            itemBuilder: (context, index) {
              return ItemInfoBuilder(list[index]);
            },
            separatorBuilder: (context, index) {
              return Divider(thickness: 1);
            },
            itemCount: list.length,
            padding: EdgeInsets.symmetric(vertical: 10),
          )
        : emptyList();
    ;
  }
}
