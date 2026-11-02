import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flixer/global/variables.dart';
import './src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());
  await loadSettings();

  runApp( const MainPage());
}

/// Loads language and region before the first TMDB call.
Future<void> loadSettings() async {
  final prefs = await SharedPreferences.getInstance();

  // Before v2 the language defaulted to English for everyone, so it was not
  // a real choice: reset it once from the device language.
  if ((prefs.getInt('settingsVersion') ?? 1) < 2) {
    final deviceLanguage = PlatformDispatcher.instance.locale.languageCode;
    await prefs.setString('language', deviceLanguage == 'en' ? 'en' : 'es');
    await prefs.setInt('settingsVersion', 2);
  }

  language = prefs.getString('language') ?? 'es';
  region = prefs.getString('watchRegion') ?? 'CL';
}
