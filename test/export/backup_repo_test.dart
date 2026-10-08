/// The acceptance line of `docs/03 §S-23`: "restore on fresh install returns
/// 100% of tx, categories, budgets, accounts".
///
/// So this file does exactly that, the long way: fills a database, writes a real
/// encrypted file, opens a *second, empty* install, restores, and then compares
/// every row — counts and contents — rather than trusting a count. It also
/// checks the two things that would make a backup dangerous rather than useful:
/// a file that did not come from this app must not grant Pro, and a wrong
/// password must not have written anything before it failed.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/capture/rule_engine.dart' show Cat;
import 'package:spendstory/data/db.dart';
import 'package:spendstory/export/backup_codec.dart';
import 'package:spendstory/export/backup_repo.dart';

const String _password = 'correct horse battery';
const int _iterations = 1000;

final DateTime _day = DateTime(2026, 10, 7, 20, 42);

int _ms(DateTime d) => d.millisecondsSinceEpoch;

/// A fresh install: an empty database plus the seed, which is what a reinstall
/// actually looks like.
Future<AppDb> _freshInstall() async {
  final db = AppDb.memory();
  await db.seedIfNeeded();
  return db;
}

/// The user's own data on top of the seed: a captured expense, a typed income, a
/// budget, a savings account and a recurring rule.
Future<void> _fill(AppDb db) async {
  await db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          id: 'tx-1',
          amountPaise: 124000,
          direction: 'expense',
          merchant: const Value('BigBasket'),
          note: const Value('weekly shopping, rice + dal'),
          categoryId: Value(Cat.grocery),
          occurredAt: _ms(_day),
          createdAt: _ms(_day),
          updatedAt: _ms(_day),
          source: 'auto_sms',
          rawText: const Value('Rs.1240.00 debited from a/c XX4421'),
          dedupeHash: 'hash-1',
        ),
      );
  await db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          id: 'tx-2',
          amountPaise: 4500000,
          direction: 'income',
          merchant: const Value('Payroll'),
          categoryId: Value(Cat.salary),
          occurredAt: _ms(_day.subtract(const Duration(days: 2))),
          createdAt: _ms(_day),
          updatedAt: _ms(_day),
          source: 'manual',
          dedupeHash: 'hash-2',
        ),
      );
  await db
      .into(db.budgets)
      .insert(
        BudgetsCompanion.insert(
          id: 'bud-1',
          categoryId: Value(Cat.grocery),
          amountPaise: 600000,
          startDay: const Value(5),
        ),
      );
  await db
      .into(db.accounts)
      .insert(
        AccountsCompanion.insert(
          id: 'acc-savings',
          name: 'Savings',
          type: 'bank',
          openingBalancePaise: const Value(2500000),
          last4: const Value('4421'),
        ),
      );
  await db
      .into(db.recurringRules)
      .insert(
        RecurringRulesCompanion.insert(
          id: 'rec-1',
          title: 'Rent',
          amountPaise: 1800000,
          direction: 'expense',
          categoryId: Value(Cat.rent),
          frequency: 'monthly',
          nextDueAt: _ms(_day.add(const Duration(days: 5))),
        ),
      );
  // A preference, and three pieces of device state that must not travel.
  await db.setMeta('locale', 'bn');
  await db.setMeta('proStatus', 'free');
  await db.setMeta('sessionCount', '17');
  await db.setMeta('reward:pdfExport:2026-10-07', '2');
}

Future<Uint8List> _backupOf(AppDb db) =>
    BackupRepo(db)
        .encrypted(password: _password, now: _day, iterations: _iterations);

/// Every row of the four tables the acceptance line names, as data.
Future<Map<String, List<Map<String, Object?>>>> _snapshot(AppDb db) async {
  Future<List<Map<String, Object?>>> rows(String table) async {
    final result = await db
        .customSelect('SELECT * FROM $table ORDER BY id')
        .get();
    return [for (final row in result) row.data.map((k, v) => MapEntry(k, v))];
  }

  return <String, List<Map<String, Object?>>>{
    'transactions': await rows('transactions'),
    'categories': await rows('categories'),
    'budgets': await rows('budgets'),
    'accounts': await rows('accounts'),
  };
}

void main() {
  group('writing a backup', () {
    test('holds the whole ledger, and no entitlements', () async {
      final db = await _freshInstall();
      addTearDown(db.close);
      await _fill(db);

      final payload = await BackupRepo(db).collect(now: _day);

      expect(payload.transactions, hasLength(2));
      expect(payload.categories, isNotEmpty);
      expect(payload.budgets, hasLength(1));
      expect(payload.accounts, hasLength(2)); // the seeded cash one + savings
      expect(payload.recurringRules, hasLength(1));
      expect(payload.exportedAtMs, _ms(_day));

      // A preference travels; the store's answer and this phone's counters do
      // not.
      expect(payload.meta['locale'], 'bn');
      expect(payload.meta.containsKey('proStatus'), isFalse);
      expect(payload.meta.containsKey('sessionCount'), isFalse);
      expect(payload.meta.keys, everyElement(isIn(backupMetaAllowlist)));
    });

    test('writes a file that is not the plaintext ledger', () async {
      final db = await _freshInstall();
      addTearDown(db.close);
      await _fill(db);

      final bytes = await _backupOf(db);

      expect(bytes.sublist(0, 4), BackupCodec.magic);
      // The merchant the user shopped at must not be readable in the file.
      final printable = String.fromCharCodes(
        bytes.where((b) => b >= 32 && b < 127),
      );
      expect(printable, isNot(contains('BigBasket')));
      // Nor the SMS the row was captured from, note the amount it carries.
      expect(printable, isNot(contains('Rs.1240.00')));
      expect(printable, isNot(contains('XX4421')));
    });
  });

  group('restoring into a fresh install', () {
    test(
      'returns 100% of transactions, categories, budgets and accounts',
      () async {
        final source = await _freshInstall();
        addTearDown(source.close);
        await _fill(source);
        final before = await _snapshot(source);
        final bytes = await _backupOf(source);

        final fresh = await _freshInstall();
        addTearDown(fresh.close);
        final report = await BackupRepo(fresh)
            .restore(bytes, password: _password);

        final after = await _snapshot(fresh);

        expect(after['transactions'], before['transactions']);
        expect(after['categories'], before['categories']);
        expect(after['budgets'], before['budgets']);
        expect(after['accounts'], before['accounts']);

        // And the screen is told what came back.
        expect(report.transactions, 2);
        expect(report.budgets, 1);
        expect(report.accounts, 2);
        expect(report.appVersion, isNotEmpty);
      },
    );

    test('does not duplicate the seed it lands on', () async {
      final source = await _freshInstall();
      addTearDown(source.close);
      await _fill(source);
      final bytes = await _backupOf(source);

      final fresh = await _freshInstall();
      addTearDown(fresh.close);
      final seededCategories =
          (await fresh.select(fresh.categories).get()).length;

      await BackupRepo(fresh).restore(bytes, password: _password);
      // Twice, because a user who is not sure will press it again.
      await BackupRepo(fresh).restore(bytes, password: _password);

      expect(
        (await fresh.select(fresh.categories).get()).length,
        seededCategories,
      );
      expect((await fresh.select(fresh.transactions).get()).length, 2);
    });

    test('adds to a phone that already has a ledger', () async {
      final source = await _freshInstall();
      addTearDown(source.close);
      await _fill(source);
      final bytes = await _backupOf(source);

      final used = await _freshInstall();
      addTearDown(used.close);
      await used
          .into(used.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'tx-other',
              amountPaise: 5000,
              direction: 'expense',
              occurredAt: _ms(_day),
              createdAt: _ms(_day),
              updatedAt: _ms(_day),
              source: 'manual',
              dedupeHash: 'hash-other',
            ),
          );

      await BackupRepo(used).restore(bytes, password: _password);

      final ids = (await used.select(used.transactions).get())
          .map((row) => row.id)
          .toSet();
      expect(ids, containsAll(<String>{'tx-1', 'tx-2', 'tx-other'}));
    });

    test(
      'marks the install onboarded, and remembers when the backup was taken',
      () async {
        final source = await _freshInstall();
        addTearDown(source.close);
        await _fill(source);
        final bytes = await _backupOf(source);

        final fresh = await _freshInstall();
        addTearDown(fresh.close);

        await BackupRepo(fresh).restore(bytes, password: _password);

        expect(await fresh.meta('onboarded'), 'true');
        expect(await fresh.meta('lastBackupAt'), '${_ms(_day)}');
        // The preference came back with it…
        expect(await fresh.meta('locale'), 'bn');
        // …and nothing about the source phone's plans or counters did.
        expect(await fresh.meta('sessionCount'), isNot('17'));
        expect(await fresh.meta('reward:pdfExport:2026-10-07'), isNull);
      },
    );

    test('cannot be used to become Pro', () async {
      final source = await _freshInstall();
      addTearDown(source.close);
      await _fill(source);

      // A real payload with the meta section edited by hand — the exact file a
      // user with a hex editor and an interest in free Pro would produce.
      final payload = await BackupRepo(source).collect(now: _day);
      final doctored = <String, dynamic>{
        ...payload.toMap(),
        'meta': <String, String>{
          ...payload.meta,
          'proStatus': 'pro',
          'proEntitlement': '{"plan":"lifetime"}',
          'reward:pdfExport:2026-10-07': '99',
        },
      };
      final bytes = BackupCodec.encrypt(
        plain: utf8.encode(jsonEncode(doctored)),
        password: _password,
        iterations: _iterations,
      );

      final fresh = await _freshInstall();
      addTearDown(fresh.close);
      await BackupRepo(fresh).restore(bytes, password: _password);

      // The ledger still comes back — the file is not rejected — but the parts
      // that decide what the user paid for are simply not read from it.
      expect((await fresh.select(fresh.transactions).get()).length, 2);
      expect(await fresh.meta('proStatus'), isNot('pro'));
      expect(await fresh.meta('proEntitlement'), isNot(contains('lifetime')));
      expect(await fresh.meta('reward:pdfExport:2026-10-07'), isNull);
    });
  });

  group('when something is wrong with the file', () {
    test('a wrong password leaves the database exactly as it was', () async {
      final source = await _freshInstall();
      addTearDown(source.close);
      await _fill(source);
      final bytes = await _backupOf(source);

      final fresh = await _freshInstall();
      addTearDown(fresh.close);
      final before = await _snapshot(fresh);

      expect(
        () => BackupRepo(fresh).restore(bytes, password: 'wrong password'),
        throwsA(isA<BackupFormatException>()),
      );

      expect(await _snapshot(fresh), before);
    });

    test(
      'a file that is not a backup is refused before anything is written',
      () async {
        final fresh = await _freshInstall();
        addTearDown(fresh.close);
        final before = await _snapshot(fresh);

        expect(
          () => BackupRepo(fresh).restore(
            Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7, 8]),
            password: _password,
          ),
          throwsA(isA<BackupFormatException>()),
        );

        expect(await _snapshot(fresh), before);
      },
    );
  });

  group('the weekly reminder', () {
    test('is due when there has never been a backup', () {
      expect(backupDue(lastBackupAt: null, now: _day), isTrue);
    });

    test('is due once a week has passed, and not before', () {
      expect(
        backupDue(
          lastBackupAt: _day.subtract(const Duration(days: 6)),
          now: _day,
        ),
        isFalse,
      );
      expect(
        backupDue(
          lastBackupAt: _day.subtract(const Duration(days: 7)),
          now: _day,
        ),
        isTrue,
      );
      expect(
        backupDue(
          lastBackupAt: _day.subtract(const Duration(days: 30)),
          now: _day,
        ),
        isTrue,
      );
    });
  });
}
