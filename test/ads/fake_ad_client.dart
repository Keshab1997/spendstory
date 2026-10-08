/// A stand-in for the ads SDK (T-601 … T-608).
///
/// The SDK is reached only through [AdClient], so a test can decide what happens
/// without an Android host, a network, or a real ad: an ad that loads, an ad that
/// never arrives, a device that has no ads at all (which is what the web preview
/// and this test run both are).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/ads/ad_client.dart';
import 'package:spendstory/ads/ad_ids.dart';
import 'package:spendstory/ads/ad_placement.dart';

class FakeAdClient implements AdClient {
  FakeAdClient({
    this.hasAds = true,
    this.unitIds = const <AdPlacement, String>{},
    this.interstitial = 'test-interstitial-unit',
    this.rewarded = 'test-rewarded-unit',
    this.loads = true,
    this.showsInterstitial = true,
    this.rewardOutcome = RewardedOutcome.earned,
    this.consentState = ConsentState.notRequired,
    this.privacyOptions = false,
  });

  @override
  final bool hasAds;

  /// A device with ads but no ids configured yet — a release build before
  /// Keshab pastes the live units in.
  final Map<AdPlacement, String> unitIds;

  final String? interstitial;

  /// The rewarded unit, or null for a build that has none.
  final String? rewarded;

  /// Whether an inline ad ever finishes loading.
  final bool loads;

  /// Whether the interstitial actually reaches the screen.
  final bool showsInterstitial;

  /// What watching a rewarded ad turns out to be: earned, dismissed, or nothing
  /// available at all.
  final RewardedOutcome rewardOutcome;

  /// What the consent flow reports.
  final ConsentState consentState;

  /// Whether a privacy-options entry point is required of the app.
  final bool privacyOptions;

  @override
  String? get appId => hasAds ? AdTestIds.appId : null;

  @override
  String? unitIdFor(AdPlacement placement) => unitIds[placement];

  @override
  String? get interstitialUnitId => hasAds ? interstitial : null;

  int initializeCalls = 0;
  final List<AdPlacement> views = <AdPlacement>[];
  final List<bool> interstitialConsent = <bool>[];

  @override
  Future<void> initialize() async => initializeCalls += 1;

  @override
  Widget? adView({
    required AdPlacement placement,
    required bool nonPersonalized,
    required ValueChanged<AdOutcome> onOutcome,
  }) {
    views.add(placement);
    if (!hasAds || unitIdFor(placement) == null) return null;
    return _FakeAdView(loads: loads, onOutcome: onOutcome);
  }

  @override
  Future<bool> showInterstitial({required bool nonPersonalized}) async {
    interstitialConsent.add(nonPersonalized);
    return showsInterstitial;
  }

  int rewardedCalls = 0;
  final List<bool> rewardedConsent = <bool>[];
  int consentChecks = 0;

  @override
  String? get rewardedUnitId => hasAds ? rewarded : null;

  @override
  Future<RewardedOutcome> showRewarded({required bool nonPersonalized}) async {
    rewardedCalls += 1;
    rewardedConsent.add(nonPersonalized);
    if (!hasAds || rewarded == null) return RewardedOutcome.unavailable;
    return rewardOutcome;
  }

  @override
  Future<ConsentState> ensureConsent() async {
    consentChecks += 1;
    return consentState;
  }

  @override
  Future<bool> privacyOptionsRequired() async => privacyOptions;

  int privacyFormCalls = 0;

  @override
  Future<bool> showPrivacyOptions() async {
    privacyFormCalls += 1;
    return privacyOptions;
  }
}

/// A client with ads on and every placement configured, which is what a device
/// with a filled-in `ad_ids.dart` looks like.
FakeAdClient configuredClient({
  bool loads = true,
  bool showsInterstitial = true,
}) => FakeAdClient(
  unitIds: <AdPlacement, String>{
    for (final placement in AdPlacement.values)
      placement: 'test-unit-${unitNameOf(placement)}',
  },
  loads: loads,
  showsInterstitial: showsInterstitial,
);

/// Mounts one widget with overrides and hands back the container, so a test can
/// read the providers back.
Future<ProviderContainer> pumpIn(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const <Override>[],
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: child),
  );
  await tester.pumpAndSettle();
  return container;
}

/// One fake creative, which reports its outcome once — after the first frame,
/// the way a platform callback does, and never inside `build`.
class _FakeAdView extends StatefulWidget {
  const _FakeAdView({required this.loads, required this.onOutcome});

  final bool loads;
  final ValueChanged<AdOutcome> onOutcome;

  @override
  State<_FakeAdView> createState() => _FakeAdViewState();
}

class _FakeAdViewState extends State<_FakeAdView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onOutcome(widget.loads ? AdOutcome.loaded : AdOutcome.failed);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 50, child: Text('FAKE AD'));
}
