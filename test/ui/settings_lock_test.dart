/// S-20's নিরাপত্তা half (T-706, `docs/03 §S-20`, `docs/04 §6`, `docs/07 §5`):
/// the app lock and the erase path, driven through the real router.
///
/// Four properties, in the order a user meets them:
///
///   * the switch does not flip on a prompt that was cancelled, and it says so;
///   * a phone that cannot ask for a fingerprint is told the truth rather than
///     being left with a switch that does nothing;
///   * a stored "on" opens the app locked, with the ledger never built behind
///     it, and unlocking returns to the screen the guard intercepted;
///   * erasing everything asks twice, purges on the second yes only, and lands
///     the app back at the language picker with an empty database.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/lock.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/data/db.dart';
import 'package:spendstory/data/seed.dart';
import 'package:spendstory/platform/app_lock.dart';
import 'package:spendstory/ui/strings.dart';

import 'ledger_harness.dart';

final SsStrings _s = SsStrings('en');

/// Settings, with a real (in-memory) database behind it — half of this feature
/// is the record, so a fake store would test nothing.
Future<(ProviderContainer, AppDb)> _pumpSettings(
  WidgetTester tester, {
  required FakeAppLock lock,
  bool enabled = false,
}) async {
  final db = AppDb.memory();
  addTearDown(db.close);
  await db.seedIfNeeded();
  await db.setMeta('onboarded', 'true');
  await db.setMeta(kAppLockMetaKey, enabled ? 'true' : 'false');

  final container = await pumpAt(
    tester,
    '/settings',
    extra: <Override>[
      appDbProvider.overrideWithValue(db),
      appLockProvider.overrideWithValue(lock),
      lockEnabledProvider.overrideWith((ref) => enabled),
    ],
  );
  return (container, db);
}

/// The app, already told by boot that the lock is on. The arm happens through
/// the same listener the real launch uses, so this is not a shortcut past the
/// wiring — it is the wiring.
Future<ProviderContainer> _pumpLocked(
  WidgetTester tester,
  FakeAppLock lock, {
  String at = '/home',
}) async {
  return pumpAt(
    tester,
    at,
    extra: <Override>[
      bootProvider.overrideWith(
        (ref) async => const BootState(
          onboarded: true,
          demoMode: true,
          locale: 'en',
          appLock: true,
        ),
      ),
      appLockProvider.overrideWithValue(lock),
    ],
  );
}

void main() {
  group('the switch', () {
    testWidgets('turns on only after the phone has confirmed the user', (
      tester,
    ) async {
      final lock = FakeAppLock(LockOutcome.unlocked);
      final (container, db) = await _pumpSettings(tester, lock: lock);

      await tester.tap(find.text(_s.appLock));
      await tester.pumpAndSettle();

      expect(container.read(lockEnabledProvider), isTrue);
      expect(await db.meta(kAppLockMetaKey), 'true');
      expect(find.text(_s.appLockOnDone), findsOneWidget);
      // The reason goes to the *system* dialog, so it has to be copy, not a
      // developer sentence.
      expect(lock.reasons, <String>[_s.appLockPromptReason]);
      // And the screen the user is looking at is not locked: they just proved
      // it is them.
      expect(container.read(lockedProvider), isFalse);
    });

    testWidgets('stays off when the prompt is cancelled', (tester) async {
      final lock = FakeAppLock(LockOutcome.cancelled);
      final (container, db) = await _pumpSettings(tester, lock: lock);

      await tester.tap(find.text(_s.appLock));
      await tester.pumpAndSettle();

      expect(container.read(lockEnabledProvider), isFalse);
      expect(await db.meta(kAppLockMetaKey), 'false');
      expect(find.text(_s.appLockCancelled), findsOneWidget);
      // Scoped to this tile: Settings carries more than one switch.
      expect(tester.widget<Switch>(switchInTile(_s.appLock)).value, isFalse);
    });

    testWidgets('says so when the phone has nothing to ask with', (
      tester,
    ) async {
      final lock = FakeAppLock(LockOutcome.unavailable);
      final (container, db) = await _pumpSettings(tester, lock: lock);

      await tester.tap(find.text(_s.appLock));
      await tester.pumpAndSettle();

      expect(container.read(lockEnabledProvider), isFalse);
      expect(await db.meta(kAppLockMetaKey), 'false');
      expect(find.text(_s.appLockUnavailable), findsOneWidget);
    });

    testWidgets('asks before turning off too, and records the change', (
      tester,
    ) async {
      final lock = FakeAppLock(LockOutcome.unlocked);
      final (container, db) = await _pumpSettings(
        tester,
        lock: lock,
        enabled: true,
      );

      await tester.tap(find.text(_s.appLock));
      await tester.pumpAndSettle();

      expect(
        lock.reasons,
        isNotEmpty,
        reason: 'an unlocked screen is not proof',
      );
      expect(container.read(lockEnabledProvider), isFalse);
      expect(await db.meta(kAppLockMetaKey), 'false');
      expect(find.text(_s.appLockOffDone), findsOneWidget);
    });
  });

  group('the lock screen', () {
    testWidgets('opens instead of the ledger, and the ledger is never built', (
      tester,
    ) async {
      final container = await _pumpLocked(
        tester,
        FakeAppLock(LockOutcome.cancelled),
      );

      expect(find.text(_s.lockTitle), findsOneWidget);
      expect(container.read(lockedProvider), isTrue);
      // The demo ledger's rows are the honest stand-in for real ones: if the
      // guard leaked, they would be on screen behind the lock.
      expect(find.text('BigBasket'), findsNothing);
      expect(find.text(_s.settings), findsNothing);
    });

    testWidgets('unlocks, and returns to the screen the guard intercepted', (
      tester,
    ) async {
      final lock = FakeAppLock(LockOutcome.cancelled);
      final container = await _pumpLocked(tester, lock, at: '/insights');

      expect(find.text(_s.lockTitle), findsOneWidget);

      lock.outcome = LockOutcome.unlocked;
      await tester.tap(find.text(_s.lockUnlock));
      await tester.pumpAndSettle();

      expect(container.read(lockedProvider), isFalse);
      // `/insights`, not Home: the guard remembers what it withheld.
      expect(find.text(_s['trend30']), findsOneWidget);
      expect(find.text(_s.lockTitle), findsNothing);
    });

    testWidgets('offers a way out of a phone that cannot answer', (
      tester,
    ) async {
      final container = await _pumpLocked(
        tester,
        FakeAppLock(LockOutcome.unavailable),
      );

      expect(find.text(_s.lockUnavailableBody), findsOneWidget);
      expect(find.text(_s.lockTurnOff), findsOneWidget);

      await tester.tap(find.text(_s.lockTurnOff));
      await tester.pumpAndSettle();

      // Not a bypass: the lock really is off, and it is back at the ledger.
      expect(container.read(lockEnabledProvider), isFalse);
      expect(container.read(lockedProvider), isFalse);
      expect(find.text('BigBasket'), findsOneWidget);
    });

    testWidgets('is not a place to sit when there is no lock', (tester) async {
      await pumpAt(tester, '/lock');

      expect(find.text(_s.lockTitle), findsNothing);
      expect(find.text('BigBasket'), findsOneWidget);
    });
  });

  group('the lock state machine', () {
    test('a glance away does not lock; a real absence does', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final actions = container.read(lockActionsProvider);
      final t0 = DateTime(2026, 10, 8, 9);

      container.read(lockEnabledProvider.notifier).state = true;

      actions.noteAway(t0);
      actions.noteBack(t0.add(const Duration(seconds: 30)));
      expect(container.read(lockedProvider), isFalse);

      actions.noteAway(t0);
      actions.noteBack(t0.add(lockGrace));
      expect(container.read(lockedProvider), isTrue);
    });

    test('with the lock off, leaving and coming back is not its business', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final actions = container.read(lockActionsProvider);
      final t0 = DateTime(2026, 10, 8, 9);

      actions.noteAway(t0);
      expect(container.read(awaySinceProvider), isNull);

      actions.noteBack(t0.add(const Duration(hours: 3)));
      expect(container.read(lockedProvider), isFalse);
    });

    test('turning the lock on does not lock the screen you are on', () async {
      final container = ProviderContainer(
        overrides: <Override>[
          appDbProvider.overrideWithValue(null),
          appLockProvider.overrideWithValue(FakeAppLock(LockOutcome.unlocked)),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(lockActionsProvider)
          .setEnabled(true, reason: 'Unlock SpendStory');

      expect(container.read(lockEnabledProvider), isTrue);
      expect(container.read(lockedProvider), isFalse);
    });
  });

  group('erase everything', () {
    testWidgets('asks twice, purges once, and lands back in onboarding', (
      tester,
    ) async {
      final db = AppDb.memory();
      addTearDown(db.close);
      await db.seedIfNeeded();
      await db.setMeta('onboarded', 'true');
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 't1',
              amountPaise: 124000,
              direction: 'expense',
              occurredAt: 1759820400000,
              createdAt: 1759820400000,
              updatedAt: 1759820400000,
              source: 'manual',
              dedupeHash: 'h1',
            ),
          );

      await pumpAt(
        tester,
        '/settings',
        extra: <Override>[
          appDbProvider.overrideWithValue(db),
          // The real boot, so the screen the erase lands on is decided by the
          // database afterwards rather than by this test's stub.
          bootProvider.overrideWith(
            (ref) async => BootState(
              onboarded: await db.onboarded,
              demoMode: false,
              locale: 'en',
              appLock: (await db.meta(kAppLockMetaKey)) == 'true',
            ),
          ),
        ],
      );

      Future<void> openDialog() async {
        await tester.ensureVisible(find.text(_s['deleteAllData']));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s['deleteAllData']));
        await tester.pumpAndSettle();
      }

      Future<void> tapDialog(String label) async {
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
      }

      // First run: the user backs out.
      await openDialog();
      expect(find.text(_s['eraseTitle']), findsOneWidget);
      await tapDialog(_s['keep']);
      expect(await db.select(db.transactions).get(), hasLength(1));

      // Second run: both yeses.
      await openDialog();
      await tapDialog(_s['erase']);
      expect(find.text(_s['lastChance']), findsOneWidget);
      // Nothing is gone yet — the second dialog is the point.
      expect(await db.select(db.transactions).get(), hasLength(1));

      await tapDialog(_s['yesErase']);
      expect(await db.select(db.transactions).get(), isEmpty);
      expect(await db.meta('onboarded'), 'false');
      // Back to the language picker, which is where a fresh install starts.
      expect(find.text(_s['languagePrompt']), findsOneWidget);
      expect(find.text(_s['deleteAllData']), findsNothing);
    });
  });
}
