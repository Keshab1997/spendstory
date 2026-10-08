/// The seam between the app and the ads SDK (T-601).
///
/// Everything above this file talks about *placements*; everything below it
/// talks to `google_mobile_ads`. The app never imports the SDK directly, which
/// is what lets it
///
/// * run on the web preview and in widget tests, where there is no ad SDK at
///   all — the conditional import below picks a stub instead,
/// * be tested with a fake client in `test/ads`,
/// * and keep the "what may an ad request know" question answerable by reading
///   one file — see [AdSpec] and the audit in `test/ads/ad_request_audit_test`.
///
/// The conditional import mirrors `lib/data/db.dart`: the SDK's Dart code is
/// never in the web build's import graph, so nothing about it can break the
/// Pages deploy.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_client_mobile.dart'
    if (dart.library.js_interop) 'ad_client_web.dart'
    as platform;
import 'ad_placement.dart';

/// What a request for one ad is allowed to contain.
///
/// Deliberately tiny: an ad unit, a shape, and whether the user has asked for
/// non-personalized ads. **No amount, no merchant, no category, no balance** —
/// an ad request built from a ledger is a policy violation and a privacy
/// breach, and the way to make that impossible is to give the type nowhere to
/// put one (`docs/08 §3`, §9).
class AdSpec {
  const AdSpec({
    required this.unitId,
    required this.format,
    required this.reservedHeight,
    this.nonPersonalized = false,
  });

  final String unitId;
  final AdFormat format;

  /// The floor this slot reserves so the page does not jump when the ad lands.
  final double reservedHeight;

  /// Set from the user's consent choice (T-607), never from their spending.
  final bool nonPersonalized;
}

/// What became of an ad slot. A failed load collapses the slot rather than
/// leaving a hole.
enum AdOutcome { loaded, failed }

/// What became of a rewarded ad the user chose to watch (T-606, `docs/08 §5`).
///
/// Three answers, because the app has to be able to tell them apart: an ad that
/// was watched to the end earns something, an ad the user closed early earns
/// nothing, and an ad that never arrived owes the user nothing either. Only the
/// first one may grant — and only when the SDK says so, never when the user taps.
enum RewardedOutcome {
  /// The SDK reported the reward.
  earned,

  /// The ad was shown and dismissed before the reward was earned.
  dismissed,

  /// Nothing was shown: no unit in this build, no consent, no fill, offline.
  unavailable,
}

/// Where the consent flow stands (T-607).
///
/// `required` is the one that matters: the user was asked and the answer was not
/// a yes, so the app may not request an ad. Everything else is a yes of some
/// kind — `notRequired` is most of the world, where Google's SDK reports that no
/// form is needed.
enum ConsentState {
  /// The flow has not run yet (or there is no consent SDK on this platform).
  unknown,

  /// Google says this user needs no form.
  notRequired,

  /// The form was shown and answered.
  obtained,

  /// Consent is needed and has not been obtained. **No ad requests.**
  required,
}

/// The ads SDK, as the app sees it.
abstract class AdClient {
  /// True when this platform and build can show an ad at all: Android/iOS, and
  /// a unit id that exists for the current flavor.
  bool get hasAds;

  /// The AdMob app id this build would use, for debug output. The Android
  /// manifest carries the same value from Gradle (`android/app/build.gradle.kts`).
  String? get appId;

  /// The unit id for a placement, or null when this build has none.
  String? unitIdFor(AdPlacement placement);

  /// The unit id for a whole-screen interstitial, or null when this build has
  /// none — in which case the gate simply has nothing to show.
  String? get interstitialUnitId;

  /// Starts the SDK. Called once, after the first frame, and only when ads can
  /// actually be shown — never on the splash (`docs/08 §8`).
  Future<void> initialize();

  /// The widget that shows the ad for [placement], or null when there is
  /// nothing to show here.
  ///
  /// The caller names a *placement*, never a unit or a spec: the ids, the shape
  /// and the reserved height are the client's business, so a screen cannot ask
  /// for an ad that does not exist or forget to label one.
  ///
  /// [onOutcome] fires exactly once: [AdOutcome.loaded] when the ad is on
  /// screen, [AdOutcome.failed] when it will never arrive.
  Widget? adView({
    required AdPlacement placement,
    required bool nonPersonalized,
    required ValueChanged<AdOutcome> onOutcome,
  });

  /// Loads and shows an interstitial. Returns true when one was actually shown,
  /// which is what the gate records — a request that fails must not burn the
  /// session's one interstitial.
  Future<bool> showInterstitial({required bool nonPersonalized});

  /// The unit id for a rewarded ad, or null when this build has none — in which
  /// case the offer is not shown at all, rather than shown and then broken.
  String? get rewardedUnitId;

  /// Loads and shows a rewarded ad the user asked for. Only
  /// [RewardedOutcome.earned] may grant anything (`docs/08 §5`).
  Future<RewardedOutcome> showRewarded({required bool nonPersonalized});

  /// Runs Google's consent flow — the UMP form, if one is required — before the
  /// first ad request, and answers what this user's consent state now is.
  ///
  /// Called once per launch, after the first frame, and *before* the SDK is
  /// initialized: Google's own guidance is consent first, requests second.
  Future<ConsentState> ensureConsent();

  /// Whether this platform requires a "privacy options" entry point — the UMP
  /// requirement that a user can change their mind later (T-610 puts the door in
  /// Settings).
  Future<bool> privacyOptionsRequired();

  /// Opens that entry point. Returns true when a form was actually shown, which
  /// is what the toast in Settings reports — a door that opens onto nothing is
  /// worse than no door.
  Future<bool> showPrivacyOptions();
}

/// The client for this platform: the real SDK on Android/iOS, a stub on the web.
final adClientProvider = Provider<AdClient>((ref) => platform.createAdClient());

/// Whether every request must ask for a non-personalized ad.
///
/// Set from the user's answer to the consent form (T-607) — a *consent* flag,
/// never a targeting one. It lives here, next to the requests it changes, so
/// there is exactly one switch between the user's choice and the SDK.
final nonPersonalizedAdsProvider = StateProvider<bool>((ref) => false);
