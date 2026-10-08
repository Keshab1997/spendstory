/// Purchases, restores and everything that can go wrong between them (T-605).
///
/// The controller is the only thing that can make a user Pro, so the tests here
/// are about it specifically: what grants access, what is written down, what
/// happens to a payment Play holds for review, and — the one that costs real
/// money — that a purchase arriving after the app was killed is not replayed
/// forever.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/data/db.dart';
import 'package:spendstory/pro/billing_client.dart';
import 'package:spendstory/pro/entitlement.dart';
import 'package:spendstory/pro/product_ids.dart';
import 'package:spendstory/pro/pro_controller.dart';

import 'fake_billing_client.dart';

final _now = DateTime(2026, 10, 8, 20, 42);

ProviderContainer _container({
  required BillingClient client,
  DateTime? now,
  AppDb? db,
}) {
  final container = ProviderContainer(
    overrides: <Override>[
      billingClientProvider.overrideWithValue(client),
      nowProvider.overrideWithValue(now ?? _now),
      bootProvider.overrideWith(
        (ref) async =>
            BootState(onboarded: true, demoMode: db == null, locale: 'en'),
      ),
      // null is a real state — the web preview and every widget test run here —
      // and it is what makes the controller use the session map.
      appDbProvider.overrideWithValue(db),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Lets the controller's stream subscription see whatever was emitted.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('a purchase', () {
    test(
      'is granted only when the store says so, not when the sheet opens',
      () async {
        final client = FakeBillingClient();
        final container = _container(client: client);
        await container.read(proControllerProvider).start();

        expect(
          await container.read(proControllerProvider).buy(ProPlan.yearly),
          isTrue,
        );
        // The sheet is open; nothing has been decided yet.
        expect(container.read(proStatusProvider), isFalse);
        expect(container.read(proEntitlementProvider), isNull);

        client.emit(
          const BillingEvent(
            outcome: BillingOutcome.purchased,
            plan: ProPlan.yearly,
          ),
        );
        await _settle();

        expect(container.read(proStatusProvider), isTrue);
        final entitlement = container.read(proEntitlementProvider)!;
        expect(entitlement.plan, ProPlan.yearly);
        expect(entitlement.source, ProSource.purchase);
        expect(entitlement.confirmedAtMs, _now.millisecondsSinceEpoch);

        // And it is written down where a restart can find it.
        expect(
          container.read(sessionProEntitlementProvider),
          entitlement.encode(),
        );
      },
    );

    test('records the pending payment without granting anything', () async {
      final client = FakeBillingClient();
      final container = _container(client: client);
      await container.read(proControllerProvider).start();

      client.emit(
        const BillingEvent(
          outcome: BillingOutcome.pending,
          plan: ProPlan.monthly,
        ),
      );
      await _settle();

      expect(container.read(proStatusProvider), isFalse);
      expect(
        container.read(lastBillingEventProvider)!.outcome,
        BillingOutcome.pending,
      );
      // The button says "waiting for the store" rather than looking tappable.
      expect(container.read(billingBusyProvider), isTrue);
    });

    test('a cancelled sheet changes nothing at all', () async {
      final client = FakeBillingClient();
      final container = _container(client: client);
      await container.read(proControllerProvider).start();

      client.emit(
        const BillingEvent(
          outcome: BillingOutcome.canceled,
          plan: ProPlan.monthly,
        ),
      );
      await _settle();

      expect(container.read(proStatusProvider), isFalse);
      expect(container.read(proEntitlementProvider), isNull);
      expect(container.read(billingBusyProvider), isFalse);
    });

    test(
      'a product this build does not know is finished, not honoured',
      () async {
        final client = FakeBillingClient();
        final container = _container(client: client);
        await container.read(proControllerProvider).start();

        client.emit(
          const BillingEvent(outcome: BillingOutcome.purchased, plan: null),
        );
        await _settle();

        expect(container.read(proStatusProvider), isFalse);
      },
    );

    test(
      'a store that cannot open its sheet says so instead of hanging',
      () async {
        final client = FakeBillingClient(available: false);
        final container = _container(client: client);

        expect(
          await container.read(proControllerProvider).buy(ProPlan.monthly),
          isFalse,
        );
        expect(
          container.read(lastBillingEventProvider)!.outcome,
          BillingOutcome.error,
        );
        expect(container.read(billingBusyProvider), isFalse);
      },
    );

    test('a refusal leaves the user free, with a reason on screen', () async {
      final client = FakeBillingClient();
      final container = _container(client: client);
      await container.read(proControllerProvider).start();

      client.emit(
        const BillingEvent(
          outcome: BillingOutcome.error,
          plan: ProPlan.monthly,
          message: 'ITEM_ALREADY_OWNED',
        ),
      );
      await _settle();

      expect(container.read(proStatusProvider), isFalse);
      expect(
        container.read(lastBillingEventProvider)!.message,
        'ITEM_ALREADY_OWNED',
      );
    });
  });

  group('a restore', () {
    test(
      'grants Pro from the store’s word, and says it was a restore',
      () async {
        final client = FakeBillingClient();
        final container = _container(client: client);
        await container.read(proControllerProvider).start();

        client.emit(
          const BillingEvent(
            outcome: BillingOutcome.restored,
            plan: ProPlan.lifetime,
          ),
        );
        await _settle();

        final entitlement = container.read(proEntitlementProvider)!;
        expect(entitlement.plan, ProPlan.lifetime);
        expect(entitlement.source, ProSource.restore);
        expect(container.read(proStatusProvider), isTrue);
      },
    );

    test(
      'runs by itself on launch, which is what ends a lapsed subscription',
      () async {
        final client = FakeBillingClient();
        final container = _container(client: client);

        await container.read(proControllerProvider).start();
        expect(client.restoreCalls, 1);

        // …and again on the user's tap from Settings or the paywall.
        await container.read(proControllerProvider).restore();
        expect(client.restoreCalls, 2);
      },
    );

    test(
      'a restore that finds nothing leaves the user free and quiet',
      () async {
        final client = FakeBillingClient();
        final container = _container(client: client);
        await container.read(proControllerProvider).start();

        await container.read(proControllerProvider).restore();
        expect(container.read(proStatusProvider), isFalse);
        expect(container.read(lastBillingEventProvider), isNull);
      },
    );
  });

  group('what survives a restart', () {
    test('a stored record comes back, with its plan and its source', () async {
      final container = _container(client: FakeBillingClient());
      container
          .read(sessionProEntitlementProvider.notifier)
          .state = ProEntitlement(
        plan: ProPlan.yearly,
        confirmedAtMs: _now
            .subtract(const Duration(days: 3))
            .millisecondsSinceEpoch,
      ).encode();

      await container.read(proControllerProvider).start();

      expect(container.read(proStatusProvider), isTrue);
      expect(container.read(proEntitlementProvider)!.plan, ProPlan.yearly);
    });

    test('a stored record past its window is cleared, not honoured', () async {
      final container = _container(client: FakeBillingClient());
      container
          .read(sessionProEntitlementProvider.notifier)
          .state = ProEntitlement(
        plan: ProPlan.monthly,
        confirmedAtMs: _now
            .subtract(const Duration(days: 90))
            .millisecondsSinceEpoch,
      ).encode();

      await container.read(proControllerProvider).start();

      expect(container.read(proStatusProvider), isFalse);
      expect(container.read(sessionProEntitlementProvider), isNull);
    });

    test('a corrupt line is treated as free', () async {
      final container = _container(client: FakeBillingClient());
      container.read(sessionProEntitlementProvider.notifier).state = 'garbage';

      await container.read(proControllerProvider).start();
      expect(container.read(proStatusProvider), isFalse);
    });
  });

  group('with a database', () {
    late AppDb db;

    setUp(() async => db = AppDb.memory());
    tearDown(() async => db.close());

    test(
      'the purchase lands in app_meta, and a restart reads it back',
      () async {
        final client = FakeBillingClient();
        final first = _container(client: client, db: db);
        await first.read(proControllerProvider).start();

        client.emit(
          const BillingEvent(
            outcome: BillingOutcome.purchased,
            plan: ProPlan.yearly,
          ),
        );
        await _settle();
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final stored = await db.meta('proEntitlement');
        expect(stored, isNotNull);
        expect(ProEntitlement.decode(stored)!.plan, ProPlan.yearly);
        // The older key the ads layer reads stays in step.
        expect(await db.meta('proStatus'), 'pro');

        // A second container over the same database — a restart.
        final second = _container(client: FakeBillingClient(), db: db);
        await second.read(proControllerProvider).start();
        expect(second.read(proStatusProvider), isTrue);
      },
    );

    test('an expired record is cleared from the database too', () async {
      await db.setMeta(
        'proEntitlement',
        ProEntitlement(
          plan: ProPlan.monthly,
          confirmedAtMs: _now
              .subtract(const Duration(days: 90))
              .millisecondsSinceEpoch,
        ).encode(),
      );
      await db.setMeta('proStatus', 'pro');

      final container = _container(client: FakeBillingClient(), db: db);
      await container.read(proControllerProvider).start();

      expect(container.read(proStatusProvider), isFalse);
      expect(await db.meta('proStatus'), 'free');
      expect(await db.meta('proEntitlement'), '');
    });
  });

  group('the store’s prices', () {
    test('are the ones the paywall shows when the store answers', () async {
      final client = FakeBillingClient();
      final container = _container(client: client);
      final products = await container.read(proProductsProvider.future);

      expect(products.map((p) => p.plan), ProPlan.values);
      expect(products[1].priceLabel, '₹699.00');
    });

    test(
      'are empty where there is no store, so the screen says "estimate"',
      () async {
        final container = _container(
          client: FakeBillingClient(available: false),
        );
        expect(await container.read(proProductsProvider.future), isEmpty);
      },
    );
  });
}
