import 'package:flixer/global/strings.dart';
import 'package:flixer/global/variables.dart';
import 'package:flixer/src/apiFunctions/tmdb.dart';

/// 'movie' or 'tv'. Trending and search results carry `media_type`; list and
/// discover results don't, but only movies have a `title`.
String mediaTypeOf(Map item) =>
    item['media_type'] ?? (item['title'] == null ? 'tv' : 'movie');

/// A TMDB list endpoint shown as a home section or an explore grid.
class CatalogQuery {
  final String title;
  final String path;
  final Map<String, String> params;
  const CatalogQuery(this.title, this.path, [this.params = const {}]);

  String get mediaType => path.contains('/tv') ? 'tv' : 'movie';
  bool get isDiscover => path.startsWith('/discover');
}

class CatalogPage {
  final List items;
  final int totalPages;
  CatalogPage(this.items, this.totalPages);
}

// Sections scroll in and out of view and the tabs rebuild; caching pages
// avoids asking TMDB for the same list again. Cleared on refresh.
final Map<String, Future<CatalogPage>> _cache = {};

void clearCatalogCache() => _cache.clear();

Future<CatalogPage> fetchCatalogPage(CatalogQuery query, int page) {
  final params = {...query.params, 'page': '$page'};
  final key = '$language|${query.path}|$params';
  return _cache[key] ??= _fetch(query, params).catchError((Object e) {
    _cache.remove(key);
    throw e;
  });
}

Future<CatalogPage> _fetch(
    CatalogQuery query, Map<String, String> params) async {
  final json = await tmdbGet(query.path, params);
  final List items = json['results'];
  items.removeWhere((item) => item['poster_path'] == null);
  for (final item in items) {
    item['media_type'] ??= query.mediaType;
  }
  // TMDB never serves pages past 500.
  final int total = json['total_pages'] ?? 1;
  return CatalogPage(items, total > 500 ? 500 : total);
}

/// Streaming services in the user's region that offer movies or series,
/// most relevant first. Shared by both tabs, so it merges both lists.
Future<List> getProviders() async {
  final lists = await Future.wait([
    for (final type in const ['movie', 'tv'])
      tmdbGet('/watch/providers/$type', {'watch_region': region})
  ]);
  final Map<int, Map> byId = {};
  for (final json in lists) {
    for (final provider in json['results']) {
      if (provider['logo_path'] != null) {
        byId.putIfAbsent(provider['provider_id'], () => provider);
      }
    }
  }
  int priority(Map provider) => (provider['display_priorities']?[region] ??
      provider['display_priority'] ??
      999) as int;
  final providers = byId.values.toList()
    ..sort((a, b) => priority(a).compareTo(priority(b)));
  return providers.take(12).toList();
}

Future<List> getGenres(String mediaType) async {
  final json = await tmdbGet('/genre/$mediaType/list');
  return json['genres'];
}

// Genres shown as home rows, in this order, when TMDB has them.
const _homeGenres = {
  'movie': [28, 35, 18, 27, 878, 16, 10749, 53],
  'tv': [10759, 35, 18, 80, 10765, 16, 99],
};

String _today() => DateTime.now().toIso8601String().substring(0, 10);

/// Home sections for a media type, limited to the given providers (any of
/// them) when the set is not empty.
List<CatalogQuery> homeSections(
    String mediaType, List genres, Set<int> providerIds) {
  final discover = '/discover/$mediaType';
  final minVotes = mediaType == 'movie' ? '500' : '200';
  final dateField =
      mediaType == 'movie' ? 'primary_release_date' : 'first_air_date';

  final List<CatalogQuery> sections;
  final Map<String, String> base;
  if (providerIds.isEmpty) {
    base = {};
    sections = [
      CatalogQuery(tr('trending'), '/trending/$mediaType/week'),
      if (mediaType == 'movie') ...[
        CatalogQuery(
            tr('nowPlaying'), '/movie/now_playing', {'region': region}),
        CatalogQuery(tr('upcoming'), '/movie/upcoming', {'region': region}),
      ] else
        CatalogQuery(tr('onTheAir'), '/tv/on_the_air'),
      CatalogQuery(tr('popularOnStreaming'), discover, {
        'sort_by': 'popularity.desc',
        'watch_region': region,
        'with_watch_monetization_types': 'flatrate',
      }),
      CatalogQuery(tr('topRated'), discover,
          {'sort_by': 'vote_average.desc', 'vote_count.gte': minVotes}),
    ];
  } else {
    base = {
      'watch_region': region,
      // '|' means OR in TMDB filters.
      'with_watch_providers': (providerIds.toList()..sort()).join('|'),
      'with_watch_monetization_types': 'flatrate|free|ads',
    };
    sections = [
      CatalogQuery(
          tr('popular'), discover, {...base, 'sort_by': 'popularity.desc'}),
      CatalogQuery(tr('topRated'), discover, {
        ...base,
        'sort_by': 'vote_average.desc',
        'vote_count.gte': minVotes,
      }),
      CatalogQuery(tr('recent'), discover, {
        ...base,
        'sort_by': '$dateField.desc',
        '$dateField.lte': _today(),
        'vote_count.gte': '20',
      }),
    ];
  }

  for (final id in _homeGenres[mediaType]!) {
    final genre = genres.where((g) => g['id'] == id).firstOrNull;
    if (genre == null) continue;
    sections.add(CatalogQuery(genre['name'], discover, {
      ...base,
      'sort_by': 'popularity.desc',
      'with_genres': '$id',
    }));
  }
  return sections;
}
