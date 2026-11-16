import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flixer/billing/playBilling.dart';
import 'package:flixer/billing/purchases.dart';

/// The one-time purchase «Sin anuncios». No server: Play is asked on the
/// phone at startup and the answer is saved in the settings ([_prefsKey]).
/// Play's answer wins (it also revokes a refunded purchase); offline, the
/// saved state stays.
class RemoveAds extends ValueNotifier<RemoveAdsState> {
  RemoveAds(this._billing, this._prefs)
      : super(RemoveAdsState(owned: _prefs.getBool(_prefsKey) ?? false)) {
    _sub = _billing.updates.listen(_onUpdate);
  }

  static const _prefsKey = 'adsRemoved';

  /// The app's instance, set up by [init] before the first frame.
  static late RemoveAds instance;

  /// True once bought: no banners and no interstitials.
  static bool get adsRemoved => instance.value.owned;

  static Future<RemoveAds> init() async {
    instance = RemoveAds(PlayBillingGateway(), await SharedPreferences.getInstance());
    unawaited(instance.verifyWithStore());
    return instance;
  }

  final BillingGateway _billing;
  final SharedPreferences _prefs;
  late final StreamSubscription<PurchaseUpdate> _sub;
  bool _disposed = false;

  /// The price for the row in Settings.
  Future<void> loadProduct() async {
    final price = await _billing.price();
    if (price != null) _set(value.copyWith(price: price));
  }

  /// Opens Play's purchase sheet; the result arrives through the updates.
  Future<void> buy() async {
    if (value.owned || value.flow == PurchaseFlow.busy) return;
    _setFlow(PurchaseFlow.busy);
    final price = await _billing.price();
    if (price == null) {
      _setFlow(PurchaseFlow.unavailable);
      return;
    }
    _set(value.copyWith(price: price));
    switch (await _billing.buy()) {
      case BuyLaunch.launched:
        break;
      case BuyLaunch.unavailable:
        _setFlow(PurchaseFlow.unavailable);
      case BuyLaunch.alreadyOwned:
        await _restore(userInitiated: true);
      case BuyLaunch.failed:
        _setFlow(PurchaseFlow.error);
    }
  }

  /// «Restaurar compra».
  Future<void> restore() => _restore(userInitiated: true);

  /// At startup, silently.
  Future<void> verifyWithStore() => _restore(userInitiated: false);

  Future<void> _restore({required bool userInitiated}) async {
    if (userInitiated) _setFlow(PurchaseFlow.busy);
    final ownership = await _billing.ownership();
    if (ownership == null) {
      // Offline or no Play: what was saved stays.
      if (userInitiated) _setFlow(PurchaseFlow.unavailable);
      return;
    }
    await _save(ownership == StoreOwnership.owned);
    if (userInitiated) {
      _setFlow(switch (ownership) {
        StoreOwnership.owned => PurchaseFlow.restored,
        StoreOwnership.pending => PurchaseFlow.pending,
        StoreOwnership.none => PurchaseFlow.nothingToRestore,
      });
    }
  }

  Future<void> _onUpdate(PurchaseUpdate update) async {
    switch (update) {
      case PurchaseUpdate.purchased || PurchaseUpdate.restored:
        await _save(true);
        _setFlow(update == PurchaseUpdate.purchased
            ? PurchaseFlow.purchased
            : PurchaseFlow.restored);
      case PurchaseUpdate.pending:
        _setFlow(PurchaseFlow.pending);
      case PurchaseUpdate.canceled:
        _setFlow(PurchaseFlow.canceled);
      case PurchaseUpdate.error:
        _setFlow(PurchaseFlow.error);
      case PurchaseUpdate.alreadyOwned:
        await _restore(userInitiated: true);
    }
  }

  Future<void> _save(bool owned) async {
    _set(value.copyWith(owned: owned));
    await _prefs.setBool(_prefsKey, owned);
  }

  void _setFlow(PurchaseFlow flow) => _set(value.copyWith(flow: flow));

  void _set(RemoveAdsState state) {
    if (!_disposed) value = state;
  }

  @override
  void dispose() {
    _disposed = true;
    _sub.cancel();
    super.dispose();
  }
}
