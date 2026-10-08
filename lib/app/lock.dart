/// The app lock's state: whether the switch is on, and whether the app is
/// currently behind the lock screen (`docs/03 §S-20`, `docs/04 §6`).
///
/// Two booleans and a timestamp, deliberately:
///
/// * [lockEnabledProvider] — the user's choice, mirrored from `app_meta`.
/// * [lockedProvider] — the app's *current* obligation to ask. It is not the
///   same thing: turning the lock on in Settings does not lock the screen the
///   user is looking at, and cold start does.
/// * [awaySinceProvider] — when the app last went to the background, so a
///   glance at a notification is not a re-prompt (see [lockGrace]).
///
/// The biometric prompt itself lives in `lib/platform/app_lock.dart`; nothing
/// here touches a plugin, so `flutter test` drives the whole state machine with
/// a fake.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seed.dart';
import '../platform/app_lock.dart';
import 'providers.dart';

/// How long the app may sit in the background before it locks itself again.
///
/// Deliberately not zero. Sharing a backup (`S-23`) hands the phone to the
/// share sheet, and a lock that re-prompts on the way back would punish exactly
/// the flow that keeps the user's data theirs; the same goes for reading a
/// transaction alert in the notification shade. A minute is long enough to send
/// a file and short enough that a phone left on a table comes back locked.
const Duration lockGrace = Duration(minutes: 1);

/// The biometric seam. Overridden in tests; on web it answers `unavailable`.
final appLockProvider = Provider<AppLock>((ref) => const LocalAuthAppLock());

/// The user's choice, hydrated at boot from `app_meta`.
final lockEnabledProvider = StateProvider<bool>((ref) => false);

/// True while the app must show [LockScreen] instead of whatever was asked for.
final lockedProvider = StateProvider<bool>((ref) => false);

/// When the app was last backgrounded, or null if it never was (or has already
/// been accounted for).
final awaySinceProvider = StateProvider<DateTime?>((ref) => null);

class LockActions {
  LockActions(this._ref);

  final Ref _ref;

  /// Called once, when boot reads a stored "on": the app opens behind the lock.
  void arm() {
    _ref.read(lockEnabledProvider.notifier).state = true;
    _ref.read(lockedProvider.notifier).state = true;
  }

  /// The Settings switch. Asking to turn the lock **on** proves the user can
  /// answer it at all — a lock they cannot open is a bricked app. Asking to
  /// turn it **off** asks for the same proof, because an already-unlocked
  /// screen is not consent, and the phone may have been handed over.
  ///
  /// Nothing changes unless the prompt comes back [LockOutcome.unlocked]; the
  /// outcome is returned so the caller can say what happened.
  Future<LockOutcome> setEnabled(bool on, {required String reason}) async {
    final outcome = await _ref.read(appLockProvider).prompt(reason: reason);
    if (outcome != LockOutcome.unlocked) return outcome;

    await _store(on);
    _ref.read(lockEnabledProvider.notifier).state = on;
    if (!on) {
      _ref.read(lockedProvider.notifier).state = false;
      _ref.read(awaySinceProvider.notifier).state = null;
    }
    return outcome;
  }

  /// The lock screen's unlock button.
  Future<LockOutcome> unlock({required String reason}) async {
    final outcome = await _ref.read(appLockProvider).prompt(reason: reason);
    if (outcome == LockOutcome.unlocked) {
      _ref.read(lockedProvider.notifier).state = false;
      _ref.read(awaySinceProvider.notifier).state = null;
    }
    return outcome;
  }

  /// The way out for a phone that cannot answer: the user enabled the lock,
  /// then deleted every fingerprint, face and PIN. Permanent lock-out is not an
  /// option this app offers — the data is on this phone and the user owns it.
  /// The escape hatch is a decision, not a bypass: the lock really does turn
  /// off, and the state is written down like any other change.
  Future<void> disableFromLockScreen() async {
    await _store(false);
    _ref.read(lockEnabledProvider.notifier).state = false;
    _ref.read(lockedProvider.notifier).state = false;
    _ref.read(awaySinceProvider.notifier).state = null;
  }

  /// The app went to the background.
  void noteAway(DateTime now) {
    if (!_ref.read(lockEnabledProvider)) return;
    _ref.read(awaySinceProvider.notifier).state = now;
  }

  /// The app came back. Locks only if it was away longer than [lockGrace].
  void noteBack(DateTime now) {
    if (!_ref.read(lockEnabledProvider)) return;
    if (_ref.read(lockedProvider)) return;
    final away = _ref.read(awaySinceProvider);
    if (away == null) return;
    _ref.read(awaySinceProvider.notifier).state = null;
    if (now.difference(away) >= lockGrace) {
      _ref.read(lockedProvider.notifier).state = true;
    }
  }

  /// `app_meta` is the whole settings store; with no database (web preview,
  /// widget tests without a real db) there is nothing to write to and the
  /// session state above is the whole story.
  Future<void> _store(bool on) async {
    final db = _ref.read(appDbProvider);
    if (db != null) await db.setMeta(kAppLockMetaKey, on ? 'true' : 'false');
  }
}

final lockActionsProvider = Provider<LockActions>((ref) => LockActions(ref));
