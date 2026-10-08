/// The rewarded offers (T-606, `docs/08 §5`).
///
/// The trade this feature makes is real — thirty seconds of somebody's
/// attention, bought with something real — so the tests are about the four
/// things that keep it a trade rather than a trick: it is opt-in, only the
/// SDK's word grants, the caps are caps, and nobody who already pays is ever
/// asked to watch an ad.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/ads/ad_client.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/data/db.dart';
import 'package:spendstory/pro/entitlement.dart';
import 'package:spendstory/pro/product_ids.dart';
import 'package:spendstory/pro/rewards.dart';

import 'fake_ad_client.dart';

final _now = DateTime(2026, 10, 8, 21, 15);

Future<ProviderContainer> _container({
  required FakeAdClient client,
  AppDb? db,
  DateTime? now,

  /// A clock a test can move forward, for the "left open across midnight" case.
  /// `nowProvider` is a plain provider, so the test also has to
  /// `container.invalidate(nowProvider)` to make it re-read.
  DateTime Function()? clock,
  bool isPro = false,
  bool onboarded = true,
}) async {
  final container = ProviderContainer(
    overrides: <Override>[
      adClientProvider.overrideWithValue(client),
      appDbProvider.overrideWithValue(db),
      if (clock != null)
        nowProvider.overrideWith((ref) => clock())
      else
        nowProvider.overrideWithValue(now ?? _now),
      bootProvider.overrideWith(
        (ref) async =>
            BootState(onboarded: onboarded, demoMode: db == null, locale: 'en'),
      ),
      if (isPro)
        proEntitlementProvider.overrideWith(
          (ref) => ProEntitlement(
            plan: ProPlan.monthly,
            confirmedAtMs: _now.millisecondsSinceEpoch,
          ),
        ),
    ],
  );
  addTearDown(container.dispose);
  // Every offer rule reads `adsVisibleProvider`, which is false until boot has
  // answered — so a test that wants to see an offer has to be past the splash.
  await container.read(bootProvider.future);
  return container;
}

void main() {
  group('the rules', () {
    const rules = RewardRules();

    test('the caps are the ones docs/08 §5 writes down', () {
      expect(rules.capOf(RewardKind.proTaste), 1);
      expect(rules.capOf(RewardKind.pdfExport), 2);
      expect(rules.tasteDuration, const Duration(hours: 24));
      // …and the taste plan's own window is the same number: one definition of
      // "24 hours" in the app, not two that can drift.
      expect(entitlementWindow(ProPlan.taste), rules.tasteDuration);
    });

    test('an offer is never made to somebody who already pays', () {
      for (final kind in RewardKind.values) {
        expect(
          rules.offers(
            kind,
            isPro: true,
            adsVisible: true,
            hasUnit: true,
            grantedToday: 0,
          ),
          isFalse,
          reason: '$kind',
        );
      }
    });

    test('an offer is not made where nothing could be shown', () {
      for (final kind in RewardKind.values) {
        expect(
          rules.offers(
            kind,
            isPro: false,
            adsVisible: false,
            hasUnit: true,
            grantedToday: 0,
          ),
          isFalse,
        );
        expect(
          rules.offers(
            kind,
            isPro: false,
            adsVisible: true,
            hasUnit: false,
            grantedToday: 0,
          ),
          isFalse,
          reason: 'a build with no rewarded unit must not promise a reward',
        );
      }
    });

    test('the cap is on grants: the offer runs out, not the ad', () {
      expect(
        rules.offers(
          RewardKind.proTaste,
          isPro: false,
          adsVisible: true,
          hasUnit: true,
          grantedToday: 1,
        ),
        isFalse,
      );
      expect(
        rules.offers(
          RewardKind.pdfExport,
          isPro: false,
          adsVisible: true,
          hasUnit: true,
          grantedToday: 1,
        ),
        isTrue,
        reason: 'the second export of the day is still owed',
      );
      expect(
        rules.offers(
          RewardKind.pdfExport,
          isPro: false,
          adsVisible: true,
          hasUnit: true,
          grantedToday: 2,
        ),
        isFalse,
      );
    });
  });

  group('watching one', () {
    test(
      'grants 24 hours of Pro when the SDK says the reward was earned',
      () async {
        final client = FakeAdClient();
        final container = await _container(client: client);
        await container.read(rewardLedgerProvider).start();

        final outcome = await container
            .read(rewardLedgerProvider)
            .watch(RewardKind.proTaste);

        expect(outcome, RewardedOutcome.earned);
        expect(client.rewardedCalls, 1);
        expect(container.read(proStatusProvider), isTrue);

        final entitlement = container.read(proEntitlementProvider)!;
        expect(entitlement.plan, ProPlan.taste);
        expect(entitlement.source, ProSource.taste);
        expect(entitlement.confirmedAtMs, _now.millisecondsSinceEpoch);
        // Exactly a day, to the millisecond — the promise was "24 hours".
        expect(
          entitlement.expiresAtMs,
          _now.millisecondsSinceEpoch +
              const Duration(hours: 24).inMilliseconds,
        );
        expect(
          container.read(rewardGrantedTodayProvider)[RewardKind.proTaste],
          1,
        );
      },
    );

    test('grants nothing when the ad was closed early', () async {
      final client = FakeAdClient(rewardOutcome: RewardedOutcome.dismissed);
      final container = await _container(client: client);
      await container.read(rewardLedgerProvider).start();

      final outcome = await container
          .read(rewardLedgerProvider)
          .watch(RewardKind.proTaste);

      expect(outcome, RewardedOutcome.dismissed);
      expect(container.read(proStatusProvider), isFalse);
      expect(container.read(proEntitlementProvider), isNull);
      // And it did not cost the user their day's one either: nothing was
      // granted, so nothing is spent.
      expect(
        container.read(rewardLedgerProvider).canOffer(RewardKind.proTaste),
        isTrue,
      );
    });

    test('grants nothing when no ad arrived at all', () async {
      final client = FakeAdClient(rewardOutcome: RewardedOutcome.unavailable);
      final container = await _container(client: client);
      await container.read(rewardLedgerProvider).start();

      expect(
        await container.read(rewardLedgerProvider).watch(RewardKind.proTaste),
        RewardedOutcome.unavailable,
      );
      expect(container.read(proStatusProvider), isFalse);
      expect(
        container.read(rewardLedgerProvider).canOffer(RewardKind.proTaste),
        isTrue,
      );
    });

    test('is offered once a day, and then says so', () async {
      final client = FakeAdClient();
      final container = await _container(client: client);
      final ledger = container.read(rewardLedgerProvider);
      await ledger.start();

      await ledger.watch(RewardKind.proTaste);

      // The taste is running, so the offer is gone for a better reason: this
      // user is Pro right now (`docs/08 §5` — never an ad to a paying user).
      expect(ledger.canOffer(RewardKind.proTaste), isFalse);

      // A second tap cannot even reach the store.
      expect(
        await ledger.watch(RewardKind.proTaste),
        RewardedOutcome.unavailable,
      );
      expect(client.rewardedCalls, 1);
    });

    test('the counter is per day, and it is written down', () async {
      final db = AppDb.memory();
      addTearDown(db.close);

      final first = await _container(client: FakeAdClient(), db: db);
      final ledger = first.read(rewardLedgerProvider);
      await ledger.start();
      await ledger.watch(RewardKind.pdfExport);
      expect(await db.meta('reward:pdfExport:2026-10-08'), '1');

      // Tomorrow: the same install, a new day, a fresh allowance.
      final tomorrow = await _container(
        client: FakeAdClient(),
        db: db,
        now: _now.add(const Duration(days: 1)),
      );
      final next = tomorrow.read(rewardLedgerProvider);
      await next.start();

      expect(next.grantedToday(RewardKind.pdfExport), 0);
      expect(next.canOffer(RewardKind.pdfExport), isTrue);
    });

    test('a ledger left open across midnight does not carry yesterday over', () async {
      var clock = _now;
      final container = await _container(
        client: FakeAdClient(),
        clock: () => clock,
      );
      final ledger = container.read(rewardLedgerProvider);
      await ledger.start();
      await ledger.watch(RewardKind.proTaste);
      expect(ledger.grantedToday(RewardKind.proTaste), 1);

      // Tomorrow morning, with the app never closed: the date has moved on, so
      // yesterday's grant is not today's.
      clock = _now.add(const Duration(days: 1));
      container.invalidate(nowProvider);

      // The ledger learns the date has changed when something asks it a
      // question that depends on the date — which every offer button does on
      // every build — so this call is the roll, and the getter below reads the
      // counters that are now today's.
      expect(ledger.canOffer(RewardKind.proTaste), isTrue);
      expect(ledger.grantedToday(RewardKind.proTaste), 0);
    });

    test('a Pro user cannot be handed one', () async {
      final client = FakeAdClient();
      final container = await _container(client: client, isPro: true);
      final ledger = container.read(rewardLedgerProvider);
      await ledger.start();

      expect(ledger.canOffer(RewardKind.proTaste), isFalse);
      expect(
        await ledger.watch(RewardKind.proTaste),
        RewardedOutcome.unavailable,
      );
      expect(client.rewardedCalls, 0);
    });

    test('the request carries the consent flag, not a preference', () async {
      final client = FakeAdClient();
      final container = await _container(client: client);
      await container.read(rewardLedgerProvider).start();

      container.read(nonPersonalizedAdsProvider.notifier).state = true;
      await container.read(rewardLedgerProvider).watch(RewardKind.proTaste);

      expect(client.rewardedConsent, <bool>[true]);
    });
  });

  group('the free PDF export', () {
    test('is a credit the export screen can spend', () async {
      final container = await _container(client: FakeAdClient());
      final ledger = container.read(rewardLedgerProvider);
      await ledger.start();

      expect(container.read(pdfExportCreditsProvider), 0);
      expect(await ledger.spendPdfCredit(), isFalse);

      await ledger.watch(RewardKind.pdfExport);
      expect(container.read(pdfExportCreditsProvider), 1);
      expect(await ledger.spendPdfCredit(), isTrue);
      expect(container.read(pdfExportCreditsProvider), 0);

      // A credit is spent once.
      expect(await ledger.spendPdfCredit(), isFalse);
    });

    test('is granted twice a day, and spending does not refill it', () async {
      final db = AppDb.memory();
      addTearDown(db.close);

      final container = await _container(client: FakeAdClient(), db: db);
      final ledger = container.read(rewardLedgerProvider);
      await ledger.start();

      expect(ledger.canOffer(RewardKind.pdfExport), isTrue);
      await ledger.watch(RewardKind.pdfExport);
      expect(ledger.canOffer(RewardKind.pdfExport), isTrue);
      await ledger.watch(RewardKind.pdfExport);

      // Both spent, and the offer is over for today.
      expect(await ledger.spendPdfCredit(), isTrue);
      expect(await ledger.spendPdfCredit(), isTrue);
      expect(ledger.pdfCreditsToday, 0);
      expect(
        ledger.canOffer(RewardKind.pdfExport),
        isFalse,
        reason: 'the cap counts grants, so spending cannot buy a third ad',
      );
      expect(await db.meta('reward:pdfExport:2026-10-08'), '2');
      expect(await db.meta('reward:pdfExport:2026-10-08:spent'), '2');
    });
  });

  group('the seam', () {
    test(
      'a build with no rewarded unit offers nothing, and asks for nothing',
      () async {
        final client = FakeAdClient(rewarded: null);
        final container = await _container(client: client);
        final ledger = container.read(rewardLedgerProvider);
        await ledger.start();

        expect(ledger.canOffer(RewardKind.proTaste), isFalse);
        expect(
          await ledger.watch(RewardKind.proTaste),
          RewardedOutcome.unavailable,
        );
        expect(client.rewardedCalls, 0);
      },
    );

    test('nobody is offered an ad before onboarding is done', () async {
      final container = await _container(
        client: FakeAdClient(),
        onboarded: false,
      );
      final ledger = container.read(rewardLedgerProvider);
      await ledger.start();

      expect(ledger.canOffer(RewardKind.proTaste), isFalse);
      expect(ledger.canOffer(RewardKind.pdfExport), isFalse);
    });
  });
}
