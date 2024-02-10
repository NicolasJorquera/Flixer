import 'package:flixer/src/apiFunctions/discoverMovies.dart';
import 'package:flixer/src/apiFunctions/discoverSeries.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/discover.dart';
import 'pages/matchPage/matchPage.dart';
import 'pages/userPage/userPage.dart';
import 'views/searchView.dart';

import '../styles/appTheme.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainApp createState() => MainApp();
}

class MainApp extends State<MainPage> with SingleTickerProviderStateMixin {
  int selectedIndex = 0;
  ThemeMode mode = ThemeMode.dark;
  bool switchTheme = false;
  List movies = [];
  List series = [];
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String lang = '';
  String watchReg = '';

  @override
  void initState() {
    super.initState();
    getPreferences();
    getMovies();
    getSeries();
  }

  void getPreferences() async {
    SharedPreferences prefs = await _prefs;
    if (!prefs.containsKey('language')) {
      prefs.setString('language', 'en');
    }
    if (!prefs.containsKey('watchRegion')) {
      prefs.setString('watchRegion', 'CL');
    }
    if (!prefs.containsKey('themeMode')) {
      prefs.setString('themeMode', 'dark');
    }

    setState(() {
      lang = prefs.getString('language')!;
      watchReg = prefs.getString('watchRegion')!;
      mode = prefs.getString('themeMode') == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;
    });

    // getMovies();
    // getSeries();
  }

  void getMovies() async {
    List mvs = await getDiscoverMovies();
    setState(() {
      movies = mvs;
    });
  }

  void getSeries() async {
    List srs = await getDiscoverSeries();
    setState(() {
      series = srs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final children = [
      Discover(
        list: movies,
        onRefresh: () => getMovies(),
      ),
      Discover(
        list: series,
        onRefresh: () => getSeries(),
      ),
      const MatchPage(),
      const UserPage()
    ];

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
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.background,
                title: Text(
                  'FLIXER',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground),
                ),
                actions: [
                  // IconButton(
                  //     onPressed: () {
                  //       setState(() {
                  //         mode = mode == ThemeMode.dark
                  //             ? ThemeMode.light
                  //             : ThemeMode.dark;
                  //       });
                  //     },
                  //     icon: Icon(
                  //       mode == ThemeMode.dark
                  //           ? Icons.light_mode
                  //           : Icons.dark_mode,
                  //       color: Theme.of(context).colorScheme.onBackground,
                  //       size: 25,
                  //     )),
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
                            return Padding(
                              padding: const EdgeInsets.only(
                                  left: 15, right: 15, bottom: 15),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 10, 0, 20),
                                    child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
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
                                          'Language',
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
                                          initialSelection: lang,
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
                                                          color:
                                                              Theme.of(context)
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
                                                            decorationColor: Colors
                                                                .transparent)))
                                          ],
                                          onSelected: (value) async {
                                            SharedPreferences prefs =
                                                await _prefs;
                                            prefs.setString('language', value!);
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
                                          'Region',
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
                                          initialSelection: watchReg,
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
                                                          color:
                                                              Theme.of(context)
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
                                                            decorationColor: Colors
                                                                .transparent)))
                                          ],
                                          onSelected: (value) async {
                                            SharedPreferences prefs =
                                                await _prefs;
                                            prefs.setString(
                                                'watchRegion', value!);
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
                                          'Theme',
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayMedium
                                              ?.copyWith(fontSize: 18),
                                        ),
                                      ]),
                                      Row(
                                        children: [
                                          Text(
                                            'Dark',
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
                                                setState(() {
                                                  mode = mode == ThemeMode.dark
                                                      ? ThemeMode.light
                                                      : ThemeMode.dark;
                                                });
                                                SharedPreferences prefs =
                                                    await _prefs;
                                                prefs.setString('themeMode',
                                                    value ? 'light' : 'dark');
                                              }),
                                          Text(
                                            'Light',
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
                                  )
                                ],
                              ),
                            );
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
                bottom: TabBar(
                    labelStyle: Theme.of(context).textTheme.displayMedium,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const [
                      Tab(
                        text: 'Movies',
                      ),
                      Tab(
                        text: 'Series',
                      )
                    ]),
              ),
              body: TabBarView(children: [
                Discover(
                  list: movies,
                  onRefresh: () => getMovies(),
                ),
                Discover(
                  list: series,
                  onRefresh: () => getSeries(),
                ),
              ]),
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
