import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Shows an interstitial only at a natural break: when a group table ends
/// and before its results. It is never tied to a navigation control (back,
/// home, opening a title), which AdMob's navigation policy flagged, and never
/// shows twice within [_minInterval].
class InterstitialAdManager {
  InterstitialAdManager._();
  static final InterstitialAdManager instance = InterstitialAdManager._();

  static const Duration _minInterval = Duration(minutes: 3);

  // Debug builds use Google's test unit so development never serves real ads.
  static final String _adUnitId = Platform.isAndroid && !kDebugMode
      ? 'ca-app-pub-3038495459046159/9335491973'
      : Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';

  InterstitialAd? _ad;
  bool _loading = false;
  DateTime? _lastShown;

  /// Loads the ad ahead of time, e.g. when voting starts.
  void preload() {
    if (_ad != null || _loading) return;
    _loading = true;
    InterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _loading = false;
          },
          onAdFailedToLoad: (LoadAdError error) {
            _loading = false;
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
  }

  /// Shows the preloaded ad if there is one and the cap allows it.
  void showAtBreak() {
    final ad = _ad;
    if (ad == null) return;
    final now = DateTime.now();
    if (_lastShown != null && now.difference(_lastShown!) < _minInterval) {
      return;
    }

    _ad = null;
    _lastShown = now;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
    );
    ad.show();
  }
}
