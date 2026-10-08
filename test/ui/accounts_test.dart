/// S-16 Accounts (T-503).
///
/// The promise of this screen is arithmetic: opening + credits − debits, worked
/// out from the same rows every other screen shows. So the tests check the
/// arithmetic, the one number the user owns (the opening balance), and the
/// behaviour that would be easy to get wrong — a deleted account must not take
/// its history with it, and an account with no transactions must still show its
/// opening balance rather than zero.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/app.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/app/router.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/domain/view_models.dart';
import 'package:spendstory/ui/screens/account_edit_sheet.dart';
import 'package:spendstory/ui/screens/accounts_screen.dart';
import 'package:spendstory/ui/theme.dart';

final _now = DateTime(2026, 10, 7, 20, 42);
int _ms(DateTime d) => d.millisecondsSinceEpoch;

AccountView _account(
  String id,
  String name,
  String type,
  int opening, {
  String? last4,
}) =>
    AccountView(
      id: id,
      name: name,
      type: type,
      openingBalancePaise: opening,
      last4: last4,
    );

TxnView _txn({
  required String id,
  required int paise,
  required String accountId,
  TxnDirection direction = TxnDirection.expense,
}) => TxnView(
  id: id,
  amountPaise: paise,
  direction: direction,
  occurredAtMs: _ms(_now),
  merchant: id,
  accountId: accountId,
);

/// ₹48,200 + ₹50,000 salary − ₹1,240 = ₹96,960 in HDFC; ₹2,500 − ₹30 = ₹2,470
/// in cash; a wallet nobody has touched, which must read ₹1,000 and not ₹0.
final _accounts = <AccountView>[
  _account('acc-hdfc', 'HDFC Bank', 'bank', 4820000, last4: '4521'),
  _account('acc-cash', 'Cash', 'cash', 250000),
  _account('acc-wallet', 'Paytm', 'wallet', 100000),
];

final _ledger = <TxnView>[
  _txn(id: 'salary', paise: 5000000, accountId: 'acc-hdfc', direction: TxnDirection.income),
  _txn(id: 'bigbasket', paise: 124000, accountId: 'acc-hdfc'),
  _txn(id: 'chai', paise: 3000, accountId: 'acc-cash'),
];

List<Override> _overrides({
  String locale = 'en',
  List<AccountView>? accounts,
  List<TxnView> ledger = const <TxnView>[],
}) => <Override>[
  appDbProvider.overrideWithValue(null),
  bootProvider.overrideWith(
    (ref) async => BootState(onboarded: true, demoMode: true, locale: locale),
  ),
  localeProvider.overrideWith((ref) => locale),
  transactionsProvider.overrideWith((ref) async => ledger),
  accountsProvider.overrideWith((ref) async {
    final base = accounts ?? _accounts;
    final patches = ref.watch(sessionAccountPatchesProvider);
    final deleted = ref.watch(sessionAccountDeletedProvider);
    final known = {for (final a in base) a.id};
    return <AccountView>[
      for (final a in base)
        if (!deleted.contains(a.id)) patches[a.id] ?? a,
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
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: _overrides(locale: locale, ledger: _ledger),
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildSsTheme(Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const AccountsScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('S-16 the route', () {
    testWidgets('resolves to the real screen', (tester) async {
      final container = ProviderContainer(
        overrides: _overrides(ledger: _ledger),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SpendStoryApp(),
        ),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/accounts');
      await tester.pumpAndSettle();

      expect(find.byType(AccountsScreen), findsOneWidget);
    });
  });

  group('S-16 balances', () {
    testWidgets('each card computes opening + credits − debits', (tester) async {
      await _pump(tester);

      expect(find.text('₹96,960'), findsOneWidget); // HDFC
      expect(find.text('₹2,470'), findsOneWidget); // cash
      expect(find.text('₹1,000'), findsWidgets); // untouched wallet
    });

    testWidgets('the total is the sum of every account', (tester) async {
      await _pump(tester);

      // 96,960 + 2,470 + 1,000.
      expect(find.text('₹1,00,430'), findsOneWidget);
    });

    testWidgets('the screen says the balance is computed on the phone', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.textContaining('worked out on this phone'), findsOneWidget);
    });

    testWidgets('a hidden account keeps its transactions out of the total', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('HDFC Bank ••4521'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('HDFC Bank ••4521'), findsNothing);
      expect(find.text('₹3,470'), findsOneWidget); // 2,470 + 1,000
    });
  });

  group('S-16 editing', () {
    testWidgets('an account can be added and shows its opening balance', (
      tester,
    ) async {
      final container = await _pump(tester);

      await tester.tap(find.text('Add account'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountEditorSheet), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'SBI Savings');
      await tester.enterText(find.byType(TextField).at(1), '5000');
      await tester.tap(find.text('Save account'));
      await tester.pumpAndSettle();

      expect(find.text('SBI Savings'), findsOneWidget);
      expect(find.text('₹5,000'), findsOneWidget);

      final saved = container.read(accountsProvider).valueOrNull ?? const [];
      expect(saved.length, 4);
      expect(saved.last.openingBalancePaise, 500000);
    });

    testWidgets('a name is required, and nothing is saved without one', (
      tester,
    ) async {
      final container = await _pump(tester);

      await tester.tap(find.text('Add account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save account'));
      await tester.pumpAndSettle();

      expect(find.text('Give the account a name'), findsOneWidget);
      expect((container.read(accountsProvider).valueOrNull ?? const []).length, 3);
    });

    testWidgets('editing the opening balance moves the card and the total', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('Paytm'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), '4000');
      await tester.tap(find.text('Save account'));
      await tester.pumpAndSettle();

      // The wallet now holds ₹4,000 and the total follows.
      expect(find.text('₹4,000'), findsOneWidget);
      expect(find.text('₹1,03,430'), findsOneWidget);
    });

    testWidgets('a negative opening balance is allowed, not "fixed"', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('Add account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Credit Card');
      await tester.enterText(find.byType(TextField).at(1), '-2500');
      await tester.tap(find.text('Card'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save account'));
      await tester.pumpAndSettle();

      expect(find.text('Credit Card'), findsOneWidget);
      expect(find.text('−₹2,500'), findsOneWidget);
    });
  });

  group('S-16 layout', () {
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
