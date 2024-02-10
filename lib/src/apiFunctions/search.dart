
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flixer/global/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List> searchAll(String qry) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  const String urlBaseCall = '/search/multi?';
  String query = 'query=' + qry + '&';
  String language = 'language=' + prefs.getString('language')! + '&';
  const String api_key = 'api_key=' + apiKeyAuth;
  String url = apiUrlBase +
      urlBaseCall +
      query +
      language +
      api_key;

  final uri = Uri.parse(url);
  final response = await http.get(uri);
  final body = response.body;
  final json = jsonDecode(body);
  List search = json['results'];
  return search;
}

Future<List> searchMovies(String qry) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  const String urlBaseCall = '/search/movie?';
  String query = 'query=' + qry + '&';
  String language = 'language=' + prefs.getString('language')! + '&';
  const String api_key = 'api_key=' + apiKeyAuth;
  String url = apiUrlBase +
      urlBaseCall +
      query +
      language +
      api_key;

  final uri = Uri.parse(url);
  final response = await http.get(uri);
  final body = response.body;
  final json = jsonDecode(body);
  List search = json['results'];
  return search;
}
Future<List> searchSeries(String qry) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  const String urlBaseCall = '/search/tv?';
  String query = 'query=' + qry + '&';
  String language = 'language=' + prefs.getString('language')! + '&';
  const String api_key = 'api_key=' + apiKeyAuth;
  String url = apiUrlBase +
      urlBaseCall +
      query +
      language +
      api_key;

  final uri = Uri.parse(url);
  final response = await http.get(uri);
  final body = response.body;
  final json = jsonDecode(body);
  List search = json['results'];
  return search;
}
Future<List> searchPeople(String qry) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  
  const String urlBaseCall = '/search/person?';
  String query = 'query=' + qry + '&';
  String language = 'language=' + prefs.getString('language')! + '&';
  const String api_key = 'api_key=' + apiKeyAuth;
  String url = apiUrlBase +
      urlBaseCall +
      query +
      language +
      api_key;

  final uri = Uri.parse(url);
  final response = await http.get(uri);
  final body = response.body;
  final json = jsonDecode(body);
  List search = json['results'];
  return search;
}

