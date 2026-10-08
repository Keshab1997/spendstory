/// The CSV export (T-705, `docs/03 §S-23`: "CSV export, all free").
///
/// The file is read by something that is not this app — Excel, Numbers, a
/// script somebody wrote — so the rules tested here are the ones that make a
/// spreadsheet open correctly: a BOM so Excel does not mangle ₹ and Bengali,
/// CRLF, quoted fields where RFC 4180 says so, amounts in plain rupees, and
/// dates in one unambiguous order.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/domain/view_models.dart';
import 'package:spendstory/export/csv.dart';

final _noon = DateTime(2026, 10, 7, 14, 5).millisecondsSinceEpoch;

TxnView _txn({
  String id = 't1',
  int amountPaise = 124000,
  TxnDirection direction = TxnDirection.expense,
  String? merchant = 'BigBasket',
  String? categoryId = 'grocery',
  String? accountId,
  String? note,
  String? rawText,
  int? atMs,
  PaymentMode mode = PaymentMode.other,
}) => TxnView(
  id: id,
  amountPaise: amountPaise,
  direction: direction,
  occurredAtMs: atMs ?? _noon,
  merchant: merchant,
  categoryId: categoryId,
  accountId: accountId,
  note: note,
  rawText: rawText,
  mode: mode,
);

void main() {
  group('a field', () {
    test('is left alone when it is ordinary', () {
      expect(csvField('BigBasket'), 'BigBasket');
      expect(csvField(null), '');
    });

    test('is quoted when it contains a comma, a quote or a newline', () {
      expect(csvField('Rice, dal'), '"Rice, dal"');
      expect(csvField('He said "hi"'), '"He said ""hi"""');
      expect(csvField('two\nlines'), '"two\nlines"');
    });
  });

  group('an amount', () {
    test('is plain rupees with two decimals', () {
      expect(csvAmount(124000), '1240.00');
      expect(csvAmount(3000), '30.00');
      expect(csvAmount(0), '0.00');
      expect(csvAmount(5), '0.05');
    });

    test('never leaks floating point', () {
      // 0.1 + 0.2 rupees, and a value where a double would round the wrong way.
      expect(csvAmount(10 + 20), '0.30');
      expect(csvAmount(999999999), '9999999.99');
    });
  });

  group('the file', () {
    test('starts with a BOM and the frozen header row', () {
      final csv = ledgerCsv(<TxnView>[]);

      expect(csv, startsWith(csvBom));
      expect(csv.substring(csvBom.length), startsWith('date,time,amount,'));
      expect(csv, contains(csvNewline));
      expect(csvColumns.first, 'date');
      expect(csvColumns.last, 'raw_message');
    });

    test('writes one row per transaction, oldest first', () {
      final csv = ledgerCsv(<TxnView>[
        _txn(id: 'new', atMs: DateTime(2026, 10, 7).millisecondsSinceEpoch),
        _txn(id: 'old', atMs: DateTime(2026, 10, 1).millisecondsSinceEpoch),
      ]);

      final rows = csv.split(csvNewline);
      expect(rows[1], startsWith('2026-10-01,'));
      expect(rows[2], startsWith('2026-10-07,'));
      expect(rows.length, 4); // header + two rows + the trailing empty piece
    });

    test('uses local dates and times, in ISO order', () {
      final csv = ledgerCsv(<TxnView>[_txn()]);

      expect(csv, contains('2026-10-07,14:05,'));
    });

    test('writes the direction and the mode as stable words, not symbols', () {
      final csv = ledgerCsv(<TxnView>[
        _txn(direction: TxnDirection.income, mode: PaymentMode.upi),
        _txn(id: 't2', direction: TxnDirection.expense),
      ]);

      expect(csv, contains(',income,'));
      expect(csv, contains(',expense,'));
      expect(csv, contains(',upi,'));
      expect(csv, contains(',other,'));
    });

    test('names the category and the account when the caller knows them', () {
      final csv = ledgerCsv(
        <TxnView>[_txn(accountId: 'cash')],
        categoryNames: <String, String>{'grocery': 'মুদি'},
        accountNames: <String, String>{'cash': 'নগদ'},
      );

      expect(csv, contains('মুদি'));
      expect(csv, contains('নগদ'));
      expect(csv, isNot(contains('grocery')));
    });

    test('falls back to the id rather than losing the row', () {
      // A category the caller did not resolve keeps its id: a blank cell would
      // hide the gap instead of showing it.
      final csv = ledgerCsv(<TxnView>[_txn(categoryId: 'cat-unknown')]);

      expect(csv, contains('cat-unknown'));
    });

    test('escapes a merchant name that would otherwise break the columns', () {
      final csv = ledgerCsv(<TxnView>[
        _txn(merchant: 'Rahul, Kirana "Store"', note: 'Paid by UPI\nRef 42'),
      ]);

      expect(csv, contains('"Rahul, Kirana ""Store"""'));
      expect(csv, contains('"Paid by UPI\nRef 42"'));
      // Four commas in the header, so every data row has to have four too —
      // an unescaped comma inside a field would show up as a fifth.
      final dataRow = csv.split(csvNewline)[1];
      expect(
        ','.allMatches(_dropQuoted(dataRow)).length,
        csvColumns.length - 1,
      );
    });

    test('keeps the raw SMS when the capture kept it', () {
      final csv = ledgerCsv(<TxnView>[
        _txn(rawText: 'Rs.1240.00 debited from a/c XX4421'),
      ]);

      expect(csv, contains('Rs.1240.00 debited from a/c XX4421'));
    });
  });
}

/// Removes quoted sections so commas inside them are not counted as separators.
String _dropQuoted(String row) {
  final out = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < row.length; i++) {
    final ch = row[i];
    if (ch == '"') {
      inQuotes = !inQuotes;
      continue;
    }
    if (!inQuotes) out.write(ch);
  }
  return out.toString();
}
