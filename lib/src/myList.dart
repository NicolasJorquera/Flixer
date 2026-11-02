import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flixer/src/apiFunctions/catalog.dart';

/// Saved movies and series, kept on the device only (no account, no server).
class MyList {
  MyList._();

  static const _prefsKey = 'myList';

  /// Newest first. Widgets listen to it to update bookmarks and rows.
  static final ValueNotifier<List<Map>> items = ValueNotifier([]);

  static String _key(Map item) => '${mediaTypeOf(item)}:${item['id']}';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null) return;
    try {
      items.value = List<Map>.from(jsonDecode(saved));
    } on FormatException {
      await prefs.remove(_prefsKey);
    }
  }

  static bool contains(Map item) =>
      items.value.any((saved) => _key(saved) == _key(item));

  static Future<void> toggle(Map item) async {
    final key = _key(item);
    if (contains(item)) {
      items.value = items.value.where((saved) => _key(saved) != key).toList();
    } else {
      // Only what the cards need, not the whole detail response.
      final entry = <String, dynamic>{'media_type': mediaTypeOf(item)};
      for (final field in const [
        'id',
        'title',
        'name',
        'poster_path',
        'backdrop_path',
        'overview',
        'vote_average',
        'vote_count',
        'release_date',
        'first_air_date',
      ]) {
        if (item[field] != null) entry[field] = item[field];
      }
      items.value = [entry, ...items.value];
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(items.value));
  }
}
