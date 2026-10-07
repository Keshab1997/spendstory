/// S-12 Add / Edit (T-404).
///
/// The spec sets a number — three taps to a saved transaction — so the first
/// test counts taps. The rest guard the traps a money keypad has: a stale
/// category after switching direction, and a save with no amount.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/ui/components/lists.dart';
import 'package:spendstory/ui/strings.dart';

import 'ledger_harness.dart';

const _en = SsStrings('en');

Finder _key(String id) => find.byKey(ValueKey<String>('keypad-$id'));

Future<void> _press(WidgetTester tester, String id) async {
  // The 88%-height sheet puts the keypad below the fold on a short viewport;
  // the full-page host does not. Scrolling to it first keeps one helper honest
  // for both hosts.
  await tester.ensureVisible(_key(id));
  await tester.pump();
  await tester.tap(_key(id));
  await tester.pump();
}

Future<void> _type(WidgetTester tester, String digits) async {
  for (final ch in digits.split('')) {
    await _press(tester, ch);
  }
}

void main() {
  testWidgets('amount, category, save — no scrolling needed', (tester) async {
    final container = await pumpAt(tester, '/transactions/edit');

    // "5 0 0 0 0" is ₹500.00 — entered in paise, like a cash register.
    await _type(tester, '50000');
    await tester.tap(find.widgetWithText(CategoryChip, 'Food'));
    await tester.pump();
    await tester.tap(find.widgetWithText(InkWell, _en.save).hitTestable());
    await tester.pumpAndSettle();

    final added = container.read(sessionAddedProvider);
    expect(added, hasLength(1));
    expect(added.single.amountPaise, 50000);
    expect(added.single.categoryId, 'food');
    expect(added.single.direction, TxnDirection.expense);
  });

  testWidgets('saving with no amount is refused, not silently ignored', (
    tester,
  ) async {
    final container = await pumpAt(tester, '/transactions/edit');

    await tester.tap(find.widgetWithText(InkWell, _en.save).hitTestable());
    await tester.pumpAndSettle();

    expect(find.text(_en.amountRequired), findsOneWidget);
    expect(container.read(sessionAddedProvider), isEmpty);
  });

  testWidgets('switching direction drops the category from the other side', (
    tester,
  ) async {
    await pumpAt(tester, '/transactions/edit');

    await _type(tester, '10000');
    await tester.tap(find.widgetWithText(CategoryChip, 'Food'));
    await tester.pump();

    await tester.tap(find.text(_en.income));
    await tester.pumpAndSettle();

    // Expense categories are gone; "Salary" is what an income offers.
    expect(find.widgetWithText(CategoryChip, 'Food'), findsNothing);
    expect(find.widgetWithText(CategoryChip, 'Salary'), findsOneWidget);
  });

  testWidgets('backspace and clear walk the amount back', (tester) async {
    await pumpAt(tester, '/transactions/edit');

    await _type(tester, '12345');
    await _press(tester, 'backspace');
    expect(find.text('₹12.34'), findsOneWidget);

    await _press(tester, 'clear');
    expect(find.text('₹0.00'), findsOneWidget);
  });

  testWidgets('editing an existing row prefills it and replaces it', (
    tester,
  ) async {
    final container = await pumpAt(tester, '/transactions/auto-1');

    await tester.tap(find.text(_en.detailEdit));
    await tester.pumpAndSettle();

    // Prefilled from the row, not blank.
    expect(find.text('₹1,240.00'), findsOneWidget);
    expect(find.text('BigBasket'), findsWidgets);

    await _press(tester, 'clear');
    await _type(tester, '99900');
    await tester.tap(find.widgetWithText(InkWell, _en.save).hitTestable());
    await tester.pumpAndSettle();

    final patched = container.read(sessionPatchesProvider)['auto-1'];
    expect(patched?.amountPaise, 99900);
    // An edit must not turn an auto-captured row into a typed one, or lose the
    // message it was read from.
    expect(patched?.source, 'auto_sms');
    expect(patched?.rawText, contains('BIGBASKET'));
  });

  for (final locale in SsStrings.supportedLocales) {
    testWidgets('no overflow in $locale at 1.3x on a 360dp phone', (
      tester,
    ) async {
      await pumpAt(
        tester,
        '/transactions/edit',
        locale: locale,
        size: const Size(360, 640),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
