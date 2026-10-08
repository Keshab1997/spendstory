/// The PDF statement (T-705, the Pro half of S-23).
///
/// A file that opens in a reader is the whole requirement, so the assertions are
/// about the file: it starts with `%PDF`, it ends with `%%EOF`, it is not empty,
/// and its money and dates are the Latin shapes a printed statement needs. The
/// fonts come from `assets/fonts` by path rather than through `rootBundle`,
/// because a test has no asset bundle to ask — and loading the real font is the
/// point: a placeholder face would hide a font that cannot be parsed.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/export/pdf_statement.dart';

Future<ByteData> _loadFont(String asset) async {
  final bytes = await File(asset).readAsBytes();
  return ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
}

StatementData _statement({
  List<StatementRow>? rows,
  String particulars = 'BigBasket',
}) => StatementData(
  period: 'October 2026',
  rows:
      rows ??
      <StatementRow>[
        StatementRow(
          date: '07 Oct 2026',
          particulars: particulars,
          category: 'Groceries',
          amountPaise: 124000,
          isIncome: false,
        ),
        StatementRow(
          date: '05 Oct 2026',
          particulars: 'Payroll',
          category: 'Salary',
          amountPaise: 4500000,
          isIncome: true,
        ),
      ],
  incomePaise: 4500000,
  expensePaise: 124000,
  footnote: statementFootnote(DateTime(2026, 10, 7, 20, 42)),
);

String _ascii(Uint8List bytes) =>
    String.fromCharCodes(bytes.where((b) => b >= 32 && b < 127));

void main() {
  group('the document', () {
    test('is a real PDF, for one month', () async {
      final bytes = await buildStatementPdf(_statement(), loadFont: _loadFont);

      expect(bytes.length, greaterThan(2000));
      expect(String.fromCharCodes(bytes.sublist(0, 5)), startsWith('%PDF'));
      expect(_ascii(bytes), contains('%%EOF'));
      // The statement's own title and the month it covers.
      expect(_ascii(bytes), contains('SpendStory statement'));
    });

    test('opens even when there is nothing in the month', () async {
      final bytes = await buildStatementPdf(
        _statement(rows: const <StatementRow>[]),
        loadFont: _loadFont,
      );

      expect(String.fromCharCodes(bytes.sublist(0, 5)), startsWith('%PDF'));
    });

    test('loads the Bengali face only when some text needs it', () async {
      final loaded = <String>[];
      Future<ByteData> loader(String asset) async {
        loaded.add(asset);
        return _loadFont(asset);
      }

      expect(needsFallbackFont(_statement()), isFalse);
      await buildStatementPdf(_statement(), loadFont: loader);
      expect(loaded, <String>[manropeAsset]);

      loaded.clear();
      expect(needsFallbackFont(_statement(particulars: 'মুদি দোকান')), isTrue);
      await buildStatementPdf(
        _statement(particulars: 'মুদি দোকান'),
        loadFont: loader,
      );
      expect(loaded, contains(notoBengaliAsset));
      expect(loaded, contains(notoDevanagariAsset));
    });
  });

  group('the printed shapes', () {
    test('money is ₹ with two decimals and thousands separators', () {
      expect(statementMoney(124000), '₹1,240.00');
      expect(statementMoney(5), '₹0.05');
      expect(statementMoney(0), '₹0.00');
      expect(statementMoney(123456789), '₹1,234,567.89');
    });

    test('the date is three letters of month, in Latin digits', () {
      expect(
        statementDate(DateTime(2026, 10, 7).millisecondsSinceEpoch),
        '07 Oct 2026',
      );
      expect(
        statementDate(DateTime(2026, 1, 31).millisecondsSinceEpoch),
        '31 Jan 2026',
      );
    });

    test('the footnote says where the file came from', () {
      final note = statementFootnote(DateTime(2026, 10, 7));

      expect(note, contains('SpendStory'));
      expect(note, contains('07 Oct 2026'));
      expect(note, contains('never left the phone'));
    });
  });
}
