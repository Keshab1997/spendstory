/// The paywall's counters across restarts (T-604).
///
/// The rules are arithmetic and live in `paywall_gate_test.dart`. What is left
/// is the part a user would notice if it were wrong: that the tenth session is
/// the tenth session of the install — not of the sitting, and not of the day
/// the app was reinstalled — and that taps collected while the paywall was
/// still holding back are not thrown away.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/data/db.dart';
import 'package:spendstory/pro/entitlement.dart';
import 'package:spendstory/pro/paywall_gate.dart';
import 'package:spendstory/pro/product_ids.dart';

void main() {
  late AppDb db;

  setUp(() async => db = AppDb.memory());
  tearDown(() async => db.close());

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: <Override>[appDbProvider.overrideWithValue(db)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'each launch counts one session, and the count is written down',
    () async {
      final first = container();
      await first.read(paywallGateProvider).start();
      expect(first.read(paywallGateProvider).session, 1);
      expect(await db.meta('sessionCount'), '1');

      // A second launch — a new container over the same database.
      final second = container();
      await second.read(paywallGateProvider).start();
      expect(second.read(paywallGateProvider).session, 2);
      expect(await db.meta('sessionCount'), '2');
    },
  );

  test('a locked tap is remembered while the paywall is still held back', () async {
    final first = container();
    final gate = first.read(paywallGateProvider);
    await gate.start();

    expect(gate.noteLockedTap(), isFalse); // 1
    expect(gate.noteLockedTap(), isFalse); // 2
    expect(await db.meta('proLockTaps'), '2');

    final second = container();
    await second.read(paywallGateProvider).start();
    expect(second.read(paywallGateProvider).lockTaps, 2);
    // The third tap of the install's life, in a session that has not spent its
    // one yet.
    expect(second.read(paywallGateProvider).noteLockedTap(), isTrue);
  });

  test('the session that saw a paywall is remembered too', () async {
    final first = container();
    final gate = first.read(paywallGateProvider);
    await gate.start();
    for (var i = 0; i < 3; i++) {
      gate.noteLockedTap();
    }
    expect(gate.shouldPrompt(PaywallTrigger.lockedInsight), isTrue);

    gate.notePrompted();
    expect(gate.shouldPrompt(PaywallTrigger.lockedInsight), isFalse);
    expect(await db.meta('proPromptedSession'), '1');
  });

  test('the tenth session is offered the paywall, the ninth is not', () async {
    await db.setMeta('sessionCount', '8');

    final ninth = container();
    await ninth.read(paywallGateProvider).start();
    expect(ninth.read(paywallGateProvider).session, 9);
    expect(
      ninth.read(paywallGateProvider).shouldPrompt(PaywallTrigger.sessionCount),
      isFalse,
    );

    final tenth = container();
    await tenth.read(paywallGateProvider).start();
    expect(tenth.read(paywallGateProvider).session, 10);
    expect(
      tenth.read(paywallGateProvider).shouldPrompt(PaywallTrigger.sessionCount),
      isTrue,
    );
  });

  test('a Pro user is never offered it, tenth session or not', () async {
    await db.setMeta('sessionCount', '40');
    await db.setMeta(
      'proEntitlement',
      ProEntitlement(
        plan: ProPlan.yearly,
        confirmedAtMs: DateTime(2026, 10, 8).millisecondsSinceEpoch,
      ).encode(),
    );

    final c = container();
    // The controller is what puts the stored entitlement into the provider the
    // gate reads; without it the gate would be reading a free install.
    final entitlement = ProEntitlement.decode(await db.meta('proEntitlement'))!;
    c.read(proEntitlementProvider.notifier).state = entitlement;
    await c.read(paywallGateProvider).start();

    expect(c.read(proStatusProvider), isTrue);
    expect(c.read(paywallGateProvider).session, 41);
    expect(
      c.read(paywallGateProvider).shouldPrompt(PaywallTrigger.sessionCount),
      isFalse,
    );
  });
}
