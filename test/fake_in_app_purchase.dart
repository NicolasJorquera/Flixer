import 'dart:async';

import 'package:flixer/billing/purchases.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart'
    show InAppPurchasePlatformAddition;

/// What Play answers when the purchase sheet closes.
enum FakeBuyResult { purchased, pending, canceled, error }

/// Google Play Billing without Play, shaped like the Android plugin:
///
/// * purchases are [GooglePlayPurchaseDetails] (Play's own purchase state),
///   and an unacknowledged one has `pendingCompletePurchase`;
/// * a canceled or failed purchase arrives without a product ID;
/// * `restorePurchases` marks pending purchases as restored too;
/// * buying something the account already owns does not open the sheet.
///
/// The fields are the Play account: they survive a «new install» (another
/// settings store and another adapter over the same fake).
class FakeInAppPurchase implements InAppPurchase {
  bool available = true;
  bool productExists = true;
  bool failRestore = false;
  FakeBuyResult buyResult = FakeBuyResult.purchased;

  /// The account owns «Sin anuncios» / has it pending in Play.
  bool owned = false;
  bool pendingInStore = false;
  bool acknowledged = false;

  final calls = <String>[];
  final completed = <String>[];
  final _updates = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async {
    calls.add('isAvailable');
    return available;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async {
    calls.add('queryProductDetails');
    final found = productExists && identifiers.contains(removeAdsProductId);
    return ProductDetailsResponse(
      productDetails: [
        if (found)
          ProductDetails(
            id: removeAdsProductId,
            title: 'Sin anuncios',
            description: '',
            price: r'US$2.99',
            rawPrice: 2.99,
            currencyCode: 'USD',
          ),
      ],
      notFoundIDs: found ? const [] : identifiers.toList(),
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    calls.add('buyNonConsumable');
    // BillingResponse.itemAlreadyOwned: the sheet does not open.
    if (owned) return false;
    scheduleMicrotask(() {
      switch (buyResult) {
        case FakeBuyResult.purchased:
          owned = true;
          _updates.add([_purchase(PurchaseStateWrapper.purchased)]);
        case FakeBuyResult.pending:
          pendingInStore = true;
          _updates.add([_purchase(PurchaseStateWrapper.pending)]);
        case FakeBuyResult.canceled:
          _updates.add([_empty(PurchaseStatus.canceled)]);
        case FakeBuyResult.error:
          _updates.add([_empty(PurchaseStatus.error)]);
      }
    });
    return true;
  }

  /// Play confirms the pending purchase (it arrives through the stream).
  void confirmPending() {
    pendingInStore = false;
    owned = true;
    _updates.add([_purchase(PurchaseStateWrapper.purchased)]);
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    calls.add('restorePurchases');
    if (failRestore) throw InAppPurchaseException(source: 'google_play', code: 'restore_transactions_failed');
    _updates.add([
      if (owned) _purchase(PurchaseStateWrapper.purchased)..status = PurchaseStatus.restored,
      if (pendingInStore) _purchase(PurchaseStateWrapper.pending)..status = PurchaseStatus.restored,
    ]);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    calls.add('completePurchase');
    completed.add(purchase.productID);
    acknowledged = true;
  }

  GooglePlayPurchaseDetails _purchase(PurchaseStateWrapper state) => GooglePlayPurchaseDetails.fromPurchase(
    PurchaseWrapper(
      orderId: 'GPA.1',
      packageName: 'com.gonisoma.flixer',
      purchaseTime: 0,
      purchaseToken: 'token',
      signature: '',
      products: const [removeAdsProductId],
      isAutoRenewing: false,
      originalJson: '{}',
      isAcknowledged: acknowledged,
      purchaseState: state,
    ),
  ).single;

  PurchaseDetails _empty(PurchaseStatus status) => PurchaseDetails(
    purchaseID: '',
    productID: '',
    status: status,
    transactionDate: null,
    verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: 'fake'),
  )..error = status == PurchaseStatus.error ? IAPError(source: 'fake', code: 'purchase_error', message: 'x') : null;

  @override
  Future<bool> buyConsumable({required PurchaseParam purchaseParam, bool autoConsume = true}) =>
      throw UnimplementedError();

  @override
  Future<String> countryCode() async => 'CL';

  @override
  T getPlatformAddition<T extends InAppPurchasePlatformAddition?>() => throw UnimplementedError();

  Future<void> close() => _updates.close();
}
