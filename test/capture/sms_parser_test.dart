import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/capture/sms_parser.dart';
import 'package:spendstory/domain/models.dart';

import 'fixture_loader.dart';

void main() {
  final parser = SmsParser();

  /// Runs one corpus file and returns the list of human-readable failures.
  List<String> runCorpus(String file, {required bool includeDate}) {
    final failures = <String>[];
    for (final item in loadFixture(file)) {
      final note = item['note'] as String;
      final body = item['body'] as String;
      final sender = item['sender'] as String;
      final smsAt = isoToMs(item['smsAtIso'] as String);
      final exp = (item['expect'] as Map).cast<String, dynamic>();

      final outcome = parser.parseSms(
        sender: sender,
        body: body,
        smsTimestampMs: smsAt,
      );

      if (!outcome.isParsed) {
        failures.add('$note → rejected as ${outcome.rejection?.wire}');
        continue;
      }
      final txn = outcome.txn!;

      void check(String field, Object? actual, Object? expected) {
        if (actual != expected) {
          failures.add('$note → $field: expected <$expected> got <$actual>');
        }
      }

      check('direction', txn.direction.wire, exp['direction']);
      check('amountPaise', txn.amountPaise, exp['amountPaise']);
      check('merchant', txn.merchant, exp['merchant']);
      check('mode', txn.mode.wire, exp['mode']);
      check('accountLast4', txn.accountLast4, exp['accountLast4']);
      if (includeDate) {
        check('date', localDateOf(txn.occurredAtMs), exp['dateIso']);
      }
    }
    return failures;
  }

  group('SMS parser — accuracy gates (docs/06 §10)', () {
    test('debit corpus parses at ≥95% with every field correct', () {
      final failures = runCorpus('debit', includeDate: true);
      final total = loadFixture('debit').length;
      final passed = total - failures.length;
      expect(
        passed / total,
        greaterThanOrEqualTo(0.95),
        reason: '${failures.length}/$total failed:\n${failures.join('\n')}',
      );
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('credit corpus parses at ≥95% with every field correct', () {
      final failures = runCorpus('credit', includeDate: true);
      final total = loadFixture('credit').length;
      final passed = total - failures.length;
      expect(
        passed / total,
        greaterThanOrEqualTo(0.95),
        reason: failures.join('\n'),
      );
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('edge cases all parse correctly', () {
      final failures = runCorpus('edge', includeDate: true);
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('non-transaction corpus produces zero transactions', () {
      final problems = <String>[];
      for (final item in loadFixture('nontx')) {
        final outcome = parser.parseSms(
          sender: item['sender'] as String,
          body: item['body'] as String,
          smsTimestampMs: isoToMs('2026-10-07T12:00:00Z'),
        );
        final expected = item['expect'] as String;
        if (outcome.isParsed) {
          problems.add('${item['note']} → wrongly parsed as ${outcome.txn}');
        } else if (outcome.rejection!.wire != expected) {
          problems.add(
            '${item['note']} → expected $expected '
            'got ${outcome.rejection!.wire}',
          );
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  });

  group('SMS parser — specific behaviours', () {
    test('balance-only alert never becomes a transaction', () {
      final outcome = parser.parseSms(
        sender: 'VM-HDFCBK',
        body: 'Your A/c XX4521 Avl Bal is Rs.12,340.50 as on 07-10-26.',
        smsTimestampMs: isoToMs('2026-10-07T12:00:00Z'),
      );
      expect(outcome.isParsed, isFalse);
      expect(outcome.rejection, ParseRejection.balanceOnly);
    });

    test('the balance figure is never mistaken for the transaction amount', () {
      final outcome = parser.parseSms(
        sender: 'VM-HDFCBK',
        body: 'Rs.1,240.00 debited from A/c XX4521 on 07-10-26. Avl Bal Rs.12,340.50',
        smsTimestampMs: isoToMs('2026-10-07T12:00:00Z'),
      );
      expect(outcome.txn!.amountPaise, 124000);
    });

    test('a future-dated mandate notice is not recorded as a spend', () {
      final outcome = parser.parseSms(
        sender: 'VM-HDFCBK',
        body: 'Rs 999.00 will be debited on 15-10-26 as per e-mandate for Netflix.',
        smsTimestampMs: isoToMs('2026-10-07T12:00:00Z'),
      );
      expect(outcome.isParsed, isFalse);
      expect(outcome.rejection, ParseRejection.nonTransaction);
    });

    test('unknown sender is ignored before any parsing happens', () {
      final outcome = parser.parseSms(
        sender: '+919876543210',
        body: 'Rs.500.00 debited from A/c XX1122 on 07-10-26.',
        smsTimestampMs: isoToMs('2026-10-07T12:00:00Z'),
      );
      expect(outcome.rejection, ParseRejection.unknownSender);
    });

    test('OTP is dropped even when it mentions a real amount', () {
      final outcome = parser.parseSms(
        sender: 'VM-HDFCBK',
        body: 'OTP 4321 for your txn of Rs 2,499 at Myntra. Do not share.',
        smsTimestampMs: isoToMs('2026-10-07T12:00:00Z'),
      );
      expect(outcome.rejection, ParseRejection.otp);
    });

    test('the raw body is preserved for the detail screen, and only there', () {
      const body =
          'Rs.500.00 debited from A/c XX1234 on 05-10-26 to VPA swiggy@ybl. Avl Bal Rs.8,900.00';
      final outcome = parser.parseSms(
        sender: 'AX-SBIINB',
        body: body,
        smsTimestampMs: isoToMs('2026-10-05T13:05:00Z'),
      );
      expect(outcome.txn!.rawText, body);
      expect(outcome.txn!.source, TxSource.autoSms);
    });
  });

  group('Notification parser', () {
    test('every notification fixture matches its expectation', () {
      final problems = <String>[];
      for (final item in loadFixture('notifications')) {
        final outcome = parser.parseNotification(
          packageName: item['package'] as String,
          title: item['title'] as String,
          body: item['body'] as String,
          timestampMs: isoToMs('2026-10-07T12:00:00Z'),
        );
        final exp = item['expect'];

        if (exp is String) {
          if (outcome.isParsed) {
            problems.add('${item['note']} → should be $exp, was parsed');
          }
          continue;
        }
        final e = (exp as Map).cast<String, dynamic>();
        if (!outcome.isParsed) {
          problems.add('${item['note']} → rejected ${outcome.rejection?.wire}');
          continue;
        }
        final txn = outcome.txn!;
        if (txn.direction.wire != e['direction']) {
          problems.add('${item['note']} direction ${txn.direction.wire}');
        }
        if (txn.amountPaise != e['amountPaise']) {
          problems.add('${item['note']} amount ${txn.amountPaise}');
        }
        if (txn.merchant != e['merchant']) {
          problems.add('${item['note']} merchant ${txn.merchant}');
        }
        if (txn.mode.wire != e['mode']) {
          problems.add('${item['note']} mode ${txn.mode.wire}');
        }
        if (txn.parserKey != e['parserKey']) {
          problems.add('${item['note']} parserKey ${txn.parserKey}');
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('the whitelist is exactly the six promised payment apps', () {
      expect(kPaymentPackages.length, 6);
      expect(kPaymentPackages.contains('com.phonepe.app'), isTrue);
      expect(kPaymentPackages.contains('com.whatsapp'), isFalse);
    });
  });

  group('normalizeDigits', () {
    test('converts Bengali and Devanagari numerals to ASCII', () {
      expect(normalizeDigits('১,২৪০.০০'), '1,240.00');
      expect(normalizeDigits('२,५००'), '2,500');
      expect(normalizeDigits('plain 123'), 'plain 123');
    });
  });
}
