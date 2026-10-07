/// S-18 Search & filter (T-406).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/ui/components/lists.dart';
import 'package:spendstory/ui/strings.dart';

import 'ledger_harness.dart';

const _en = SsStrings('en');

/// The filter row scrolls horizontally, so a chip may start off-screen.
Future<void> _tapChip(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(CategoryChip, label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

Future<void> _query(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens idle, explaining what it searches', (tester) async {
    await pumpAt(tester, '/search');
    expect(find.text(_en.searchStartTitle), findsOneWidget);
    expect(find.byType(TxRow), findsNothing);
  });

  testWidgets('matches a merchant and counts the results', (tester) async {
    await pumpAt(tester, '/search');
    await _query(tester, 'chai');

    expect(find.byType(TxRow), findsOneWidget);
    expect(find.text('Chaiwala'), findsOneWidget);
    expect(find.text('1 ${_en.searchResultCount}'), findsOneWidget);
  });

  testWidgets('matches an amount typed the way a human remembers it', (
    tester,
  ) async {
    await pumpAt(tester, '/search');

    // The row is stored as 124000 paise; the user remembers "1240".
    await _query(tester, '1240');
    expect(find.text('BigBasket'), findsOneWidget);
    expect(find.byType(TxRow), findsOneWidget);

    // And with the separator they would actually type.
    await _query(tester, '1,240');
    expect(find.byType(TxRow), findsOneWidget);
  });

  testWidgets('matches a note', (tester) async {
    await pumpAt(tester, '/search');
    await _query(tester, 'morning');
    expect(find.text('Chaiwala'), findsOneWidget);
  });

  testWidgets('a filter narrows without a query, and can be cleared', (
    tester,
  ) async {
    await pumpAt(tester, '/search');

    await _tapChip(tester, _en.income);
    expect(find.text('Payroll'), findsOneWidget);
    expect(find.text('BigBasket'), findsNothing);

    await _tapChip(tester, _en.filterSourceManual);
    // Income AND typed-by-hand: nothing in this ledger is both.
    expect(find.text(_en.searchNoResults), findsOneWidget);

    await tester.tap(find.text(_en.filterClear));
    await tester.pumpAndSettle();
    expect(find.text(_en.searchStartTitle), findsOneWidget);
  });

  testWidgets('the auto filter separates captured rows from typed ones', (
    tester,
  ) async {
    await pumpAt(tester, '/search');

    await _tapChip(tester, _en.filterSourceAuto);
    expect(find.byType(TxRow), findsNWidgets(2));
    expect(find.text('Chaiwala'), findsNothing);
  });

  testWidgets('a query that matches nothing says so', (tester) async {
    await pumpAt(tester, '/search');
    await _query(tester, 'zzzz');
    expect(find.text(_en.searchNoResults), findsOneWidget);
  });

  for (final locale in SsStrings.supportedLocales) {
    testWidgets('no overflow in $locale at 1.3x on a 360dp phone', (
      tester,
    ) async {
      await pumpAt(
        tester,
        '/search',
        locale: locale,
        size: const Size(360, 640),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
