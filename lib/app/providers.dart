/// Riverpod wiring — the seam between the database and the widgets.
///
/// The important property of this file: **the UI has no idea whether it is
/// running against SQLite or the demo ledger.** Every screen reads the same
/// providers, which return the same view models either way. That is what makes
/// the web preview an honest preview rather than a mock-up, and it is why the
/// device build and the preview can never drift apart visually.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The conditional import must name the *stub* explicitly: a bare filename would
// resolve relative to this file (lib/app/), not to lib/data/.
import '../data/connection_io.dart'
    if (dart.library.js_interop) '../data/connection_web.dart';
import '../data/db.dart';
import '../data/demo_data.dart';
import '../data/tx_repo.dart';
import '../domain/view_models.dart';
import '../ui/format.dart';
import '../ui/strings.dart';

/// The database, or null on a platform that has none (web).
final appDbProvider = Provider<AppDb?>((ref) {
  if (!hasDatabaseSupport) return null;
  final db = AppDb.open();
  ref.onDispose(db.close);
  return db;
});

/// True when the app is rendering the bundled ledger because there is no
/// database. The UI shows a small, honest banner in this mode — never a
/// pretend-"live" screen.
final demoModeProvider = Provider<bool>(
  (ref) => ref.watch(appDbProvider) == null,
);

final demoLedgerProvider = Provider<DemoLedger>((ref) => DemoLedger());

/// Everything resolved at cold start: whether onboarding is done, and which of
/// the three languages to open in.
class BootState {
  const BootState({
    required this.onboarded,
    required this.demoMode,
    required this.locale,
  });

  final bool onboarded;
  final bool demoMode;
  final String locale;
}

/// Runs once, behind the splash screen: open the database, seed it if this is
/// the first launch, and read the stored preferences.
final bootProvider = FutureProvider<BootState>((ref) async {
  final db = ref.watch(appDbProvider);

  if (db == null) {
    // Web preview: nothing to seed, nothing to read. Open in Bengali, because
    // the preview exists to show what a Bengali-first user sees.
    return const BootState(onboarded: true, demoMode: true, locale: 'bn');
  }

  await db.seedIfNeeded();

  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final deviceCode = deviceLocale.languageCode;
  final stored = await db.meta('locale');

  return BootState(
    onboarded: await db.onboarded,
    demoMode: false,
    locale:
        stored ??
        (SsStrings.supportedLocales.contains(deviceCode) ? deviceCode : 'en'),
  );
});

/// Active language: `bn` | `hi` | `en`. Switched instantly from Settings or the
/// language screen — no restart, no reload.
final localeProvider = StateProvider<String>((ref) => 'bn');

final stringsProvider = Provider<SsStrings>(
  (ref) => SsStrings(ref.watch(localeProvider)),
);

/// Light / dark / system. The design ships both themes; the user picks.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Free or Pro. Batch 7 (T-601) backs this with a real purchase; until then it
/// is what the paywall flips so the ad-free state can be reviewed.
final proStatusProvider = StateProvider<bool>((ref) => false);

// -----------------------------------------------------------------------------
// data
// -----------------------------------------------------------------------------

final transactionsProvider = FutureProvider<List<TxnView>>((ref) async {
  final db = ref.watch(appDbProvider);
  if (db == null) return ref.watch(demoLedgerProvider).transactions;
  final rows = await TxRepo(db).recent(limit: 500);
  return rows.map(TxnView.fromRow).toList();
});

final categoriesProvider = FutureProvider<List<CategoryView>>((ref) async {
  final db = ref.watch(appDbProvider);
  if (db == null) return ref.watch(demoLedgerProvider).categories;
  final rows = await db.select(db.categories).get();
  return rows
      .where((r) => r.deletedAt == null)
      .map(CategoryView.fromRow)
      .toList();
});

final accountsProvider = FutureProvider<List<AccountView>>((ref) async {
  final db = ref.watch(appDbProvider);
  if (db == null) return ref.watch(demoLedgerProvider).accounts;
  final rows = await db.select(db.accounts).get();
  return [
    for (final r in rows.where((r) => r.deletedAt == null))
      AccountView(
        id: r.id,
        name: r.name,
        type: r.type,
        openingBalancePaise: r.openingBalancePaise,
        last4: r.last4,
      ),
  ];
});

/// The overall monthly cap, or null when the user has not set one.
final overallBudgetProvider = FutureProvider<int?>((ref) async {
  final db = ref.watch(appDbProvider);
  if (db == null) return ref.watch(demoLedgerProvider).overallBudgetPaise;

  // Chained `where` calls: drift ANDs them, and no boolean-operator extension
  // (or its import) is needed in this file.
  final rows =
      await (db.select(db.budgets)
            ..where((b) => b.deletedAt.isNull())
            ..where((b) => b.categoryId.isNull()))
          .get();
  if (rows.isEmpty) return null;
  return rows.first.amountPaise;
});

/// Per-category caps, categoryId → paise.
final categoryBudgetsProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(appDbProvider);
  if (db == null) return ref.watch(demoLedgerProvider).budgetCaps;

  final rows = await (db.select(
    db.budgets,
  )..where((b) => b.deletedAt.isNull())).get();
  return {
    for (final r in rows)
      if (r.categoryId != null) r.categoryId!: r.amountPaise,
  };
});

// -----------------------------------------------------------------------------
// derived
// -----------------------------------------------------------------------------

/// The month the home screen and insights are showing.
final selectedMonthProvider = StateProvider<int>(
  (ref) => startOfMonth(DateTime.now().millisecondsSinceEpoch),
);

/// Income, expense and category split for the selected month.
final monthSummaryProvider = Provider<LedgerSummary>((ref) {
  final txns = ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[];
  final month = ref.watch(selectedMonthProvider);
  return LedgerSummary.from(txns, fromMs: month, toMs: endOfMonth(month));
});

/// The same figures for the previous month — the "১২% কম" comparison.
final previousMonthSummaryProvider = Provider<LedgerSummary>((ref) {
  final txns = ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[];
  final month = ref.watch(selectedMonthProvider);
  final prev = startOfPreviousMonth(month);
  return LedgerSummary.from(txns, fromMs: prev, toMs: endOfMonth(prev));
});

/// Expense totals for the last six months, oldest first — the Insights trend.
final sixMonthTrendProvider = Provider<List<int>>((ref) {
  final txns = ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[];
  final now = DateTime.now();
  return [
    for (var i = 5; i >= 0; i--)
      LedgerSummary.from(
        txns,
        fromMs: DateTime(now.year, now.month - i).millisecondsSinceEpoch,
        toMs: DateTime(now.year, now.month - i + 1).millisecondsSinceEpoch - 1,
      ).expensePaise,
  ];
});

/// Six short month labels matching [sixMonthTrendProvider].
final sixMonthLabelsProvider = Provider<List<String>>((ref) {
  final locale = ref.watch(localeProvider);
  final now = DateTime.now();
  return [
    for (var i = 5; i >= 0; i--)
      monthLabel(
        DateTime(now.year, now.month - i).millisecondsSinceEpoch,
        locale: locale,
      ).split(' ').first,
  ];
});

/// How many transactions are still unfiled — the badge on the Transactions tab.
final uncategorisedCountProvider = Provider<int>((ref) {
  final txns = ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[];
  return txns.where((t) => t.categoryId == null).length;
});

/// A category lookup by id, for the rows.
final categoryByIdProvider = Provider<Map<String, CategoryView>>((ref) {
  final list =
      ref.watch(categoriesProvider).valueOrNull ?? const <CategoryView>[];
  return {for (final c in list) c.id: c};
});

/// Whether ads should be visible at all — Pro is ad-free, and nothing shows
/// before onboarding finishes.
final adsVisibleProvider = Provider<bool>((ref) {
  final isPro = ref.watch(proStatusProvider);
  final boot = ref.watch(bootProvider).valueOrNull;
  return !isPro && (boot?.onboarded ?? false);
});
