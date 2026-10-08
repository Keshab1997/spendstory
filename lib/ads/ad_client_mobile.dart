/// The ads SDK, on the platforms that have one (T-601).
///
/// This file is not in the web build's import graph — the conditional import in
/// `ad_client.dart` swaps in `ad_client_web.dart` there — so everything here is
/// free to use `dart:io` and `google_mobile_ads` without a second thought.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;

import 'ad_client.dart';
import 'ad_ids.dart' as ids;
import 'ad_placement.dart';

AdClient createAdClient() => MobileAdClient();

class MobileAdClient implements AdClient {
  MobileAdClient({bool? android, bool? ios})
    : _android = android ?? Platform.isAndroid,
      _ios = ios ?? Platform.isIOS;

  final bool _android;
  final bool _ios;

  bool _initialized = false;

  /// Starts false: **nothing is requested until consent says it may be**. The
  /// consent flow (`ensureConsent`) is the only thing that opens this gate, and
  /// it runs before the SDK is initialized (T-607).
  bool _mayRequestAds = false;

  bool _consentChecked = false;

  @override
  bool get hasAds => _android || _ios;

  @override
  String? get rewardedUnitId =>
      hasAds ? ids.rewardedUnitId(testIds: ids.adTestMode) : null;

  @override
  String? get appId => hasAds ? ids.appIdFor(testIds: ids.adTestMode) : null;

  @override
  String? unitIdFor(AdPlacement placement) {
    if (!hasAds) return null;
    return ids.unitIdFor(placement, testIds: ids.adTestMode, android: _android);
  }

  @override
  String? get interstitialUnitId =>
      hasAds ? ids.interstitialUnitId(testIds: ids.adTestMode) : null;

  @override
  Future<void> initialize() async {
    if (!hasAds || _initialized) return;
    _initialized = true;
    // The app id lives in the manifest, not here; if it is missing the SDK
    // throws on Android, which is why the Gradle placeholder always resolves to
    // something (test id in debug, checked in release).
    await gma.MobileAds.instance.initialize();
  }

  /// The consent flow, once per launch, before any request (T-607).
  ///
  /// Google's UMP SDK answers three questions in a row: may the app ask this
  /// user at all, does this user need a form, and — after the form — may the app
  /// request ads. Only the last one opens [_mayRequestAds], and a failure
  /// anywhere in the flow leaves it closed: an ad that is not shown costs
  /// nothing, an ad shown without consent costs the account.
  @override
  Future<ConsentState> ensureConsent() async {
    if (!hasAds) return ConsentState.notRequired;
    if (_consentChecked) {
      return _mayRequestAds ? ConsentState.obtained : ConsentState.required;
    }
    _consentChecked = true;

    final info = gma.ConsentInformation.instance;
    try {
      await _requestConsentInfo(info);
      if (await info.isConsentFormAvailable()) {
        await gma.ConsentForm.loadAndShowConsentFormIfRequired((_) {});
      }
      _mayRequestAds = await info.canRequestAds();
      if (!_mayRequestAds) return ConsentState.required;
      final status = await info.getConsentStatus();
      return status == gma.ConsentStatus.notRequired
          ? ConsentState.notRequired
          : ConsentState.obtained;
    } catch (_) {
      // No Play services, no network, a debug device with no test identifiers:
      // the flow could not run, so nothing may be requested.
      _mayRequestAds = false;
      return ConsentState.unknown;
    }
  }

  Future<void> _requestConsentInfo(gma.ConsentInformation info) {
    final done = Completer<void>();
    info.requestConsentInfoUpdate(
      gma.ConsentRequestParameters(
        tagForUnderAgeOfConsent: false,
        // A debug build is treated as the EEA so the form can actually be seen
        // and tested from India, which is where this app is developed. Release
        // builds get the real geography, always.
        consentDebugSettings: kDebugMode
            ? gma.ConsentDebugSettings(
                debugGeography: gma.DebugGeography.debugGeographyEea,
              )
            : null,
      ),
      done.complete,
      // A failed update is not a crash: `canRequestAds` below is the answer
      // that matters, and it stays closed.
      (_) => done.complete(),
    );
    return done.future;
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    if (!hasAds) return false;
    try {
      final status = await gma.ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == gma.PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  /// Shows the privacy-options form, for a user who wants to change their mind
  /// (Settings, T-610). Returns true when a form was shown.
  @override
  Future<bool> showPrivacyOptions() async {
    if (!hasAds) return false;
    try {
      // The UMP form needs an update behind it, and a phone that never ran the
      // flow at launch — a paying user's — has not done one. Getting one here
      // costs a call, and makes the door work wherever it is opened from.
      final info = gma.ConsentInformation.instance;
      await _requestConsentInfo(info);
      await gma.ConsentForm.showPrivacyOptionsForm((_) {});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The one place in the app that builds an ad request.
  ///
  /// Nothing from the ledger can reach this — see [AdSpec].
  gma.AdRequest _request(AdSpec spec) =>
      gma.AdRequest(nonPersonalizedAds: spec.nonPersonalized ? true : null);

  /// The one place a spec is built. A screen hands in a placement; everything
  /// else — the unit id, the shape, the height, the consent flag — is decided
  /// here, which is what keeps `test/ads/ad_request_audit_test.dart` able to
  /// name every request site in the app.
  AdSpec? _specFor(AdPlacement placement, {required bool nonPersonalized}) {
    final unitId = unitIdFor(placement);
    if (unitId == null) return null;
    return AdSpec(
      unitId: unitId,
      format: formatOf(placement),
      reservedHeight: reservedHeightOf(placement),
      nonPersonalized: nonPersonalized,
    );
  }

  @override
  Widget? adView({
    required AdPlacement placement,
    required bool nonPersonalized,
    required ValueChanged<AdOutcome> onOutcome,
  }) {
    if (!hasAds || !_mayRequestAds) return null;
    final spec = _specFor(placement, nonPersonalized: nonPersonalized);
    if (spec == null) return null;
    return _SdkAdView(client: this, spec: spec, onOutcome: onOutcome);
  }

  @override
  Future<bool> showInterstitial({required bool nonPersonalized}) async {
    if (!hasAds || !_mayRequestAds) return false;

    final unitId = interstitialUnitId;
    if (unitId == null) return false;
    final spec = AdSpec(
      unitId: unitId,
      format: AdFormat.interstitial,
      reservedHeight: 0,
      nonPersonalized: nonPersonalized,
    );

    final done = Completer<bool>();
    await gma.InterstitialAd.load(
      adUnitId: spec.unitId,
      request: _request(spec),
      adLoadCallback: gma.InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = gma.FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!done.isCompleted) done.complete(true);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!done.isCompleted) done.complete(false);
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          if (!done.isCompleted) done.complete(false);
        },
      ),
    );
    return done.future;
  }

  /// Loads and shows a rewarded ad. The reward is whatever the SDK reports, and
  /// the caller may only act on [RewardedOutcome.earned] — a tap is not a
  /// reward, and neither is a partially watched ad (`docs/08 §5`).
  @override
  Future<RewardedOutcome> showRewarded({required bool nonPersonalized}) async {
    if (!hasAds || !_mayRequestAds) return RewardedOutcome.unavailable;
    final unitId = rewardedUnitId;
    if (unitId == null) return RewardedOutcome.unavailable;

    final spec = AdSpec(
      unitId: unitId,
      format: AdFormat.rewarded,
      reservedHeight: 0,
      nonPersonalized: nonPersonalized,
    );

    final done = Completer<RewardedOutcome>();
    var earned = false;

    await gma.RewardedAd.load(
      adUnitId: spec.unitId,
      request: _request(spec),
      rewardedAdLoadCallback: gma.RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = gma.FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (done.isCompleted) return;
              done.complete(
                earned ? RewardedOutcome.earned : RewardedOutcome.dismissed,
              );
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!done.isCompleted) done.complete(RewardedOutcome.unavailable);
            },
          );
          ad.show(onUserEarnedReward: (ad, reward) => earned = true);
        },
        onAdFailedToLoad: (error) {
          if (!done.isCompleted) done.complete(RewardedOutcome.unavailable);
        },
      ),
    );
    return done.future;
  }
}

/// One loaded ad, from request to dispose.
///
/// Loading starts when the slot appears and the ad is disposed the moment the
/// slot goes away — a native ad holds a platform view, and leaking one keeps a
/// whole WebView alive (`docs/08 §8`).
class _SdkAdView extends StatefulWidget {
  const _SdkAdView({
    required this.client,
    required this.spec,
    required this.onOutcome,
  });

  final MobileAdClient client;
  final AdSpec spec;
  final ValueChanged<AdOutcome> onOutcome;

  @override
  State<_SdkAdView> createState() => _SdkAdViewState();
}

class _SdkAdViewState extends State<_SdkAdView> {
  gma.BannerAd? _banner;
  gma.NativeAd? _native;
  bool _loaded = false;

  gma.AdWithView? get _ad => _banner ?? _native;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final client = widget.client;
    final spec = widget.spec;

    switch (spec.format) {
      case AdFormat.banner:
        _banner = gma.BannerAd(
          adUnitId: spec.unitId,
          // The slot reserves 56 and the standard banner is 320×50, so the
          // reserved box is never smaller than the ad inside it.
          size: gma.AdSize.banner,
          request: client._request(spec),
          listener: gma.BannerAdListener(
            onAdLoaded: (ad) => _ready(),
            onAdFailedToLoad: (ad, error) {
              ad.dispose();
              _banner = null;
              _failed();
            },
          ),
        )..load();
      case AdFormat.native:
        _native = gma.NativeAd(
          adUnitId: spec.unitId,
          request: client._request(spec),
          listener: gma.NativeAdListener(
            onAdLoaded: (ad) => _ready(),
            onAdFailedToLoad: (ad, error) {
              ad.dispose();
              _native = null;
              _failed();
            },
          ),
          // Google's built-in template, so there is no factory to register in
          // Kotlin. It brings its own "Sponsored" row, which is what the policy
          // asks for and what a hand-rolled layout usually forgets.
          nativeTemplateStyle: gma.NativeTemplateStyle(
            templateType: gma.TemplateType.small,
          ),
        )..load();
      case AdFormat.interstitial:
      case AdFormat.rewarded:
        // Whole-screen formats are shown by the gate, not placed inline.
        break;
    }
  }

  void _ready() {
    if (!mounted) return;
    setState(() => _loaded = true);
    widget.onOutcome(AdOutcome.loaded);
  }

  void _failed() {
    if (!mounted) {
      widget.onOutcome(AdOutcome.failed);
      return;
    }
    widget.onOutcome(AdOutcome.failed);
  }

  @override
  void dispose() {
    _banner?.dispose();
    _native?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return gma.AdWidget(ad: ad);
  }
}
