// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flixer/src/widgets/movieInfo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flixer/ads/adaptativeBannerAd.dart';
import 'dart:io';

import 'package:flixer/global/constants.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class PersonInfoPage extends StatefulWidget {
  final dynamic personID;
  const PersonInfoPage({super.key, required this.personID});
  @override
  _PersonInfoPageState createState() => _PersonInfoPageState(personID);
}

class _PersonInfoPageState extends State<PersonInfoPage> {
  final dynamic personID;
  _PersonInfoPageState(this.personID);
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  String lang = '';
  String watchReg = '';
  dynamic details = [];
  dynamic images = [];
  dynamic movies = [];
  dynamic series = [];

  InterstitialAd? _interstitialAd;

  final adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3038495459046159/9335491973'
      : 'ca-app-pub-3940256099942544/4411468910';

  @override
  void initState() {
    super.initState();
    getPreferences();
    
    loadAd();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void getPreferences() async {
    SharedPreferences prefs = await _prefs;

    setState(() {
      lang = prefs.getString('language')!;
      watchReg = prefs.getString('watchRegion')!;
    });

    getDetails();
    getImages();
    getMovies();
    getSeries();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    _interstitialAd?.show();

    return SafeArea(
      child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: FutureBuilder(
            future: Future.delayed(const Duration(seconds: 1)),
            builder: (context, snapshot) {
              if (details.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              } else {
                return ListView(
                  padding: EdgeInsets.only(top: 0),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          child: Icon(
                            Icons.arrow_back,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                          style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(5),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .background
                                  .withOpacity(0.5),
                              shadowColor: Colors.transparent),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        Text(
                                  details['name'],
                                  style:
                                      Theme.of(context).textTheme.displayMedium,
                                ),
                        ElevatedButton(
                          child: Icon(
                            Icons.home_outlined,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                          style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(5),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .background
                                  .withOpacity(0.5),
                              shadowColor: Colors.transparent),
                          onPressed: () {
                            loadAd();
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                          },
                        )
                      ],
                    ),
                    SizedBox(
                        height: 300,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              clipBehavior: Clip.hardEdge,
                              color: Theme.of(context).colorScheme.background,
                              shadowColor: Colors.transparent,
                              child: details['profile_path'] != null
                                  ? Image.network(
                                      image_resize +
                                          details['profile_path'],
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface,
                                    ),
                            ),
                          ],
                        )),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(details['biography'], style: Theme.of(context).textTheme.displaySmall,),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        'Pictures',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 20),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    SizedBox(
                        height: 200,
                        child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              return Stack(children: <Widget>[
                                Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  clipBehavior: Clip.hardEdge,
                                  color:
                                      Theme.of(context).colorScheme.background,
                                  shadowColor: Colors.transparent,
                                  child: images[index]['file_path'] != null
                                      ? Image.network(
                                          image_resize +
                                              images[index]['file_path'],
                                          height: 200,
                                          width: 130,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          height: 200,
                                          width: 130,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                        ),
                                ),
                              ]);
                            },
                            separatorBuilder: (context, index) {
                              return const SizedBox(
                                width: 5,
                              );
                            },
                            itemCount: images.length)),
                    const SizedBox(
                      height: 5,
                    ),
                    Divider(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        'Movies',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 20),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    SizedBox(
                        height: 200,
                        child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              return Stack(children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => MovieInfoPage(
                                                movie: movies[index])));
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    clipBehavior: Clip.hardEdge,
                                    shadowColor: Colors.transparent,
                                    child: movies[index]['poster_path'] != null
                                        ? Image.network(
                                            image_resize +
                                                movies[index]['poster_path'],
                                            height: 200,
                                            width: 130,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: 200,
                                            width: 130,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                          ),
                                  ),
                                ),
                              ]);
                            },
                            separatorBuilder: (context, index) {
                              return const SizedBox(
                                width: 5,
                              );
                            },
                            itemCount: movies.length)),
                    const SizedBox(
                      height: 5,
                    ),
                    Divider(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        'Series',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 20),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    SizedBox(
                        height: 200,
                        child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              return Stack(children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => MovieInfoPage(
                                                movie: series[index])));
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    clipBehavior: Clip.hardEdge,
                                    shadowColor: Colors.transparent,
                                    child: series[index]['poster_path'] != null
                                        ? Image.network(
                                            image_resize +
                                                series[index]['poster_path'],
                                            height: 200,
                                            width: 130,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: 200,
                                            width: 130,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                          ),
                                  ),
                                ),
                              ]);
                            },
                            separatorBuilder: (context, index) {
                              return const SizedBox(
                                width: 5,
                              );
                            },
                            itemCount: series.length)),
                    const SizedBox(
                      height: 10,
                    )
                  ],
                );
              }
            },
          ),
          bottomNavigationBar: Container(
              color: Theme.of(context).colorScheme.background,
              child: AdaptativeBannerAdWidget())),
    );
  }

  void getDetails() async {
    String queryBase = '/person/' + personID + '?';
    String language = 'language=' + lang + '&';
    String api_key = 'api_key=' + apiKeyAuth;

    String url = apiUrlBase + queryBase + language + api_key;

    final uri = Uri.parse(url);
    final response = await http.get(uri);
    final body = response.body;
    final dtl = jsonDecode(body);
    setState(() {
      details = dtl;
    });
  }

  void getImages() async {
    String queryBase = '/person/' + personID + '/images?';
    String api_key = 'api_key=' + apiKeyAuth;

    String url = apiUrlBase + queryBase + api_key;

    final uri = Uri.parse(url);
    final response = await http.get(uri);
    final body = response.body;
    final json = jsonDecode(body);
    final img = json['profiles'];
    setState(() {
      images = img;
    });
  }

  void getMovies() async {
    String queryBase = '/person/' + personID + '/movie_credits?';
    String language = 'language=' + lang + '&';
    String api_key = 'api_key=' + apiKeyAuth;

    String url = apiUrlBase + queryBase + language + api_key;

    final uri = Uri.parse(url);
    final response = await http.get(uri);
    final body = response.body;
    final json = jsonDecode(body);
    final mov = json['cast'];
    setState(() {
      movies = mov;
    });
  }

  void getSeries() async {
    String queryBase = '/person/' + personID + '/tv_credits?';
    String language = 'language=' + lang + '&';
    String api_key = 'api_key=' + apiKeyAuth;

    String url = apiUrlBase + queryBase + language + api_key;

    final uri = Uri.parse(url);
    final response = await http.get(uri);
    final body = response.body;
    final json = jsonDecode(body);
    final srs = json['cast'];
    setState(() {
      series = srs;
    });
  }

  void loadAd() {
    InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            debugPrint('$ad loaded.');
            // Keep a reference to the ad so you can show it later.
            var rnd = Random().nextInt(100);
            if (rnd > 70) {
              _showInterstitialAd(ad);
            }
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
  }

  void _showInterstitialAd(InterstitialAd ad) {
    _interstitialAd = ad;
    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
