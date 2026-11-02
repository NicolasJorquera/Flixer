import 'dart:math';

import 'package:flixer/global/variables.dart';
import 'package:flixer/src/apiFunctions/tmdb.dart';

Future<List> getTrendingSeries() async {
  List series = await tmdbList('/trending/tv/day');
  series.shuffle();
  return series;
}

Future<List> getDiscoverSeries() async {
  String randPage = (Random().nextInt(50) + 1).toString();

  List series = await tmdbList('/discover/tv', {
    'sort_by': 'popularity.desc',
    'watch_region': region,
    'page': randPage,
  });
  series.shuffle();
  return series;
}

Future<List> getDiscoverSeriesByGenre(genre) async {
  List series = await tmdbList('/discover/tv', {
    'sort_by': 'popularity.desc',
    'watch_region': region,
    'with_genres': genre['id'].toString(),
  });
  series.shuffle();
  return series;
}

Future<List> getSeriesGenres() async {
  final json = await tmdbGet('/genre/tv/list');
  List seriesGenres = json['genres'];
  for (var genre in seriesGenres) {
    genre['list'] = [];
  }

  return seriesGenres;
}
