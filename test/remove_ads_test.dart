import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flixer/billing/playBilling.dart';
import 'package:flixer/billing/purchases.dart';
import 'package:flixer/billing/removeAds.dart';
import 'package:flixer/src/widgets/removeAdsTile.dart';

import 'fake_in_app_purchase.dart';

/// «Sin anuncios»: the controller over the real Play Billing adapter and a
/// fake InAppPurchase shaped like the Android plugin.
void main() {
  late FakeInAppPurchase play;

  setUp(() => play = FakeInAppPurchase());
  tearDown(() => play.close());

  /// One install with its own settings; [play] is the shared Play account.
  Future<RemoveAds> install([Map<String, Object> saved = const {}]) async {
    SharedPreferences.setMockInitialValues(saved);
    final billing = PlayBillingGateway(play);
    final removeAds = RemoveAds(billing, await SharedPreferences.getInstance());
    addTearDown(() {
      removeAds.dispose();
      billing.dispose();
    });
    return removeAds;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('buying removes ads, saves it and acknowledges the purchase', () async {
    final r = await install();
    await r.buy();
    await settle();
    expect(r.value.owned, isTrue);
    expect(r.value.flow, PurchaseFlow.purchased);
    expect(play.acknowledged, isTrue);
    expect((await SharedPreferences.getInstance()).getBool('adsRemoved'), isTrue);
  });

  test('a pending payment keeps the ads until Play confirms it', () async {
    play.buyResult = FakeBuyResult.pending;
    final r = await install();
    await r.buy();
    await settle();
    expect(r.value.owned, isFalse);
    expect(r.value.flow, PurchaseFlow.pending);
    play.confirmPending();
    await settle();
    expect(r.value.owned, isTrue);
  });

  test('canceled and failed purchases keep the ads', () async {
    play.buyResult = FakeBuyResult.canceled;
    final r = await install();
    await r.buy();
    await settle();
    expect(r.value, isA<RemoveAdsState>().having((s) => s.owned, 'owned', false));
    expect(r.value.flow, PurchaseFlow.canceled);
    play.buyResult = FakeBuyResult.error;
    await r.buy();
    await settle();
    expect(r.value.flow, PurchaseFlow.error);
  });

  test('without the product in Play the purchase is unavailable', () async {
    play.productExists = false;
    final r = await install();
    await r.buy();
    expect(r.value.flow, PurchaseFlow.unavailable);
    expect(r.value.owned, isFalse);
  });

  test('a new install restores, also when buying again', () async {
    play.owned = true;
    final r = await install();
    await r.buy();
    await settle();
    expect(r.value.owned, isTrue);
    expect(r.value.flow, PurchaseFlow.restored);
  });

  test('restore on an account without the purchase says so', () async {
    final r = await install();
    await r.restore();
    expect(r.value.flow, PurchaseFlow.nothingToRestore);
    expect(r.value.owned, isFalse);
  });

  test('startup check: Play revokes a refunded purchase', () async {
    final r = await install({'adsRemoved': true});
    expect(r.value.owned, isTrue);
    await r.verifyWithStore();
    expect(r.value.owned, isFalse);
    expect(r.value.flow, PurchaseFlow.idle);
  });

  test('startup check offline keeps the saved purchase', () async {
    play.failRestore = true;
    final r = await install({'adsRemoved': true});
    await r.verifyWithStore();
    expect(r.value.owned, isTrue);
  });

  group('settings row', () {
    Future<void> pump(WidgetTester tester, RemoveAds r) async {
      RemoveAds.instance = r;
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: RemoveAdsTile())));
      await tester.pump();
    }

    testWidgets('shows Play price, buy and restore', (tester) async {
      final r = await tester.runAsync(install);
      await pump(tester, r!);
      await tester.runAsync(settle);
      await tester.pump();
      expect(find.text(r'Comprar · US$2.99'), findsOneWidget);
      expect(find.text('Restaurar compra'), findsOneWidget);
    });

    testWidgets('once bought only the status remains', (tester) async {
      final r = await tester.runAsync(() => install({'adsRemoved': true}));
      await pump(tester, r!);
      expect(find.text('Compra activa: Flixer no muestra anuncios.'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Restaurar compra'), findsNothing);
    });
  });
}
