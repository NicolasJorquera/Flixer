import 'dart:math';

import 'package:flixer/global/variables.dart';
import 'package:flixer/src/apiFunctions/tmdb.dart';

Future<List> getTrendingMovies() async {
  List movies = await tmdbList('/trending/movie/day');
  movies.shuffle();
  return movies;
}

Future<List> getDiscoverMovies() async {
  String randPage = (Random().nextInt(50) + 1).toString();

  List movies = await tmdbList('/discover/movie', {
    'sort_by': 'popularity.desc',
    'watch_region': region,
    'page': randPage,
  });
  movies.shuffle();
  return movies;
}

Future<List> getDiscoverMoviesByGenre(genre) async {
  List movies = await tmdbList('/discover/movie', {
    'sort_by': 'popularity.desc',
    'watch_region': region,
    'with_genres': genre['id'].toString(),
  });
  movies.shuffle();
  return movies;
}

Future<List> getMoviesGenres() async {
  final json = await tmdbGet('/genre/movie/list');
  List moviesGenres = json['genres'];
  for (var genre in moviesGenres) {
    genre['list'] = [];
  }

  return moviesGenres;
}
