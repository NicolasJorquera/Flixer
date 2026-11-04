import 'package:flixer/src/apiFunctions/catalog.dart';
import 'package:flixer/ads/adaptativeBannerAd.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flixer/global/strings.dart';
import 'package:flixer/global/variables.dart';

import 'widgets/homeFeed.dart';
import 'widgets/providerBar.dart';
import 'views/myListView.dart';
import 'mesa/mesaHomeView.dart';
import 'views/searchView.dart';

import '../styles/appTheme.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainApp createState() => MainApp();
}

class MainApp extends State<MainPage> with SingleTickerProviderStateMixin {
  ThemeMode mode = ThemeMode.dark;
  bool switchTheme = false;
  // Part of the feeds' keys: bumping it rebuilds them after a settings change.
  int feedVersion = 0;
  // Platform filter shared by the Movies and Series tabs; empty means all.
  List providers = [];
  Set<int> providerIds = {};
  // The platform bar hides while scrolling down and returns when scrolling up.
  bool showProviderBar = true;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    getPreferences();
    loadProviders();
  }

  // Without providers the bar stays empty and the feeds show everything.
  Future<void> loadProviders() async {
    try {
      final result = await getProviders();
      setState(() {
        providers = result;
        // Drop platforms that are not offered in a newly chosen region.
        providerIds = providerIds
            .where((id) => providers.any((p) => p['provider_id'] == id))
            .toSet();
      });
    } on Exception {
      return;
    }
  }

  void getPreferences() async {
    SharedPreferences prefs = await _prefs;
    setState(() {
      mode = prefs.getString('themeMode') == 'light'
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  void reloadFeeds() {
    clearCatalogCache();
    setState(() {
      feedVersion++;
    });
    loadProviders();
  }

  @override
  Widget build(BuildContext context) {
    switchTheme = mode == ThemeMode.dark ? false : true;

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: Builder(
          builder: (context) => DefaultTabController(
            initialIndex: 0,
            length: 2,
            child: Scaffold(
                backgroundColor: Theme.of(context).colorScheme.background,
                appBar: AppBar(
                  backgroundColor: Theme.of(context).colorScheme.background,
                  elevation: 0,
                  leading: Image.asset(
                    mode == ThemeMode.dark
                        ? 'assets/icon/darkThemeIconLarge.png'
                        : 'assets/icon/lightThemeIconLarge.png',
                    height: 50,
                    width: 50,
                  ),
                  actions: [
                    IconButton(
                        tooltip: tr('mesa'),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MesaHomeView()));
                        },
                        icon: Icon(
                          Icons.groups_outlined,
                          color: Theme.of(context).colorScheme.onBackground,
                          size: 25,
                        )),
                    IconButton(
                        tooltip: tr('myList'),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MyListView()));
                        },
                        icon: Icon(
                          Icons.bookmark_border,
                          color: Theme.of(context).colorScheme.onBackground,
                          size: 25,
                        )),
                    IconButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SearchView()));
                        },
                        icon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.onBackground,
                          size: 25,
                        )),
                    IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(
                                  builder: (context, setSheetState) =>
                                      Padding(
                                padding: EdgeInsets.only(
                                    left: 15,
                                    right: 15,
                                    bottom: 15 +
                                        MediaQuery.of(context)
                                            .viewPadding
                                            .bottom),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 10, 0, 20),
                                      child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              4,
                                          child: Container(
                                            width: double.infinity,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                          )),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 15),
                                            child: Icon(
                                              Icons.translate,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onBackground,
                                            ),
                                          ),
                                          Text(
                                            tr('language'),
                                            style: Theme.of(context)
                                                .textTheme
                                                .displayMedium
                                                ?.copyWith(fontSize: 18),
                                          ),
                                        ]),
                                        SizedBox(
                                          width: 150,
                                          child: DropdownMenu(
                                            expandedInsets: EdgeInsets.only(
                                                left: 20, right: 0),
                                            inputDecorationTheme:
                                                InputDecorationTheme(
                                                    border: InputBorder.none),
                                            initialSelection: language,
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .displaySmall
                                                ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onBackground,
                                                    fontSize: 18),
                                            menuStyle: MenuStyle(
                                                backgroundColor:
                                                    MaterialStatePropertyAll(
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .surfaceTint),
                                                shadowColor:
                                                    MaterialStatePropertyAll(
                                                        Colors.transparent)),
                                            dropdownMenuEntries: [
                                              DropdownMenuEntry(
                                                value: 'en',
                                                label: 'English',
                                                labelWidget: Text('English',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displaySmall
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onBackground,
                                                            decorationColor: Colors
                                                                .transparent)),
                                              ),
                                              DropdownMenuEntry(
                                                  value: 'es',
                                                  label: 'Español',
                                                  labelWidget: Text('Español',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .displaySmall
                                                          ?.copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onBackground,
                                                              decorationColor:
                                                                  Colors
                                                                      .transparent)))
                                            ],
                                            onSelected: (value) async {
                                              language = value!;
                                              SharedPreferences prefs =
                                                  await _prefs;
                                              prefs.setString(
                                                  'language', value);
                                              setSheetState(() {});
                                              reloadFeeds();
                                            },
                                          ),
                                        )
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 15),
                                            child: Icon(
                                              Icons.place,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onBackground,
                                            ),
                                          ),
                                          Text(
                                            tr('region'),
                                            style: Theme.of(context)
                                                .textTheme
                                                .displayMedium
                                                ?.copyWith(fontSize: 18),
                                          ),
                                        ]),
                                        SizedBox(
                                          width: 150,
                                          child: DropdownMenu(
                                            expandedInsets: EdgeInsets.only(
                                                left: 20, right: 0),
                                            inputDecorationTheme:
                                                InputDecorationTheme(
                                                    border: InputBorder.none),
                                            initialSelection: region,
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .displaySmall
                                                ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onBackground,
                                                    fontSize: 18),
                                            menuStyle: MenuStyle(
                                                backgroundColor:
                                                    MaterialStatePropertyAll(
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .surfaceTint),
                                                shadowColor:
                                                    MaterialStatePropertyAll(
                                                        Colors.transparent)),
                                            dropdownMenuEntries: [
                                              DropdownMenuEntry(
                                                value: 'US',
                                                label: 'USA',
                                                labelWidget: Text('USA',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displaySmall
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onBackground,
                                                            decorationColor: Colors
                                                                .transparent)),
                                              ),
                                              DropdownMenuEntry(
                                                  value: 'CL',
                                                  label: 'Chile',
                                                  labelWidget: Text('Chile',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .displaySmall
                                                          ?.copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onBackground,
                                                              decorationColor:
                                                                  Colors
                                                                      .transparent)))
                                            ],
                                            onSelected: (value) async {
                                              region = value!;
                                              SharedPreferences prefs =
                                                  await _prefs;
                                              prefs.setString(
                                                  'watchRegion', value);
                                              reloadFeeds();
                                            },
                                          ),
                                        )
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 15),
                                            child: Icon(
                                              Icons.light,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onBackground,
                                            ),
                                          ),
                                          Text(
                                            tr('theme'),
                                            style: Theme.of(context)
                                                .textTheme
                                                .displayMedium
                                                ?.copyWith(fontSize: 18),
                                          ),
                                        ]),
                                        Row(
                                          children: [
                                            Text(
                                              tr('dark'),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .displaySmall
                                                  ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onBackground,
                                                      fontSize: 15),
                                            ),
                                            Switch(
                                                value: switchTheme,
                                                onChanged: (value) async {
                                                  setSheetState(() {
                                                    switchTheme = value;
                                                  });
                                                  setState(() {
                                                    mode =
                                                        mode == ThemeMode.dark
                                                            ? ThemeMode.light
                                                            : ThemeMode.dark;
                                                  });
                                                  SharedPreferences prefs =
                                                      await _prefs;
                                                  prefs.setString('themeMode',
                                                      value ? 'light' : 'dark');
                                                }),
                                            Text(
                                              tr('light'),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .displaySmall
                                                  ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onBackground,
                                                      fontSize: 15),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                    Divider(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      height: 30,
                                    ),
                                    Row(children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15),
                                        child: Icon(
                                          Icons.info_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onBackground,
                                        ),
                                      ),
                                      Expanded(
                                        // Attribution required by the TMDB API terms.
                                        child: Text(
                                          '${tr('notStreaming')} '
                                          'This product uses the TMDB API but is not endorsed or certified by TMDB. '
                                          '${tr('justWatch')}.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .displaySmall
                                              ?.copyWith(fontSize: 13),
                                        ),
                                      ),
                                    ])
                                  ],
                                ),
                              ));
                            },
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20))),
                          );
                        },
                        icon: Icon(
                          Icons.settings,
                          color: Theme.of(context).colorScheme.onBackground,
                          size: 25,
                        ))
                  ],
                ),
                body: Column(
                  children: [
                    // Above the tabs because it filters both.
                    TweenAnimationBuilder<double>(
                      tween:
                          Tween(end: showProviderBar && providers.isNotEmpty ? 1 : 0),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, visible, child) => ClipRect(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          heightFactor: visible,
                          child: Opacity(opacity: visible, child: child),
                        ),
                      ),
                      child: ProviderBar(
                        providers: providers,
                        selectedIds: providerIds,
                        onChanged: (ids) => setState(() {
                          providerIds = ids;
                        }),
                      ),
                    ),
                    TabBar(
                        labelStyle: Theme.of(context).textTheme.displayMedium,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        tabs: [
                          Tab(
                            text: tr('movies'),
                          ),
                          Tab(
                            text: tr('series'),
                          )
                        ]),
                    Expanded(
                      child: NotificationListener<UserScrollNotification>(
                        onNotification: (notification) {
                          // Only the feeds' vertical scroll, not tabs or rows.
                          if (notification.metrics.axis != Axis.vertical) {
                            return false;
                          }
                          final show = notification.direction ==
                              ScrollDirection.forward;
                          if (notification.direction != ScrollDirection.idle &&
                              show != showProviderBar) {
                            setState(() {
                              showProviderBar = show;
                            });
                          }
                          return false;
                        },
                        child: TabBarView(children: [
                          HomeFeed(
                              key: ValueKey('movie$feedVersion'),
                              mediaType: 'movie',
                              providerIds: providerIds,
                              onRefresh: loadProviders),
                          HomeFeed(
                              key: ValueKey('tv$feedVersion'),
                              mediaType: 'tv',
                              providerIds: providerIds,
                              onRefresh: loadProviders),
                        ]),
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: Container(
                    color: Theme.of(context).colorScheme.background,
                    child: AdaptativeBannerAdWidget())
                // bottomNavigationBar: BottomNavigationBar(
                //     type: BottomNavigationBarType.fixed,
                //     backgroundColor: Theme.of(context).colorScheme.background,
                //     currentIndex: selectedIndex,
                //     iconSize: 30,
                //     showSelectedLabels: true,
                //     selectedFontSize: 12,
                //     unselectedFontSize: 12,
                //     showUnselectedLabels: true,
                //     selectedItemColor: Theme.of(context).colorScheme.onBackground,
                //     unselectedItemColor: Theme.of(context).colorScheme.secondary,
                //     onTap: (value) {
                //       setState(() {
                //         selectedIndex = value;
                //       });
                //       if (value == 1 && series.isEmpty) {
                //         getSeries();
                //       }
                //     },
                //     items: const [
                //       BottomNavigationBarItem(
                //           icon: Icon(
                //             Icons.movie,
                //           ),
                //           label: 'Movies'),
                //       BottomNavigationBarItem(
                //           icon: Icon(
                //             Icons.tv,
                //           ),
                //           label: 'Series'),
                //       // BottomNavigationBarItem(
                //       //     icon: Icon(
                //       //       Icons.light,
                //       //     ),
                //       //     label: 'Match'),
                //       // BottomNavigationBarItem(
                //       //     icon: Icon(
                //       //       Icons.person,
                //       //     ),
                //       //     label: 'User')
                //     ])
                ),
          ),
        ));
  }
}
