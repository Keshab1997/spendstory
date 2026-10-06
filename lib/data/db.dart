/// The Drift database. One file, on the device, never synced.
///
/// Opening sequence matters and is deliberate:
///
/// 1. `PRAGMA foreign_keys = ON` — SQLite ships with enforcement *off*, so
///    without this a transaction could reference a category that does not exist.
/// 2. `PRAGMA journal_mode = WAL` — a capture can land while the UI is reading
///    the ledger, and a crash mid-write must not corrupt the database.
/// 3. Seeding runs once, outside the migration, so a re-install with a restored
///    backup never duplicates the built-in rules.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../capture/sender_allowlist.dart';
import 'seed.dart';
import 'tables.dart';

part 'db.g.dart';

@DriftDatabase(
  tables: [
    Transactions,
    Categories,
    Accounts,
    Budgets,
    RecurringRules,
    MerchantRules,
    SmsSenders,
    ParseLog,
    AppMeta,
  ],
)
class AppDb extends _$AppDb {
  AppDb(super.e);

  /// In-memory database for tests. Every test gets a clean slate, and nothing
  /// touches the file system.
  factory AppDb.memory() => AppDb(NativeDatabase.memory());

  /// The real thing: a file in the app's private documents directory.
  factory AppDb.open() => AppDb(_openConnection());

  static QueryExecutor _openConnection() => LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'spendstory.sqlite'));
    return NativeDatabase.createInBackground(file);
  });

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Additive migrations only — a column is never dropped from a shipped
      // schema, because a user's ledger is not something we can re-create.
      // Each new schema version adds one `if (from < N)` step here, and gets a
      // test that opens a database seeded at version N-1.
      throw StateError('no migration registered for v$from → v$to');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  /// Runs once per install: categories, the default cash account, the merchant
  /// rule table and the sender allowlist. Safe to call on every boot — it is a
  /// no-op after the first one.
  Future<SeedReport> seedIfNeeded() async {
    final report = await seedDatabase(this);
    await setMeta('ruleVersion', '${SenderAllowlist.ruleVersion}');
    return report;
  }

  /// Soft-deletes everything, for the DPDP "erase all my data" path. Rows stay
  /// until the next vacuum so an accidental tap can still be undone, but every
  /// query filters them out immediately.
  Future<void> softDeleteAll() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await transaction(() async {
      await (update(transactions)..where((t) => t.deletedAt.isNull())).write(
        TransactionsCompanion(deletedAt: Value(now)),
      );
      await (update(categories)..where((t) => t.isSystem.equals(false))).write(
        CategoriesCompanion(deletedAt: Value(now)),
      );
      await (update(budgets)..where((t) => t.deletedAt.isNull())).write(
        BudgetsCompanion(deletedAt: Value(now)),
      );
      await (update(recurringRules)..where((t) => t.deletedAt.isNull())).write(
        RecurringRulesCompanion(deletedAt: Value(now)),
      );
    });
  }

  /// Hard purge — only reachable after the double confirm in Settings.
  Future<void> purgeEverything() async {
    await transaction(() async {
      await delete(parseLog).go();
      await delete(transactions).go();
      await delete(budgets).go();
      await delete(recurringRules).go();
      await delete(merchantRules).go();
      await delete(smsSenders).go();
      await delete(accounts).go();
      await delete(categories).go();
      await delete(appMeta).go();
    });
  }

  /// Reads a setting, or null when it was never written.
  Future<String?> meta(String key) async {
    final row = await (select(
      appMeta,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Writes a setting.
  Future<void> setMeta(String key, String value) => into(appMeta)
      .insertOnConflictUpdate(AppMetaCompanion.insert(key: key, value: value));

  Future<bool> get onboarded async => (await meta('onboarded')) == 'true';
}
