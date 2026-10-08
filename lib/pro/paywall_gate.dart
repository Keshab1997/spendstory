/// When the paywall is allowed to appear (T-604).
///
/// `docs/03 §S-22` names three placements — the Settings card, the third tap on
/// a Pro-locked insight, and the tenth session — and then the rule that makes
/// them bearable: **at most one paywall per session**. This is that rule, kept
/// away from the screens so it can be tested as arithmetic instead of as taps.
///
/// Two things are deliberately *not* gated here. A user tapping something that
/// says "Pro" (the Settings card, the "See Pro" button) asked for the paywall
/// and always gets it — that is `PaywallTrigger.userAsked`. And a user who
/// already pays is never shown it at all, whatever the counters say.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';

/// What is asking for the paywall.
enum PaywallTrigger {
  /// The user tapped something that names Pro. Never refused, never counted
  /// against the per-session limit — refusing a request the user made is the
  /// kind of behaviour this app does not have.
  userAsked,

  /// A tap on something that is locked and says so (the custom date range, for
  /// instance). Counted; the paywall comes on the third one.
  lockedInsight,

  /// The app offering itself, after enough sessions to have earned it.
  sessionCount,
}

/// The placement arithmetic of §S-22, with no state of its own.
class PaywallGateRules {
  const PaywallGateRules({
    this.tapsBeforePrompt = 3,
    this.sessionsBeforePrompt = 10,
  });

  final int tapsBeforePrompt;
  final int sessionsBeforePrompt;

  bool allows(
    PaywallTrigger trigger, {
    required bool isPro,
    required int session,
    required int lockTaps,
    required int? promptedInSession,
  }) {
    if (isPro) return false;
    if (trigger == PaywallTrigger.userAsked) return true;
    // One a session, whoever asks and whenever they ask.
    if (promptedInSession != null && promptedInSession >= session) return false;

    return switch (trigger) {
      PaywallTrigger.lockedInsight => lockTaps >= tapsBeforePrompt,
      PaywallTrigger.sessionCount => session >= sessionsBeforePrompt,
      PaywallTrigger.userAsked => true,
    };
  }
}

/// The counters the rules need: how many times this install has been opened,
/// how many locked taps it has collected, and which session last saw a paywall.
///
/// Kept in memory and written to `app_meta`, so a purchase prompt survives a
/// restart exactly as long as it should — the tenth session is the tenth
/// session, not the tenth since the last reinstall.
class PaywallGate {
  PaywallGate(this._ref);

  final Ref _ref;

  static const PaywallGateRules rules = PaywallGateRules();

  int _session = 1;
  int _lockTaps = 0;
  int? _promptedInSession;

  int get session => _session;
  int get lockTaps => _lockTaps;
  int? get promptedInSession => _promptedInSession;

  /// Counts this launch. Called once, from the shell, after the first frame.
  Future<void> start() async {
    final db = _ref.read(appDbProvider);
    if (db == null) return; // web preview: one session, nothing stored

    _session = (int.tryParse(await db.meta('sessionCount') ?? '') ?? 0) + 1;
    _lockTaps = int.tryParse(await db.meta('proLockTaps') ?? '') ?? 0;
    _promptedInSession = int.tryParse(
      await db.meta('proPromptedSession') ?? '',
    );
    await db.setMeta('sessionCount', '$_session');
  }

  /// Whether this request may open the paywall right now.
  bool shouldPrompt(PaywallTrigger trigger) => rules.allows(
    trigger,
    isPro: _ref.read(proStatusProvider),
    session: _session,
    lockTaps: _lockTaps,
    promptedInSession: _promptedInSession,
  );

  /// Records one tap on a locked insight and answers whether it earned a
  /// paywall. The counters are written down even when it did not: the third tap
  /// is the third tap of this install's life, not of this sitting.
  bool noteLockedTap() {
    _lockTaps += 1;
    _remember('proLockTaps', '$_lockTaps');
    return shouldPrompt(PaywallTrigger.lockedInsight);
  }

  /// Records that a paywall was opened, which spends this session's one.
  void notePrompted() {
    _promptedInSession = _session;
    _remember('proPromptedSession', '$_session');
  }

  void _remember(String key, String value) {
    final db = _ref.read(appDbProvider);
    if (db != null) unawaited(db.setMeta(key, value));
  }
}

/// The gate for this install. Lives here rather than in `lib/app/providers.dart`
/// for the same reason the billing controller does: the gate reads the billing
/// state, so the provider has to sit on the `lib/pro` side of that line.
final paywallGateProvider = Provider<PaywallGate>((ref) => PaywallGate(ref));

/// The one way a screen asks for the paywall. Returns false when the rules say
/// "not now" — the caller then decides what to do instead, and it should be
/// something quiet and useful rather than nothing at all.
bool requestPaywall(WidgetRef ref, PaywallTrigger trigger) {
  final gate = ref.read(paywallGateProvider);
  final allowed = switch (trigger) {
    PaywallTrigger.lockedInsight => gate.noteLockedTap(),
    _ => gate.shouldPrompt(trigger),
  };
  if (allowed) gate.notePrompted();
  return allowed;
}
