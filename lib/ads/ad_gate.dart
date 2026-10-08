/// The interstitial governor (T-602, `docs/08 §4`).
///
/// An interstitial is the most valuable ad in the app and the easiest way to
/// lose a user, so it gets one trigger, one showing per session, and a four
/// minute floor on top. Everything that decides is a pure function of state
/// that can be handed in, which is the only reason "max 1 per session" is a
/// claim the tests can check rather than a comment.
///
/// It is also the *only* place that reads [AdTrigger], so adding a trigger
/// means editing one list — and `docs/08 §3` says that list stays at one until
/// there is a reason otherwise.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'ad_client.dart';

/// The one navigation an interstitial may interrupt.
enum AdTrigger {
  /// Tapping Insights on the home screen.
  homeToInsights,
}

/// The decisions, with no clock and no refs in sight.
class AdGateRules {
  const AdGateRules({
    this.maxPerSession = 1,
    this.minGap = const Duration(seconds: 240),
  });

  final int maxPerSession;

  /// The floor between two interstitials, in case a future build allows more
  /// than one per session. `docs/08 §4`: 240 seconds.
  final Duration minGap;

  /// The triggers that may ever show one.
  static const Set<AdTrigger> allowedTriggers = <AdTrigger>{
    AdTrigger.homeToInsights,
  };

  bool allows({
    required AdTrigger trigger,
    required bool isPro,
    required bool hasAd,
    required bool adsVisible,
    required int shownThisSession,
    required DateTime? lastShownAt,
    required DateTime now,
  }) {
    if (isPro || !hasAd || !adsVisible) return false;
    if (!allowedTriggers.contains(trigger)) return false;
    if (shownThisSession >= maxPerSession) return false;
    // `docs/08 §4` spells the floor as `> 240s`, so the boundary itself is
    // still inside it.
    if (lastShownAt != null && now.difference(lastShownAt) <= minGap) {
      return false;
    }
    return true;
  }
}

/// What one app run has spent.
class AdGate {
  AdGate(this._ref, {this.rules = const AdGateRules()});

  final Ref _ref;
  final AdGateRules rules;

  int _shownThisSession = 0;
  DateTime? _lastShownAt;

  int get shownThisSession => _shownThisSession;

  /// Whether a trigger may show an interstitial right now.
  bool allows(AdTrigger trigger) {
    final client = _ref.read(adClientProvider);
    return rules.allows(
      trigger: trigger,
      isPro: _ref.read(proStatusProvider),
      hasAd: client.hasAds,
      adsVisible: _ref.read(adsVisibleProvider),
      shownThisSession: _shownThisSession,
      lastShownAt: _lastShownAt,
      now: _ref.read(nowProvider),
    );
  }

  /// Shows one if the rules allow it. Returns true only when an interstitial
  /// really reached the screen — a request that fails to load costs the user
  /// nothing, so it does not spend the session's one showing.
  Future<bool> maybeShow(AdTrigger trigger) async {
    if (!allows(trigger)) return false;

    final client = _ref.read(adClientProvider);
    if (client.interstitialUnitId == null) return false;

    final shown = await client.showInterstitial(
      nonPersonalized: _ref.read(nonPersonalizedAdsProvider),
    );
    if (shown) {
      _shownThisSession += 1;
      _lastShownAt = _ref.read(nowProvider);
    }
    return shown;
  }
}

final adGateProvider = Provider<AdGate>((ref) => AdGate(ref));
