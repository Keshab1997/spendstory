/// AdMob ids, per build flavor (T-601, `docs/08 §3`, §9).
///
/// One rule decides everything here: **a debug build can never request a live
/// ad, and a release build can never request a test ad.** Test ids in a shipped
/// apk are invalid traffic — the fastest way to lose an AdMob account — and live
/// ids in a debug build are how a developer ends up explaining clicks they never
/// made. So the flavor is the switch, and it is read in exactly one place.
///
/// The live ids are empty until Keshab creates the units in the AdMob console
/// and fills them in. An empty id is not an error: [unitIdFor] returns null, the
/// slot asks for nothing, and the app simply has no ads in it — which is a much
/// better release-day surprise than a crash or a policy strike.
library;

import 'package:flutter/foundation.dart' show kReleaseMode;

import 'ad_placement.dart';

/// Google's published test ids. These are safe to keep in the repo: they serve
/// only dummy creatives, and they are the only ids a debug build may use.
class AdTestIds {
  const AdTestIds._();

  static const String appId = 'ca-app-pub-3940256099942544~3347511713';

  /// Fixed 320×50 banners, one per platform.
  static const String bannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String bannerIos = 'ca-app-pub-3940256099942544/2934735716';

  /// Native advanced, one per platform.
  static const String nativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const String nativeIos = 'ca-app-pub-3940256099942544/3986624511';

  static const String interstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String rewarded = 'ca-app-pub-3940256099942544/5224354917';
}

/// The live units, one per placement in `docs/08 §2`.
///
/// TODO(Keshab): paste the ids from the AdMob console here — app id first, then
/// one unit per row. Nothing else in the app has to change; an empty value just
/// means that placement stays dark.
class AdLiveIds {
  const AdLiveIds._();

  /// The AdMob *app* id (`~` not `/`) — the one the Android manifest needs.
  static const String appId = '';

  static const Map<AdPlacement, String> units = <AdPlacement, String>{
    AdPlacement.homeBanner: '',
    AdPlacement.budgetNative: '',
    AdPlacement.budgetDetailBanner: '',
    AdPlacement.accountsBanner: '',
    AdPlacement.insightsBanner: '',
    AdPlacement.recurringNative: '',
  };

  static const String interstitial = '';
  static const String rewarded = '';
}

/// True in a debug or profile build. Release is the only flavor that may talk to
/// live units.
const bool adTestMode = !kReleaseMode;

/// Whether ads exist at all in this build: off until the live ids are filled in.
bool get adIdsConfigured =>
    !adTestMode && (AdLiveIds.appId.isNotEmpty || _anyLiveUnit);

bool get _anyLiveUnit => AdLiveIds.units.values.any((id) => id.isNotEmpty);

/// The unit id for a placement, or null when this build has no id for it.
///
/// [testIds] is a parameter rather than a read of [adTestMode] so that both
/// flavors are testable in one test run — the audit in `test/ads` checks that a
/// release build resolves to live ids and never to Google's test ones.
String? unitIdFor(
  AdPlacement placement, {
  required bool testIds,
  required bool android,
}) {
  if (testIds) {
    return switch (formatOf(placement)) {
      AdFormat.banner =>
        android ? AdTestIds.bannerAndroid : AdTestIds.bannerIos,
      AdFormat.native =>
        android ? AdTestIds.nativeAndroid : AdTestIds.nativeIos,
      // Whole-screen formats are not placements: ask for them through
      // [interstitialUnitId] / [rewardedUnitId].
      AdFormat.interstitial || AdFormat.rewarded => null,
    };
  }
  final id = AdLiveIds.units[placement];
  return (id == null || id.isEmpty) ? null : id;
}

/// The AdMob app id for the manifest, or null when it has not been filled in.
String? appIdFor({required bool testIds}) {
  if (testIds) return AdTestIds.appId;
  return AdLiveIds.appId.isEmpty ? null : AdLiveIds.appId;
}

/// The interstitial / rewarded unit for this flavor, or null if unset.
String? interstitialUnitId({required bool testIds}) =>
    testIds ? AdTestIds.interstitial : _orNull(AdLiveIds.interstitial);

String? rewardedUnitId({required bool testIds}) =>
    testIds ? AdTestIds.rewarded : _orNull(AdLiveIds.rewarded);

String? _orNull(String id) => id.isEmpty ? null : id;
