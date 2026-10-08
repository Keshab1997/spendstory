/// `BackupRepo` — the encrypted export/restore and the CSV writer
/// (`docs/05 §4`, S-23 / T-705).
///
/// The file it writes is the *whole ledger*: transactions, categories,
/// accounts, budgets and recurring rules, plus the few preferences that belong
/// to the person rather than the phone. Restoring it into a fresh install has
/// to give back 100% of those — that is the acceptance line in `docs/03 §S-23`,
/// and it is what `test/export/backup_repo_test.dart` checks by comparing every
/// table before and after.
///
/// Three things are deliberately **not** in the file, because a backup must not
/// be a way to become Pro, and must not overwrite what this phone knows better:
///
/// * **Any entitlement or reward state** (`proStatus`, `proEntitlement`,
///   `reward:…`, `sessionCount`, `proLockTaps`, the trial reminder, the ads
///   consent flag). The store — not a file the user can edit — decides what
///   somebody paid for. Restore filters what it accepts through an allowlist
///   rather than trusting the file, so a hand-edited backup changes nothing.
/// * **The SMS sender allowlist.** It is seed data with a version number
///   (`ruleVersion`), not user data; a fresh install must keep the newer list.
/// * **Built-in merchant rules** — only the user's own overrides
///   (`isUserDefined`) travel, for the same reason: the app's own rules are
///   replaced by newer ones on every release.
///
/// Restore is an **upsert**, never a wipe: ids are stable, so restoring over an
/// install that already has data adds what is in the file and leaves the rest
/// alone. Reinstalling and restoring is the case the feature exists for; losing
/// something a user typed on the phone they are holding is not a risk worth
/// taking for a tidier implementation.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../app/app_info.dart';
import '../data/db.dart';
import '../domain/view_models.dart';
import 'backup_codec.dart';
import 'csv.dart';

/// The marker in a decoded payload, so a JSON file that is not ours is refused
/// before anything is written.
const String backupPayloadFormat = 'spendstory-backup';

/// The payload version. A file written by a newer app is refused rather than
/// half-understood.
const int backupPayloadVersion = 1;

/// Preferences that describe the person rather than this install. Everything
/// else in `app_meta` is device state: entitlements, counters, alerts.
const Set<String> backupMetaAllowlist = <String>{
  'locale',
  'theme',
  'lastBackupAt',
};

/// Everything a backup file carries, in memory.
class BackupPayload {
  const BackupPayload({
    required this.exportedAtMs,
    required this.appVersion,
    required this.schemaVersion,
    required this.categories,
    required this.accounts,
    required this.transactions,
    required this.budgets,
    required this.recurringRules,
    required this.merchantRules,
    required this.meta,
  });

  final int exportedAtMs;
  final String appVersion;
  final int schemaVersion;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> recurringRules;
  final List<Map<String, dynamic>> merchantRules;
  final Map<String, String> meta;

  /// How many transactions the file holds — the number the screen shows before
  /// it overwrites anything.
  int get transactionCount => transactions.length;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'format': backupPayloadFormat,
    'version': backupPayloadVersion,
    'exportedAtMs': exportedAtMs,
    'appVersion': appVersion,
    'schemaVersion': schemaVersion,
    'categories': categories,
    'accounts': accounts,
    'transactions': transactions,
    'budgets': budgets,
    'recurringRules': recurringRules,
    'merchantRules': merchantRules,
    'meta': meta,
  };

  String encode() => jsonEncode(toMap());

  /// Parses a decrypted payload. Throws [BackupFormatException] when the bytes
  /// are not a backup of this app, or are newer than this build understands.
  factory BackupPayload.decode(String text) {
    final Object? raw;
    try {
      raw = jsonDecode(text);
    } on FormatException {
      throw const BackupFormatException('The backup does not contain data.');
    }
    if (raw is! Map<String, dynamic>) {
      throw const BackupFormatException('The backup does not contain data.');
    }
    if (raw['format'] != backupPayloadFormat) {
      throw const BackupFormatException('Not a SpendStory backup file.');
    }
    final version = raw['version'];
    if (version is! int || version > backupPayloadVersion) {
      throw const BackupFormatException(
        'This backup was written by another version of the app.',
      );
    }
    return BackupPayload(
      exportedAtMs: (raw['exportedAtMs'] as num?)?.toInt() ?? 0,
      appVersion: raw['appVersion'] as String? ?? '',
      schemaVersion: (raw['schemaVersion'] as num?)?.toInt() ?? 0,
      categories: _rows(raw['categories']),
      accounts: _rows(raw['accounts']),
      transactions: _rows(raw['transactions']),
      budgets: _rows(raw['budgets']),
      recurringRules: _rows(raw['recurringRules']),
      merchantRules: _rows(raw['merchantRules']),
      meta: <String, String>{
        for (final entry
            in (raw['meta'] as Map?)?.entries ??
                const <MapEntry<String, Object?>>[])
          if (backupMetaAllowlist.contains(entry.key) && entry.value is String)
            entry.key as String: entry.value as String,
      },
    );
  }

  static List<Map<String, dynamic>> _rows(Object? value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return <Map<String, dynamic>>[
      for (final row in value)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }
}

/// What a restore put back, so the screen can say it out loud.
class RestoreReport {
  const RestoreReport({
    required this.transactions,
    required this.categories,
    required this.accounts,
    required this.budgets,
    required this.recurringRules,
    required this.merchantRules,
    required this.exportedAtMs,
    required this.appVersion,
  });

  final int transactions;
  final int categories;
  final int accounts;
  final int budgets;
  final int recurringRules;
  final int merchantRules;
  final int exportedAtMs;
  final String appVersion;

  int get total =>
      transactions +
      categories +
      accounts +
      budgets +
      recurringRules +
      merchantRules;
}

/// Whether the weekly reminder is owed. True when there has never been a backup
/// or the last one is older than [every].
///
/// A pure function on purpose: the weekly rule is the part that has to be
/// right, and it is decided by two dates rather than by a timer that only runs
/// while the app is open.
bool backupDue({
  required DateTime? lastBackupAt,
  required DateTime now,
  Duration every = const Duration(days: 7),
}) => lastBackupAt == null || now.difference(lastBackupAt) >= every;

/// Reads the database into a payload, writes it out encrypted, writes the CSV,
/// and puts a payload back.
class BackupRepo {
  BackupRepo(this._db);

  final AppDb _db;

  /// `spendstory-backup-2026-10-08.ssbk`. The extension is ours, so a file
  /// shared into a chat is recognisable — the picker still accepts any file and
  /// the codec's magic bytes are what actually decide whether it can be opened.
  static String suggestedFileName(DateTime now, {String extension = 'ssbk'}) {
    final stamp =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return 'spendstory-backup-$stamp.$extension';
  }

  /// Reads every table the file carries.
  Future<BackupPayload> collect({DateTime? now}) async {
    final liveCategories =
        await (_db.select(_db.categories)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
            .get();
    final liveAccounts =
        await (_db.select(_db.accounts)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
            .get();
    final liveTransactions =
        await (_db.select(_db.transactions)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm(expression: t.occurredAt)]))
            .get();
    final liveBudgets = await (_db.select(
      _db.budgets,
    )..where((t) => t.deletedAt.isNull())).get();
    final liveRecurring = await (_db.select(
      _db.recurringRules,
    )..where((t) => t.deletedAt.isNull())).get();
    final userRules = await (_db.select(
      _db.merchantRules,
    )..where((t) => t.isUserDefined.equals(true))).get();
    final metaRows = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.isIn(backupMetaAllowlist))).get();

    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return BackupPayload(
      exportedAtMs: nowMs,
      appVersion: AppInfo.version,
      schemaVersion: _db.schemaVersion,
      categories: [for (final row in liveCategories) row.toJson()],
      accounts: [for (final row in liveAccounts) row.toJson()],
      transactions: [for (final row in liveTransactions) row.toJson()],
      budgets: [for (final row in liveBudgets) row.toJson()],
      recurringRules: [for (final row in liveRecurring) row.toJson()],
      merchantRules: [for (final row in userRules) row.toJson()],
      meta: {for (final row in metaRows) row.key: row.value},
    );
  }

  /// Collects, encodes and encrypts — the bytes the share sheet gets.
  Future<Uint8List> encrypted({
    required String password,
    DateTime? now,
    int iterations = BackupCodec.defaultIterations,
  }) async {
    final payload = await collect(now: now);
    return BackupCodec.encrypt(
      plain: utf8.encode(payload.encode()),
      password: password,
      iterations: iterations,
    );
  }

  /// The free export: the same ledger, as a spreadsheet, in the language the
  /// user chose for the category and account names.
  Future<String> csv({
    Map<String, String> categoryNames = const <String, String>{},
    Map<String, String> accountNames = const <String, String>{},
  }) async {
    final rows =
        await (_db.select(_db.transactions)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm(expression: t.occurredAt)]))
            .get();
    return ledgerCsv(
      [for (final row in rows) TxnView.fromRow(row)],
      categoryNames: categoryNames,
      accountNames: accountNames,
    );
  }

  /// Decrypts and writes the payload back. Nothing is written until the whole
  /// file has been read and decoded, and the writes run in one transaction, so
  /// a wrong password or a damaged file leaves the database exactly as it was.
  Future<RestoreReport> restore(
    List<int> bytes, {
    required String password,
    DateTime? now,
  }) async {
    final plain = BackupCodec.decrypt(envelope: bytes, password: password);
    final payload = BackupPayload.decode(utf8.decode(plain));

    await _db.transaction(() async {
      for (final json in payload.categories) {
        await _db
            .into(_db.categories)
            .insertOnConflictUpdate(
              CategoryRow.fromJson(json).toCompanion(false),
            );
      }
      for (final json in payload.accounts) {
        await _db
            .into(_db.accounts)
            .insertOnConflictUpdate(
              AccountRow.fromJson(json).toCompanion(false),
            );
      }
      for (final json in payload.transactions) {
        await _db
            .into(_db.transactions)
            .insertOnConflictUpdate(TxnRow.fromJson(json).toCompanion(false));
      }
      for (final json in payload.budgets) {
        await _db
            .into(_db.budgets)
            .insertOnConflictUpdate(
              BudgetRow.fromJson(json).toCompanion(false),
            );
      }
      for (final json in payload.recurringRules) {
        await _db
            .into(_db.recurringRules)
            .insertOnConflictUpdate(
              RecurringRuleRow.fromJson(json).toCompanion(false),
            );
      }
      for (final json in payload.merchantRules) {
        await _db
            .into(_db.merchantRules)
            .insertOnConflictUpdate(
              MerchantRuleRow.fromJson(json).toCompanion(false),
            );
      }
      // Only the allowlisted preferences; the rest of `app_meta` belongs to
      // this install and to the store.
      for (final entry in payload.meta.entries) {
        if (!backupMetaAllowlist.contains(entry.key)) continue;
        await _db.setMeta(entry.key, entry.value);
      }
      await _db.setMeta('lastBackupAt', '${payload.exportedAtMs}');
      await _db.setMeta('onboarded', 'true');
    });

    return RestoreReport(
      transactions: payload.transactions.length,
      categories: payload.categories.length,
      accounts: payload.accounts.length,
      budgets: payload.budgets.length,
      recurringRules: payload.recurringRules.length,
      merchantRules: payload.merchantRules.length,
      exportedAtMs: payload.exportedAtMs,
      appVersion: payload.appVersion,
    );
  }
}
