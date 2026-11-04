// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flixer/global/strings.dart';
import 'package:flixer/src/apiFunctions/tmdb.dart';
import 'package:flixer/src/widgets/movieInfo.dart';
import 'package:flixer/src/widgets/statusViews.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flixer/ads/adaptativeBannerAd.dart';

import 'package:flixer/global/constants.dart';

class PersonInfoPage extends StatefulWidget {
  final dynamic personID;
  const PersonInfoPage({super.key, required this.personID});
  @override
  _PersonInfoPageState createState() => _PersonInfoPageState();
}

class _PersonInfoPageState extends State<PersonInfoPage> {
  late Future<void> request;
  dynamic details = {};
  dynamic images = [];
  dynamic movies = [];
  dynamic series = [];

  @override
  void initState() {
    super.initState();
    request = getDetails();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  /// Biography, photos and credits in one request.
  Future<void> getDetails() async {
    final json = await tmdbGet('/person/${widget.personID}', {
      'append_to_response': 'images,movie_credits,tv_credits',
    });
    setState(() {
      details = json;
      images = json['images']?['profiles'] ?? [];
      movies = json['movie_credits']?['cast'] ?? [];
      series = json['tv_credits']?['cast'] ?? [];
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
            future: request,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorView(
                    onRetry: () => setState(() {
                          request = getDetails();
                        }));
              } else if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingView();
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
                            semanticLabel: tr('back'),
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
                        Expanded(
                          child: Text(
                            details['name'] ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                        ),
                        ElevatedButton(
                          child: Icon(
                            Icons.home_outlined,
                            semanticLabel: tr('home'),
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
                      child: Text(details['biography'] ?? '', style: Theme.of(context).textTheme.displaySmall,),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        tr('pictures'),
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
                        tr('movies'),
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
                        tr('series'),
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
}
