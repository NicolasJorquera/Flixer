// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:flixer/ads/interstitialAd.dart';
import 'package:flixer/global/strings.dart';
import 'package:flixer/global/variables.dart';
import 'package:flixer/src/apiFunctions/tmdb.dart';
import 'package:flixer/src/widgets/personInfo.dart';
import 'package:flixer/src/widgets/statusViews.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:flixer/ads/adaptativeBannerAd.dart';

class MovieInfoPage extends StatefulWidget {
  final dynamic movie;
  const MovieInfoPage({super.key, required this.movie});
  @override
  _MovieInfoPageState createState() => _MovieInfoPageState();
}

class _MovieInfoPageState extends State<MovieInfoPage> {
  YoutubePlayerController? _controller;
  late Map movie;
  late bool isTv;
  late Future<void> details;
  bool isVideoEnded = false;
  bool delayTrailerEnded = false;
  bool muted = true;
  Timer? _trailerTimer;
  List cast = [];
  List recommendations = [];
  List platforms = [];
  String genres = '';

  static const image_url = 'https://image.tmdb.org/t/p/w500';
  static const image_original = 'https://image.tmdb.org/t/p/original';

  @override
  void initState() {
    super.initState();
    movie = Map.of(widget.movie);
    isTv = movie['media_type'] == 'tv' || movie['title'] == null;
    InterstitialAdManager.instance.onDetailOpened();
    details = fetchDetails();
  }

  @override
  void dispose() {
    _trailerTimer?.cancel();
    _controller?.dispose();
    InterstitialAdManager.instance.onDetailClosed();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  /// Details, trailer, cast, recommendations and providers in one request.
  Future<void> fetchDetails() async {
    final json = await tmdbGet('/${isTv ? 'tv' : 'movie'}/${movie['id']}', {
      'append_to_response': 'videos,credits,recommendations,watch/providers',
      // Without this, a Spanish request only returns Spanish trailers.
      'include_video_language': '$language,en,null',
    });

    final List videos = (json['videos']?['results'] ?? [])
        .where((video) => video['site'] == 'YouTube')
        .toList();
    final trailer = videos.firstWhere((video) => video['type'] == 'Trailer',
        orElse: () => videos.isEmpty ? null : videos.first);

    setState(() {
      for (final key in const [
        'title',
        'name',
        'overview',
        'vote_average',
        'release_date',
        'first_air_date',
        'backdrop_path'
      ]) {
        if (json[key] != null) movie[key] = json[key];
      }
      genres = (json['genres'] as List? ?? [])
          .map((genre) => genre['name'])
          .join(' - ');
      cast = json['credits']?['cast'] ?? [];
      recommendations = (json['recommendations']?['results'] ?? [])
          .where((item) => item['poster_path'] != null)
          .toList();
      platforms = parsePlatforms(json['watch/providers']?['results']?[region]);

      if (trailer != null && _controller == null) {
        _controller = YoutubePlayerController(
          initialVideoId: trailer['key'],
          flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: true,
              hideControls: true,
              hideThumbnail: true,
              enableCaption: false,
              useHybridComposition: true),
        );
        _trailerTimer = Timer(const Duration(seconds: 5), () {
          setState(() {
            delayTrailerEnded = true;
          });
        });
      }
    });
  }

  /// One entry per provider, tagged with how it is offered (stream first).
  List parsePlatforms(Map? country) {
    final List result = [];
    if (country == null) return result;
    for (final type in const ['flatrate', 'free', 'ads', 'rent', 'buy']) {
      for (final provider in (country[type] ?? [])) {
        if (provider['logo_path'] != null &&
            !result.any((p) => p['provider_id'] == provider['provider_id'])) {
          result.add({...provider, 'type': type});
        }
      }
    }
    return result;
  }

  void pauseTrailer() {
    _controller?.pause();
    setState(() {
      isVideoEnded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    return SafeArea(
      child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: FutureBuilder(
            future: details,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorView(
                    onRetry: () => setState(() {
                          details = fetchDetails();
                        }));
              } else if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingView();
              } else {
                return PopScope(
                  onPopInvokedWithResult: (didPop, result) {
                    _controller?.pause();
                  },
                  child: ListView(
                    padding: EdgeInsets.only(top: 0),
                    children: [
                      Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.only(bottom: 0),
                            child: ShaderMask(
                              shaderCallback: (rect) {
                                return LinearGradient(
                                  begin: Alignment.center,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Theme.of(context).colorScheme.background,
                                    Colors.transparent
                                  ],
                                ).createShader(Rect.fromLTRB(
                                    0, 0, rect.width, rect.height));
                              },
                              blendMode: BlendMode.dstIn,
                              child: movie['backdrop_path'] == null
                                  ? Container()
                                  : _controller == null ||
                                          isVideoEnded ||
                                          !delayTrailerEnded
                                      ? Image.network(
                                          image_original +
                                              movie['backdrop_path'],
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.3,
                                          width:
                                              MediaQuery.of(context).size.width,
                                          fit: BoxFit.cover,
                                        )
                                      : SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.3,
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: YoutubePlayer(
                                            controlsTimeOut: Duration.zero,
                                            controller: _controller!,
                                            showVideoProgressIndicator: false,
                                            onReady: () {
                                              setState(() {
                                                isVideoEnded = false;
                                              });
                                            },
                                            onEnded: (metaData) {
                                              setState(() {
                                                isVideoEnded = true;
                                              });
                                            },
                                          ),
                                        ),
                            ),
                          ),
                          Positioned(
                              top: MediaQuery.of(context).size.height * 0.005,
                              left: MediaQuery.of(context).size.width * 0.005,
                              child: ElevatedButton(
                                child: Icon(
                                  Icons.arrow_back,
                                  semanticLabel: tr('back'),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
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
                              )),
                          Positioned(
                              top: MediaQuery.of(context).size.height * 0.005,
                              right: MediaQuery.of(context).size.width * 0.005,
                              child: ElevatedButton(
                                child: Icon(
                                  Icons.home_outlined,
                                  semanticLabel: tr('home'),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
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
                                  Navigator.popUntil(
                                      context, (route) => route.isFirst);
                                },
                              )),
                          if (_controller != null &&
                              delayTrailerEnded &&
                              !isVideoEnded)
                            Positioned(
                                bottom: 8,
                                right: 8,
                                child: IconButton(
                                  tooltip: tr(muted ? 'unmute' : 'mute'),
                                  style: IconButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .background
                                          .withOpacity(0.5)),
                                  onPressed: () {
                                    setState(() {
                                      muted
                                          ? _controller!.unMute()
                                          : _controller!.mute();
                                      muted = !muted;
                                    });
                                  },
                                  icon: Icon(
                                    muted ? Icons.volume_off : Icons.volume_up,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                  ),
                                )),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Text(
                                  movie['title'] ?? movie['name'],
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.displayLarge,
                                )),
                            const SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              height: 20,
                              child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onBackground,
                                          size: 10,
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          (movie['vote_average'] as num? ?? 0)
                                                  .toStringAsFixed(1) +
                                              '/10',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onBackground),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Icon(
                                          Icons.circle,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onBackground,
                                          size: 5,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          movie['release_date'] ??
                                              (movie['first_air_date'] == null
                                                  ? ''
                                                  : movie['first_air_date']),
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onBackground),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Icon(
                                          Icons.circle,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onBackground,
                                          size: 5,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          genres,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onBackground),
                                        )
                                      ],
                                    ),
                                  ]),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Text(
                          (movie['overview'] ?? '').isEmpty
                              ? tr('noOverview')
                              : movie['overview'],
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 15),
                        ),
                      ),
                      Divider(
                        color: Theme.of(context).colorScheme.secondary,
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          tr('whereToWatch'),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 20),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      platforms.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                  tr('noPlatforms'),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface)),
                            )
                          : SizedBox(
                              height: 82,
                              child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    return Semantics(
                                      label:
                                          '${platforms[index]['provider_name']}, ${tr(platforms[index]['type'])}',
                                      excludeSemantics: true,
                                      child: Column(
                                        children: [
                                          Card(
                                            shadowColor: Colors.transparent,
                                            color: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            clipBehavior: Clip.hardEdge,
                                            child: Image.network(
                                              image_url +
                                                  platforms[index]['logo_path'],
                                              height: 50,
                                              width: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Text(
                                            tr(platforms[index]['type']),
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onBackground,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  separatorBuilder: (context, index) {
                                    return const SizedBox(
                                      width: 5,
                                    );
                                  },
                                  itemCount: platforms.length)),
                      Padding(
                        padding: const EdgeInsets.only(left: 10, top: 5),
                        child: Text(
                          tr('justWatch'),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 11),
                        ),
                      ),
                      Divider(
                        color: Theme.of(context).colorScheme.secondary,
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          tr('cast'),
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
                                      pauseTrailer();
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  PersonInfoPage(
                                                      personID: cast[index]
                                                              ['id']
                                                          .toString())));
                                    },
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      clipBehavior: Clip.hardEdge,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .background,
                                      shadowColor: Colors.transparent,
                                      child: ShaderMask(
                                          shaderCallback: (rect) {
                                            return LinearGradient(
                                              begin: Alignment.center,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Theme.of(context)
                                                    .colorScheme
                                                    .background,
                                                Colors.transparent
                                              ],
                                            ).createShader(Rect.fromLTRB(
                                                0, 0, rect.width, rect.height));
                                          },
                                          blendMode: BlendMode.dstIn,
                                          child: cast[index]['profile_path'] !=
                                                  null
                                              ? Image.network(
                                                  image_url +
                                                      cast[index]
                                                          ['profile_path'],
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
                                                )),
                                    ),
                                  ),
                                  Positioned(
                                    top: 160,
                                    left: 5,
                                    child: Text(
                                      cast[index]['name'] + tr('as'),
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onBackground,
                                          fontSize: 12),
                                    ),
                                  ),
                                  Positioned(
                                    top: 180,
                                    left: 5,
                                    child: Text(
                                      cast[index]['character'] ?? '',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onBackground,
                                          fontSize: 12),
                                    ),
                                  )
                                ]);
                              },
                              separatorBuilder: (context, index) {
                                return const SizedBox(
                                  width: 5,
                                );
                              },
                              itemCount: cast.length)),
                      Divider(
                        color: Theme.of(context).colorScheme.secondary,
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          tr('related'),
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
                                      pauseTrailer();

                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  MovieInfoPage(
                                                      movie: recommendations[
                                                          index])));
                                    },
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      clipBehavior: Clip.hardEdge,
                                      shadowColor: Colors.transparent,
                                      child: recommendations[index]
                                                  ['poster_path'] !=
                                              null
                                          ? Image.network(
                                              image_url +
                                                  recommendations[index]
                                                      ['poster_path'],
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
                              itemCount: recommendations.length)),
                      const SizedBox(
                        height: 10,
                      )
                    ],
                  ),
                );
              }
            },
          ),
          bottomNavigationBar: Container(
              color: Theme.of(context).colorScheme.background,
              child: AdaptativeBannerAdWidget())),
    );
  }
}
