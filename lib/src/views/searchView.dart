import 'dart:async';
import 'dart:math';

import 'package:flixer/global/strings.dart';
import 'package:flixer/src/widgets/movieInfo.dart';
import 'package:flixer/src/widgets/statusViews.dart';
import 'package:flixer/src/widgets/personInfo.dart';
import 'package:flutter/material.dart';
import 'package:flixer/src/apiFunctions/search.dart';
import 'package:flixer/src/apiFunctions/tmdb.dart';

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
  bool searchFailed = false;
  Timer? _debounce;
  int _searchId = 0;
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
  }

  @override
  void dispose() {
    super.dispose();
    _debounce?.cancel();
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
                          hintText: tr('search'),
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

                            // Wait until the user stops typing.
                            _debounce?.cancel();
                            _debounce = Timer(
                                const Duration(milliseconds: 400), getLists);
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
                    tabs: <Widget>[
                      Tab(
                        text: tr('all'),
                      ),
                      Tab(
                        text: tr('movies'),
                      ),
                      Tab(
                        text: tr('series'),
                      ),
                      Tab(
                        text: tr('people'),
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
                          : searchFailed
                          ? ErrorView(onRetry: getLists)
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
    final query = searchString.trim();
    // Responses can arrive out of order; only the latest search is shown.
    final id = ++_searchId;
    if (query.isEmpty) {
      setState(() {
        searchFailed = false;
        searchAllList = [];
        searchMoviesList = [];
        searchSeriesList = [];
        searchPeopleList = [];
      });
      return;
    }

    try {
      final results = await searchAll(query);
      if (id != _searchId) return;
      setState(() {
        searchFailed = false;
        searchAllList = results;
        searchMoviesList =
            results.where((item) => item['media_type'] == 'movie').toList();
        searchSeriesList =
            results.where((item) => item['media_type'] == 'tv').toList();
        searchPeopleList =
            results.where((item) => item['media_type'] == 'person').toList();
      });
    } on TmdbException {
      if (id != _searchId) return;
      setState(() {
        searchFailed = true;
      });
    }
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
                  ? tr('searchHint')
                  : tr('noResults'),
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
    String str = tr('knownFor');
    for (var i = 0; i < known_for.length; i++) {
      Map item = known_for[i];

      if (item.containsKey('title')) {
        str = str +
            item['title'] +
            (i == known_for.length - 2
                ? tr('and')
                : (i == known_for.length - 1 ? '' : ', '));
      }
      if (item.containsKey('name')) {
        str = str +
            item['name'] +
            (i == known_for.length - 2
                ? tr('and')
                : (i == known_for.length - 1 ? '' : ', '));
      }
    }

    if (str == tr('knownFor')) {
      str = str + tr('nothingYet');
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
  }
}
