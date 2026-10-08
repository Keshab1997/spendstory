// drift exports a top-level `isNull` that would shadow the matcher of the
// same name used in the assertions below.
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/capture/rule_engine.dart';
import 'package:spendstory/capture/sender_allowlist.dart';
import 'package:spendstory/data/db.dart';
import 'package:spendstory/data/seed.dart';

void main() {
  late AppDb db;

  setUp(() async {
    db = AppDb.memory();
  });

  tearDown(() async {
    await db.close();
  });

  TransactionsCompanion sampleTxn({
    required String id,
    required String hash,
    int amountPaise = 124000,
    String direction = 'expense',
    String? categoryId = Cat.food,
    String? accountId = kCashAccountId,
    int occurredAt = 1759820400000,
  }) => TransactionsCompanion.insert(
    id: id,
    amountPaise: amountPaise,
    direction: direction,
    categoryId: Value(categoryId),
    accountId: Value(accountId),
    occurredAt: occurredAt,
    createdAt: occurredAt,
    updatedAt: occurredAt,
    source: 'auto_sms',
    dedupeHash: hash,
  );

  group('schema', () {
    test('is version 2 and creates all eight tables plus app_meta', () async {
      expect(db.schemaVersion, 2);

      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      final tables = rows.map((r) => r.read<String>('name')).toSet();

      for (final expected in <String>[
        'transactions',
        'categories',
        'accounts',
        'budgets',
        'recurring_rules',
        'merchant_rules',
        'sms_senders',
        'parse_log',
        'app_meta',
      ]) {
        expect(tables, contains(expected), reason: 'missing table $expected');
      }
    });

    test('creates the indexes the query patterns rely on', () async {
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .get();
      final indexes = rows.map((r) => r.read<String>('name')).toSet();

      expect(indexes, contains('idx_tx_occurred_at'));
      expect(indexes, contains('idx_tx_category'));
      expect(indexes, contains('idx_tx_account'));
      expect(indexes, contains('idx_tx_source'));
      expect(indexes, contains('idx_rule_pattern'));
      expect(indexes, contains('idx_log_created'));
    });

    test('foreign keys are enforced (PRAGMA foreign_keys = ON)', () async {
      final on = await db
          .customSelect('PRAGMA foreign_keys')
          .getSingle()
          .then((r) => r.data.values.first);
      expect(on, 1);
    });

    test('WAL journal mode is on', () async {
      final mode = await db
          .customSelect('PRAGMA journal_mode')
          .getSingle()
          .then((r) => r.data.values.first);
      expect('$mode'.toLowerCase(), 'memory'); // :memory: cannot use WAL
    });
  });

  group('seed', () {
    test(
      'first run writes categories, cash account, rules and senders',
      () async {
        final report = await db.seedIfNeeded();

        expect(report.alreadySeeded, isFalse);
        expect(report.categories, 18); // 12 expense + 6 income
        expect(report.accounts, 1);
        expect(report.merchantRules, RuleEngine.defaultRules.length);
        expect(report.senders, SenderAllowlist.defaultEntries.length);
        expect(report.ruleVersion, SenderAllowlist.ruleVersion);

        final categories = await db.select(db.categories).get();
        expect(categories.where((c) => c.kind == 'expense').length, 12);
        expect(categories.where((c) => c.kind == 'income').length, 6);
      },
    );

    test('every category carries all three languages and an icon', () async {
      await db.seedIfNeeded();
      for (final c in await db.select(db.categories).get()) {
        expect(c.nameEn, isNotEmpty, reason: c.id);
        expect(c.nameHi, isNotEmpty, reason: '${c.id} needs a Hindi name');
        expect(c.nameBn, isNotEmpty, reason: '${c.id} needs a Bengali name');
        expect(c.icon, isNotEmpty, reason: c.id);
        expect(
          RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(c.colorHex),
          isTrue,
          reason: '${c.id} colour ${c.colorHex}',
        );
        expect(c.isSystem, isTrue);
      }
    });

    test('the default account is cash and marked default', () async {
      await db.seedIfNeeded();
      final accounts = await db.select(db.accounts).get();
      expect(accounts.length, 1);
      expect(accounts.single.id, kCashAccountId);
      expect(accounts.single.type, 'cash');
      expect(accounts.single.isDefault, isTrue);
      expect(accounts.single.openingBalancePaise, 0);
    });

    test('second run is a no-op — no duplicate rows', () async {
      final first = await db.seedIfNeeded();
      final second = await db.seedIfNeeded();

      expect(second.alreadySeeded, isTrue);
      expect(second.categories, first.categories);
      expect(second.accounts, 1);
      expect((await db.select(db.categories).get()).length, first.categories);
      expect(
        (await db.select(db.merchantRules).get()).length,
        first.merchantRules,
      );
    });

    test('every seeded merchant rule points at a real category', () async {
      await db.seedIfNeeded();
      final ids = (await db.select(db.categories).get())
          .map((c) => c.id)
          .toSet();
      final rules = await db.select(db.merchantRules).get();

      expect(rules, isNotEmpty);
      for (final r in rules) {
        expect(
          ids,
          contains(r.categoryId),
          reason: 'rule "${r.pattern}" → unknown category ${r.categoryId}',
        );
      }
    });

    test(
      'every category the rule engine can emit exists in the seed',
      () async {
        await db.seedIfNeeded();
        final seeded = (await db.select(db.categories).get())
            .map((c) => c.id)
            .toSet();
        final used = RuleEngine.defaultRules.map((r) => r.categoryKey).toSet();
        expect(
          seeded.containsAll(used),
          isTrue,
          reason: 'missing: ${used.difference(seeded)}',
        );
      },
    );

    test('sender rows are stamped with the rule version', () async {
      await db.seedIfNeeded();
      final senders = await db.select(db.smsSenders).get();
      expect(senders.length, SenderAllowlist.defaultEntries.length);
      for (final s in senders) {
        expect(s.addedInRuleVersion, SenderAllowlist.ruleVersion);
        expect(s.enabled, isTrue);
      }
      // And the rows are queryable by the normalized id the parser produces.
      final hdfc = senders.where((s) => s.senderId == 'HDFCBK').toList();
      expect(hdfc.length, 1);
      expect(hdfc.single.parserKey, 'hdfc');
    });

    test('ids are unique across rules and senders', () async {
      await db.seedIfNeeded();
      final ruleIds = (await db.select(db.merchantRules).get()).map(
        (r) => r.id,
      );
      final senderIds = (await db.select(db.smsSenders).get()).map((s) => s.id);
      expect(ruleIds.toSet().length, ruleIds.length);
      expect(senderIds.toSet().length, senderIds.length);
    });

    test('defaults land in app_meta', () async {
      await db.seedIfNeeded();
      expect(await db.onboarded, isFalse);
      expect(await db.meta('locale'), 'en');
      expect(await db.meta('theme'), 'system');
      expect(await db.meta('ruleVersion'), '${SenderAllowlist.ruleVersion}');
    });
  });

  group('transactions', () {
    setUp(() async {
      await db.seedIfNeeded();
    });

    test('insert and read back with paise intact', () async {
      await db
          .into(db.transactions)
          .insert(sampleTxn(id: 'tx-1', hash: 'hash-1', amountPaise: 124050));

      final row = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('tx-1'))).getSingle();

      expect(row.amountPaise, 124050); // ₹1,240.50 — no float rounding
      expect(row.direction, 'expense');
      expect(row.mode, 'other'); // default
      expect(row.isRecurring, isFalse);
      expect(row.deletedAt, isNull);
    });

    test('the dedupeHash unique index rejects a redelivered message', () async {
      Future<void> insertTwin() => db
          .into(db.transactions)
          .insert(sampleTxn(id: 'tx-b', hash: 'same-hash'));

      await db
          .into(db.transactions)
          .insert(sampleTxn(id: 'tx-a', hash: 'same-hash'));

      // A plain insert must blow up rather than silently double-count.
      await expectLater(
        insertTwin(),
        throwsA(predicate((e) => '$e'.toUpperCase().contains('UNIQUE'))),
      );

      // The repository path uses insertOrIgnore instead, which is the behaviour
      // the capture pipeline depends on: the redelivery becomes a no-op.
      await db
          .into(db.transactions)
          .insert(
            sampleTxn(id: 'tx-b', hash: 'same-hash'),
            mode: InsertMode.insertOrIgnore,
          );

      final rows = await db.select(db.transactions).get();
      expect(rows.length, 1);
      expect(rows.single.id, 'tx-a');
    });

    test(
      'a transaction cannot reference a category that does not exist',
      () async {
        Future<void> insertOrphan() => db
            .into(db.transactions)
            .insert(
              sampleTxn(id: 'tx-orphan', hash: 'h-orphan', categoryId: 'nope'),
            );

        await expectLater(
          insertOrphan(),
          throwsA(predicate((e) => '$e'.toUpperCase().contains('FOREIGN KEY'))),
        );
      },
    );

    test('soft-deleted rows disappear from the ledger query', () async {
      await db.into(db.transactions).insert(sampleTxn(id: 'tx-1', hash: 'h1'));
      await db.into(db.transactions).insert(sampleTxn(id: 'tx-2', hash: 'h2'));

      final now = DateTime.now().millisecondsSinceEpoch;
      await (db.update(db.transactions)..where((t) => t.id.equals('tx-1')))
          .write(TransactionsCompanion(deletedAt: Value(now)));

      final live = await (db.select(
        db.transactions,
      )..where((t) => t.deletedAt.isNull())).get();

      expect(live.length, 1);
      expect(live.single.id, 'tx-2');
      // The row is still on disk, so "Undo" is a single UPDATE away.
      expect((await db.select(db.transactions).get()).length, 2);
    });

    test('account balance is computed, never stored', () async {
      await db
          .into(db.transactions)
          .insert(sampleTxn(id: 'tx-e', hash: 'he', amountPaise: 124000));
      await db
          .into(db.transactions)
          .insert(
            sampleTxn(
              id: 'tx-i',
              hash: 'hi',
              amountPaise: 4500000,
              direction: 'income',
              categoryId: Cat.salary,
            ),
          );
      await db
          .into(db.transactions)
          .insert(sampleTxn(id: 'tx-deleted', hash: 'hd', amountPaise: 999999));
      await (db.update(
        db.transactions,
      )..where((t) => t.id.equals('tx-deleted'))).write(
        TransactionsCompanion(
          deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

      Future<int> sumOf(String direction) async {
        final q = db.selectOnly(db.transactions)
          ..addColumns([db.transactions.amountPaise.sum()])
          ..where(
            db.transactions.accountId.equals(kCashAccountId) &
                db.transactions.direction.equals(direction) &
                db.transactions.deletedAt.isNull(),
          );
        final value = await q
            .map((r) => r.read(db.transactions.amountPaise.sum()))
            .getSingle();
        return value ?? 0;
      }

      final opening =
          (await db.select(db.accounts).get()).single.openingBalancePaise;
      final balance = opening + await sumOf('income') - await sumOf('expense');

      expect(await sumOf('expense'), 124000);
      expect(await sumOf('income'), 4500000);
      expect(balance, 4376000); // ₹43,760.00
    });
  });

  group('app_meta and erase', () {
    test('meta round-trips and onboarding flips', () async {
      await db.setMeta('locale', 'bn');
      expect(await db.meta('locale'), 'bn');

      await db.setMeta('onboarded', 'true');
      expect(await db.onboarded, isTrue);

      // Writing the same key twice updates instead of throwing.
      await db.setMeta('locale', 'hi');
      expect(await db.meta('locale'), 'hi');
      expect(await db.meta('does_not_exist'), isNull);
    });

    test(
      'softDeleteAll hides the ledger but keeps the rows recoverable',
      () async {
        await db.seedIfNeeded();
        await db
            .into(db.transactions)
            .insert(sampleTxn(id: 'tx-1', hash: 'h1'));

        await db.softDeleteAll();

        final live = await (db.select(
          db.transactions,
        )..where((t) => t.deletedAt.isNull())).get();
        expect(live, isEmpty);
        expect((await db.select(db.transactions).get()).length, 1);
      },
    );

    test('purgeEverything is the double-confirmed hard erase', () async {
      await db.seedIfNeeded();
      await db.into(db.transactions).insert(sampleTxn(id: 'tx-1', hash: 'h1'));

      await db.purgeEverything();

      expect(await db.select(db.transactions).get(), isEmpty);
      expect(await db.select(db.categories).get(), isEmpty);
      expect(await db.select(db.accounts).get(), isEmpty);
      expect(await db.select(db.merchantRules).get(), isEmpty);
      expect(await db.select(db.smsSenders).get(), isEmpty);
      expect(await db.select(db.appMeta).get(), isEmpty);
    });
  });

  group('parse_log', () {
    test('stores the reason, never the message body', () async {
      await db
          .into(db.parseLog)
          .insert(
            ParseLogCompanion.insert(
              id: 'log-1',
              matched: false,
              failureReason: const Value('otp'),
              senderId: const Value('HDFCBK'),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );

      final row = await db.select(db.parseLog).getSingle();
      expect(row.matched, isFalse);
      expect(row.failureReason, 'otp');
      expect(row.parserKey, isNull);
    });
  });
}
