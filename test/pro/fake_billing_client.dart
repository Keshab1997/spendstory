/// A stand-in for the store (T-604, T-605).
///
/// The paywall and the controller are tested through this: a purchase that Play
/// grants, one it holds for review, one the user backs out of, one that fails,
/// a restore that finds something, and a device with no store at all. None of
/// that needs a Play account, and every one of them is a real user's story.
library;

import 'dart:async';

import 'package:spendstory/pro/billing_client.dart';
import 'package:spendstory/pro/product_ids.dart';

class FakeBillingClient implements BillingClient {
  FakeBillingClient({
    this.available = true,
    List<ProProduct>? products,
    this.startsPurchase = true,
  }) : _products =
           products ??
           <ProProduct>[
             for (final plan in purchasablePlans)
               ProProduct(
                 plan: plan,
                 priceLabel: _label(plan),
                 rawPrice: fallbackPricePaise(plan) / 100,
                 currencyCode: 'INR',
               ),
           ];

  @override
  final bool available;

  /// False models the store refusing to even open its sheet — no Play services,
  /// or a product that is not live in this country.
  final bool startsPurchase;

  final List<ProProduct> _products;

  final StreamController<BillingEvent> _events =
      StreamController<BillingEvent>.broadcast();

  int initializeCalls = 0;
  int restoreCalls = 0;
  final List<ProPlan> bought = <ProPlan>[];

  @override
  Stream<BillingEvent> get events => _events.stream;

  @override
  Future<void> initialize() async => initializeCalls += 1;

  @override
  Future<List<ProProduct>> products() async =>
      available ? _products : const <ProProduct>[];

  @override
  Future<bool> buy(ProPlan plan) async {
    bought.add(plan);
    return available && startsPurchase;
  }

  @override
  Future<void> restore() async => restoreCalls += 1;

  @override
  void dispose() => _events.close();

  /// The store answering, some time after the sheet closed. Play never replies
  /// inside the tap, which is exactly what the controller has to survive.
  void emit(BillingEvent event) => _events.add(event);

  static String _label(ProPlan plan) => switch (plan) {
    ProPlan.monthly => '₹99.00',
    ProPlan.yearly => '₹699.00',
    ProPlan.lifetime => '₹1,499.00',
    // Not for sale: a fake store that could sell one would make the ledger's
    // "the taste cannot be bought" test meaningless.
    ProPlan.taste => 'not for sale',
  };
}
