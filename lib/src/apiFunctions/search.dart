import 'package:flixer/src/apiFunctions/tmdb.dart';

/// Movies, series and people in one request; each result has a `media_type`
/// ('movie', 'tv' or 'person') so the search tabs can split them.
Future<List> searchAll(String qry) async {
  final json = await tmdbGet('/search/multi', {'query': qry});
  List search = json['results'];
  return search;
}
