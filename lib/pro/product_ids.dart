/// The three products, and what a plan means (T-605, `docs/08 §6`).
///
/// The ids below are the ones Play has to be told about — Keshab creates them
/// once in the Play Console (Monetize → Products → Subscriptions for the two
/// subscriptions, In-app products for the lifetime unlock), and from then on the
/// store is the source of truth for price. Nothing here hard-codes a price the
/// user is charged: [fallbackPricePaise] exists only so the paywall can be
/// looked at before the store has answered, and it is labelled as an estimate
/// wherever it is shown.
library;

/// What the user has.
///
/// The three purchasable plans, plus the 24-hour taste that a rewarded ad earns
/// (T-606). The taste is a plan rather than a flag on purpose: it then shares the
/// window arithmetic, the expiry and the clearing with everything else, instead
/// of being a second kind of "Pro" that every reader of the entitlement has to
/// know about. It has no product id — see [productIdFor] — because it is not for
/// sale.
enum ProPlan { monthly, yearly, lifetime, taste }

/// Play Console product ids. `ss_pro_…` matches the ad units' `ss_` prefix so
/// the console reads consistently.
class ProProductIds {
  const ProProductIds._();

  static const String monthly = 'ss_pro_monthly';
  static const String yearly = 'ss_pro_yearly';
  static const String lifetime = 'ss_pro_lifetime';

  static const Set<String> all = <String>{monthly, yearly, lifetime};

  /// The subscriptions. A lifetime unlock is a one-time purchase, which is a
  /// different object in the Play Console — spare the reader the wrong tab.
  static const Set<String> subscriptions = <String>{monthly, yearly};
}

/// The plan a store product can buy, or null when the plan is not for sale.
///
/// Null is the answer for the taste: there is no product to query, nothing to
/// charge, and a build that somehow asked for one would be refused by
/// `RuestController.buy` rather than shown an empty store sheet.
String? productIdFor(ProPlan plan) => switch (plan) {
  ProPlan.monthly => ProProductIds.monthly,
  ProPlan.yearly => ProProductIds.yearly,
  ProPlan.lifetime => ProProductIds.lifetime,
  ProPlan.taste => null,
};

/// The plans a paywall may offer, in the order `docs/08 §6` lists them. Derived
/// from the product ids, so a fourth product in the console is a one-line change
/// here rather than a second list to keep in step.
final List<ProPlan> purchasablePlans = <ProPlan>[
  for (final plan in ProPlan.values)
    if (productIdFor(plan) != null) plan,
];

/// The plan a product id belongs to, or null for an id this build does not know
/// — a product retired from the console, or a typo in the Play listing.
ProPlan? planForProductId(String id) {
  for (final plan in ProPlan.values) {
    if (productIdFor(plan) == id) return plan;
  }
  return null;
}

/// Whether this plan was bought (or earned) — the taste is the one that is
/// neither.

/// `docs/08 §6`. Shown when the store has not answered yet, and marked as an
/// estimate on screen — never used to charge anyone.
int fallbackPricePaise(ProPlan plan) => switch (plan) {
  ProPlan.monthly => 9900,
  ProPlan.yearly => 69900,
  ProPlan.lifetime => 149900,
  // Nothing. The taste is earned, never sold, and the paywall's tiers are built
  // from [purchasablePlans] so it is never asked to price one.
  ProPlan.taste => 0,
};

/// The free trial, on the yearly plan only (`docs/08 §6`). Play is what actually
/// enforces it; this is what the paywall promises and what the entitlement
/// window accounts for.
Duration? trialFor(ProPlan plan) =>
    plan == ProPlan.yearly ? const Duration(days: 7) : null;

/// How long a purchase of [plan] is trusted without another word from Play.
///
/// Deliberately a little **longer** than the billing period. The app has no
/// server to ask (that is the whole product promise), so the only thing that can
/// end a subscription locally is the store's own restore. A window shorter than
/// the period would lock a paying user out of what they paid for while the
/// renewal was still in flight — the worst bug this feature can have. A window
/// longer than the period means a cancelled subscription keeps working for a few
/// extra days, which is the direction a mistake should point.
Duration entitlementWindow(ProPlan plan) => switch (plan) {
  ProPlan.monthly => const Duration(days: 31),
  ProPlan.yearly => const Duration(days: 372), // 365 + the 7-day trial
  ProPlan.lifetime => const Duration(days: 365 * 100),
  // A taste is exactly a day long — a reward has no grace period, and giving it
  // one would only make "24 hours" a lie (`docs/08 §5`).
  ProPlan.taste => const Duration(hours: 24),
};

/// Whether the store will charge for this plan again. Lifetime does not, and a
/// taste is not a subscription at all — which is why the paywall only promises a
/// renewal date for the two plans that have one.
bool isRenewing(ProPlan plan) =>
    plan == ProPlan.monthly || plan == ProPlan.yearly;
