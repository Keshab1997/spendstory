/// No ads, on purpose (the web preview and any platform without the SDK).
///
/// The preview exists so Keshab can look at a screen without building an apk —
/// it has no AdMob, no play services and no business showing an ad. Returning a
/// client that has nothing also means the preview exercises the *degraded* path
/// every time: an `AdSlot` that fails to fill must still leave a page that looks
/// finished.
library;

import 'package:flutter/widgets.dart';

import 'ad_client.dart';
import 'ad_placement.dart';

AdClient createAdClient() => const WebAdClient();

class WebAdClient implements AdClient {
  const WebAdClient();

  @override
  bool get hasAds => false;

  @override
  String? get appId => null;

  @override
  String? unitIdFor(AdPlacement placement) => null;

  @override
  String? get interstitialUnitId => null;

  @override
  Future<void> initialize() async {}

  @override
  Widget? adView({
    required AdPlacement placement,
    required bool nonPersonalized,
    required ValueChanged<AdOutcome> onOutcome,
  }) => null;

  @override
  Future<bool> showInterstitial({required bool nonPersonalized}) async => false;

  @override
  String? get rewardedUnitId => null;

  @override
  Future<RewardedOutcome> showRewarded({required bool nonPersonalized}) async =>
      RewardedOutcome.unavailable;

  /// There is no consent SDK here — and nothing to consent to, because there are
  /// no ads. Saying `notRequired` rather than `unknown` keeps the web preview
  /// out of the "consent has not run yet, request nothing" state, which is what
  /// this client does anyway for its own reasons.
  @override
  Future<ConsentState> ensureConsent() async => ConsentState.notRequired;

  @override
  Future<bool> privacyOptionsRequired() async => false;
}
