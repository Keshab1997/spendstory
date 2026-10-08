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

/// What the user is buying.
enum ProPlan { monthly, yearly, lifetime }

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

String productIdFor(ProPlan plan) => switch (plan) {
  ProPlan.monthly => ProProductIds.monthly,
  ProPlan.yearly => ProProductIds.yearly,
  ProPlan.lifetime => ProProductIds.lifetime,
};

/// The plan a product id belongs to, or null for an id this build does not know
/// — a product retired from the console, or a typo in the Play listing.
ProPlan? planForProductId(String id) {
  for (final plan in ProPlan.values) {
    if (productIdFor(plan) == id) return plan;
  }
  return null;
}

/// `docs/08 §6`. Shown when the store has not answered yet, and marked as an
/// estimate on screen — never used to charge anyone.
int fallbackPricePaise(ProPlan plan) => switch (plan) {
  ProPlan.monthly => 9900,
  ProPlan.yearly => 69900,
  ProPlan.lifetime => 149900,
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
};

/// Whether this plan can end. Lifetime is the one the user keeps forever.
bool isRenewing(ProPlan plan) => plan != ProPlan.lifetime;
