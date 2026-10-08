/// Riverpod wiring — the seam between the database and the widgets.
///
/// The important property of this file: **the UI has no idea whether it is
/// running against SQLite or the demo ledger.** Every screen reads the same
/// providers, which return the same view models either way. That is what makes
/// the web preview an honest preview rather than a mock-up, and it is why the
/// device build and the preview can never drift apart visually.
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The conditional import must name the *stub* explicitly: a bare filename would
// resolve relative to this file (lib/app/), not to lib/data/.
import '../data/connection_io.dart'
    if (dart.library.js_interop) '../data/connection_web.dart';
import '../data/db.dart';
import '../data/demo_data.dart';
import '../data/tx_repo.dart';
import '../domain/models.dart';
import '../domain/view_models.dart';
import '../platform/permissions.dart';
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

/// How the permission screens talk to the platform. Overridden in tests, where
/// there is no Android host to answer (see [PermissionsApi]).
final permissionsProvider = Provider<PermissionsApi>(
  (ref) => const DevicePermissions(),
);

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

/// ---------------------------------------------------------------------------
/// The session overlay
///
/// Everything below exists because the app has two backends: SQLite on a phone,
/// and nothing at all in the web preview and in widget tests. Rather than give
/// the preview a fake read-only ledger that ignores the user, writes land in
/// these in-memory overlays and the same screens respond exactly as they would
/// on a device. Nothing here survives a reload, and that is correct — a preview
/// is a preview, not a database.
/// ---------------------------------------------------------------------------

/// Rows deleted in this session while there is no database. On a device a
/// delete is a real soft delete in SQLite.
final sessionDeletedIdsProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);

/// Rows edited in this session while there is no database: id → the new row.
final sessionPatchesProvider = StateProvider<Map<String, TxnView>>(
  (ref) => const <String, TxnView>{},
);

/// Rows added in this session while there is no database, newest first.
final sessionAddedProvider = StateProvider<List<TxnView>>(
  (ref) => const <TxnView>[],
);

/// Categories created or edited in this session while there is no database.
final sessionCategoryPatchesProvider = StateProvider<Map<String, CategoryView>>(
  (ref) => const <String, CategoryView>{},
);

final sessionCategoryDeletedProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);

/// Budgets created or edited in this session while there is no database.
final sessionBudgetPatchesProvider = StateProvider<Map<String, BudgetView>>(
  (ref) => const <String, BudgetView>{},
);

final sessionBudgetDeletedProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);

/// Accounts created or edited in this session while there is no database.
final sessionAccountPatchesProvider = StateProvider<Map<String, AccountView>>(
  (ref) => const <String, AccountView>{},
);

final sessionAccountDeletedProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);

final transactionsProvider = FutureProvider<List<TxnView>>((ref) async {
  final db = ref.watch(appDbProvider);
  final deleted = ref.watch(sessionDeletedIdsProvider);
  final patches = ref.watch(sessionPatchesProvider);
  final added = ref.watch(sessionAddedProvider);

  final base = db == null
      ? ref.watch(demoLedgerProvider).transactions
      : (await TxRepo(db).recent(limit: 500)).map(TxnView.fromRow).toList();

  final rows = <TxnView>[
    for (final t in <TxnView>[...added, ...base])
      if (!deleted.contains(t.id)) patches[t.id] ?? t,
  ];
  // One ordering rule for both backends, so a row the user just added appears
  // where its date says it belongs rather than always on top.
  rows.sort((a, b) => b.occurredAtMs.compareTo(a.occurredAtMs));
  return rows;
});

/// Every write the ledger screens can perform, in one place.
///
/// Two backends, one contract: with a database the change is persisted through
/// [TxRepo] (soft delete, so Undo is real rather than a re-insert); without one
/// it lands in the session overlays above. Callers never branch on which.
class TxActions {
  const TxActions(this._ref);

  final Ref _ref;

  Future<void> delete(String id) async {
    final db = _ref.read(appDbProvider);
    if (db == null) {
      _ref
          .read(sessionDeletedIdsProvider.notifier)
          .update((ids) => <String>{...ids, id});
      return;
    }
    await TxRepo(db).softDelete(id);
    _ref.invalidate(transactionsProvider);
  }

  /// Undo. The row was never actually removed, so this restores it rather than
  /// writing a new one — the id, the raw SMS and the capture history survive.
  Future<void> restore(String id) async {
    final db = _ref.read(appDbProvider);
    if (db == null) {
      _ref
          .read(sessionDeletedIdsProvider.notifier)
          .update((ids) => <String>{...ids}..remove(id));
      return;
    }
    await TxRepo(db).restore(id);
    _ref.invalidate(transactionsProvider);
  }

  Future<void> setCategory(String id, String categoryId) async {
    final current = _find(id);
    if (current == null) return;
    await update(current.copyWith(categoryId: categoryId));
  }

  /// Applies an edited row (S-12 in edit mode).
  Future<void> update(TxnView updated) async {
    final db = _ref.read(appDbProvider);
    if (db == null) {
      _ref
          .read(sessionPatchesProvider.notifier)
          .update((map) => <String, TxnView>{...map, updated.id: updated});
      // A row added in this session is replaced in place, so an edit of an edit
      // does not resurrect the original.
      _ref
          .read(sessionAddedProvider.notifier)
          .update(
            (list) => <TxnView>[
              for (final t in list)
                if (t.id == updated.id) updated else t,
            ],
          );
      return;
    }
    await TxRepo(db).updateManual(
      updated.id,
      amountPaise: updated.amountPaise,
      categoryId: updated.categoryId,
      merchant: updated.merchant,
      note: updated.note,
      occurredAt: updated.occurredAtMs,
      mode: updated.mode.wire,
    );
    _ref.invalidate(transactionsProvider);
  }

  /// Saves a transaction the user typed in (S-12 in add mode).
  Future<String> add({
    required int amountPaise,
    required TxnDirection direction,
    required int occurredAtMs,
    String? merchant,
    String? categoryId,
    String? accountId,
    PaymentMode mode = PaymentMode.cash,
    String? note,
  }) async {
    final db = _ref.read(appDbProvider);
    if (db == null) {
      final id = 'session-${DateTime.now().microsecondsSinceEpoch}';
      _ref
          .read(sessionAddedProvider.notifier)
          .update(
            (list) => <TxnView>[
              TxnView(
                id: id,
                amountPaise: amountPaise,
                direction: direction,
                occurredAtMs: occurredAtMs,
                merchant: merchant,
                categoryId: categoryId,
                mode: mode,
                note: note,
              ),
              ...list,
            ],
          );
      return id;
    }
    final id = await TxRepo(db).insertManual(
      amountPaise: amountPaise,
      direction: direction,
      occurredAt: occurredAtMs,
      merchant: merchant,
      categoryId: categoryId,
      accountId: accountId,
      mode: mode,
      note: note,
    );
    _ref.invalidate(transactionsProvider);
    return id;
  }

  TxnView? _find(String id) {
    final all =
        _ref.read(transactionsProvider).valueOrNull ?? const <TxnView>[];
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}

final txActionsProvider = Provider<TxActions>((ref) => TxActions(ref));

final categoriesProvider = FutureProvider<List<CategoryView>>((ref) async {
  final db = ref.watch(appDbProvider);
  final patches = ref.watch(sessionCategoryPatchesProvider);
  final deleted = ref.watch(sessionCategoryDeletedProvider);

  final base = db == null
      ? ref.watch(demoLedgerProvider).categories
      : (await db.select(db.categories).get())
            .where((r) => r.deletedAt == null)
            .map(CategoryView.fromRow)
            .toList();

  final known = {for (final c in base) c.id};
  return <CategoryView>[
    for (final c in base)
      if (!deleted.contains(c.id)) patches[c.id] ?? c,
    // Categories created in this session, which have no row behind them yet.
    for (final entry in patches.entries)
      if (!known.contains(entry.key) && !deleted.contains(entry.key))
        entry.value,
  ];
});

/// Create / edit / delete for the category manager (S-13).
class CategoryActions {
  const CategoryActions(this._ref);

  final Ref _ref;

  Future<void> save(CategoryView category) async {
    final db = _ref.read(appDbProvider);
    if (db == null) {
      _ref
          .read(sessionCategoryPatchesProvider.notifier)
          .update(
            (map) => <String, CategoryView>{...map, category.id: category},
          );
      return;
    }
    await db
        .into(db.categories)
        .insertOnConflictUpdate(
          CategoriesCompanion.insert(
            id: category.id,
            kind: category.kind.wire,
            nameEn: category.nameEn,
            nameHi: category.nameHi,
            nameBn: category.nameBn,
            icon: category.icon,
            colorHex: category.colorHex,
            monthlyCapPaise: Value(category.monthlyCapPaise),
          ),
        );
    _ref.invalidate(categoriesProvider);
  }

  /// Hides a category. Rows already filed under it keep their id — reassigning
  /// someone's history behind their back would be worse than an orphan label,
  /// and the list falls back to the merchant name.
  Future<void> delete(String id) async {
    final db = _ref.read(appDbProvider);
    if (db == null) {
      _ref
          .read(sessionCategoryDeletedProvider.notifier)
          .update((ids) => <String>{...ids, id});
      return;
    }
    await (db.update(db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    _ref.invalidate(categoriesProvider);
  }
}

final categoryActionsProvider = Provider<CategoryActions>(
  (ref) => CategoryActions(ref),
);

final accountsProvider = FutureProvider<List<AccountView>>((ref) async {
  final db = ref.watch(appDbProvider);
  final patches = ref.watch(sessionAccountPatchesProvider);
  final deleted = ref.watch(sessionAccountDeletedProvider);

  final base = db == null
      ? ref.watch(demoLedgerProvider).accounts
      : [
          for (final r in (await db.select(db.accounts).get()).where(
            (r) => r.deletedAt == null,
          ))
            AccountView(
              id: r.id,
              name: r.name,
              type: r.type,
              openingBalancePaise: r.openingBalancePaise,
              last4: r.last4,
              colorHex: r.colorHex,
            ),
        ];

  final known = {for (final a in base) a.id};
  return <AccountView>[
    for (final a in base)
      if (!deleted.contains(a.id)) patches[a.id] ?? a,
    // Accounts created in this session, which have no row behind them yet.
    for (final entry in patches.entries)
      if (!known.contains(entry.key) && !deleted.contains(entry.key))
        entry.value,
  ];
});

/// Computed balances, accountId → paise.
///
/// Balance is *opening + income − expense* and is never stored
/// (`docs/05-DATA-MODEL.md` §2). With a database the sum runs in SQL over the
/// whole table; without one it is folded from the same transaction list every
/// screen already reads, so the web preview shows a balance that moves when the
/// user adds a row.
final accountBalancesProvider = FutureProvider<Map<String, int>>((ref) async {
  final accounts = ref.watch(accountsProvider).valueOrNull;
  if (accounts == null || accounts.isEmpty) return const <String, int>{};

  final db = ref.watch(appDbProvider);
  if (db == null) {
    final txns = ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[];
    final balances = <String, int>{
      for (final a in accounts) a.id: a.openingBalancePaise,
    };
    for (final t in txns) {
      final id = t.accountId;
      if (id == null || !balances.containsKey(id)) continue;
      balances[id] =
          balances[id]! +
          (t.direction == TxnDirection.income ? t.amountPaise : -t.amountPaise);
    }
    return balances;
  }

  final repo = TxRepo(db);
  return {
    for (final a in accounts) a.id: await repo.balancePaise(a.id),
  };
});

/// Create / edit / delete for the accounts screen (S-16).
class AccountActions {
  const AccountActions(this._ref);

  final Ref _ref;

  Future<void> save(AccountView account) async {
    final db = _ref.read(appDbProvider);
    if (db == null) {
      _ref
          .read(sessionAccountPatchesProvider.notifier)
          .update((map) => <String, AccountView>{...map, account.id: account});
      return;
    }
    await db
        .into(db.accounts)
        .insertOnConflictUpdate(
          AccountsCompanion.insert(
            id: account.id,
            name: account.name,
            type: account.type,
            openingBalancePaise: Value(account.openingBalancePaise),
            last4: Value(account.last4),
            colorHex: Value(account.colorHex),
          ),
        );
    _ref.invalidate(accountsProvider);
  }

  /// Soft-hides an account, like a category. The transactions that ran through
  /// it keep their `accountId`: a hidden account must not silently rewrite the
  /// history it holds.
  Future<void> delete(String id) async {
    final db = _ref.read(appDbProvider);
    if (db == null) {
      _ref
          .read(sessionAccountDeletedProvider.notifier)
          .update((ids) => <String>{...ids, id});
      return;
    }
    await (db.update(db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    _ref.invalidate(accountsProvider);
  }
}

final accountActionsProvider = Provider<AccountActions>(
  (ref) => AccountActions(ref),
);

/// Every budget row, database or demo.
final budgetsProvider = FutureProvider<List<BudgetView>>((ref) async {
  final db = ref.watch(appDbProvider);
  final patches = ref.watch(sessionBudgetPatchesProvider);
  final deleted = ref.watch(sessionBudgetDeletedProvider);

  final base = db == null
      ? ref.watch(demoLedgerProvider).budgets
      : [
          for (final r in (await db.select(db.budgets).get()).where(
            (r) => r.deletedAt == null,
          ))
            BudgetView.fromRow(r),
        ];

  final known = {for (final b in base) b.id};
  return <BudgetView>[
    for (final b in base)
      if (!deleted.contains(b.id)) patches[b.id] ?? b,
    for (final entry in patches.entries)
      if (!known.contains(entry.key) && !deleted.contains(entry.key))
        entry.value,
  ];
});

/// The overall monthly cap, or null when the user has not set one.
final overallBudgetProvider = FutureProvider<int?>((ref) async {
  final budgets = await ref.watch(budgetsProvider.future);
  for (final b in budgets) {
    if (b.isOverall) return b.amountPaise;
  }
  return null;
});

/// Per-category caps, categoryId → paise.
final categoryBudgetsProvider = FutureProvider<Map<String, int>>((ref) async {
  final budgets = await ref.watch(budgetsProvider.future);
  return {
    for (final b in budgets)
      if (b.categoryId != null) b.categoryId!: b.amountPaise,
  };
});

/// The overall budget row itself, for the list and the detail route.
final overallBudgetRowProvider = FutureProvider<BudgetView?>((ref) async {
  final budgets = await ref.watch(budgetsProvider.future);
  for (final b in budgets) {
    if (b.isOverall) return b;
  }
  return null;
});

/// Create / edit / delete for the budget screens (S-14, S-15).
class BudgetActions {
  const BudgetActions(this._ref);

  final Ref _ref;

  Future<void> save(BudgetView budget) async {
    final db = _ref.read(appDbProvider);
    if (db == null) {
      _ref
          .read(sessionBudgetPatchesProvider.notifier)
          .update((map) => <String, BudgetView>{...map, budget.id: budget});
      return;
    }
    await db
        .into(db.budgets)
        .insertOnConflictUpdate(
          BudgetsCompanion.insert(
            id: budget.id,
            categoryId: Value(budget.categoryId),
            period: Value(budget.period),
            amountPaise: budget.amountPaise,
            startDay: Value(budget.startDay),
            alertAt80: Value(budget.alertAt80),
            alertAt100: Value(budget.alertAt100),
            startsOn: Value(budget.startsOn),
            endsOn: Value(budget.endsOn),
          ),
        );
    _ref.invalidate(budgetsProvider);
  }

  /// Removes the cap, not the spending: the rows that were counted against it
  /// keep their category and stay in the ledger.
  Future<void> delete(String id) async {
    final db = _ref.read(appDbProvider);
    if (db == null) {
      _ref
          .read(sessionBudgetDeletedProvider.notifier)
          .update((ids) => <String>{...ids, id});
      return;
    }
    await (db.update(db.budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    _ref.invalidate(budgetsProvider);
  }
}

final budgetActionsProvider = Provider<BudgetActions>(
  (ref) => BudgetActions(ref),
);

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
