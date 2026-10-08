/// The opt-in rewarded offer in the app (T-606, `docs/08 §5`).
///
/// `test/ads/ad_rewards_test.dart` holds the arithmetic — the caps, the granting,
/// the day rollover. This file holds the part a user sees, on the one screen that
/// carries the offer: a labelled button that says exactly what it is, a reward
/// that is granted by the store's answer rather than by the tap, a sentence
/// instead of a button once the day's one is spent, and no offer at all to
/// somebody who already pays.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/ads/ad_client.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/domain/view_models.dart';
import 'package:spendstory/pro/entitlement.dart';
import 'package:spendstory/pro/product_ids.dart';
import 'package:spendstory/pro/rewards.dart';
import 'package:spendstory/ui/screens/insights_screen.dart';
import 'package:spendstory/ui/theme.dart';

import '../ads/fake_ad_client.dart';

final _now = DateTime(2026, 10, 8, 21, 15);

final _ledger = <TxnView>[
  TxnView(
    id: 't1',
    amountPaise: 120000,
    direction: TxnDirection.expense,
    occurredAtMs: _now.millisecondsSinceEpoch,
    merchant: 'BigBasket',
    categoryId: 'grocery',
  ),
];

const _categories = <CategoryView>[
  CategoryView(
    id: 'grocery',
    kind: TxnDirection.expense,
    nameEn: 'Grocery',
    nameHi: 'किराना',
    nameBn: 'বাজার',
    icon: '🛒',
    colorHex: '#14C8B8',
  ),
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required FakeAdClient client,
  bool isPro = false,
  String locale = 'en',
  Future<void> Function(ProviderContainer container)? before,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: <Override>[
      appDbProvider.overrideWithValue(null),
      bootProvider.overrideWith(
        (ref) async =>
            BootState(onboarded: true, demoMode: true, locale: locale),
      ),
      localeProvider.overrideWith((ref) => locale),
      nowProvider.overrideWithValue(_now),
      proStatusProvider.overrideWith((ref) => isPro),
      categoriesProvider.overrideWith((ref) async => _categories),
      transactionsProvider.overrideWith((ref) async => _ledger),
      adClientProvider.overrideWithValue(client),
    ],
  );
  addTearDown(container.dispose);

  // Boot first: `adsVisibleProvider` is false until it has answered, and every
  // offer rule reads it.
  await container.read(bootProvider.future);
  await container.read(rewardLedgerProvider).start();
  if (before != null) await before(container);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildSsTheme(Brightness.light),
        home: const InsightsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapOffer(WidgetTester tester) async {
  final offer = find.text('Watch an ad for 24 hours of Pro');
  await tester.ensureVisible(offer);
  await tester.pumpAndSettle();
  await tester.tap(offer);
  await tester.pumpAndSettle();
}

void main() {
  group('the offer', () {
    testWidgets('says what it is, next to the offer to pay', (tester) async {
      await _pump(tester, client: FakeAdClient());

      expect(find.text('Watch an ad for 24 hours of Pro'), findsOneWidget);
      // The paid route is still there, and still the gold one: the ad is the
      // alternative, never the only door.
      expect(find.text('See Pro'), findsOneWidget);
    });

    testWidgets('is not offered in a build that has no rewarded unit', (
      tester,
    ) async {
      await _pump(tester, client: FakeAdClient(rewarded: null));

      expect(find.text('Watch an ad for 24 hours of Pro'), findsNothing);
      expect(find.text('See Pro'), findsOneWidget);
    });

    testWidgets('is not offered to somebody who pays', (tester) async {
      await _pump(tester, client: FakeAdClient(), isPro: true);

      // A Pro user does not see the Pro card at all — that is the thing they
      // paid for (`docs/08 §5`).
      expect(find.text('Watch an ad for 24 hours of Pro'), findsNothing);
      expect(find.text('See Pro'), findsNothing);
    });

    testWidgets('reads in Bengali, and fits on a 360dp phone', (tester) async {
      await _pump(tester, client: FakeAdClient(), locale: 'bn');

      final offer = find.text('বিজ্ঞাপন দেখে ২৪ ঘণ্টার Pro নিন');
      await tester.ensureVisible(offer);
      await tester.pumpAndSettle();
      expect(offer, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('watching one', () {
    testWidgets('grants a 24-hour entitlement, and says so', (tester) async {
      final client = FakeAdClient();
      final container = await _pump(tester, client: client);

      await _tapOffer(tester);

      expect(client.rewardedCalls, 1);
      final entitlement = container.read(proEntitlementProvider)!;
      expect(entitlement.plan, ProPlan.taste);
      expect(entitlement.source, ProSource.taste);
      expect(
        entitlement.expiresAtMs! - entitlement.confirmedAtMs,
        const Duration(hours: 24).inMilliseconds,
      );
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Pro is on for 24 hours. Enjoy it.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('grants nothing when the ad was closed early', (tester) async {
      final client = FakeAdClient(rewardOutcome: RewardedOutcome.dismissed);
      final container = await _pump(tester, client: client);

      await _tapOffer(tester);

      expect(container.read(proEntitlementProvider), isNull);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('nothing was granted'),
        ),
        findsOneWidget,
      );
      // …and the offer is still there, because nothing was spent.
      expect(find.text('Watch an ad for 24 hours of Pro'), findsOneWidget);
    });

    testWidgets('an ad that never arrives leaves the user where they were', (
      tester,
    ) async {
      final client = FakeAdClient(rewardOutcome: RewardedOutcome.unavailable);
      final container = await _pump(tester, client: client);

      await _tapOffer(tester);

      expect(container.read(proEntitlementProvider), isNull);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('No ad is available'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('once the day’s one is spent, the button becomes a sentence', (
      tester,
    ) async {
      await _pump(
        tester,
        client: FakeAdClient(),
        // Today's taste, already watched — the state a second visit finds the
        // screen in.
        before: (container) async {
          await container.read(rewardLedgerProvider).watch(RewardKind.proTaste);
        },
      );

      expect(find.text('Watch an ad for 24 hours of Pro'), findsNothing);
      expect(
        find.text('You have used today’s 24-hour Pro. It comes back tomorrow.'),
        findsOneWidget,
      );
      // The paid route is untouched: the reward running out is not the app
      // giving up on selling Pro.
      expect(find.text('See Pro'), findsOneWidget);
    });
  });
}
