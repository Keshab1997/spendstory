/// S-11 Transaction detail (T-403).
///
/// The screen exists to answer "where did this number come from?", so the
/// source row and the raw-message viewer get the most attention here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/ui/strings.dart';

import 'ledger_harness.dart';

const _en = SsStrings('en');

void main() {
  testWidgets('renders the amount, the merchant and the source', (
    tester,
  ) async {
    await pumpAt(tester, '/transactions/auto-1');

    expect(find.text('BigBasket'), findsWidgets);
    expect(find.text('−₹1,240'), findsOneWidget);
    expect(find.text(_en.detailSource), findsOneWidget);
    // "Auto (SMS)" — the claim the user is being asked to trust.
    expect(find.text(_en['sourceAutoSms']), findsOneWidget);
  });

  testWidgets('the raw message is collapsed, and opens on tap', (tester) async {
    await pumpAt(tester, '/transactions/auto-1');

    expect(find.text(_en.detailRawTitle), findsOneWidget);
    expect(find.textContaining('XX4421'), findsNothing);

    await tester.tap(find.text(_en.detailRawTitle));
    await tester.pumpAndSettle();

    // The exact text, not a summary of it.
    expect(find.textContaining('Rs.1240.00 debited'), findsOneWidget);
    expect(find.textContaining('Ref 582910'), findsOneWidget);
    expect(find.text(_en.detailRawHint), findsOneWidget);
  });

  testWidgets('a typed row says so instead of pretending to have a message', (
    tester,
  ) async {
    await pumpAt(tester, '/transactions/manual-1');

    expect(find.text(_en.detailNoRaw), findsOneWidget);
    expect(find.text(_en['sourceManual']), findsOneWidget);
    // The note the user left is shown as its own row.
    expect(find.text('morning cha'), findsOneWidget);
  });

  testWidgets('delete asks first, then removes the row and leaves', (
    tester,
  ) async {
    final container = await pumpAt(tester, '/transactions/auto-1');

    await tester.tap(find.text(_en.txDelete));
    await tester.pumpAndSettle();
    expect(find.text(_en.detailDeleteConfirmTitle), findsOneWidget);

    // Backing out changes nothing.
    await tester.tap(find.text(_en.cancel));
    await tester.pumpAndSettle();
    expect(container.read(sessionDeletedIdsProvider), isEmpty);

    await tester.tap(find.text(_en.txDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, _en.txDelete));
    await tester.pumpAndSettle();

    expect(container.read(sessionDeletedIdsProvider), contains('auto-1'));
    expect(pathOf(container), '/transactions');
  });

  testWidgets('Change re-files the transaction', (tester) async {
    final container = await pumpAt(tester, '/transactions/auto-1');

    await tester.tap(find.text(_en.detailChange));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();

    expect(
      container.read(sessionPatchesProvider)['auto-1']?.categoryId,
      'food',
    );
  });

  testWidgets('a deep link to a row that is gone says so', (tester) async {
    await pumpAt(tester, '/transactions/does-not-exist');
    expect(find.text(_en.detailNotFound), findsOneWidget);
  });

  for (final locale in SsStrings.supportedLocales) {
    testWidgets('no overflow in $locale at 1.3x on a 360dp phone', (
      tester,
    ) async {
      await pumpAt(
        tester,
        '/transactions/auto-1',
        locale: locale,
        size: const Size(360, 640),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
