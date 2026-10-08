/// Where an ad is allowed to be, and in what shape (Batch 7, `docs/08 §2–3`).
///
/// The enum is the *screen*, not the size, because that is how the inventory in
/// `docs/08 §2` is written: one AdMob unit per screen, so a report in the AdMob
/// console can be read against the screen it came from. The size follows from
/// the placement, and every screen's spec in `docs/03` decides which placements
/// exist at all — the ones listed here are the only legal ones, and a screen
/// that is not on this list gets no ad.
library;

enum AdPlacement {
  /// S-09 Home, below the hero money card. `ss_home_banner`.
  homeBanner,

  /// S-14 Budget list, in-feed after the third row. `ss_budget_native`.
  budgetNative,

  /// S-15 Budget detail, at the bottom below the rows. `ss_budget_detail_banner`.
  budgetDetailBanner,

  /// S-16 Accounts, at the bottom. `ss_accounts_banner`.
  accountsBanner,

  /// S-17 Insights, at the very bottom, under every chart. `ss_insights_banner`.
  insightsBanner,

  /// S-19 Recurring, in-feed under the rules. `ss_recurring_native`.
  recurringNative,
}

/// What the SDK is asked for. Banners are a fixed 320×50 box; native units use
/// AdMob's built-in templates and size themselves.
///
/// [interstitial] and [rewarded] are whole-screen formats: they belong to a
/// *moment* (a navigation, a tap on "watch an ad"), not to a placement on a
/// screen, so no [AdPlacement] ever maps to them.
enum AdFormat { banner, native, interstitial, rewarded }

AdFormat formatOf(AdPlacement placement) => switch (placement) {
  AdPlacement.homeBanner ||
  AdPlacement.budgetDetailBanner ||
  AdPlacement.accountsBanner ||
  AdPlacement.insightsBanner => AdFormat.banner,
  AdPlacement.budgetNative || AdPlacement.recurringNative => AdFormat.native,
};

/// The height reserved before the ad arrives, so nothing jumps when it does.
///
/// A banner fills this exactly. A native unit is a floor rather than a ceiling:
/// the built-in templates choose their own height, and clipping one would clip
/// its click target — which is the kind of thing that gets an account flagged.
double reservedHeightOf(AdPlacement placement) =>
    formatOf(placement) == AdFormat.banner ? 56 : 84;

/// The unit's name in `docs/08 §2`, so the code and the AdMob console can be
/// matched up without a second table.
String unitNameOf(AdPlacement placement) => switch (placement) {
  AdPlacement.homeBanner => 'ss_home_banner',
  AdPlacement.budgetNative => 'ss_budget_native',
  AdPlacement.budgetDetailBanner => 'ss_budget_detail_banner',
  AdPlacement.accountsBanner => 'ss_accounts_banner',
  AdPlacement.insightsBanner => 'ss_insights_banner',
  AdPlacement.recurringNative => 'ss_recurring_native',
};
