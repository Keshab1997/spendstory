/// S-14 Budgets (T-501).
///
/// What the screen promises, in the order it promises it: the overall cap and
/// its headline, the categories ranked by how much of their cap is gone, the
/// three threshold states, an ad that never appears above the content, and an
/// empty state that offers the way out. Plus the thing that actually breaks
/// here — Bengali and Hindi at a large text scale on a small phone.
///
/// The screen runs against the session overlays (`appDbProvider` is null), the
/// same way the web preview does, so a budget the test saves goes through the
/// real write seam rather than a mock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/domain/view_models.dart';
import 'package:spendstory/ui/components/ad_slot.dart';
import 'package:spendstory/ui/components/lists.dart';
import 'package:spendstory/ui/screens/budget_edit_sheet.dart';
import 'package:spendstory/ui/screens/budgets_screen.dart';
import 'package:spendstory/ui/theme.dart';

final _now = DateTime(2026, 10, 7, 20);
int _ms(DateTime d) => d.millisecondsSinceEpoch;

TxnView _txn({
  required String id,
  required int paise,
  required String categoryId,
  DateTime? at,
}) => TxnView(
  id: id,
  amountPaise: paise,
  direction: TxnDirection.expense,
  occurredAtMs: _ms(at ?? _now),
  merchant: id,
  categoryId: categoryId,
);

const _categories = <CategoryView>[
  CategoryView(
    id: 'food',
    kind: TxnDirection.expense,
    nameEn: 'Food',
    nameHi: 'खाना',
    nameBn: 'খাবার',
    icon: '🍜',
    colorHex: '#F5B843',
  ),
  CategoryView(
    id: 'grocery',
    kind: TxnDirection.expense,
    nameEn: 'Grocery',
    nameHi: 'किराना',
    nameBn: 'বাজার',
    icon: '🛒',
    colorHex: '#14C8B8',
  ),
  CategoryView(
    id: 'transport',
    kind: TxnDirection.expense,
    nameEn: 'Transport',
    nameHi: 'यातायात',
    nameBn: 'যাতায়াত',
    icon: '🚕',
    colorHex: '#3E63DD',
  ),
  CategoryView(
    id: 'fun',
    kind: TxnDirection.expense,
    nameEn: 'Fun',
    nameHi: 'मनोरंजन',
    nameBn: 'বিনোদন',
    icon: '🎬',
    colorHex: '#E5484D',
  ),
];

/// ₹4,000 grocery (50%), ₹900 food of ₹1,000 (90%), ₹3,900 transport of ₹3,000
/// (130%) — one of each threshold state, which is the whole point of the screen.
final _ledger = <TxnView>[
  _txn(id: 'big-basket', paise: 400000, categoryId: 'grocery'),
  _txn(id: 'swiggy', paise: 90000, categoryId: 'food'),
  _txn(id: 'uber', paise: 390000, categoryId: 'transport'),
];

final _budgets = <BudgetView>[
  const BudgetView(id: 'b-overall', amountPaise: 4000000),
  const BudgetView(id: 'b-grocery', categoryId: 'grocery', amountPaise: 800000),
  const BudgetView(id: 'b-food', categoryId: 'food', amountPaise: 100000),
  const BudgetView(
    id: 'b-transport',
    categoryId: 'transport',
    amountPaise: 300000,
  ),
  const BudgetView(id: 'b-fun', categoryId: 'fun', amountPaise: 20000),
];

List<Override> _overrides({
  String locale = 'en',
  List<BudgetView> budgets = const <BudgetView>[],
  bool seeded = true,
}) => <Override>[
  appDbProvider.overrideWithValue(null),
  localeProvider.overrideWith((ref) => locale),
  transactionsProvider.overrideWith((ref) async => _ledger),
  categoriesProvider.overrideWith((ref) async => _categories),
  // The same overlay logic the real provider has, so a save from the editor
  // sheet changes the screen exactly as it would in the preview.
  budgetsProvider.overrideWith((ref) async {
    final list = seeded ? budgets : const <BudgetView>[];
    final patches = ref.watch(sessionBudgetPatchesProvider);
    final deleted = ref.watch(sessionBudgetDeletedProvider);
    final known = {for (final b in list) b.id};
    return <BudgetView>[
      for (final b in list)
        if (!deleted.contains(b.id)) patches[b.id] ?? b,
      for (final entry in patches.entries)
        if (!known.contains(entry.key) && !deleted.contains(entry.key))
          entry.value,
    ];
  }),
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String locale = 'en',
  Size size = const Size(390, 844),
  double textScale = 1.0,
  bool seeded = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: _overrides(locale: locale, seeded: seeded, budgets: _budgets),
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildSsTheme(Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const BudgetsScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('S-14 headline', () {
    testWidgets('carries the overall cap and how much of it is used', (
      tester,
    ) async {
      await _pump(tester);

      // ₹40,000 cap, ₹8,800 spent across the three rows → 22%.
      expect(find.text('₹40,000'), findsOneWidget);
      expect(find.textContaining('22%'), findsOneWidget);
      expect(find.textContaining('used'), findsOneWidget);
    });

    testWidgets('the headline states what is left of the cap', (tester) async {
      await _pump(tester);
      // ₹40,000 − ₹8,800 spent.
      expect(find.textContaining('Left ₹31,200'), findsOneWidget);
    });
  });

  group('S-14 category rows', () {
    testWidgets('are ranked by how much of the cap is gone', (tester) async {
      await _pump(tester);

      final transport = tester.getTopLeft(find.text('Transport')).dy;
      final food = tester.getTopLeft(find.text('Food')).dy;
      final grocery = tester.getTopLeft(find.text('Grocery')).dy;

      // 130% → 90% → 50%.
      expect(transport, lessThan(food));
      expect(food, lessThan(grocery));
    });

    testWidgets('each row states its fraction and its percentage', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('₹4,000 / ₹8,000'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('130%'), findsOneWidget);
    });

    testWidgets('the 80% and 100% thresholds are visible, not only coloured', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('a budget at 120% gets a sentence, not just a red bar', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.textContaining('30% over'), findsOneWidget);
    });
  });

  group('S-14 ads', () {
    testWidgets('the native slot sits after the third row, never above it', (
      tester,
    ) async {
      await _pump(tester);

      final ad = find.byType(AdSlot);
      expect(ad, findsOneWidget);

      final adY = tester.getTopLeft(ad).dy;
      final transportY = tester.getTopLeft(find.text('Transport')).dy;
      final groceryY = tester.getTopLeft(find.text('Grocery')).dy;
      expect(adY, greaterThan(transportY), reason: 'never above the fold');
      expect(adY, greaterThan(groceryY));
      // The fourth row (Fun has no spending, but the budget exists) sits below.
      expect(find.byType(CategoryAvatar), findsNWidgets(4));
    });

    testWidgets('with three rows or fewer there is no ad in the list', (
      tester,
    ) async {
      await _pump(tester, seeded: false);
      expect(find.byType(AdSlot), findsNothing);
    });

    testWidgets('a Pro user sees no slot at all', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: [
          ..._overrides(),
          proStatusProvider.overrideWith((ref) => true),
          bootProvider.overrideWith(
            (ref) async =>
                const BootState(onboarded: true, demoMode: true, locale: 'en'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildSsTheme(Brightness.light),
            home: const BudgetsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdSlot), findsNothing);
    });
  });

  group('S-14 empty state', () {
    testWidgets('offers the way to set the first budget', (tester) async {
      await _pump(tester, seeded: false);

      expect(find.text('No budget set'), findsOneWidget);
      expect(
        find.textContaining('One overall cap, or limits per category.'),
        findsWidgets,
        reason: 'the overall card and the empty state both say what to do',
      );
    });

    testWidgets('the empty state opens the editor', (tester) async {
      await _pump(tester, seeded: false);

      await tester.tap(find.text('Set a budget').first);
      await tester.pumpAndSettle();

      expect(find.byType(BudgetEditorSheet), findsOneWidget);
    });
  });

  group('S-14 editor', () {
    testWidgets('saving a category budget puts it on the screen', (
      tester,
    ) async {
      final container = await _pump(tester, seeded: false);

      await tester.tap(find.text('New budget').first);
      await tester.pumpAndSettle();

      // Pick a category, type a limit, save.
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2500');
      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();

      final saved = container.read(budgetsProvider).valueOrNull ?? const [];
      expect(saved.length, 1);
      expect(saved.single.categoryId, 'food');
      expect(saved.single.amountPaise, 250000);
      expect(find.text('₹900 / ₹2,500'), findsOneWidget);
    });

    testWidgets('an empty amount saves nothing and says why', (tester) async {
      final container = await _pump(tester, seeded: false);

      await tester.tap(find.text('New budget').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();

      expect(find.text('Enter an amount'), findsOneWidget);
      expect(container.read(budgetsProvider).valueOrNull, isEmpty);
    });

    testWidgets('editing the overall cap changes the headline', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Edit budget'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '50000');
      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();

      expect(find.text('₹50,000'), findsOneWidget);
      // ₹8,800 of ₹50,000 is 18%.
      expect(find.textContaining('18%'), findsOneWidget);
    });

    testWidgets('deleting the overall cap leaves the category rows alone', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('Edit budget'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete budget'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      // The headline card is gone, the categories are not.
      expect(find.text('₹40,000'), findsNothing);
      expect(find.text('Grocery'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
    });
  });

  group('S-14 layout', () {
    for (final locale in const ['bn', 'hi', 'en']) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets('no overflow in $locale at ${scale}x on a 360dp phone', (
          tester,
        ) async {
          await _pump(
            tester,
            locale: locale,
            size: const Size(360, 640),
            textScale: scale,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$locale at ${scale}x overflowed',
          );
        });
      }
    }
  });
}
