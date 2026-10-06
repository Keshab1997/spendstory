/// The capture pipeline's front door — **steps ① → ⑦** of
/// `docs/06-SMS-PARSING.md` in one place, and the only class the Android layer
/// talks to.
///
/// Flow for every incoming message:
///
/// ```
/// ① OTP guard      → drop, never logged with a body
/// ② allowlist      → drop unknown senders
/// ③ parse          → amount / direction / merchant / date / account
/// ④ categorise     → rule engine, falling back to the raw text
/// ⑤ resolve account→ by last4, else the default account
/// ⑥ dedupe + write → TxRepo
/// ⑦ log            → parse_log (reason only, never the message)
/// ```
///
/// Deliberately Flutter-free: the Android `SmsReceiver` / notification listener
/// hand raw strings in, and everything below this line is testable in plain
/// Dart with an in-memory database.
library;

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../data/db.dart';
import '../data/tx_repo.dart';
import '../domain/models.dart';
import 'rule_engine.dart';
import 'sms_parser.dart';

const _uuid = Uuid();

enum CaptureStatus {
  /// A new transaction was written.
  added,

  /// We had already seen this payment. Nothing was written.
  duplicate,

  /// The message was not a transaction (or was a credential). Nothing was read.
  rejected,
}

class CaptureResult {
  const CaptureResult({
    required this.status,
    this.txnId,
    this.txn,
    this.categoryId,
    this.rejection,
    this.reason,
  });

  final CaptureStatus status;

  /// Set when [status] is [CaptureStatus.added].
  final String? txnId;

  /// The parsed transaction, when parsing got that far.
  final ParsedTxn? txn;

  /// Which category the rule engine picked, or null when the engine was not
  /// confident enough to file it.
  final String? categoryId;

  final ParseRejection? rejection;

  /// Human-readable detail for the local parse log.
  final String? reason;

  bool get written => status == CaptureStatus.added;
}

class CaptureService {
  CaptureService({
    required AppDb db,
    SmsParser? parser,
    RuleEngine? engine,
    TxRepo? repo,
    DateTime Function()? clock,
  }) : _db = db,
       parser = parser ?? SmsParser(),
       engine = engine ?? RuleEngine(),
       repo = repo ?? TxRepo(db),
       _clock = clock ?? DateTime.now;

  final AppDb _db;
  final SmsParser parser;
  final RuleEngine engine;
  final TxRepo repo;
  final DateTime Function() _clock;

  /// Handles one bank SMS. [sender] is the raw sender ID, prefix and all.
  Future<CaptureResult> handleSms({
    required String sender,
    required String body,
    required int timestampMs,
  }) {
    final outcome = parser.parseSms(
      sender: sender,
      body: body,
      smsTimestampMs: timestampMs,
    );
    return _ingest(outcome, channel: _Channel.sms, senderRef: sender);
  }

  /// Handles one payment-app notification.
  Future<CaptureResult> handleNotification({
    required String packageName,
    required String title,
    required String body,
    required int timestampMs,
  }) {
    final outcome = parser.parseNotification(
      packageName: packageName,
      title: title,
      body: body,
      timestampMs: timestampMs,
    );
    return _ingest(outcome, channel: _Channel.notif, senderRef: packageName);
  }

  Future<CaptureResult> _ingest(
    ParseOutcome outcome, {
    required _Channel channel,
    required String senderRef,
  }) async {
    final now = _clock().millisecondsSinceEpoch;

    if (!outcome.isParsed) {
      await _log(outcome: outcome, senderRef: senderRef, now: now);
      return CaptureResult(
        status: CaptureStatus.rejected,
        rejection: outcome.rejection,
        reason: outcome.rejection?.wire,
      );
    }

    final txn = outcome.txn!;

    // ④ categorise — a confident rule wins; anything vague stays unfiled so the
    // UI can ask instead of guessing wrong.
    final rule = engine.classify(merchant: txn.merchant, rawText: txn.rawText);
    final categoryId = rule.isConfident ? rule.categoryKey : null;

    // ⑤ point the transaction at an account: the one whose last4 matches, else
    // the user's default account.
    final accountId = await _resolveAccountId(txn.accountLast4);

    // ⑥ dedupe + write.
    final insert = await repo.insertParsed(
      txn,
      categoryId: categoryId,
      accountId: accountId,
    );

    await _log(outcome: outcome, senderRef: senderRef, now: now);

    if (!insert.isNew) {
      return CaptureResult(
        status: CaptureStatus.duplicate,
        txnId: insert.id,
        txn: txn,
        categoryId: categoryId,
        reason: 'already recorded',
      );
    }

    return CaptureResult(
      status: CaptureStatus.added,
      txnId: insert.id,
      txn: txn,
      categoryId: categoryId,
      reason: rule.matchedPattern == null
          ? 'filed without a rule'
          : 'matched "${rule.matchedPattern}" (${rule.confidence})',
    );
  }

  Future<String?> _resolveAccountId(String? last4) async {
    final accounts = await _db.select(_db.accounts).get();
    final live = accounts.where((a) => a.deletedAt == null).toList();
    if (live.isEmpty) return null;

    if (last4 != null) {
      for (final a in live) {
        if (a.last4 == last4) return a.id;
      }
    }
    for (final a in live) {
      if (a.isDefault) return a.id;
    }
    return live.first.id;
  }

  /// Writes one line to the local parse log. The message body never appears
  /// here — only the reason — so a shared log can never leak a bank SMS.
  Future<void> _log({
    required ParseOutcome outcome,
    required String senderRef,
    required int now,
  }) async {
    await _db
        .into(_db.parseLog)
        .insert(
          ParseLogCompanion.insert(
            id: _uuid.v4(),
            senderId: Value(senderRef),
            matched: outcome.isParsed,
            parserKey: Value(outcome.txn?.parserKey),
            failureReason: Value(outcome.rejection?.wire),
            createdAt: now,
          ),
        );
  }
}

enum _Channel { sms, notif }
