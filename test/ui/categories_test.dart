/// S-13 Categories manager (T-405).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/ui/strings.dart';

import 'ledger_harness.dart';

const _en = SsStrings('en');

void main() {
  testWidgets('the two tabs separate expense from income', (tester) async {
    await pumpAt(tester, '/categories');

    expect(find.text('Grocery'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);

    await tester.tap(find.text(_en.income));
    await tester.pumpAndSettle();

    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Grocery'), findsNothing);
  });

  testWidgets('the + button creates a category that shows up in the grid', (
    tester,
  ) async {
    final container = await pumpAt(tester, '/categories');

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text(_en.catNew), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, _en.catNameEn),
      'Petrol',
    );
    await tester.tap(find.widgetWithText(InkWell, _en.save).hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Petrol'), findsOneWidget);
    final saved = container.read(sessionCategoryPatchesProvider).values.single;
    expect(saved.nameEn, 'Petrol');
    // One name is enough — the others fall back rather than rendering blank.
    expect(saved.nameBn, 'Petrol');
    expect(saved.kind.wire, 'expense');
  });

  testWidgets('a category with no name at all is refused', (tester) async {
    final container = await pumpAt(tester, '/categories');

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, _en.save).hitTestable());
    await tester.pumpAndSettle();

    expect(find.text(_en.catNameRequired), findsOneWidget);
    expect(container.read(sessionCategoryPatchesProvider), isEmpty);
  });

  testWidgets('editing an existing category keeps its id', (tester) async {
    final container = await pumpAt(tester, '/categories');

    await tester.tap(find.text('Grocery'));
    await tester.pumpAndSettle();
    expect(find.text(_en.catEditTitle), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, _en.catNameEn),
      'Groceries',
    );
    await tester.tap(find.widgetWithText(InkWell, _en.save).hitTestable());
    await tester.pumpAndSettle();

    expect(
      container.read(sessionCategoryPatchesProvider)['grocery']?.nameEn,
      'Groceries',
    );
  });

  testWidgets('delete warns about the history it is not touching', (
    tester,
  ) async {
    final container = await pumpAt(tester, '/categories');

    await tester.tap(find.text('Grocery'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, _en.catDelete).hitTestable());
    await tester.pumpAndSettle();

    expect(find.text(_en.catDeleteWarn), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, _en.txDelete));
    await tester.pumpAndSettle();

    expect(container.read(sessionCategoryDeletedProvider), contains('grocery'));
    expect(find.text('Grocery'), findsNothing);
  });

  for (final locale in SsStrings.supportedLocales) {
    testWidgets('no overflow in $locale at 1.3x on a 360dp phone', (
      tester,
    ) async {
      await pumpAt(
        tester,
        '/categories',
        locale: locale,
        size: const Size(360, 640),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
