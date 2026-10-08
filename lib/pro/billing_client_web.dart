/// No store, on purpose — the web preview and any platform without Play.
///
/// `available` is false, so the paywall draws itself completely and then says
/// plainly that payments are not connected here. That is the honest preview: the
/// tiers, prices, restore button and fine print are all reviewable without a
/// Play account, and nothing pretends a purchase happened.
library;

import 'dart:async';

import 'billing_client.dart';
import 'product_ids.dart';

BillingClient createBillingClient() => const WebBillingClient();

class WebBillingClient implements BillingClient {
  const WebBillingClient();

  @override
  bool get available => false;

  @override
  Stream<BillingEvent> get events => const Stream<BillingEvent>.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<List<ProProduct>> products() async => const <ProProduct>[];

  @override
  Future<bool> buy(ProPlan plan) async => false;

  @override
  Future<void> restore() async {}

  @override
  void dispose() {}
}
