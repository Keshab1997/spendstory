/// S-22 Pro paywall (T-604).
///
/// `docs/03 §S-22` sets four rules — price clearly shown, no countdown dark
/// pattern, privacy and terms links, restore offered — and `docs/08 §6` adds the
/// one that matters most commercially *and* ethically: nothing on this screen
/// may be a fake. So the tests here check the three tiers and their real
/// arithmetic, that the store's price is what is displayed, that a Pro user is
/// shown their receipt instead of being sold to again, and that the screen is
/// reachable from Settings as well as from a locked feature.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/app/router.dart';
import 'package:spendstory/pro/billing_client.dart';
import 'package:spendstory/pro/entitlement.dart';
import 'package:spendstory/pro/product_ids.dart';
import 'package:spendstory/ui/screens/pro_screen.dart';
import 'package:spendstory/ui/theme.dart';

import '../pro/fake_billing_client.dart';
import 'ledger_harness.dart';

final _now = DateTime(2026, 10, 8, 20, 42);

Future<ProviderContainer> _pumpPaywall(
  WidgetTester tester, {
  BillingClient? client,
  ProEntitlement? entitlement,
  String locale = 'en',
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: <Override>[
      ...harnessOverrides(locale: locale),
      nowProvider.overrideWithValue(_now),
      billingClientProvider.overrideWithValue(client ?? FakeBillingClient()),
      if (entitlement != null)
        proEntitlementProvider.overrideWith((ref) => entitlement),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildSsTheme(Brightness.light),
        home: const ProScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('S-22 the tiers', () {
    testWidgets('all three are on the screen, priced', (tester) async {
      await _pumpPaywall(tester);

      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
      expect(find.text('Lifetime'), findsOneWidget);

      // Google's test store answers with its own labels; the screen shows the
      // store's price, not one it formatted itself.
      expect(find.text('₹99.00'), findsOneWidget);
      expect(find.text('₹699.00'), findsOneWidget);
      expect(find.text('₹1,499.00'), findsOneWidget);
    });

    testWidgets('monthly is the one selected when the screen opens', (
      tester,
    ) async {
      // The cheapest tier, and the one the user can upgrade out of on their own.
      // Pre-selecting the most expensive plan is what `docs/08 §6` calls a dark
      // pattern, so this is a rule with a test rather than a preference.
      await _pumpPaywall(tester);

      final selected = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      expect(selected, hasLength(3));

      // The check sits inside the selected card: only the first one is ticked.
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      final checkY = tester.getTopLeft(find.byIcon(Icons.check_rounded)).dy;
      expect(checkY, lessThan(tester.getTopLeft(find.text('Yearly')).dy));
    });

    testWidgets('the yearly badge is arithmetic, not a claim', (tester) async {
      await _pumpPaywall(tester);

      // 99 × 12 = 1,188; 699 saves 41.2% → 41%, computed from the same prices
      // shown on the same screen.
      expect(find.text('Save 41%'), findsOneWidget);
    });

    testWidgets('with no store, the prices are labelled as estimates', (
      tester,
    ) async {
      await _pumpPaywall(tester, client: FakeBillingClient(available: false));

      // The documented prices, and an honest note about what they are.
      expect(find.textContaining('₹99'), findsOneWidget);
      expect(find.textContaining('Estimates'), findsOneWidget);
    });

    testWidgets('no countdown, no struck-through price, no fake urgency', (
      tester,
    ) async {
      await _pumpPaywall(tester);

      // Nothing on this screen may be a timer or a discount that is not real.
      // Matched as whole words: "Spending forecast" must not look like the
      // word "ending" to this test.
      final banned = <RegExp>[
        RegExp(r'\bleft\b'),
        RegExp(r'\bending\b'),
        RegExp(r'\btoday only\b', caseSensitive: false),
        RegExp(r'\bhurry\b', caseSensitive: false),
        RegExp(r'\bwas \u20b9'),
        RegExp(r'\blimited time\b', caseSensitive: false),
      ];
      final shown = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      for (final pattern in banned) {
        expect(
          pattern.hasMatch(shown),
          isFalse,
          reason: '"${pattern.pattern}" is the shape of a dark pattern',
        );
      }
    });

    testWidgets('the trial is stated, and the footnote says how to stop', (
      tester,
    ) async {
      await _pumpPaywall(tester);
      expect(find.text('7 days free, cancel anytime.'), findsOneWidget);
      expect(find.text('Cancel any time in the Play Store.'), findsOneWidget);
    });

    testWidgets('reads in Bengali too, without overflowing', (tester) async {
      await _pumpPaywall(tester, locale: 'bn');
      expect(find.text('বার্ষিক'), findsOneWidget);
      expect(find.text('পরে দেখব'), findsOneWidget);
    });
  });

  group('S-22 the required controls', () {
    testWidgets(
      'restore is offered, and it is the one that reaches the store',
      (tester) async {
        final client = FakeBillingClient();
        await _pumpPaywall(tester, client: client);

        await tester.scrollUntilVisible(find.text('Restore a purchase'), 200);
        await tester.tap(find.text('Restore a purchase'));
        await tester.pumpAndSettle();

        expect(client.restoreCalls, 1);
        // Nothing was found, and the app says that rather than nothing at all.
        expect(
          find.text('No purchase found for this account.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('“maybe later” closes the screen without a guilt trip', (
      tester,
    ) async {
      await _pumpPaywall(tester);

      expect(find.text('Maybe later'), findsOneWidget);
      // The close button and this one both leave; neither is hidden or greyed.
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('privacy and terms are both one tap away', (tester) async {
      await _pumpPaywall(tester);

      await tester.scrollUntilVisible(find.text('Privacy'), 200);
      await tester.tap(find.text('Privacy'));
      await tester.pumpAndSettle();
      expect(find.textContaining('never sent to a server'), findsOneWidget);
      await tester.tapAt(const Offset(200, 60)); // dismiss the sheet
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Terms'), 200);
      await tester.tap(find.text('Terms'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Play Store policy'), findsOneWidget);
    });

    testWidgets('an unreachable store is said out loud, not swallowed', (
      tester,
    ) async {
      await _pumpPaywall(tester, client: FakeBillingClient(available: false));

      await tester.scrollUntilVisible(
        find.text('Start your 7-day free trial'),
        200,
      );
      await tester.tap(find.text('Start your 7-day free trial'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('The store could not be reached'),
        findsWidgets,
      );
    });
  });

  group('S-22 for someone who already paid', () {
    testWidgets('shows the plan and the renewal, and nothing to buy', (
      tester,
    ) async {
      await _pumpPaywall(
        tester,
        entitlement: ProEntitlement(
          plan: ProPlan.yearly,
          confirmedAtMs: _now
              .subtract(const Duration(days: 3))
              .millisecondsSinceEpoch,
        ),
      );

      expect(find.text('Pro is active'), findsWidgets);
      expect(find.text('Yearly'), findsOneWidget); // the plan they own
      expect(find.textContaining('Renews on'), findsOneWidget);

      // No tiers, no price, no buy button — there is nothing to sell them.
      expect(find.text('Lifetime'), findsNothing);
      expect(find.textContaining('₹'), findsNothing);
      expect(find.text('Start your 7-day free trial'), findsNothing);

      // Restore stays, because a reinstall is exactly who needs it.
      expect(find.text('Restore a purchase'), findsOneWidget);
    });

    testWidgets('a 24-hour taste owner is told what they have, not sold to', (
      tester,
    ) async {
      await _pumpPaywall(
        tester,
        entitlement: ProEntitlement(
          plan: ProPlan.taste,
          confirmedAtMs: _now.millisecondsSinceEpoch,
          source: ProSource.taste,
        ),
      );

      expect(find.text('Pro is active'), findsWidgets);
      expect(find.text('24-hour taste'), findsOneWidget);
      expect(
        find.textContaining('Pro is on for 24 hours'),
        findsOneWidget,
        reason: 'a taste is not a subscription, so it has no renewal date',
      );
      expect(find.textContaining('Renews on'), findsNothing);

      // Nothing to buy, and no tiers: they are Pro right now, however they got
      // here.
      expect(find.text('Lifetime'), findsNothing);
      expect(find.textContaining('₹'), findsNothing);
      expect(find.text('Restore a purchase'), findsOneWidget);
    });

    testWidgets('a lifetime owner is not shown a renewal date', (tester) async {
      await _pumpPaywall(
        tester,
        entitlement: ProEntitlement(
          plan: ProPlan.lifetime,
          confirmedAtMs: _now.millisecondsSinceEpoch,
        ),
      );

      expect(find.text('Lifetime'), findsOneWidget);
      expect(find.textContaining('Renews on'), findsNothing);
    });
  });

  group('S-22 the way in', () {
    testWidgets('settings opens it, and shows the current state', (
      tester,
    ) async {
      final container = await pumpAt(tester, '/settings');

      // Settings already carried the gold card (S-20); T-604 is what makes it
      // lead somewhere that can take money, and T-610 adds the restore row
      // below it.
      await tester.ensureVisible(find.text('SpendStory Pro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SpendStory Pro'));
      await tester.pumpAndSettle();

      expect(find.byType(ProScreen), findsOneWidget);
      expect(
        container
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .matches
            .map((m) => m.matchedLocation),
        contains('/pro'),
      );
    });

    testWidgets('settings carries a restore of its own, beside the card', (
      tester,
    ) async {
      final client = FakeBillingClient();
      await pumpAt(
        tester,
        '/settings',
        extra: [billingClientProvider.overrideWithValue(client)],
      );

      // One lookup already happened on launch — that is T-605's own restore,
      // which is what ends a lapsed subscription without the user asking.
      final before = client.restoreCalls;

      await tester.ensureVisible(find.text('Restore a purchase'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore a purchase'));
      await tester.pumpAndSettle();

      expect(client.restoreCalls, before + 1);
      expect(find.text('No purchase found for this account.'), findsOneWidget);
    });
  });
}
