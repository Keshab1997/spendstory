/// Shared setup for the Batch 5 screen tests (T-407).
///
/// Every test here drives the **real app and the real router** — not a screen
/// widget pumped in isolation — because half of what Batch 5 added is route
/// wiring, and a screen that renders perfectly at a path nothing reaches is not
/// done. The database is null throughout, which is also what the web preview
/// runs, so the session overlay is exercised rather than mocked away.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/app.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/app/router.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/domain/view_models.dart';

final harnessNow = DateTime(2026, 10, 7, 20, 42);

int ms(DateTime d) => d.millisecondsSinceEpoch;

/// One auto-captured row (with the SMS it came from), one typed row, one
/// income row. Between them they cover every branch the detail screen has.
final List<TxnView> harnessLedger = <TxnView>[
  TxnView(
    id: 'auto-1',
    amountPaise: 124000,
    direction: TxnDirection.expense,
    occurredAtMs: ms(harnessNow),
    merchant: 'BigBasket',
    categoryId: 'grocery',
    mode: PaymentMode.upi,
    source: 'auto_sms',
    rawText:
        'Rs.1240.00 debited from a/c XX4421 on 07-10-26 to BIGBASKET via UPI '
        'Ref 582910. Not you? Call 18001234.',
  ),
  TxnView(
    id: 'manual-1',
    amountPaise: 3000,
    direction: TxnDirection.expense,
    occurredAtMs: ms(harnessNow.subtract(const Duration(days: 1))),
    merchant: 'Chaiwala',
    categoryId: 'food',
    note: 'morning cha',
  ),
  TxnView(
    id: 'income-1',
    amountPaise: 4500000,
    direction: TxnDirection.income,
    occurredAtMs: ms(harnessNow.subtract(const Duration(days: 2))),
    merchant: 'Payroll',
    categoryId: 'salary',
    source: 'auto_sms',
    rawText: 'Rs.45000.00 credited to a/c XX4421 on 05-10-26. Salary.',
  ),
];

const List<CategoryView> harnessCategories = <CategoryView>[
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
    id: 'food',
    kind: TxnDirection.expense,
    nameEn: 'Food',
    nameHi: 'खाना',
    nameBn: 'খাবার',
    icon: '🍜',
    colorHex: '#F5B843',
  ),
  CategoryView(
    id: 'salary',
    kind: TxnDirection.income,
    nameEn: 'Salary',
    nameHi: 'वेतन',
    nameBn: 'বেতন',
    icon: '💰',
    colorHex: '#6C4CF1',
  ),
];

List<Override> harnessOverrides({String locale = 'en'}) => <Override>[
  appDbProvider.overrideWithValue(null),
  bootProvider.overrideWith(
    (ref) async => BootState(onboarded: true, demoMode: true, locale: locale),
  ),
  localeProvider.overrideWith((ref) => locale),
  categoriesProvider.overrideWith((ref) async {
    final patches = ref.watch(sessionCategoryPatchesProvider);
    final deleted = ref.watch(sessionCategoryDeletedProvider);
    final known = {for (final c in harnessCategories) c.id};
    return <CategoryView>[
      for (final c in harnessCategories)
        if (!deleted.contains(c.id)) patches[c.id] ?? c,
      for (final entry in patches.entries)
        if (!known.contains(entry.key) && !deleted.contains(entry.key))
          entry.value,
    ];
  }),
  transactionsProvider.overrideWith((ref) async {
    final deleted = ref.watch(sessionDeletedIdsProvider);
    final patches = ref.watch(sessionPatchesProvider);
    final added = ref.watch(sessionAddedProvider);
    final rows = <TxnView>[
      for (final t in <TxnView>[...added, ...harnessLedger])
        if (!deleted.contains(t.id)) patches[t.id] ?? t,
    ];
    rows.sort((a, b) => b.occurredAtMs.compareTo(a.occurredAtMs));
    return rows;
  }),
];

/// Boots the app, navigates to [location], and returns the container so a test
/// can read the overlays back.
Future<ProviderContainer> pumpAt(
  WidgetTester tester,
  String location, {
  String locale = 'en',
  Size size = const Size(390, 844),
  double textScale = 1.0,
  List<Override> extra = const <Override>[],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...harnessOverrides(locale: locale),
        ...extra,
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const SpendStoryApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  container.read(routerProvider).go(location);
  await tester.pumpAndSettle();
  return container;
}

String pathOf(ProviderContainer container) =>
    container.read(routerProvider).routerDelegate.currentConfiguration.uri.path;
