/// The two rewarded offers (T-606, `docs/08 §5`).
///
/// The bet in `docs/08 §5` is that an Indian user who will not pay ₹99 will
/// watch thirty seconds for something real. So the offers are real:
///
/// | Offer | Cap | Grants |
/// |---|---|---|
/// | 24 hours of Pro | 1 a day | a [ProPlan.taste] entitlement |
/// | One free PDF export | 2 a day | one credit S-23 spends |
///
/// Four rules make it a fair trade rather than a slot machine, and each one has
/// a test:
///
/// * **Opt-in, always.** Nothing autoplays, and the button says what it is.
/// * **Only the SDK's word grants.** A tap is not a reward, and neither is an ad
///   the user closed after three seconds.
/// * **Never to somebody who already pays.** A Pro user is never offered an ad
///   of any kind, rewarded included — that is the thing they paid to be rid of.
/// * **The cap is on grants, not on attempts.** An ad that never filled, or
///   failed halfway, costs the user nothing and does not spend the day's one.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_client.dart';
import '../app/providers.dart';
import 'product_ids.dart';
import 'pro_controller.dart';

/// The two things an ad can buy in this app.
enum RewardKind {
  /// 24 hours of Pro, for watching one rewarded ad — `docs/08 §5`'s "Pro taste".
  proTaste,

  /// One free PDF export, spent on S-23 (T-705). Kept here rather than in the
  /// export screen so the daily cap cannot be re-implemented, and re-broken,
  /// somewhere else.
  pdfExport,
}

/// The caps, with no clock and no refs in sight.
class RewardRules {
  const RewardRules({
    this.proTastePerDay = 1,
    this.pdfExportsPerDay = 2,
    this.tasteDuration = const Duration(hours: 24),
  });

  /// `docs/08 §5`: one 24-hour taste a day.
  final int proTastePerDay;

  /// `docs/08 §5`: two free PDF exports a day.
  final int pdfExportsPerDay;

  /// How long the taste lasts. It is the whole entitlement window of the taste
  /// plan, in one place, so the offer and the expiry cannot disagree.
  final Duration tasteDuration;

  int capOf(RewardKind kind) => switch (kind) {
    RewardKind.proTaste => proTastePerDay,
    RewardKind.pdfExport => pdfExportsPerDay,
  };

  /// Whether the offer may even be *shown*.
  bool offers(
    RewardKind kind, {
    required bool isPro,
    required bool adsVisible,
    required bool hasUnit,
    required int grantedToday,
  }) {
    if (isPro || !adsVisible || !hasUnit) return false;
    return grantedToday < capOf(kind);
  }
}

/// Today's counters, and the only thing that hands out a reward.
///
/// Counters live in `app_meta` under `reward:<kind>:<day>` — one key per kind per
/// day, so yesterday's numbers cannot leak into today and a timezone change
/// cannot hand out a second taste by accident.
class RewardLedger {
  RewardLedger(this._ref, {this.rules = const RewardRules()});

  final Ref _ref;
  final RewardRules rules;

  String? _day;
  final Map<RewardKind, int> _granted = <RewardKind, int>{};
  int _pdfSpent = 0;

  int grantedToday(RewardKind kind) => _granted[kind] ?? 0;

  /// Free PDF exports this user may still spend today.
  int get pdfCreditsToday => grantedToday(RewardKind.pdfExport) - _pdfSpent;

  /// Reads today's counters. Called from the shell, after the first frame, so
  /// the button knows whether it is still owed an offer before it is drawn.
  Future<void> start() async {
    final db = _ref.read(appDbProvider);
    _day = _dayKey(_ref.read(nowProvider));

    if (db == null) {
      return; // web preview: nothing stored, and nothing to store
    }
    for (final kind in RewardKind.values) {
      final stored = int.tryParse(await db.meta(_key(kind)) ?? '') ?? 0;
      if (stored > 0) _granted[kind] = stored;
    }
    _pdfSpent = int.tryParse(await db.meta(_pdfSpentKey()) ?? '') ?? 0;
    _publish();
  }

  /// Whether the offer may be shown right now.
  bool canOffer(RewardKind kind) {
    _rollIfNeeded();
    final client = _ref.read(adClientProvider);
    return rules.offers(
      kind,
      isPro: _ref.read(proStatusProvider),
      adsVisible: _ref.read(adsVisibleProvider),
      hasUnit: client.rewardedUnitId != null,
      grantedToday: grantedToday(kind),
    );
  }

  /// The user's tap on "watch an ad". Returns what the ad turned out to be, and
  /// grants only when the SDK reported the reward.
  Future<RewardedOutcome> watch(RewardKind kind) async {
    if (!canOffer(kind)) return RewardedOutcome.unavailable;

    final outcome = await _ref
        .read(adClientProvider)
        .showRewarded(nonPersonalized: _ref.read(nonPersonalizedAdsProvider));

    if (outcome == RewardedOutcome.earned) await _grant(kind);
    return outcome;
  }

  /// Spends one free export, for S-23. False when there is none left, which the
  /// export screen reads as "this one is Pro".
  Future<bool> spendPdfCredit() async {
    _rollIfNeeded();
    if (pdfCreditsToday <= 0) return false;
    _pdfSpent += 1;
    final db = _ref.read(appDbProvider);
    if (db != null) await db.setMeta(_pdfSpentKey(), '$_pdfSpent');
    _publish();
    return true;
  }

  Future<void> _grant(RewardKind kind) async {
    _granted[kind] = grantedToday(kind) + 1;

    if (kind == RewardKind.proTaste) {
      // A taste is an entitlement like any other: same window arithmetic, same
      // expiry, same clearing on the next launch. It is deliberately *not* a
      // second kind of Pro that the rest of the app has to know about.
      _ref.read(proControllerProvider).grantTaste();
    }

    final db = _ref.read(appDbProvider);
    if (db != null) await db.setMeta(_key(kind), '${_granted[kind]}');
    _publish();
  }

  /// Rolls the counters if the app was left open across midnight, so a taste
  /// watched at 11pm is not still "today's" at 1am.
  void _rollIfNeeded() {
    final day = _dayKey(_ref.read(nowProvider));
    if (day == _day) return;
    _day = day;
    _granted.clear();
    _pdfSpent = 0;
  }

  void _publish() {
    _ref.read(rewardGrantedTodayProvider.notifier).state =
        Map<RewardKind, int>.of(_granted);
    _ref.read(pdfExportCreditsProvider.notifier).state = pdfCreditsToday;
  }

  String _key(RewardKind kind) => 'reward:${kind.name}:$_day';

  String _pdfSpentKey() => 'reward:${RewardKind.pdfExport.name}:$_day:spent';

  /// The day the counters belong to. Local midnight is the boundary a user
  /// actually experiences — "come back tomorrow" has to mean after they sleep.
  static String _dayKey(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

final rewardLedgerProvider = Provider<RewardLedger>((ref) => RewardLedger(ref));

/// What has been granted today, per kind — what the offer buttons read.
final rewardGrantedTodayProvider = StateProvider<Map<RewardKind, int>>(
  (ref) => const <RewardKind, int>{},
);

/// Free PDF exports available to spend today (S-23 / T-705).
final pdfExportCreditsProvider = StateProvider<int>((ref) => 0);

/// The plan a taste grants, re-exported so a caller does not have to reach into
/// `product_ids.dart` to talk about the reward.
const ProPlan kTastePlan = ProPlan.taste;
