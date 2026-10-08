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
import '../data/budget_alerts.dart';
import '../data/connection_io.dart'
    if (dart.library.js_interop) '../data/connection_web.dart';
import '../data/db.dart';
import '../data/demo_data.dart';
import '../data/recurring_tasks.dart';
import '../data/tx_repo.dart';
import '../domain/budget_math.dart';
import '../domain/models.dart';
import '../domain/view_models.dart';
import '../platform/native_bridge.dart';
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

/// The clock, as a provider.
///
/// Screens that divide by "days left" are only as testable as their idea of
/// today, so the one thing they are allowed to read is this. Overridden in
/// tests; never overridden in the app.
final nowProvider = Provider<DateTime>((ref) => DateTime.now());

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
    TxSource source = TxSource.manual,
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
                // The demo path used to drop this, so a row that named an
                // account looked account-less in the preview.
                accountId: accountId,
                mode: mode,
                source: source.wire,
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
      source: source,
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
    final txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[];
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
  return {for (final a in accounts) a.id: await repo.balancePaise(a.id)};
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
      BudgetsCompanion(deletedAt: Value(DateTime.now().millisecondsSinceEpoch)),
    );
    _ref.invalidate(budgetsProvider);
  }
}

final budgetActionsProvider = Provider<BudgetActions>(
  (ref) => BudgetActions(ref),
);

// -----------------------------------------------------------------------------
// budget alerts (T-505)
// -----------------------------------------------------------------------------

/// Every budget, spent and rated — exactly what the budget screen draws.
///
/// Alerts read this rather than re-adding the numbers themselves: a warning
/// that disagrees with the bar it is warning about is worse than no warning.
/// A Future on purpose: `valueOrNull` on a provider nobody has started yet is
/// null, and an alert pipeline that silently sees an empty ledger would decide
/// there was nothing to warn about. Awaiting both makes "no budgets" and "not
/// loaded yet" impossible to confuse.
final budgetStatusesProvider = FutureProvider<List<BudgetStatus>>((ref) async {
  final budgets = await ref.watch(budgetsProvider.future);
  final txns = await ref.watch(transactionsProvider.future);
  final nowMs = ref.watch(nowProvider).millisecondsSinceEpoch;

  return <BudgetStatus>[
    for (final budget in budgets)
      budgetStatus(txns: txns, budget: budget, nowMs: nowMs),
  ];
});

/// Posting one notification. The seam every notification in the app goes
/// through, so a test can watch what was sent without an Android host anywhere
/// near it — budget alerts and recurring reminders alike.
final notificationPosterProvider =
    Provider<Future<bool> Function(int id, String title, String body)>(
      (ref) =>
          (id, title, body) =>
              NativeBridge.postNotification(id: id, title: title, body: body),
    );

/// What posting a budget alert actually means.
final budgetAlertSenderProvider = Provider<Future<bool> Function(BudgetAlert)>((
  ref,
) {
  final post = ref.watch(notificationPosterProvider);
  return (alert) => post(alert.notificationId, alert.title, alert.body);
});

/// The day each alert was last delivered, for the demo/web build where there is
/// no database to write the record to.
final sessionAlertsSentProvider = StateProvider<Map<String, String>>(
  (ref) => const <String, String>{},
);

/// Runs the alert check and returns what actually went out.
///
/// Called when the shell appears and whenever the ledger changes; the
/// once-a-day cap is what makes calling it that often safe.
typedef BudgetAlertRunner = Future<List<BudgetAlert>> Function();

final budgetAlertRunnerProvider = Provider<BudgetAlertRunner>((ref) {
  return () async {
    final statuses = await ref.read(budgetStatusesProvider.future);
    if (statuses.isEmpty) return const <BudgetAlert>[];

    final today = alertDay(ref.read(nowProvider));
    final db = ref.read(appDbProvider);

    // Read back what has already been delivered. The database is the record on
    // a phone; the session map stands in for it in the demo build.
    final sentOn = <String, String>{};
    if (db == null) {
      sentOn.addAll(ref.read(sessionAlertsSentProvider));
    } else {
      for (final status in statuses) {
        for (final level in const ['80', '100']) {
          final key = 'budget:${status.budget.id}:$level';
          final day = await db.meta('alert:$key');
          if (day != null) sentOn[key] = day;
        }
      }
    }

    // The category names go in the body ("Food: ₹150 left"), so the categories
    // have to be loaded before `categoryByIdProvider` is read — it answers from
    // whatever has arrived, and an empty map here means the alert says
    // "Category budget" instead of naming the one that is nearly spent.
    await ref.read(categoriesProvider.future);

    final owed = owedBudgetAlerts(
      statuses: statuses,
      strings: ref.read(stringsProvider),
      locale: ref.read(localeProvider),
      today: today,
      sentOn: sentOn,
      categories: ref.read(categoryByIdProvider),
    );
    if (owed.isEmpty) return const <BudgetAlert>[];

    final send = ref.read(budgetAlertSenderProvider);
    final delivered = <BudgetAlert>[];

    for (final alert in owed) {
      var ok = false;
      try {
        ok = await send(alert);
      } catch (_) {
        // A host that cannot post is not a crash: the alert stays owed.
        ok = false;
      }
      if (!ok) continue;

      delivered.add(alert);
      if (db == null) {
        ref
            .read(sessionAlertsSentProvider.notifier)
            .update((map) => <String, String>{...map, alert.key: today});
      } else {
        await db.setMeta('alert:${alert.key}', today);
      }
    }

    return delivered;
  };
});

// -----------------------------------------------------------------------------
// recurring rules (T-506)
// -----------------------------------------------------------------------------

final sessionRecurringPatchesProvider =
    StateProvider<Map<String, RecurringRuleView>>(
      (ref) => const <String, RecurringRuleView>{},
    );

final sessionRecurringDeletedProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);

final sessionRecurringAddedProvider = StateProvider<List<RecurringRuleView>>(
  (ref) => const <RecurringRuleView>[],
);

/// What the recurring pipeline has already done, for the demo build where there
/// is no database to write the record to. On a phone both maps live in
/// `app_meta`, keyed `recurring-posted:<id>:<due day>` and
/// `recurring-reminded:<id>:<due day>`.
final sessionRecurringPostedProvider = StateProvider<Map<String, String>>(
  (ref) => const <String, String>{},
);

final sessionRecurringRemindedProvider = StateProvider<Map<String, String>>(
  (ref) => const <String, String>{},
);

/// Rent, EMIs, subscriptions — same shape as every other list provider: the
/// database on a phone, the demo rules on the web, and the session overlay in
/// both so an edit is visible immediately.
final recurringProvider = FutureProvider<List<RecurringRuleView>>((ref) async {
  final db = ref.watch(appDbProvider);
  final patches = ref.watch(sessionRecurringPatchesProvider);
  final deleted = ref.watch(sessionRecurringDeletedProvider);

  final base = db == null
      ? <RecurringRuleView>[
          ...ref.watch(sessionRecurringAddedProvider),
          ...ref.watch(demoLedgerProvider).recurring,
        ]
      : [
          for (final r in (await db.select(db.recurringRules).get()).where(
            (r) => r.deletedAt == null,
          ))
            RecurringRuleView.fromRow(r),
        ];
  base.sort((a, b) => a.nextDueAt.compareTo(b.nextDueAt));

  final known = {for (final r in base) r.id};
  return <RecurringRuleView>[
    for (final r in base)
      if (!deleted.contains(r.id)) patches[r.id] ?? r,
    for (final entry in patches.entries)
      if (!known.contains(entry.key) && !deleted.contains(entry.key))
        entry.value,
  ];
});

/// Create, edit and delete rules (S-19).
class RecurringActions {
  const RecurringActions(this._ref);

  final Ref _ref;

  Future<void> save(RecurringRuleView rule) async {
    final db = _ref.read(appDbProvider);
    if (db == null) {
      _ref
          .read(sessionRecurringPatchesProvider.notifier)
          .update((map) => <String, RecurringRuleView>{...map, rule.id: rule});
      return;
    }
    await db
        .into(db.recurringRules)
        .insertOnConflictUpdate(
          RecurringRulesCompanion.insert(
            id: rule.id,
            title: rule.title,
            amountPaise: rule.amountPaise,
            direction: rule.direction.wire,
            categoryId: Value(rule.categoryId),
            accountId: Value(rule.accountId),
            frequency: rule.frequency,
            interval: Value(rule.interval),
            dayOfMonth: Value(rule.dayOfMonth),
            nextDueAt: rule.nextDueAt,
            autoPost: Value(rule.autoPost),
            remindDaysBefore: Value(rule.remindDaysBefore),
          ),
        );
    _ref.invalidate(recurringProvider);
  }

  /// Stops the rule. Payments it already posted stay in the ledger, because
  /// they happened.
  Future<void> delete(String id) async {
    final db = _ref.read(appDbProvider);
    if (db == null) {
      _ref
          .read(sessionRecurringDeletedProvider.notifier)
          .update((ids) => <String>{...ids, id});
      return;
    }
    await (db.update(db.recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    _ref.invalidate(recurringProvider);
  }
}

final recurringActionsProvider = Provider<RecurringActions>(
  (ref) => RecurringActions(ref),
);

/// What one pass of the recurring pipeline did — the return value is what the
/// tests assert on.
typedef RecurringRun = ({
  List<RecurringPost> posted,
  List<RecurringReminder> reminded,
});

typedef RecurringRunner = Future<RecurringRun> Function();

const String _kPostedPrefix = 'recurring-posted:';
const String _kRemindedPrefix = 'recurring-reminded:';

/// Posts what is due: the payments auto-post promised, and the reminders.
///
/// Runs on the same two triggers as the budget alerts (shell start-up, ledger
/// change). Every action is recorded against the due date it belongs to, which
/// is what makes running this often safe.
final recurringRunnerProvider = Provider<RecurringRunner>((ref) {
  return () async {
    final rules = await ref.read(recurringProvider.future);
    if (rules.isEmpty) {
      return (posted: <RecurringPost>[], reminded: <RecurringReminder>[]);
    }

    final now = ref.read(nowProvider);
    final nowMs = now.millisecondsSinceEpoch;
    final today = alertDay(now);
    final db = ref.read(appDbProvider);

    Future<Map<String, String>> records(String prefix) async {
      if (db == null) {
        return Map<String, String>.from(
          prefix == _kPostedPrefix
              ? ref.read(sessionRecurringPostedProvider)
              : ref.read(sessionRecurringRemindedProvider),
        );
      }
      final rows = await db.metaWithPrefix(prefix);
      return <String, String>{
        for (final row in rows) row.key.substring(prefix.length): row.value,
      };
    }

    Future<void> remember(String prefix, String key, String day) async {
      if (db == null) {
        final notifier = prefix == _kPostedPrefix
            ? ref.read(sessionRecurringPostedProvider.notifier)
            : ref.read(sessionRecurringRemindedProvider.notifier);
        notifier.update((map) => <String, String>{...map, key: day});
        return;
      }
      await db.setMeta('$prefix$key', day);
    }

    final posted = <RecurringPost>[];
    final toPost = dueRecurringPosts(
      rules: rules,
      nowMs: nowMs,
      postedOn: await records(_kPostedPrefix),
    );

    for (final post in toPost) {
      await ref
          .read(txActionsProvider)
          .add(
            amountPaise: post.rule.amountPaise,
            direction: post.rule.direction,
            occurredAtMs: post.dueMs,
            merchant: post.rule.title,
            categoryId: post.rule.categoryId,
            accountId: post.rule.accountId,
            source: TxSource.recurring,
          );
      await ref
          .read(recurringActionsProvider)
          .save(
            post.rule.copyWith(
              nextDueAt: nextDueAfterPost(post: post, nowMs: nowMs),
            ),
          );
      await remember(_kPostedPrefix, post.key, today);
      posted.add(post);
    }

    // A rule that just posted itself is not also reminded about.
    final advanced = <String, RecurringRuleView>{
      for (final post in posted)
        post.rule.id: post.rule.copyWith(
          nextDueAt: nextDueAfterPost(post: post, nowMs: nowMs),
        ),
    };

    final reminded = <RecurringReminder>[];
    final owed = owedRecurringReminders(
      rules: [for (final rule in rules) advanced[rule.id] ?? rule],
      strings: ref.read(stringsProvider),
      locale: ref.read(localeProvider),
      nowMs: nowMs,
      sentOn: await records(_kRemindedPrefix),
    );

    final send = ref.read(notificationPosterProvider);
    for (final reminder in owed) {
      var ok = false;
      try {
        ok = await send(reminder.notificationId, reminder.title, reminder.body);
      } catch (_) {
        ok = false;
      }
      if (!ok) continue;
      await remember(_kRemindedPrefix, reminder.key, today);
      reminded.add(reminder);
    }

    return (posted: posted, reminded: reminded);
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

/// Expense totals for the last six months, oldest first. The S-17 rewrite
/// draws a 30-day line instead, so nothing on a screen reads this yet — it is
/// kept for the MiniBars component and the home trend still to come.
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
