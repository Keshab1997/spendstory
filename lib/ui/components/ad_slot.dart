/// Ad placeholders.
///
/// The real units — `ss_home_banner`, `ss_budget_native` and friends — are wired
/// to `google_mobile_ads` in Batch 7 (T-601). Until then this widget reserves
/// the *exact* space the real banner will occupy, so nobody is surprised by the
/// layout shifting under them when ads go live, and so the "where do ads go"
/// decision is visible in the running app rather than only in `docs/08`.
///
/// Rules from `docs/03-SCREEN-SPECS.md` that this widget enforces:
///
/// * Pro users never see it — [AdSlot] returns an empty box.
/// * Ads never appear on onboarding, permission, add/edit, list or detail
///   screens, and never docked above the bottom navigation. The only legal
///   placements are the three called out in [AdPlacement].
/// * The slot is never taller than the real unit, so no content is pushed off
///   screen when the real ad loads.
library;

import 'package:flutter/material.dart';

import '../tokens.dart';

enum AdPlacement {
  /// Home, immediately below the hero money card. Banner — 320×50.
  homeBanner,

  /// Budget list, after the third budget row. Native — the same height as a row.
  budgetNative,

  /// Accounts / Insights / Recurring, above the last section. Banner.
  sectionBanner,

  /// Budget detail, inline after the category breakdown. Native.
  detailNative,
}

class AdSlot extends StatelessWidget {
  const AdSlot({
    super.key,
    required this.placement,
    this.showPlaceholder = true,
  });

  final AdPlacement placement;

  /// In a release build this is false and the slot renders nothing until the
  /// real ad fills it — reserving space for an ad that never arrives would be
  /// worse than a small layout shift.
  final bool showPlaceholder;

  static double heightFor(AdPlacement placement) => switch (placement) {
    AdPlacement.homeBanner => 56,
    AdPlacement.sectionBanner => 56,
    AdPlacement.budgetNative => 84,
    AdPlacement.detailNative => 84,
  };

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    if (!showPlaceholder) return SizedBox(height: heightFor(placement));

    return Container(
      height: heightFor(placement),
      margin: const EdgeInsets.only(top: SsSpace.x4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surfaceTint,
        borderRadius: SsRadius.rMd,
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined, size: 16, color: c.textTertiary),
          const SizedBox(width: SsSpace.x2),
          Flexible(
            child: Text(
              'বিজ্ঞাপন — ${_label(placement)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SsText.micro.copyWith(color: c.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  static String _label(AdPlacement p) => switch (p) {
    AdPlacement.homeBanner => 'banner 320×50',
    AdPlacement.sectionBanner => 'banner',
    AdPlacement.budgetNative => 'native',
    AdPlacement.detailNative => 'native',
  };
}

/// Whether ads should be shown at all. Pro is ad-free, and a user who has not
/// finished onboarding must never see an ad.
bool shouldShowAds({required bool isPro, required bool onboarded}) =>
    !isPro && onboarded;

/// Kept next to the slot so the paywall and the ad gate can never disagree about
/// what "free" means.
bool isProFromMeta(String? proStatus) => proStatus == 'pro';
