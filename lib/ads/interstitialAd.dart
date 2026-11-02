import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Shows an interstitial only when leaving a detail page, at most once every
/// [_showEvery] detail pages and never twice within [_minInterval], so ads
/// never interrupt a trailer or the content the user opened.
class InterstitialAdManager {
  InterstitialAdManager._();
  static final InterstitialAdManager instance = InterstitialAdManager._();

  static const int _showEvery = 4;
  static const Duration _minInterval = Duration(minutes: 3);

  // Debug builds use Google's test unit so development never serves real ads.
  static final String _adUnitId = Platform.isAndroid && !kDebugMode
      ? 'ca-app-pub-3038495459046159/9335491973'
      : Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';

  InterstitialAd? _ad;
  bool _loading = false;
  int _detailViews = 0;
  DateTime? _lastShown;

  void _load() {
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

  /// Call when a detail page opens; preloads the ad so it is ready on exit.
  void onDetailOpened() {
    _detailViews++;
    _load();
  }

  /// Call when a detail page closes; shows the ad if the caps allow it.
  void onDetailClosed() {
    final ad = _ad;
    if (ad == null || _detailViews < _showEvery) return;
    final now = DateTime.now();
    if (_lastShown != null && now.difference(_lastShown!) < _minInterval) {
      return;
    }

    _ad = null;
    _detailViews = 0;
    _lastShown = now;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _load();
      },
    );
    ad.show();
  }
}
