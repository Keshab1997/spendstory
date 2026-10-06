/// Duplicate suppression — **step ⑥** of the capture pipeline.
///
/// Two layers, because one is not enough in practice:
///
/// * [fingerprint] — a strict, storage-level unique key. Same amount, direction,
///   sender, account and minute → same hash. This is what the `dedupeHash`
///   UNIQUE index in `docs/05-DATA-MODEL.md` enforces, so a redelivered SMS can
///   never create a second row.
/// * [isNearDuplicate] — a softer check used when the *same* payment arrives
///   through two different channels: once as a bank SMS and once as a GPay
///   notification. Those arrive seconds-to-minutes apart with different text, so
///   fingerprints differ; amount + direction + a ten-minute window is the right
///   test. The caller keeps the richer record (usually the one with a merchant).
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../domain/models.dart';

class Dedupe {
  const Dedupe._();

  /// Fingerprints are bucketed to the minute so that the same transaction whose
  /// SMS body says `07-10-26` and whose receiver timestamp is a few seconds off
  /// still collapses to one row.
  static const int bucketMs = 60 * 1000;

  /// Window used for the cross-channel (SMS + notification) check.
  static const int nearWindowMs = 10 * 60 * 1000;

  /// Strict unique key for persistence.
  static String fingerprint({required ParsedTxn txn, String? senderKey}) {
    final bucket = txn.occurredAtMs ~/ bucketMs;
    final payload = <String>[
      txn.amountPaise.toString(),
      txn.direction.wire,
      bucket.toString(),
      (senderKey ?? txn.senderId ?? txn.sourceRef ?? '').toUpperCase(),
      txn.accountLast4 ?? '',
    ].join('|');
    return sha1.convert(utf8.encode(payload)).toString();
  }

  /// True when [a] and [b] look like the same real-world payment captured twice
  /// from different sources.
  static bool isNearDuplicate(
    ParsedTxn a,
    ParsedTxn b, {
    int windowMs = nearWindowMs,
  }) {
    if (a.amountPaise != b.amountPaise) return false;
    if (a.direction != b.direction) return false;
    final dt = (a.occurredAtMs - b.occurredAtMs).abs();
    if (dt > windowMs) return false;
    // Same source, same window → the fingerprint layer already handled it.
    return a.source != b.source;
  }

  /// Given a candidate and the records already stored nearby, picks the record
  /// worth keeping. Prefers the entry with a merchant and with more specific
  /// mode information, so an SMS alert (`paid to BigBasket, mode upi`) beats a
  /// bare notification (`₹1,240 paid`).
  static ParsedTxn preferDetailed(ParsedTxn a, ParsedTxn b) {
    final scoreA = _detailScore(a);
    final scoreB = _detailScore(b);
    return scoreB > scoreA ? b : a;
  }

  static int _detailScore(ParsedTxn t) {
    var s = 0;
    if (t.merchant != null && t.merchant!.isNotEmpty) s += 3;
    if (t.accountLast4 != null) s += 2;
    if (t.mode != PaymentMode.other) s += 1;
    if (t.source == TxSource.autoSms) {
      s += 1; // bank SMS is the authoritative text
    }
    return s;
  }
}
