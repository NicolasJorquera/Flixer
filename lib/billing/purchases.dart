/// One-time purchase «Sin anuncios» (non-consumable, Google Play Billing).
///
/// No server: Play is asked on the phone and the answer is kept in the
/// settings. The price always comes from Play; the app never shows a fixed one.
const removeAdsProductId = 'flixer_remove_ads';

/// What is happening with the purchase (shown by the row in Settings).
enum PurchaseFlow {
  idle,

  /// Asking Play or showing its purchase sheet.
  busy,

  /// Play left it pending (cash payment, family approval…): ads stay until
  /// Play confirms it.
  pending,

  /// Bought or restored from the card.
  purchased,
  restored,

  /// «Restaurar compra»: this Play account does not have it.
  nothingToRestore,
  canceled,
  error,

  /// No Play Store, no connection, or the product does not exist in Play
  /// Console yet.
  unavailable,
}

class RemoveAdsState {
  const RemoveAdsState({required this.owned, this.flow = PurchaseFlow.idle, this.price});

  /// The purchase is active: no ads at all.
  final bool owned;
  final PurchaseFlow flow;

  /// Localized price reported by Play; null until Play answers.
  final String? price;

  RemoveAdsState copyWith({bool? owned, PurchaseFlow? flow, String? price}) =>
      RemoveAdsState(owned: owned ?? this.owned, flow: flow ?? this.flow, price: price ?? this.price);

  @override
  bool operator ==(Object other) =>
      other is RemoveAdsState && other.owned == owned && other.flow == flow && other.price == price;

  @override
  int get hashCode => Object.hash(owned, flow, price);

  @override
  String toString() => 'RemoveAdsState(owned: $owned, $flow, $price)';
}

/// What the Play account has, according to Play.
enum StoreOwnership { owned, pending, none }

/// How opening the purchase sheet went.
enum BuyLaunch {
  /// The sheet is open; the result arrives through [BillingGateway.updates].
  launched,

  /// No Play, no connection or no such product.
  unavailable,

  /// The account already has it (another install): restore instead.
  alreadyOwned,
  failed,
}

/// A purchase result from Play, including late ones (a pending purchase that
/// Play confirms while the app is open).
enum PurchaseUpdate { purchased, restored, pending, canceled, error, alreadyOwned }

/// Google Play Billing behind a port: presentation and domain never see it.
/// The adapter acknowledges purchases so Play does not refund them after
/// three days. No method throws.
abstract interface class BillingGateway {
  /// Localized price of [removeAdsProductId]; null without Play, offline or
  /// when the product does not exist.
  Future<String?> price();

  Future<BuyLaunch> buy();

  /// Asks Play what the account owns; null when Play cannot answer (no Play,
  /// offline): then the saved state stays.
  Future<StoreOwnership?> ownership();

  Stream<PurchaseUpdate> get updates;
}
