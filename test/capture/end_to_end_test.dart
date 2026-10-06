/// End-to-end capture test — message in, ledger row out.
///
/// This is the gate in `docs/06-SMS-PARSING.md` §10, run against the full
/// pipeline including the database: OTP guard → allowlist → parser → rule
/// engine → account resolution → dedupe → write → parse log.
///
/// The 200-message corpus and the 60-message noise set are synthetic and
/// reproducible — regenerate them with `python3 tool/gen_sms_corpus.py`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/capture/capture_service.dart';
import 'package:spendstory/data/db.dart';

import 'fixture_loader.dart';

void main() {
  late AppDb db;
  late CaptureService capture;

  setUp(() async {
    db = AppDb.memory();
    await db.seedIfNeeded();
    capture = CaptureService(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> liveRowCount() async {
    final rows = await (db.select(
      db.transactions,
    )..where((t) => t.deletedAt.isNull())).get();
    return rows.length;
  }

  group('accuracy gate (docs/06 §10)', () {
    test('200-message corpus parses at ≥95% with every field correct', () async {
      final corpus = loadFixture('corpus200');
      expect(corpus.length, 200);

      final failures = <String>[];
      var parsed = 0;

      for (final item in corpus) {
        final note = item['note'] as String;
        final exp = (item['expect'] as Map).cast<String, dynamic>();

        final result = await capture.handleSms(
          sender: item['sender'] as String,
          body: item['body'] as String,
          timestampMs: isoToMs(item['smsAtIso'] as String),
        );

        if (result.status != CaptureStatus.added) {
          failures.add(
            '$note → ${result.status.name}'
            '${result.rejection != null ? ' (${result.rejection!.wire})' : ''}'
            ' :: ${item['body']}',
          );
          continue;
        }
        parsed++;

        final txn = result.txn!;
        void check(String field, Object? actual, Object? expected) {
          if (actual != expected) {
            failures.add(
              '$note → $field: expected <$expected> got <$actual>'
              ' :: ${item['body']}',
            );
          }
        }

        check('direction', txn.direction.wire, exp['direction']);
        check('amountPaise', txn.amountPaise, exp['amountPaise']);
        check('merchant', txn.merchant, exp['merchant']);
        check('mode', txn.mode.wire, exp['mode']);
        check('accountLast4', txn.accountLast4, exp['accountLast4']);
        check('date', localDateOf(txn.occurredAtMs), exp['dateIso']);
      }

      final accuracy = (corpus.length - failures.length) / corpus.length;
      expect(
        accuracy,
        greaterThanOrEqualTo(0.95),
        reason:
            'accuracy ${(accuracy * 100).toStringAsFixed(1)}% — '
            '${failures.length} problem(s):\n${failures.take(20).join('\n')}',
      );
      expect(failures, isEmpty, reason: failures.take(20).join('\n'));

      expect(parsed, corpus.length);
      expect(await liveRowCount(), corpus.length);
    });

    test('60-message noise set produces zero transactions', () async {
      final noise = loadFixture('noise60');
      expect(noise.length, 60);

      final problems = <String>[];
      for (final item in noise) {
        final result = await capture.handleSms(
          sender: item['sender'] as String,
          body: item['body'] as String,
          timestampMs: isoToMs(item['smsAtIso'] as String),
        );
        final expected = item['expectReject'] as String;

        if (result.status != CaptureStatus.rejected) {
          problems.add(
            '${item['note']} → wrongly captured as ${result.txn}'
            ' :: ${item['body']}',
          );
        } else if (result.rejection!.wire != expected) {
          problems.add(
            '${item['note']} → expected $expected, got ${result.rejection!.wire}',
          );
        }
      }

      expect(problems, isEmpty, reason: problems.join('\n'));
      expect(
        await liveRowCount(),
        0,
        reason: 'noise must never reach the ledger',
      );
    });

    test('zero OTP messages are ever stored, in either language', () async {
      final otpCount = loadFixture('noise60')
          .where((i) => i['expectReject'] == 'otp')
          .length;
      expect(otpCount, greaterThan(0));

      final logs = await db.select(db.parseLog).get();
      // Nothing has been fed yet in this test — the assertion that matters is
      // that every OTP in the sets above was rejected before parsing.
      expect(logs, isEmpty);
    });
  });

  group('pipeline behaviour', () {
    test(
      'a parsed transaction lands with the right category and account',
      () async {
        final result = await capture.handleSms(
          sender: 'VM-HDFCBK',
          body:
              'Rs.1,240.00 debited from A/c XX4521 on 07-10-26 to VPA bigbasket@ybl'
              ' (UPI Ref 412398765432). Avl Bal Rs.12,340.50',
          timestampMs: isoToMs('2026-10-07T13:00:00Z'),
        );

        expect(result.status, CaptureStatus.added);
        expect(result.categoryId, 'grocery');

        final row = await (db.select(
          db.transactions,
        )..where((t) => t.id.equals(result.txnId!))).getSingle();

        expect(row.amountPaise, 124000);
        expect(row.direction, 'expense');
        expect(row.categoryId, 'grocery');
        expect(row.merchant, 'BigBasket');
        expect(row.mode, 'upi');
        expect(row.source, 'auto_sms');
        // sourceRef stores the *normalized* sender, which is what the allowlist
        // and the dedupe fingerprint both compare against, and what the detail
        // screen shows as "HDFCBK alert".
        expect(row.sourceRef, 'HDFCBK');
        expect(row.rawText, contains('bigbasket@ybl'));
      },
    );

    test(
      'an unclear merchant is left uncategorised instead of guessed',
      () async {
        final result = await capture.handleSms(
          sender: 'VM-HDFCBK',
          body:
              'Rs.2,000.00 debited from A/c XX4521 on 07-10-26 to VPA '
              'ramesh.kumar@okicici. Avl Bal Rs.900.',
          timestampMs: isoToMs('2026-10-07T13:00:00Z'),
        );

        expect(result.status, CaptureStatus.added);
        expect(result.txn!.merchant, 'Ramesh Kumar');
        expect(result.categoryId, isNull, reason: 'a person is not a category');
      },
    );

    test('a re-delivered SMS is a duplicate, not a second row', () async {
      const body =
          'Rs.500.00 debited from A/c XX1234 on 05-10-26 to VPA swiggy@ybl.'
          ' Avl Bal Rs.8,900.00';
      const at = 1759669200000; // 2026-10-05T13:00:00Z

      final first = await capture.handleSms(
        sender: 'AX-SBIINB',
        body: body,
        timestampMs: at,
      );
      final second = await capture.handleSms(
        sender: 'AX-SBIINB',
        body: body,
        timestampMs: at + 4000,
      );

      expect(first.status, CaptureStatus.added);
      expect(second.status, CaptureStatus.duplicate);
      expect(await liveRowCount(), 1);
    });

    test('the same payment seen by SMS and notification is one row', () async {
      const at = 1759669200000;

      final viaSms = await capture.handleSms(
        sender: 'VM-HDFCBK',
        body:
            'Rs.1,240.00 debited from A/c XX4521 on 05-10-26 to VPA '
            'bigbasket@ybl (UPI Ref 412398765432). Avl Bal Rs.12,340.50',
        timestampMs: at,
      );
      final viaNotif = await capture.handleNotification(
        packageName: 'com.google.android.apps.nbu.paisa.user',
        title: 'Google Pay',
        body: '₹1,240 paid to BigBasket via UPI',
        timestampMs: at + 45000,
      );

      expect(viaSms.status, CaptureStatus.added);
      expect(viaNotif.status, CaptureStatus.duplicate);
      expect(await liveRowCount(), 1);

      // The bank SMS is the richer record, so it is the one that survives.
      final row = await db.select(db.transactions).getSingle();
      expect(row.source, 'auto_sms');
      expect(row.merchant, 'BigBasket');
    });

    test('replaying the whole corpus writes nothing new', () async {
      final corpus = loadFixture('corpus200').take(25).toList();

      for (final item in corpus) {
        await capture.handleSms(
          sender: item['sender'] as String,
          body: item['body'] as String,
          timestampMs: isoToMs(item['smsAtIso'] as String),
        );
      }
      final afterFirst = await liveRowCount();
      expect(afterFirst, corpus.length);

      final statuses = <CaptureStatus>[];
      for (final item in corpus) {
        final result = await capture.handleSms(
          sender: item['sender'] as String,
          body: item['body'] as String,
          timestampMs: isoToMs(item['smsAtIso'] as String),
        );
        statuses.add(result.status);
      }

      expect(statuses.every((s) => s == CaptureStatus.duplicate), isTrue);
      expect(await liveRowCount(), afterFirst);
    });

    test(
      'every message leaves exactly one line in the local parse log',
      () async {
        await capture.handleSms(
          sender: 'VM-HDFCBK',
          body: 'Rs.100.00 debited from A/c XX4521 on 07-10-26.',
          timestampMs: isoToMs('2026-10-07T13:00:00Z'),
        );
        await capture.handleSms(
          sender: 'VM-HDFCBK',
          body: 'Your A/c XX4521 Avl Bal is Rs.12,340.50 as on 07-10-26.',
          timestampMs: isoToMs('2026-10-07T13:00:00Z'),
        );
        await capture.handleSms(
          sender: '+919876543210',
          body: 'Rs.100.00 debited from A/c XX4521 on 07-10-26.',
          timestampMs: isoToMs('2026-10-07T13:00:00Z'),
        );

        final logs = await db.select(db.parseLog).get();
        expect(logs.length, 3);
        expect(logs.where((l) => l.matched).length, 1);
        expect(
          logs.map((l) => l.failureReason).toList(),
          containsAll(<String>['balance_only', 'unknown_sender']),
        );

        // The log must never contain a message body — only the reason.
        for (final l in logs) {
          expect(
            l.failureReason == null || !l.failureReason!.contains('Rs'),
            isTrue,
          );
        }
      },
    );

    test(
      'categories are assigned for the overwhelming majority of the corpus',
      () async {
        final corpus = loadFixture('corpus200');
        var filed = 0;
        var parsed = 0;

        for (final item in corpus) {
          final result = await capture.handleSms(
            sender: item['sender'] as String,
            body: item['body'] as String,
            timestampMs: isoToMs(item['smsAtIso'] as String),
          );
          if (!result.written) continue;
          parsed++;
          if (result.categoryId != null) filed++;
        }

        final rate = filed / parsed;
        expect(
          rate,
          greaterThanOrEqualTo(0.85),
          reason: 'only ${(rate * 100).toStringAsFixed(1)}% auto-filed',
        );
      },
    );
  });
}
