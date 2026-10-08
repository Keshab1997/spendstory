/// The app lock's platform half: asking the phone to prove it is the owner.
///
/// S-20's নিরাপত্তা section offers one switch, and `docs/07 §5` lists it as a
/// security safeguard: opening the ledger can require a fingerprint, a face, or
/// the phone's own PIN. The check happens inside Android through
/// `androidx.biometric` (wrapped by `local_auth`) on a `FragmentActivity`;
/// SpendStory receives one bit — *it was them* — and stores nothing. There is no
/// biometric data in the app, no hash of one, and nothing extra to leak.
///
/// [prompt] never throws. The web preview, `flutter test` and a phone with no
/// enrolment all land in the same place — [LockOutcome.unavailable] — for the
/// same reason [NativeBridge] answers "no host" instead of failing: a lock is a
/// guard, and a guard that crashes the app is worse than one that declines.
library;

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// What came back from the system prompt.
enum LockOutcome {
  /// The user proved it is them.
  unlocked,

  /// The user dismissed the prompt, or it timed out. Not a failure — the app
  /// stays exactly as locked as it was.
  cancelled,

  /// There was nothing to ask: no host (web, `flutter test`), nothing enrolled
  /// on the phone, or the OS refused to show a prompt. The UI says so instead
  /// of pretending the user cancelled.
  unavailable,
}

/// The seam every screen goes through, so a widget test can watch an unlock
/// without an Android host anywhere near it.
abstract class AppLock {
  /// Asks the system to authenticate the user. [reason] is the sentence the
  /// system dialog shows, and comes from the ARB files like all other copy.
  Future<LockOutcome> prompt({required String reason});
}

/// The real thing: `local_auth` → `BiometricPrompt` on this phone.
class LocalAuthAppLock implements AppLock {
  const LocalAuthAppLock();

  @override
  Future<LockOutcome> prompt({required String reason}) async {
    // No plugin, no prompt, no exception: the web preview is a preview.
    if (kIsWeb) return LockOutcome.unavailable;

    try {
      final ok = await LocalAuthentication().authenticate(
        localizedReason: reason,
        // Device credentials are allowed on purpose. A lock that accepts only
        // a fingerprint becomes a lock-out the day the user deletes their
        // fingerprints — and the phone's PIN is the same proof Android itself
        // would demand to open the device.
        biometricOnly: false,
        // The system retries the prompt when the app comes back to the front,
        // instead of failing with an error the user cannot act on.
        persistAcrossBackgrounding: true,
      );
      return ok ? LockOutcome.unlocked : LockOutcome.cancelled;
    } on LocalAuthException catch (error) {
      switch (error.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
          return LockOutcome.cancelled;
        default:
          // `noBiometricsEnrolled`, `noBiometricHardware`, `uiUnavailable`,
          // `noCredentialsSet` and anything added later: all of them mean the
          // same thing to the UI — this phone cannot answer right now.
          return LockOutcome.unavailable;
      }
    } on Object {
      // MissingPluginException in a widget test, PlatformException from a host
      // that does not implement the channel, anything else. Never a crash.
      return LockOutcome.unavailable;
    }
  }
}
