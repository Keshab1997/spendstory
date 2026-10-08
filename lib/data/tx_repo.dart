/// Transaction repository — the only place that writes the ledger.
///
/// Every write goes through here so that three invariants hold no matter which
/// caller is responsible:
///
/// 1. **Money stays in paise.** Nothing in this file ever converts to rupees.
/// 2. **Dedupe is enforced at two levels** — the `dedupeHash` unique index for
///    redelivered messages, and a near-duplicate check for the same payment
///    arriving through two channels (a bank SMS and a payment-app notification).
/// 3. **Deletes are soft.** `softDelete` stamps `deletedAt`; the row stays until
///    the user's undo window closes, which is what makes the snackbar honest.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../capture/dedupe.dart';
import '../domain/models.dart';
import 'db.dart';

const _uuid = Uuid();

/// Outcome of a write attempt, so callers can report the truth to the user
/// ("added" vs "এই লেনদেনটা আগেই ছিল").
enum InsertOutcome { added, duplicate }

/// What came back from a write. [id] is the row that now holds the transaction:
/// the new row when [outcome] is [InsertOutcome.added], and the row we already
/// had when it is a duplicate — which is what the "already recorded" banner
/// links to.
class InsertResult {
  const InsertResult(this.outcome, this.id);

  final InsertOutcome outcome;
  final String? id;

  bool get isNew => outcome == InsertOutcome.added;
}

class TxRepo {
  TxRepo(this.db);

  final AppDb db;

  /// Inserts a parsed transaction, or reports that it was already known.
  ///
  /// [categoryId] and [accountId] come from the capture service, which is the
  /// only layer that knows about the rule engine and the account list.
  Future<InsertResult> insertParsed(
    ParsedTxn txn, {
    String? categoryId,
    String? accountId,
  }) async {
    final hash = Dedupe.fingerprint(txn: txn);

    final existing = await (db.select(
      db.transactions,
    )..where((t) => t.dedupeHash.equals(hash))).getSingleOrNull();
    if (existing != null) {
      return InsertResult(InsertOutcome.duplicate, existing.id);
    }

    // Cross-channel duplicate: the same payment seen by both the bank SMS and
    // the payment app's notification. Keep whichever record carries more detail
    // rather than inserting two rows.
    final near = await _findNearDuplicate(txn);
    if (near != null) {
      final keepNew = Dedupe.preferDetailed(_rowToParsed(near), txn) == txn;
      if (keepNew) {
        await (db.update(
          db.transactions,
        )..where((t) => t.id.equals(near.id))).write(
          TransactionsCompanion(
            merchant: Value(txn.merchant ?? near.merchant),
            categoryId: Value(categoryId ?? near.categoryId),
            accountId: Value(accountId ?? near.accountId),
            mode: Value(txn.mode.wire),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
      }
      return InsertResult(InsertOutcome.duplicate, near.id);
    }

    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            amountPaise: txn.amountPaise,
            direction: txn.direction.wire,
            merchant: Value(txn.merchant),
            categoryId: Value(categoryId),
            accountId: Value(accountId),
            mode: Value(txn.mode.wire),
            occurredAt: txn.occurredAtMs,
            createdAt: now,
            updatedAt: now,
            source: txn.source.wire,
            sourceRef: Value(txn.sourceRef ?? txn.senderId),
            rawText: Value(txn.rawText),
            dedupeHash: hash,
          ),
        );

    return InsertResult(InsertOutcome.added, id);
  }

  Future<TxnRow?> _findNearDuplicate(ParsedTxn txn) async {
    final from = txn.occurredAtMs - Dedupe.nearWindowMs;
    final to = txn.occurredAtMs + Dedupe.nearWindowMs;

    final rows =
        await (db.select(db.transactions)
              ..where(
                (t) =>
                    t.deletedAt.isNull() &
                    t.amountPaise.equals(txn.amountPaise) &
                    t.direction.equals(txn.direction.wire) &
                    t.occurredAt.isBetweenValues(from, to),
              )
              ..limit(5))
            .get();

    for (final row in rows) {
      if (row.source == txn.source.wire) continue;
      if (Dedupe.isNearDuplicate(_rowToParsed(row), txn)) return row;
    }
    return null;
  }

  /// The live ledger, newest first.
  Stream<List<TxnRow>> watchRecent({int limit = 200}) {
    return (db.select(db.transactions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  Future<List<TxnRow>> recent({int limit = 200, int offset = 0}) {
    return (db.select(db.transactions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<TxnRow>> inRange(int fromMs, int toMs) {
    return (db.select(db.transactions)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.occurredAt.isBiggerOrEqualValue(fromMs) &
                t.occurredAt.isSmallerOrEqualValue(toMs),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<TxnRow?> byId(String id) => (db.select(
    db.transactions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Inserts a transaction the user typed in themselves (S-12).
  ///
  /// Deliberately **not** routed through [insertParsed]: a manual entry has no
  /// message to fingerprint, and running it through the dedupe path would let
  /// two genuine ₹20 chai payments five minutes apart collapse into one. The
  /// user is the authority on what they just typed.
  Future<String> insertManual({
    required int amountPaise,
    required TxnDirection direction,
    required int occurredAt,
    String? merchant,
    String? categoryId,
    String? accountId,
    PaymentMode mode = PaymentMode.cash,
    String? note,
    TxSource source = TxSource.manual,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            amountPaise: amountPaise,
            direction: direction.wire,
            merchant: Value(merchant),
            categoryId: Value(categoryId),
            accountId: Value(accountId),
            mode: Value(mode.wire),
            occurredAt: occurredAt,
            createdAt: now,
            updatedAt: now,
            source: source.wire,
            note: Value(note),
            // Unique per row: a manual entry must never collide with another.
            dedupeHash: 'manual:$id',
          ),
        );
    return id;
  }

  /// Soft delete — the undo snackbar's whole mechanism.
  Future<void> softDelete(String id) async {
    await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Puts a soft-deleted row back, used by "Undo".
  Future<void> restore(String id) async {
    await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      const TransactionsCompanion(deletedAt: Value(null)),
    );
  }

  /// Edits a transaction the user tapped into.
  Future<void> updateManual(
    String id, {
    int? amountPaise,
    String? categoryId,
    String? merchant,
    String? note,
    int? occurredAt,
    String? mode,
  }) async {
    await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        amountPaise: amountPaise == null
            ? const Value.absent()
            : Value(amountPaise),
        categoryId: categoryId == null
            ? const Value.absent()
            : Value(categoryId),
        merchant: merchant == null ? const Value.absent() : Value(merchant),
        note: note == null ? const Value.absent() : Value(note),
        occurredAt: occurredAt == null
            ? const Value.absent()
            : Value(occurredAt),
        mode: mode == null ? const Value.absent() : Value(mode),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Computed balance: opening + income − expense. Never stored, never stale.
  Future<int> balancePaise(String accountId) async {
    final account = await (db.select(
      db.accounts,
    )..where((a) => a.id.equals(accountId))).getSingleOrNull();
    if (account == null) return 0;

    final income = await _sumOf(accountId, TxnDirection.income.wire);
    final expense = await _sumOf(accountId, TxnDirection.expense.wire);
    return account.openingBalancePaise + income - expense;
  }

  Future<int> _sumOf(String accountId, String direction) async {
    final query = db.selectOnly(db.transactions)
      ..addColumns([db.transactions.amountPaise.sum()])
      ..where(
        db.transactions.accountId.equals(accountId) &
            db.transactions.direction.equals(direction) &
            db.transactions.deletedAt.isNull(),
      );
    final value = await query
        .map((row) => row.read(db.transactions.amountPaise.sum()))
        .getSingle();
    return value ?? 0;
  }

  /// Totals for one direction in a date range — the building block for the
  /// home hero card and the monthly roll-ups.
  Future<int> totalPaise({
    required String direction,
    required int fromMs,
    required int toMs,
    String? categoryId,
  }) async {
    final query = db.selectOnly(db.transactions)
      ..addColumns([db.transactions.amountPaise.sum()])
      ..where(
        db.transactions.direction.equals(direction) &
            db.transactions.occurredAt.isBiggerOrEqualValue(fromMs) &
            db.transactions.occurredAt.isSmallerOrEqualValue(toMs) &
            db.transactions.deletedAt.isNull(),
      );
    if (categoryId != null) {
      query.where(db.transactions.categoryId.equals(categoryId));
    }
    final value = await query
        .map((row) => row.read(db.transactions.amountPaise.sum()))
        .getSingle();
    return value ?? 0;
  }

  static ParsedTxn _rowToParsed(TxnRow row) => ParsedTxn(
    amountPaise: row.amountPaise,
    direction: TxnDirection.fromWire(row.direction) ?? TxnDirection.expense,
    occurredAtMs: row.occurredAt,
    source: TxSource.values.firstWhere(
      (s) => s.wire == row.source,
      orElse: () => TxSource.manual,
    ),
    parserKey: row.sourceRef ?? 'unknown',
    merchant: row.merchant,
    accountLast4: null,
    mode: PaymentMode.fromWire(row.mode),
    senderId: row.sourceRef,
    rawText: row.rawText,
  );
}
