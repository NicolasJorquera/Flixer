import 'dart:math';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flixer/global/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List> getTrendingSeries() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  const String urlBaseCall = '/trending/tv/day?';
  String language = 'language=' + prefs.getString('language')! + '&';
  const String api_key = 'api_key=' + apiKeyAuth;
  String url = apiUrlBase +
      urlBaseCall +
      language +
      api_key;

  final uri = Uri.parse(url);
  final response = await http.get(uri);
  final body = response.body;
  final json = jsonDecode(body);
  List series = json['results'];
  series.removeWhere((serie) => !(serie as Map).containsKey('poster_path'));
  series.shuffle();
  return series;
}

Future<List> getDiscoverSeries() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String randPage = (Random().nextInt(50) + 1).toString();
  
  const String urlBaseCall = '/discover/tv?';
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
  List series = json['results'];
  series.removeWhere((serie) => serie['poster_path'] == null);
  series.shuffle();
  return series;
}

Future<List> getDiscoverSeriesByGenre(genre) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  const String urlBaseCall = '/discover/tv?';
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
  List series = json['results'];
  series.removeWhere((serie) => !(serie as Map).containsKey('poster_path'));
  series.shuffle();
  return series;
}

Future<List> getSeriesGenres() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  
  const String urlBaseCall = '/genre/tv/list?';
  String language = 'language=' + prefs.getString('language')! + '&';
  const String api_key = 'api_key=' + apiKeyAuth;
  String url = apiUrlBase + urlBaseCall + language + api_key;

  final uri = Uri.parse(url);
  final response = await http.get(uri);
  final body = response.body;
  final json = jsonDecode(body);
  List seriesGenres = json['genres'];
  for (var genre in seriesGenres) {
    genre['list'] = [];
  }

  return seriesGenres;
}

