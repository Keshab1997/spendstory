import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/capture/dedupe.dart';
import 'package:spendstory/capture/sms_parser.dart';
import 'package:spendstory/domain/models.dart';

import 'fixture_loader.dart';

void main() {
  final parser = SmsParser();

  ParsedTxn txn({
    required int amountPaise,
    TxnDirection direction = TxnDirection.expense,
    int occurredAtMs = 1759820400000,
    TxSource source = TxSource.autoSms,
    String? senderId = 'HDFCBK',
    String? accountLast4 = '4521',
    String? merchant,
    PaymentMode mode = PaymentMode.upi,
  }) => ParsedTxn(
    amountPaise: amountPaise,
    direction: direction,
    occurredAtMs: occurredAtMs,
    source: source,
    parserKey: 'test',
    senderId: senderId,
    accountLast4: accountLast4,
    merchant: merchant,
    mode: mode,
  );

  group('Dedupe.fingerprint', () {
    test('is stable for the same transaction', () {
      final a = txn(amountPaise: 124000, merchant: 'BigBasket');
      final b = txn(amountPaise: 124000, merchant: 'BigBasket');
      expect(Dedupe.fingerprint(txn: a), Dedupe.fingerprint(txn: b));
    });

    test('two messages a few seconds apart collapse to one fingerprint', () {
      final a = txn(amountPaise: 124000, occurredAtMs: 1759820400000);
      final b = txn(amountPaise: 124000, occurredAtMs: 1759820400000 + 20000);
      expect(Dedupe.fingerprint(txn: a), Dedupe.fingerprint(txn: b));
    });

    test('different amounts never collide', () {
      expect(
        Dedupe.fingerprint(txn: txn(amountPaise: 124000)),
        isNot(Dedupe.fingerprint(txn: txn(amountPaise: 124001))),
      );
    });

    test('a credit and a debit of the same amount never collide', () {
      expect(
        Dedupe.fingerprint(txn: txn(amountPaise: 500000)),
        isNot(
          Dedupe.fingerprint(
            txn: txn(amountPaise: 500000, direction: TxnDirection.income),
          ),
        ),
      );
    });

    test('different accounts never collide', () {
      expect(
        Dedupe.fingerprint(txn: txn(amountPaise: 124000, accountLast4: '4521')),
        isNot(
          Dedupe.fingerprint(
            txn: txn(amountPaise: 124000, accountLast4: '8899'),
          ),
        ),
      );
    });

    test('transactions more than a minute apart do not collide', () {
      final a = txn(amountPaise: 2000, occurredAtMs: 1759820400000);
      final b = txn(amountPaise: 2000, occurredAtMs: 1759820400000 + 120000);
      expect(Dedupe.fingerprint(txn: a), isNot(Dedupe.fingerprint(txn: b)));
    });
  });

  group(
    'Dedupe.isNearDuplicate — the SMS + notification double-capture case',
    () {
      final smsTxn = txn(
        amountPaise: 124000,
        source: TxSource.autoSms,
        merchant: 'BigBasket',
        occurredAtMs: 1759820400000,
      );
      final notifTxn = txn(
        amountPaise: 124000,
        source: TxSource.autoNotif,
        merchant: null,
        accountLast4: null,
        occurredAtMs: 1759820400000 + 45000, // 45s later
      );

      test('same payment, two channels, 45 seconds apart → duplicate', () {
        expect(Dedupe.isNearDuplicate(smsTxn, notifTxn), isTrue);
      });

      test('same channel is not treated as a cross-channel duplicate', () {
        final other = txn(
          amountPaise: 124000,
          source: TxSource.autoSms,
          occurredAtMs: 1759820400000 + 45000,
        );
        expect(Dedupe.isNearDuplicate(smsTxn, other), isFalse);
      });

      test('more than ten minutes apart is a different payment', () {
        final later = txn(
          amountPaise: 124000,
          source: TxSource.autoNotif,
          occurredAtMs: 1759820400000 + 11 * 60 * 1000,
        );
        expect(Dedupe.isNearDuplicate(smsTxn, later), isFalse);
      });

      test('different amount is never a duplicate', () {
        final other = txn(
          amountPaise: 45000,
          source: TxSource.autoNotif,
          occurredAtMs: 1759820400000 + 45000,
        );
        expect(Dedupe.isNearDuplicate(smsTxn, other), isFalse);
      });
    },
  );

  group('Dedupe.preferDetailed', () {
    test('keeps the record that has a merchant and an account', () {
      final rich = txn(
        amountPaise: 124000,
        source: TxSource.autoSms,
        merchant: 'BigBasket',
        accountLast4: '4521',
      );
      final bare = txn(
        amountPaise: 124000,
        source: TxSource.autoNotif,
        mode: PaymentMode.other,
      );
      expect(Dedupe.preferDetailed(bare, rich).merchant, 'BigBasket');
      expect(Dedupe.preferDetailed(rich, bare).merchant, 'BigBasket');
    });
  });

  group('Dedupe against the real corpus', () {
    test('the same SMS parsed twice yields one fingerprint', () {
      final item = loadFixture('debit').first;
      final body = item['body'] as String;
      final smsAt = isoToMs(item['smsAtIso'] as String);

      final first = parser.parseSms(
        sender: item['sender'] as String,
        body: body,
        smsTimestampMs: smsAt,
      );
      final second = parser.parseSms(
        sender: item['sender'] as String,
        body: body,
        smsTimestampMs: smsAt + 4000,
      );

      expect(first.isParsed, isTrue);
      expect(second.isParsed, isTrue);
      expect(
        Dedupe.fingerprint(txn: first.txn!),
        Dedupe.fingerprint(txn: second.txn!),
      );
    });
  });

  test('fingerprints are 40-char sha1 hex digests', () {
    final fp = Dedupe.fingerprint(txn: txn(amountPaise: 100));
    expect(fp.length, 40);
    expect(RegExp(r'^[0-9a-f]{40}$').hasMatch(fp), isTrue);
  });
}
