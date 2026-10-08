/// The paywall's placement rules (T-604, `docs/03 §S-22`).
///
/// Three placements — Settings, the third tap on a locked insight, the tenth
/// session — and one cap: a single paywall per session. The counters are what
/// makes the difference between an app that offers itself and an app that
/// nags, so they are tested as arithmetic first, then as taps in
/// `test/ui/insights_test.dart`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/pro/paywall_gate.dart';

bool allows(
  PaywallTrigger trigger, {
  bool isPro = false,
  int session = 1,
  int lockTaps = 0,
  int? promptedInSession,
}) => const PaywallGateRules().allows(
  trigger,
  isPro: isPro,
  session: session,
  lockTaps: lockTaps,
  promptedInSession: promptedInSession,
);

void main() {
  group('a user who taps something that says Pro', () {
    test('gets the paywall the first time, not the third', () {
      // The Settings card and the "See Pro" button are requests, not nudges.
      // Refusing one would be the app pretending not to hear.
      expect(allows(PaywallTrigger.userAsked), isTrue);
    });

    test('gets it even in a session that already showed one', () {
      expect(
        allows(PaywallTrigger.userAsked, session: 4, promptedInSession: 4),
        isTrue,
      );
    });
  });

  group('a locked insight', () {
    test('is not interrupted on the first two taps', () {
      expect(allows(PaywallTrigger.lockedInsight, lockTaps: 1), isFalse);
      expect(allows(PaywallTrigger.lockedInsight, lockTaps: 2), isFalse);
    });

    test('opens the paywall on the third', () {
      expect(allows(PaywallTrigger.lockedInsight, lockTaps: 3), isTrue);
      expect(allows(PaywallTrigger.lockedInsight, lockTaps: 9), isTrue);
    });

    test('…unless this session already spent its one', () {
      expect(
        allows(
          PaywallTrigger.lockedInsight,
          session: 7,
          lockTaps: 5,
          promptedInSession: 7,
        ),
        isFalse,
      );
    });

    test('…and a session that lapsed opens a fresh allowance', () {
      // Session 7's paywall does not silence session 8.
      expect(
        allows(
          PaywallTrigger.lockedInsight,
          session: 8,
          lockTaps: 5,
          promptedInSession: 7,
        ),
        isTrue,
      );
    });
  });

  group('the app offering itself', () {
    test('waits for the tenth session', () {
      expect(allows(PaywallTrigger.sessionCount, session: 9), isFalse);
      expect(allows(PaywallTrigger.sessionCount, session: 10), isTrue);
    });

    test('does not open on the session that already saw one', () {
      expect(
        allows(PaywallTrigger.sessionCount, session: 11, promptedInSession: 11),
        isFalse,
      );
    });

    test('does not count a reinstall as a fresh start', () {
      // The counter lives in `app_meta`; this is the arithmetic the stored
      // value passes through on launch number twenty.
      expect(allows(PaywallTrigger.sessionCount, session: 20), isTrue);
    });
  });

  group('somebody who already pays', () {
    test('is never shown a paywall, for any reason at all', () {
      for (final trigger in PaywallTrigger.values) {
        expect(
          allows(
            trigger,
            isPro: true,
            session: 50,
            lockTaps: 40,
            promptedInSession: null,
          ),
          isFalse,
          reason: '$trigger',
        );
      }
    });
  });
}
