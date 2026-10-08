/// The seam between the app and the store (T-605).
///
/// Same shape as `lib/ads/ad_client.dart`, for the same reason: the paywall and
/// the settings sheet must be testable without a Play account, and the web
/// preview must build with no billing plugin in it at all. The conditional
/// import picks the store on Android/iOS and an honest "nothing to sell" stub
/// everywhere else.
///
/// Everything below this file talks to `in_app_purchase`; everything above it
/// talks about [ProPlan] and [BillingEvent].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'billing_client_mobile.dart'
    if (dart.library.js_interop) 'billing_client_web.dart'
    as platform;
import 'product_ids.dart';

/// One product, as the store describes it. [priceLabel] is the store's own
/// localized string ("₹699.00") and is what the paywall shows — a price the app
/// formats itself would be a price the user was never charged.
class ProProduct {
  const ProProduct({
    required this.plan,
    required this.priceLabel,
    required this.rawPrice,
    required this.currencyCode,
    this.title,
  });

  final ProPlan plan;
  final String priceLabel;
  final double rawPrice;
  final String currencyCode;
  final String? title;
}

/// What came back from a purchase attempt.
enum BillingOutcome {
  /// Play says the money is in. The entitlement is granted on this.
  purchased,

  /// A previous purchase came back — a reinstall, a new phone, or the app
  /// asking Play on launch what this account owns.
  restored,

  /// Play is holding the payment for review (the common case for a first
  /// purchase in India). Nothing is granted yet, and nothing is wrong.
  pending,

  /// The user backed out of the store sheet.
  canceled,

  /// The store refused, or something threw. [BillingEvent.message] says what.
  error,
}

class BillingEvent {
  const BillingEvent({required this.outcome, this.plan, this.message});

  final BillingOutcome outcome;
  final ProPlan? plan;
  final String? message;

  /// True for the only two outcomes that mean "this user owns Pro".
  bool get grantsAccess =>
      outcome == BillingOutcome.purchased || outcome == BillingOutcome.restored;

  @override
  String toString() =>
      'BillingEvent(${outcome.name}${plan == null ? '' : ', ${plan!.name}'})';
}

/// The store, as the app sees it.
abstract class BillingClient {
  /// False on the web preview, in widget tests, and on a device with no Play
  /// services — in which case the paywall says so instead of failing on a tap.
  bool get available;

  /// Every purchase event, including the ones that arrive out of nowhere: a
  /// purchase completing after a process death, a restore, a pending payment
  /// that finally cleared.
  Stream<BillingEvent> get events;

  /// Starts listening and asks the store what this account already owns.
  Future<void> initialize();

  /// The products the store will actually sell, with its own prices. Empty when
  /// the store cannot be reached or the products are not live yet.
  Future<List<ProProduct>> products();

  /// Opens the store's purchase sheet. Returns false when there was nothing to
  /// buy — the paywall then says so rather than appearing to do nothing.
  Future<bool> buy(ProPlan plan);

  /// Asks the store to re-deliver what this account owns. Mandatory on the
  /// paywall and in Settings (`docs/08 §6`).
  Future<void> restore();

  void dispose();
}

/// The store for this platform: Play/App Store on mobile, nothing elsewhere.
final billingClientProvider = Provider<BillingClient>(
  (ref) => platform.createBillingClient(),
);
