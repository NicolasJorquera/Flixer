// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;

class MovieInfoPage extends StatefulWidget {
  final dynamic movie;
  const MovieInfoPage({super.key, required this.movie});
  @override
  _MovieInfoPageState createState() => _MovieInfoPageState(movie);
}

class _MovieInfoPageState extends State<MovieInfoPage> {
  dynamic _controller = '';
  final dynamic movie;
  List videos = [];
  List cast = [];
  bool isVideoEnded = false;
  bool delayTrailerEnded = false;
  List recommendations = [];
  List platforms = [];
  String genres = '';
  _MovieInfoPageState(this.movie);

  static const image_url = 'https://image.tmdb.org/t/p/w500';
  static const image_original = 'https://image.tmdb.org/t/p/original';

  @override
  void initState() {
    super.initState();
    //fetchVideos();
    fetchCast();
    fetchRecommendations();
    fetchPlatforms();
    fetchGenres();

    _delayTrailer();
  }

  void _delayTrailer() {
// Timer.periodic will execute the code which is in the callback,
// in this case, we are increasing the sec state every second,
// As you want to execute it every minute, put Duration(seconds: 60)

    Timer(const Duration(seconds: 5), () {
      setState(() {
        delayTrailerEnded = true;
      });
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: FutureBuilder(
          future: Future.delayed(const Duration(seconds: 1)),
          builder: (context, snapshot) {
            if (cast.isEmpty && recommendations.isEmpty && platforms.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            } else {
              return ListView(
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
                            ).createShader(
                                Rect.fromLTRB(0, 0, rect.width, rect.height));
                          },
                          blendMode: BlendMode.dstIn,
                          child: movie['backdrop_path'] == null
                              ? Container()
                              : (videos.isEmpty && !isVideoEnded) ||
                                      isVideoEnded ||
                                      !delayTrailerEnded
                                  ? Image.network(
                                      image_original + movie['backdrop_path'],
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.3,
                                      width: MediaQuery.of(context).size.width,
                                      fit: BoxFit.cover,
                                    )
                                  : SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.3,
                                      width: MediaQuery.of(context).size.width,
                                      child: YoutubePlayer(
                                        controlsTimeOut: Duration.zero,
                                        controller: _controller,
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
                        bottom: MediaQuery.of(context).size.height * 0.22,
                        right: MediaQuery.of(context).size.width * 0.85,
                        child: BackButton(
                          color: Colors.white,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge,
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
                                      movie['vote_average'].toString() + '/10',
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
                      movie['overview'],
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontSize: 15),
                    ),
                  ),
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
                      'Platforms',
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
                          child: Text('No platforms available in your region',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground)),
                        )
                      : SizedBox(
                          height: 60,
                          child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return Card(
                                  color: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  clipBehavior: Clip.hardEdge,
                                  child: Image.network(
                                    image_url + platforms[index]['logo_path'],
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) {
                                return const SizedBox(
                                  width: 5,
                                );
                              },
                              itemCount: platforms.length)),
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
                      'Cast',
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
                                color: Theme.of(context).colorScheme.background,
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
                                    child: cast[index]['profile_path'] != null
                                        ? Image.network(
                                            image_url +
                                                cast[index]['profile_path'],
                                            height: 200,
                                            width: 130,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: 200,
                                            width: 130,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onBackground,
                                          )),
                              ),
                              Positioned(
                                top: 160,
                                left: 5,
                                child: Text(
                                  cast[index]['name'] + ' as',
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
                                  cast[index]['character'],
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
                      'Related',
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
                                  if (videos.isNotEmpty) {
                                    setState(() {
                                      _controller.pause();
                                    });
                                    setState(() {
                                      isVideoEnded = true;
                                    });
                                  }

                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => MovieInfoPage(
                                              movie: recommendations[index])));
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
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
                                              .onBackground,
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
              );
            }
          },
        ));
  }

  void fetchGenres() async {
    const api_url = 'https://api.themoviedb.org/3';
    const api_Key = '36e984f2374fdfcbcea58dba752094dc';

    String url = '';
    if (movie['name'] == null) {
      url =
          api_url + '/movie/' + movie['id'].toString() + '?api_key=' + api_Key;
    } else {
      url = api_url + '/tv/' + movie['id'].toString() + '?api_key=' + api_Key;
    }

    final uri = Uri.parse(url);
    final response = await http.get(uri);
    final body = response.body;
    final json = jsonDecode(body);
    final gnres = json['genres'];

    for (var index = 0; index < gnres.length; index++) {
      if (index == 0) {
        genres = gnres[index]['name'];
      } else {
        genres = genres + ' - ' + gnres[index]['name'];
      }
    }
    ;
  }

  void fetchPlatforms() async {
    const api_url = 'https://api.themoviedb.org/3';
    const api_Key = '36e984f2374fdfcbcea58dba752094dc';

    String url = '';
    if (movie['name'] == null) {
      url = api_url +
          '/movie/' +
          movie['id'].toString() +
          '/watch/providers?api_key=' +
          api_Key;
    } else {
      url = api_url +
          '/tv/' +
          movie['id'].toString() +
          '/watch/providers?api_key=' +
          api_Key;
    }

    final uri = Uri.parse(url);
    final response = await http.get(uri);
    final body = response.body;
    final json = jsonDecode(body);
    final pltforms = json['results'];
    final pltformsCountry = pltforms['CL'];
    if (pltformsCountry != null) {
      pltformsCountry.forEach((key, value) {
        if (value is List) {
          for (var element in value) {
            if (element['logo_path'] != null &&
                !platforms.any((platform) =>
                    platform['provider_id'] == element['provider_id'])) {
              setState(() {
                platforms.add(element);
              });
            }
          }
        }
      });
    }
  }

  void fetchRecommendations() async {
    const api_url = 'https://api.themoviedb.org/3';
    const api_Key = '36e984f2374fdfcbcea58dba752094dc';

    String url = '';
    if (movie['name'] == null) {
      url = api_url +
          '/movie/' +
          movie['id'].toString() +
          '/recommendations?api_key=' +
          api_Key;
    } else {
      url = api_url +
          '/tv/' +
          movie['id'].toString() +
          '/recommendations?api_key=' +
          api_Key;
    }

    final uri = Uri.parse(url);
    final response = await http.get(uri);
    final body = response.body;
    final json = jsonDecode(body);
    final recms = json['results'];
    setState(() {
      recommendations = recms;
    });
  }

  void fetchCast() async {
    const api_url = 'https://api.themoviedb.org/3';
    const api_Key = '36e984f2374fdfcbcea58dba752094dc';

    String url = '';
    if (movie['name'] == null) {
      url = api_url +
          '/movie/' +
          movie['id'].toString() +
          '/credits?api_key=' +
          api_Key;
    } else {
      url = api_url +
          '/tv/' +
          movie['id'].toString() +
          '/credits?api_key=' +
          api_Key;
    }

    final uri = Uri.parse(url);
    final response = await http.get(uri);
    final body = response.body;
    final json = jsonDecode(body);
    final cst = json['cast'];
    setState(() {
      cast = cst;
    });
  }

  // void fetchVideos() async {
  //   const api_url = 'https://api.themoviedb.org/3';
  //   const api_Key = '36e984f2374fdfcbcea58dba752094dc';

  //   String url = '';

  //   if (movie['name'] == null) {
  //     url = api_url +
  //         '/movie/' +
  //         movie['id'].toString() +
  //         '/videos?api_key=' +
  //         api_Key;
  //   } else {
  //     url = api_url +
  //         '/tv/' +
  //         movie['id'].toString() +
  //         '/videos?api_key=' +
  //         api_Key;
  //   }

  //   final uri = Uri.parse(url);
  //   final response = await http.get(uri);
  //   final body = response.body;
  //   final json = jsonDecode(body);
  //   final vds = json['results'];
  //   setState(() {
  //     videos = vds;
  //   });
  //   if (videos.length > 0) {
  //     dynamic trailer;
  //     for (var videoData in videos) {
  //       if (videoData['type'] == 'Trailer') {
  //         trailer = videoData;
  //       }
  //       if (videos.last == videoData && trailer == null) {
  //         trailer = videoData;
  //       }
  //     }
  //     setState(() {
  //       _controller = YoutubePlayerController(
  //         initialVideoId: trailer['key'],
  //         flags: const YoutubePlayerFlags(
  //             autoPlay: true,
  //             mute: false,
  //             hideControls: true,
  //             hideThumbnail: true,
  //             enableCaption: false,
  //             useHybridComposition: true),
  //       );
  //     });
  //   }
  // }
}
