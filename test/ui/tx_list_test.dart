/// S-10 Transactions list (T-402).
///
/// The screen's promises, in the order a user meets them: the month strip picks
/// a month and the list obeys it, the summary chips agree with the rows below
/// them, the filter chips filter, a swipe left deletes with a working Undo, and
/// a swipe right re-categorises. Plus the thing that actually breaks in this
/// app: Bengali and Hindi at a large text scale, on a small phone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/domain/view_models.dart';
import 'package:spendstory/ui/components/lists.dart';
import 'package:spendstory/ui/format.dart';
import 'package:spendstory/ui/screens/tx_list_screen.dart';
import 'package:spendstory/ui/strings.dart';
import 'package:spendstory/ui/theme.dart';

final _now = DateTime(2026, 10, 7, 20);

int _ms(DateTime d) => d.millisecondsSinceEpoch;

TxnView _txn({
  required String id,
  required int paise,
  required DateTime at,
  TxnDirection direction = TxnDirection.expense,
  String? merchant,
  String? categoryId,
}) => TxnView(
  id: id,
  amountPaise: paise,
  direction: direction,
  occurredAtMs: _ms(at),
  merchant: merchant ?? id,
  categoryId: categoryId,
);

/// Two months of rows, so the month strip has somewhere to go.
final _ledger = <TxnView>[
  _txn(id: 'bigbasket', paise: 124000, at: _now, categoryId: 'cat-grocery'),
  _txn(
    id: 'salary',
    paise: 4500000,
    at: _now,
    direction: TxnDirection.income,
    categoryId: 'cat-salary',
  ),
  _txn(
    id: 'chaiwala',
    paise: 3000,
    at: _now.subtract(const Duration(days: 1)),
    categoryId: 'cat-food',
  ),
  _txn(id: 'september-bill', paise: 90000, at: DateTime(2026, 9, 12, 10)),
];

const _categories = <CategoryView>[
  CategoryView(
    id: 'cat-grocery',
    kind: TxnDirection.expense,
    nameEn: 'Grocery',
    nameHi: 'किराना',
    nameBn: 'মুদি',
    icon: '🛒',
    colorHex: '#14C8B8',
  ),
  CategoryView(
    id: 'cat-food',
    kind: TxnDirection.expense,
    nameEn: 'Food',
    nameHi: 'खाना',
    nameBn: 'খাবার',
    icon: '🍜',
    colorHex: '#F5B843',
  ),
  CategoryView(
    id: 'cat-salary',
    kind: TxnDirection.income,
    nameEn: 'Salary',
    nameHi: 'वेतन',
    nameBn: 'বেতন',
    icon: '💰',
    colorHex: '#6C4CF1',
  ),
];

List<Override> _overrides({String locale = 'bn'}) => <Override>[
  // No database: the screen runs against the session overlays, which is also
  // exactly what the web preview does.
  appDbProvider.overrideWithValue(null),
  localeProvider.overrideWith((ref) => locale),
  selectedMonthProvider.overrideWith((ref) => startOfMonth(_ms(_now))),
  transactionsProvider.overrideWith((ref) async {
    final deleted = ref.watch(sessionDeletedIdsProvider);
    final patches = ref.watch(sessionPatchesProvider);
    final added = ref.watch(sessionAddedProvider);
    final rows = <TxnView>[
      for (final t in <TxnView>[...added, ..._ledger])
        if (!deleted.contains(t.id)) patches[t.id] ?? t,
    ];
    rows.sort((a, b) => b.occurredAtMs.compareTo(a.occurredAtMs));
    return rows;
  }),
  categoriesProvider.overrideWith((ref) async => _categories),
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String locale = 'bn',
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: _overrides(locale: locale));
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildSsTheme(Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const TxListScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('S-10 month strip', () {
    testWidgets('opens on the selected month and lists only its rows', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('BigBasket'), findsNothing); // merchant is the id here
      expect(find.text('bigbasket'), findsOneWidget);
      expect(find.text('chaiwala'), findsOneWidget);
      expect(find.text('salary'), findsOneWidget);

      // September's row belongs to September.
      expect(find.text('september-bill'), findsNothing);
    });

    testWidgets('the back arrow moves a month and the list follows', (
      tester,
    ) async {
      final container = await _pump(tester);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(
        container.read(selectedMonthProvider),
        startOfMonth(_ms(DateTime(2026, 9, 1))),
      );
      expect(find.text('september-bill'), findsOneWidget);
      expect(find.text('bigbasket'), findsNothing);
    });

    testWidgets('the forward arrow is disabled in the current month', (
      tester,
    ) async {
      final container = await _pump(tester);
      final before = container.read(selectedMonthProvider);

      final next = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
      );
      expect(next.onPressed, isNull, reason: 'no months in the future');
      expect(container.read(selectedMonthProvider), before);
    });
  });

  group('S-10 summary and filters', () {
    testWidgets('the chips carry the month totals', (tester) async {
      await _pump(tester, locale: 'en');

      // ₹1,240 + ₹30 spent, ₹45,000 in.
      expect(find.text('₹1,270'), findsOneWidget);
      expect(find.text('₹45,000'), findsOneWidget);
    });

    testWidgets('the income filter hides expenses, and the reverse', (
      tester,
    ) async {
      await _pump(tester, locale: 'en');
      final s = const SsStrings('en');

      await tester.tap(find.widgetWithText(CategoryChip, s.income));
      await tester.pumpAndSettle();
      expect(find.text('salary'), findsOneWidget);
      expect(find.text('bigbasket'), findsNothing);

      await tester.tap(find.widgetWithText(CategoryChip, s.expense).first);
      await tester.pumpAndSettle();
      expect(find.text('salary'), findsNothing);
      expect(find.text('bigbasket'), findsOneWidget);

      // ...and the summary chips still describe the whole month.
      expect(find.text('₹45,000'), findsOneWidget);
    });
  });

  group('S-10 swipe actions', () {
    testWidgets('swipe left deletes the row, and Undo brings it back', (
      tester,
    ) async {
      final container = await _pump(tester, locale: 'en');

      await tester.drag(find.text('bigbasket'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('bigbasket'), findsNothing);
      expect(container.read(sessionDeletedIdsProvider), contains('bigbasket'));

      await tester.tap(find.text(const SsStrings('en').txUndo));
      await tester.pumpAndSettle();

      expect(find.text('bigbasket'), findsOneWidget);
      expect(
        container.read(sessionDeletedIdsProvider),
        isNot(contains('bigbasket')),
      );
    });

    testWidgets('swipe right opens the sheet and re-categorises', (
      tester,
    ) async {
      final container = await _pump(tester, locale: 'en');

      await tester.drag(find.text('bigbasket'), const Offset(500, 0));
      await tester.pumpAndSettle();

      // Only expense categories are offered for a debit. Scoped to the chips,
      // because "Food" is also the meta line of the row behind the sheet.
      expect(find.widgetWithText(CategoryChip, 'Grocery'), findsOneWidget);
      expect(find.widgetWithText(CategoryChip, 'Food'), findsOneWidget);
      expect(find.widgetWithText(CategoryChip, 'Salary'), findsNothing);

      await tester.tap(find.widgetWithText(CategoryChip, 'Food'));
      await tester.pumpAndSettle();

      expect(
        container.read(sessionPatchesProvider)['bigbasket']?.categoryId,
        'cat-food',
      );
      // The row survived the swipe — a re-categorise is not a delete.
      expect(find.text('bigbasket'), findsOneWidget);
    });
  });

  group('S-10 layout', () {
    for (final locale in SsStrings.supportedLocales) {
      for (final scale in <double>[1.0, 1.3]) {
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
