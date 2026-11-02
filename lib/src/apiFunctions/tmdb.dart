import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flixer/global/constants.dart';
import 'package:flixer/global/variables.dart';

class TmdbException implements Exception {
  final String message;
  TmdbException(this.message);

  @override
  String toString() => 'TmdbException: $message';
}

/// TMDB's plain 'es' is the Spain translation; es-MX is the Latin American one.
String get tmdbLanguage => language == 'es' ? 'es-MX' : 'en-US';

/// Single entry point for TMDB v3: adds the API key and the user's language,
/// encodes the query and throws [TmdbException] on network or HTTP errors so
/// screens can show an error state instead of spinning forever.
Future<dynamic> tmdbGet(String path,
    [Map<String, String> params = const {}]) async {
  final uri = Uri.parse(apiUrlBase + path).replace(queryParameters: {
    'api_key': apiKeyAuth,
    'language': tmdbLanguage,
    ...params,
  });

  final http.Response response;
  try {
    response = await http.get(uri).timeout(const Duration(seconds: 15));
  } on Exception catch (e) {
    throw TmdbException('$path: ${e.runtimeType}');
  }
  if (response.statusCode != 200) {
    throw TmdbException('$path: HTTP ${response.statusCode}');
  }
  return jsonDecode(response.body);
}

/// Results of a list endpoint, without items that have no poster.
Future<List> tmdbList(String path, [Map<String, String> params = const {}]) async {
  final json = await tmdbGet(path, params);
  final List results = json['results'];
  results.removeWhere((item) => item['poster_path'] == null);
  return results;
}
