import 'dart:math';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flixer/global/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List> getTrendingMovies() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  const String urlBaseCall = '/trending/movie/day?';
  String language = 'language=' + prefs.getString('language')! + '&';
  const String api_key = 'api_key=' + apiKeyAuth;
  String url = apiUrlBase + urlBaseCall + language + api_key;

  final uri = Uri.parse(url);
  final response = await http.get(uri);
  final body = response.body;
  final json = jsonDecode(body);
  List movies = json['results'];
  movies.removeWhere((movie) => !(movie as Map).containsKey('poster_path'));
  movies.shuffle();
  return movies;
}

Future<List> getDiscoverMovies() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String randPage = (Random().nextInt(50) + 1).toString();

  const String urlBaseCall = '/discover/movie?';
  const String sort_by = 'sort_by=popularity.desc&';
  String watch_region = 'watch_region=' + prefs.getString('watchRegion')! + '&';
  String language = 'language=' + prefs.getString('language')! + '&';
  String page = 'page=' + randPage + '&';
  const String api_key = 'api_key=' + apiKeyAuth;
  String url = apiUrlBase +
      urlBaseCall +
      sort_by +
      watch_region +
      language +
      page +
      api_key;

  final uri = Uri.parse(url);
  final response = await http.get(uri);
  final body = response.body;
  final json = jsonDecode(body);
  List movies = json['results'];
  movies.removeWhere((movie) => !(movie as Map).containsKey('poster_path'));
  movies.shuffle();
  return movies;
}

Future<List> getDiscoverMoviesByGenre(genre) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();


  const String urlBaseCall = '/discover/movie?';
  const String sort_by = 'sort_by=popularity.desc&';
  String watch_region = 'watch_region=' + prefs.getString('watchRegion')! + '&';
  String language = 'language=' + prefs.getString('language')! + '&';
  String with_genres = 'with_genres=' + genre['id'].toString() + '&';
  const String api_key = 'api_key=' + apiKeyAuth;
  String url = apiUrlBase +
      urlBaseCall +
      sort_by +
      watch_region +
      language +
      with_genres +
      api_key;

  final uri = Uri.parse(url);
  final response = await http.get(uri);
  final body = response.body;
  final json = jsonDecode(body);
  List movies = json['results'];
  movies.removeWhere((movie) => !(movie as Map).containsKey('poster_path'));
  movies.shuffle();
  return movies;
}

Future<List> getMoviesGenres() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  
  const String urlBaseCall = '/genre/movie/list?';
  String language = 'language=' + prefs.getString('language')! + '&';
  const String api_key = 'api_key=' + apiKeyAuth;
  String url = apiUrlBase + urlBaseCall + language + api_key;

  final uri = Uri.parse(url);
  final response = await http.get(uri);
  final body = response.body;
  final json = jsonDecode(body);
  List moviesGenres = json['genres'];
  for (var genre in moviesGenres) {
    genre['list'] = [];
  }

  return moviesGenres;
}
