import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flixer/billing/removeAds.dart';
import 'package:flixer/global/variables.dart';
import 'package:flixer/src/mesa/mesaPromo.dart';
import 'package:flixer/src/myList.dart';
import './src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final removeAds = await RemoveAds.init();
  // A buyer never loads the AdMob SDK at startup.
  if (!removeAds.value.owned) unawaited(MobileAds.instance.initialize());
  await loadSettings();
  await MyList.load();
  await MesaPromo.load();

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
