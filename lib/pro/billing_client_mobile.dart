/// The real store, via `in_app_purchase` (T-605).
///
/// The API is small and the pitfalls are not: a purchase is not finished until
/// the app calls `completePurchase`, and forgetting that means Play re-delivers
/// the same purchase forever. So every event this file emits is followed by the
/// completion call, before anything else looks at it.
///
/// Like `ad_client_mobile.dart`, this file is outside the web build's import
/// graph — the conditional import in `billing_client.dart` swaps it out.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:in_app_purchase/in_app_purchase.dart' as iap;

import 'billing_client.dart';
import 'product_ids.dart';

BillingClient createBillingClient() => MobileBillingClient();

class MobileBillingClient implements BillingClient {
  MobileBillingClient({bool? android, bool? ios})
    : _android = android ?? Platform.isAndroid,
      _ios = ios ?? Platform.isIOS;

  final bool _android;
  final bool _ios;

  final StreamController<BillingEvent> _events =
      StreamController<BillingEvent>.broadcast();

  StreamSubscription<List<iap.PurchaseDetails>>? _subscription;
  bool _initialized = false;

  iap.InAppPurchase get _store => iap.InAppPurchase.instance;

  @override
  bool get available => _android || _ios;

  @override
  Stream<BillingEvent> get events => _events.stream;

  @override
  Future<void> initialize() async {
    if (!available || _initialized) return;
    _initialized = true;

    if (!await _store.isAvailable()) return;

    _subscription ??= _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) => _events.add(
        BillingEvent(outcome: BillingOutcome.error, message: '$error'),
      ),
    );
  }

  /// Play delivers *every* event here, including ones the user never started in
  /// this app run — which is why this is the only place an entitlement is ever
  /// granted.
  Future<void> _onPurchases(List<iap.PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final plan = planForProductId(purchase.productID);

      switch (purchase.status) {
        case iap.PurchaseStatus.pending:
          _events.add(
            BillingEvent(outcome: BillingOutcome.pending, plan: plan),
          );
        case iap.PurchaseStatus.canceled:
          _events.add(
            BillingEvent(outcome: BillingOutcome.canceled, plan: plan),
          );
        case iap.PurchaseStatus.error:
          _events.add(
            BillingEvent(
              outcome: BillingOutcome.error,
              plan: plan,
              message: purchase.error?.message,
            ),
          );
        case iap.PurchaseStatus.purchased:
        case iap.PurchaseStatus.restored:
          // A purchase this build cannot name is still finished rather than left
          // hanging: a retired product must not block Play's queue.
          _events.add(
            BillingEvent(
              outcome: purchase.status == iap.PurchaseStatus.restored
                  ? BillingOutcome.restored
                  : BillingOutcome.purchased,
              plan: plan,
            ),
          );
      }

      // Finishing the transaction is not optional and not the caller's job:
      // until this runs, Play hands the same purchase back on every launch.
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  @override
  Future<List<ProProduct>> products() async {
    if (!available) return const <ProProduct>[];
    await initialize();

    try {
      final response = await _store.queryProductDetails(ProProductIds.all);
      return <ProProduct>[
        for (final details in response.productDetails)
          if (planForProductId(details.id) case final plan?)
            ProProduct(
              plan: plan,
              priceLabel: details.price,
              rawPrice: details.rawPrice,
              currencyCode: details.currencyCode,
              title: details.title,
            ),
      ];
    } catch (_) {
      // No Play services, no network, products not live yet — the paywall falls
      // back to its own prices and says they are estimates.
      return const <ProProduct>[];
    }
  }

  @override
  Future<bool> buy(ProPlan plan) async {
    if (!available) return false;
    await initialize();

    final id = productIdFor(plan);
    final response = await _store.queryProductDetails(<String>{id});
    if (response.productDetails.isEmpty) return false;

    // Subscriptions and the lifetime unlock are both non-consumables to
    // `in_app_purchase`: they are bought once and owned, and the two
    // subscriptions are what Play's own billing period manages.
    final started = await _store.buyNonConsumable(
      purchaseParam: iap.PurchaseParam(
        productDetails: response.productDetails.first,
      ),
    );
    return started;
  }

  @override
  Future<void> restore() async {
    if (!available) return;
    await initialize();
    await _store.restorePurchases();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _events.close();
  }
}
