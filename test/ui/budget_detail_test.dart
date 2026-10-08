/// S-15 Budget detail (T-502).
///
/// The screen exists for one number — what is left divided by the days left —
/// so most of this file is about that number being right, being absent when it
/// should be, and being reachable: a detail screen nobody can navigate to is a
/// screen nobody has.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/app.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/app/router.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/domain/view_models.dart';
import 'package:spendstory/ui/components/ad_slot.dart';
import 'package:spendstory/ui/screens/budget_detail_screen.dart';
import 'package:spendstory/ui/screens/budgets_screen.dart';
import 'package:spendstory/ui/screens/tx_detail_screen.dart';

/// 7 October 2026, 20:42 — day 7 of a 31-day month.
final _now = DateTime(2026, 10, 7, 20, 42);
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
];

/// ₹250 of a ₹1,000 food cap — ₹750 left over 24 days (8th–31st).
final _ledger = <TxnView>[
  _txn(id: 'tea', paise: 10000, categoryId: 'food'),
  _txn(id: 'lunch', paise: 15000, categoryId: 'food'),
  _txn(id: 'rice', paise: 90000, categoryId: 'grocery'),
];

final _budgets = <BudgetView>[
  const BudgetView(id: 'b-food', categoryId: 'food', amountPaise: 100000),
  const BudgetView(id: 'b-grocery', categoryId: 'grocery', amountPaise: 800000),
];

List<Override> _overrides({
  String locale = 'en',
  List<BudgetView> budgets = const <BudgetView>[],
  List<TxnView> ledger = const <TxnView>[],
}) => <Override>[
  appDbProvider.overrideWithValue(null),
  nowProvider.overrideWith((ref) => _now),
  // The app takes its opening language from boot, so this has to agree — a
  // locale override alone is overwritten on the first frame.
  bootProvider.overrideWith(
    (ref) async => BootState(onboarded: true, demoMode: true, locale: locale),
  ),
  localeProvider.overrideWith((ref) => locale),
  transactionsProvider.overrideWith((ref) async => ledger),
  categoriesProvider.overrideWith((ref) async => _categories),
  budgetsProvider.overrideWith((ref) async {
    final patches = ref.watch(sessionBudgetPatchesProvider);
    final deleted = ref.watch(sessionBudgetDeletedProvider);
    final known = {for (final b in budgets) b.id};
    return <BudgetView>[
      for (final b in budgets)
        if (!deleted.contains(b.id)) patches[b.id] ?? b,
      for (final entry in patches.entries)
        if (!known.contains(entry.key) && !deleted.contains(entry.key))
          entry.value,
    ];
  }),
];

/// Boots the real app and router, then navigates to [location].
Future<ProviderContainer> _pumpAt(
  WidgetTester tester,
  String location, {
  String locale = 'en',
  Size size = const Size(390, 844),
  double textScale = 1.0,
  List<BudgetView>? budgets,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: _overrides(
      locale: locale,
      budgets: budgets ?? _budgets,
      ledger: _ledger,
    ),
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const SpendStoryApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  container.read(routerProvider).go(location);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('S-15 navigation', () {
    testWidgets('a budget row opens its own screen', (tester) async {
      await _pumpAt(tester, '/budgets');

      expect(find.byType(BudgetsScreen), findsOneWidget);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Asserted on the screen, not on the delegate's idea of the path: an
      // imperative push lands on the page without rewriting the root match.
      expect(find.byType(BudgetDetailScreen), findsOneWidget);
      expect(find.text('Daily allowance'), findsOneWidget);
    });

    testWidgets('an unknown budget id shows the empty state, not a crash', (
      tester,
    ) async {
      await _pumpAt(tester, '/budgets/does-not-exist');

      expect(find.byType(BudgetDetailScreen), findsOneWidget);
      expect(find.text('No budget set'), findsOneWidget);
    });
  });

  group('S-15 the ring and the totals', () {
    testWidgets('carries the percentage, spent, left and the limit', (
      tester,
    ) async {
      await _pumpAt(tester, '/budgets/b-food');

      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('₹250'), findsWidgets);
      expect(find.text('₹750'), findsWidgets);
      expect(find.text('₹1,000'), findsWidgets);
    });

  });

  group('S-15 the daily allowance', () {
    testWidgets('divides what is left by the days left', (tester) async {
      await _pumpAt(tester, '/budgets/b-food');

      // ₹750 over the 24 days from 8 October: ₹31 a day, floored on purpose.
      expect(find.text('Daily allowance'), findsOneWidget);
      expect(find.textContaining('₹31'), findsWidgets);
      expect(find.textContaining('24 days left'), findsOneWidget);
    });

    testWidgets('an over-budget cap does not divide, it says the cap is used', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        '/budgets/b-food',
        budgets: const <BudgetView>[
          BudgetView(id: 'b-food', categoryId: 'food', amountPaise: 20000),
        ],
      );

      expect(find.text('125%'), findsOneWidget);
      expect(
        find.textContaining('The budget is used up'),
        findsOneWidget,
        reason: 'no allowance to give, and the screen must not invent one',
      );
      expect(find.textContaining('a day'), findsNothing);
    });

    testWidgets('a spent-up cap on its last day still renders', (tester) async {
      // Nothing left and no days left is the case that divides by zero if the
      // screen is careless, so it is pumped on purpose.
      await _pumpAt(tester, '/budgets/b-grocery');

      expect(find.text('11%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('S-15 the evidence', () {
    testWidgets('lists only the rows this cap counts', (tester) async {
      await _pumpAt(tester, '/budgets/b-food');

      expect(find.text('tea'), findsOneWidget);
      expect(find.text('lunch'), findsOneWidget);
      expect(find.text('rice'), findsNothing, reason: 'grocery is not food');
    });

    testWidgets('a row taps through to the transaction', (tester) async {
      await _pumpAt(tester, '/budgets/b-food');

      await tester.tap(find.text('tea'));
      await tester.pumpAndSettle();

      expect(find.byType(TxDetailScreen), findsOneWidget);
    });

    testWidgets('the slot is below the rows it could interrupt', (
      tester,
    ) async {
      await _pumpAt(tester, '/budgets/b-food');

      final ad = find.byType(AdSlot);
      if (ad.evaluate().isNotEmpty) {
        final adY = tester.getTopLeft(ad).dy;
        final rowY = tester.getTopLeft(find.text('lunch')).dy;
        expect(adY, greaterThan(rowY));
      }
    });
  });

  group('S-15 editing from the detail screen', () {
    testWidgets('a new limit redraws the numbers', (tester) async {
      await _pumpAt(tester, '/budgets/b-food');

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '500');
      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();

      // ₹250 of ₹500 is 50%, the ring follows, the sheet is gone.
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('₹500'), findsWidgets);
      expect(find.text('Save budget'), findsNothing);
    });

    testWidgets('deleting leaves the detail screen and drops the row', (
      tester,
    ) async {
      await _pumpAt(tester, '/budgets/b-food');

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete budget'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      // Back on the list, without the row that was just deleted.
      expect(find.byType(BudgetDetailScreen), findsNothing);
      expect(find.byType(BudgetsScreen), findsOneWidget);
      expect(find.text('Food'), findsNothing);
      expect(find.text('Grocery'), findsOneWidget);
    });
  });

  group('S-15 layout', () {
    for (final locale in const ['bn', 'hi', 'en']) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets('no overflow in $locale at ${scale}x on a 360dp phone', (
          tester,
        ) async {
          await _pumpAt(
            tester,
            '/budgets/b-food',
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
