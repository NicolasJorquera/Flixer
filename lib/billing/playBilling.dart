import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'package:flixer/billing/purchases.dart';

/// [BillingGateway] over Google Play Billing (in_app_purchase). Play Billing
/// talks to the Play Store app on the phone; it never sees what the user browses.
///
/// * Every purchase of [removeAdsProductId] that is not pending is
///   acknowledged (`completePurchase`), or Play refunds it after three days.
/// * On Android a canceled or failed purchase arrives without a product ID:
///   Flixer sells one product, so those updates are about it.
class PlayBillingGateway implements BillingGateway {
  /// [iap] is replaced in tests; the app uses Play's.
  PlayBillingGateway([InAppPurchase? iap]) : _iap = iap ?? InAppPurchase.instance {
    try {
      _sub = _iap.purchaseStream.listen(_onPurchases, onError: (Object _) {});
    } catch (_) {
      // No Play Billing on this system: nothing arrives, the app keeps its ads.
    }
  }

  final InAppPurchase _iap;
  final _updates = StreamController<PurchaseUpdate>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;

  /// Purchases that arrive while [ownership] waits for Play's answer.
  List<PurchaseDetails>? _restoreBatch;
  Future<StoreOwnership?>? _restoring;

  @override
  Stream<PurchaseUpdate> get updates => _updates.stream;

  @override
  Future<String?> price() async => (await _queryProduct())?.price;

  @override
  Future<BuyLaunch> buy() async {
    try {
      final product = await _queryProduct();
      if (product == null) return BuyLaunch.unavailable;
      if (await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product))) {
        return BuyLaunch.launched;
      }
    } catch (e) {
      if (_isAlreadyOwned(e)) return BuyLaunch.alreadyOwned;
    }
    // Android answers «already owned» as a sheet that did not open.
    return await ownership() == StoreOwnership.owned ? BuyLaunch.alreadyOwned : BuyLaunch.failed;
  }

  @override
  Future<StoreOwnership?> ownership() => _restoring ??= _restore().whenComplete(() => _restoring = null);

  Future<StoreOwnership?> _restore() async {
    final batch = _restoreBatch = [];
    try {
      if (!await _iap.isAvailable()) return null;
      await _iap.restorePurchases();
      // The batch is added to the stream just before the call returns.
      await Future<void>.delayed(Duration.zero);
      final mine = batch.where((p) => p.productID == removeAdsProductId);
      if (mine.any((p) => !_isPending(p))) return StoreOwnership.owned;
      if (mine.isNotEmpty) return StoreOwnership.pending;
      return StoreOwnership.none;
    } catch (_) {
      return null;
    } finally {
      _restoreBatch = null;
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != removeAdsProductId && p.productID.isNotEmpty) continue;
      final batch = _restoreBatch;
      if (batch != null && p.status == PurchaseStatus.restored) {
        batch.add(p);
        if (!_isPending(p)) await _complete(p);
        continue;
      }
      final update = switch (p.status) {
        _ when _isPending(p) => PurchaseUpdate.pending,
        PurchaseStatus.purchased => PurchaseUpdate.purchased,
        PurchaseStatus.restored => PurchaseUpdate.restored,
        PurchaseStatus.canceled => PurchaseUpdate.canceled,
        PurchaseStatus.error when _isAlreadyOwned(p.error) => PurchaseUpdate.alreadyOwned,
        PurchaseStatus.error => PurchaseUpdate.error,
        PurchaseStatus.pending => PurchaseUpdate.pending,
      };
      if (update != PurchaseUpdate.pending) await _complete(p);
      _updates.add(update);
    }
  }

  Future<ProductDetails?> _queryProduct() async {
    if (_product case final p?) return p;
    try {
      if (!await _iap.isAvailable()) return null;
      final response = await _iap.queryProductDetails({removeAdsProductId});
      final found = response.productDetails.where((p) => p.id == removeAdsProductId);
      return _product = found.isEmpty ? null : found.first;
    } catch (_) {
      return null;
    }
  }

  Future<void> _complete(PurchaseDetails p) async {
    if (!p.pendingCompletePurchase) return;
    try {
      await _iap.completePurchase(p);
    } catch (_) {
      // Retried on the next check with Play (every startup).
    }
  }

  void dispose() {
    _sub?.cancel();
    _updates.close();
  }

  /// On Android `restorePurchases` marks pending purchases as restored too:
  /// Play's own state decides.
  static bool _isPending(PurchaseDetails p) =>
      p.status == PurchaseStatus.pending ||
      (p is GooglePlayPurchaseDetails && p.billingClientPurchase.purchaseState == PurchaseStateWrapper.pending);

  static bool _isAlreadyOwned(Object? e) =>
      e.toString().contains('itemAlreadyOwned') || e.toString().contains('ITEM_ALREADY_OWNED');
}
