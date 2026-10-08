// The one test that guards a shipped schema: an install that already has a
// ledger must open after an upgrade, keep every row, and gain whatever the new
// version adds. `lib/data/db.dart` has one `if (from < N)` step per version and
// this file has one test per step.
//
// drift exports a top-level `isNull` that would shadow the matcher of the same
// name used in the assertions below.
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spendstory/data/db.dart';

void main() {
  late Directory tmp;
  late File file;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('spendstory-migration');
    file = File(p.join(tmp.path, 'spendstory.sqlite'));
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  /// Writes a database in the shape v1 shipped in, with one row already in it.
  ///
  /// v1 is v2 with one table less and the version pragma rewound, so that is
  /// exactly how it is built here: no hand-copied CREATE TABLE statements to
  /// drift away from the real schema.
  Future<void> writeV1File() async {
    final fresh = AppDb(NativeDatabase(file));
    await fresh
        .into(fresh.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 'v1-tx',
            amountPaise: 4200,
            direction: 'expense',
            occurredAt: 1759820400000,
            createdAt: 1759820400000,
            updatedAt: 1759820400000,
            source: 'manual',
            dedupeHash: 'v1-hash',
          ),
        );
    await fresh.customStatement('DROP TABLE recurring_rules');
    await fresh.customStatement('PRAGMA user_version = 1');
    await fresh.close();
  }

  test('a v1 database reopens at v2 with recurring rules and its ledger', () async {
    await writeV1File();

    final db = AppDb(NativeDatabase(file));
    addTearDown(db.close);

    // The upgrade ran rather than a re-create: the v1 row is still here.
    final txns = await db.select(db.transactions).get();
    expect(txns.map((t) => t.id), <String>['v1-tx']);
    expect(txns.single.amountPaise, 4200);

    // And the table v2 adds is real — writable and readable, not just declared.
    await db
        .into(db.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            id: 'rule-rent',
            title: 'Rent',
            amountPaise: 1800000,
            direction: 'expense',
            frequency: 'monthly',
            interval: const Value<int>(1),
            dayOfMonth: const Value<int>(5),
            nextDueAt: 1760000000000,
          ),
        );
    final rules = await db.select(db.recurringRules).get();
    expect(rules.single.title, 'Rent');
    expect(rules.single.interval, 1);
    expect(rules.single.dayOfMonth, 5);
    expect(rules.single.autoPost, isFalse);
  });
}
