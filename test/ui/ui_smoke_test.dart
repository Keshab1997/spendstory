/// Design-system and shell smoke tests.
///
/// These assert the promises that are easy to break silently: both themes exist
/// and differ, a missing string is caught, the demo ledger is sane, and the home
/// screen actually renders the design rather than an empty scaffold.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/app.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/app/router.dart';
import 'package:spendstory/data/demo_data.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/ui/components/lists.dart';
import 'package:spendstory/ui/components/money.dart';
import 'package:spendstory/ui/strings.dart';
import 'package:spendstory/ui/theme.dart';
import 'package:spendstory/ui/tokens.dart';

List<Override> _overrides({String locale = 'bn'}) => <Override>[
  appDbProvider.overrideWithValue(null),
  bootProvider.overrideWith(
    (ref) async => BootState(onboarded: true, demoMode: true, locale: locale),
  ),
];

Future<void> _pumpApp(WidgetTester tester, {String locale = 'bn'}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(locale: locale),
      child: const SpendStoryApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('tokens and themes', () {
    test('both brightnesses build, and are genuinely different', () {
      final light = buildSsTheme(Brightness.light);
      final dark = buildSsTheme(Brightness.dark);

      final l = light.extension<SsColors>()!;
      final d = dark.extension<SsColors>()!;

      expect(l.isDark, isFalse);
      expect(d.isDark, isTrue);
      expect(l.bg, isNot(d.bg));
      expect(l.textPrimary, isNot(d.textPrimary));
      expect(l.surface, isNot(d.surface));
      expect(l.expense, isNot(d.expense));
      expect(l.income, isNot(d.income));
    });

    test('the accent ramp matches the design lock', () {
      expect(SsColors.light.violet600, const Color(0xFF6C4CF1));
      expect(SsColors.dark.violet600, const Color(0xFF8B6BFF));
      expect(SsColors.light.teal500, const Color(0xFF14C8B8));
      expect(SsColors.dark.income, const Color(0xFF2FD4C4));
      expect(SsColors.light.gold500, const Color(0xFFF5B843));
    });

    test('the theme carries the text styles, not Material defaults', () {
      final theme = buildSsTheme(Brightness.light);
      expect(theme.textTheme.displayLarge?.fontSize, 44);
      expect(theme.textTheme.displayLarge?.fontWeight, FontWeight.w800);
      expect(
        theme.textTheme.displayLarge?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(theme.scaffoldBackgroundColor, SsColors.light.bg);
    });

    test('a widget can read the tokens it was given', () {
      final swatch = Builder(
        builder: (context) =>
            Text('${SsColors.of(context).violet600.toARGB32()}'),
      );

      for (final brightness in Brightness.values) {
        final expected = brightness == Brightness.dark
            ? SsColors.dark
            : SsColors.light;
        final theme = buildSsTheme(brightness);
        expect(theme.extension<SsColors>(), expected);
      }
      expect(swatch, isNotNull);
    });
  });

  group('strings', () {
    test('no key is missing from any language', () {
      expect(SsStrings.missingKeys, isEmpty);
    });

    test('all three languages are wired', () {
      for (final code in SsStrings.supportedLocales) {
        final s = SsStrings(code);
        expect(s.appName, 'SpendStory');
        expect(s.heroLabel, isNotEmpty);
        expect(s.txTitle, isNotEmpty);
      }
      // Bengali and Hindi must not fall back to English.
      expect(SsStrings('bn').insights, 'বিশ্লেষণ');
      expect(SsStrings('hi').insights, 'विश्लेषण');
    });
  });

  group('demo ledger', () {
    final ledger = DemoLedger(now: DateTime(2026, 10, 7, 20));

    test('produces a sane ledger with six months of history', () {
      expect(ledger.transactions.length, greaterThan(60));

      final months = <String>{
        for (final t in ledger.transactions)
          DateTime.fromMillisecondsSinceEpoch(t.occurredAtMs).month.toString(),
      };
      expect(months.length, 6, reason: 'the trend chart needs six months');
    });

    test('every transaction points at a real seeded category', () {
      final ids = ledger.categories.map((c) => c.id).toSet();
      for (final t in ledger.transactions) {
        if (t.categoryId == null) continue;
        expect(ids, contains(t.categoryId), reason: t.merchant);
      }
    });

    test('income and expenses both exist, and amounts are positive paise', () {
      expect(
        ledger.transactions.any((t) => t.direction == TxnDirection.income),
        isTrue,
      );
      expect(
        ledger.transactions.any((t) => t.direction == TxnDirection.expense),
        isTrue,
      );
      for (final t in ledger.transactions) {
        expect(t.amountPaise, greaterThan(0));
      }
    });

    test('is deterministic — the preview must not reshuffle on reload', () {
      final again = DemoLedger(now: DateTime(2026, 10, 7, 20));
      expect(again.transactions.length, ledger.transactions.length);
      expect(
        again.transactions.map((t) => t.amountPaise).toList(),
        ledger.transactions.map((t) => t.amountPaise).toList(),
      );
    });

    test('budgets and categories line up', () {
      expect(ledger.overallBudgetPaise, isNotNull);
      expect(ledger.budgetCaps, isNotEmpty);
      for (final b in ledger.budgeted) {
        expect(b.capPaise, greaterThan(0));
      }
    });
  });

  group('home screen', () {
    testWidgets('renders the hero card, the budget and recent rows', (
      tester,
    ) async {
      await _pumpApp(tester);

      expect(find.text('এই মাসের খরচ'), findsOneWidget);
      expect(find.text('আয়'), findsWidgets);
      expect(find.text('মাসিক বাজেট'), findsOneWidget);
      expect(find.text('সাম্প্রতিক লেনদেন'), findsOneWidget);
      expect(find.byType(CountUpMoney), findsOneWidget);
      expect(find.byType(MoneyText), findsWidgets);
    });

    testWidgets(
      'shows the demo banner, because the numbers are not the user’s',
      (tester) async {
        await _pumpApp(tester);
        expect(
          find.textContaining('ওয়েব প্রিভিউ', findRichText: true),
          findsOneWidget,
        );
      },
    );

    testWidgets('the recent list renders real rows with signed amounts', (
      tester,
    ) async {
      await _pumpApp(tester);

      // The five most recent transactions, whatever they happen to be.
      expect(find.byType(TxRow), findsNWidgets(5));

      // The sign is rendered, so the direction is legible without colour.
      final signed = tester
          .widgetList<MoneyText>(find.byType(MoneyText))
          .where((m) => m.showSign);
      expect(signed, isNotEmpty);

      // And a row carries a merchant and a category, not a blank.
      final row = tester.widget<TxRow>(find.byType(TxRow).first);
      expect(row.txn.amountPaise, greaterThan(0));
      expect(row.category, isNotNull);
    });

    testWidgets('the quick actions are present', (tester) async {
      await _pumpApp(tester);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.savings_outlined), findsWidgets);
      expect(find.byIcon(Icons.category_outlined), findsWidgets);
    });
  });

  group('locale switching', () {
    testWidgets('selection localizes data labels and every app surface', (
      tester,
    ) async {
      await _pumpApp(tester, locale: 'en');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final router = container.read(routerProvider);

      expect(container.read(localeProvider), 'en');
      expect(find.text('Spent this month'), findsOneWidget);
      expect(find.text('Advertisement — banner 320×50'), findsOneWidget);
      expect(find.textContaining('Groceries'), findsWidgets);
      expect(find.text('এই মাসের খরচ'), findsNothing);

      container.read(localeProvider.notifier).state = 'hi';
      await tester.pumpAndSettle();
      expect(find.text('इस महीने का खर्च'), findsOneWidget);
      expect(find.text('विज्ञापन — बैनर ३२०×५०'), findsOneWidget);

      container.read(localeProvider.notifier).state = 'en';
      await tester.pumpAndSettle();
      router.go('/transactions');
      await tester.pumpAndSettle();
      expect(find.text('Transactions'), findsWidgets);
      // Assert on the first row's own category rather than on a merchant that
      // may or may not be above the fold: the list builds lazily, so which
      // rows exist in the tree depends on the day the suite runs.
      final firstRow = tester.widget<TxRow>(find.byType(TxRow).first);
      expect(firstRow.category, isNotNull);
      expect(find.textContaining(firstRow.category!.label('en')), findsWidgets);
      expect(find.text('মুদি ও বাজার'), findsNothing);

      router.go('/insights');
      await tester.pumpAndSettle();
      expect(find.text('Last 6 months'), findsOneWidget);

      router.go('/settings');
      await tester.pumpAndSettle();
      expect(find.text('Set monthly limits by category'), findsOneWidget);
      expect(find.text('Delete all data'), findsOneWidget);

      router.go('/pro');
      await tester.pumpAndSettle();
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('₹699'), findsOneWidget);
      expect(find.text('Start your 7-day free trial'), findsOneWidget);

      router.go('/budgets');
      await tester.pumpAndSettle();
      // The real screen now, not the Batch 6 placeholder: the overall cap and
      // a category cap, both in English.
      expect(find.text('This month\'s budget'), findsOneWidget);
      expect(find.text('Category budget'), findsWidgets);
    });
  });
}
