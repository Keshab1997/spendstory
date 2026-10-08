/// The CSV export (T-705, `docs/05 §4`'s `BackupRepo`, `docs/03 §S-23`).
///
/// This file is *data*, not UI: the column names are English, the digits are
/// Latin, the dates are ISO 8601 and the numbers are plain rupees with two
/// decimals, whatever language the app is running in. A spreadsheet in Kolkata,
/// a relative's laptop and a support thread all have to read the same file, and
/// localized digits inside a CSV break every one of them. The screen is
/// translated; the file is portable.
///
/// The rules that matter are RFC 4180's and they are all in [csvField]: a field
/// containing a comma, a quote or a line break is quoted, and a quote inside a
/// quoted field is doubled. Amounts are always positive with the direction in
/// its own column, because a minus sign is easy to lose in a spreadsheet and
/// nearly impossible to notice later.
///
/// The output starts with a UTF-8 BOM and uses CRLF line endings. Excel is the
/// most likely reader of this file on a Windows machine, and both of those are
/// what it needs to show `₹` and Bengali correctly instead of mojibake.
library;

import '../domain/view_models.dart';

/// The column order is frozen: a script somebody wrote against yesterday's
/// export keeps working tomorrow.
const List<String> csvColumns = <String>[
  'date',
  'time',
  'amount',
  'direction',
  'merchant',
  'category',
  'account',
  'mode',
  'source',
  'note',
  'raw_message',
];

/// A UTF-8 BOM, so Excel does not read the file as Latin-1.
const String csvBom = '\uFEFF';

/// The line ending RFC 4180 asks for.
const String csvNewline = '\r\n';

/// One field, quoted only when it has to be, with quotes doubled inside.
String csvField(String? value) {
  final text = value ?? '';
  final needsQuotes =
      text.contains(',') ||
      text.contains('"') ||
      text.contains('\n') ||
      text.contains('\r');
  if (!needsQuotes) return text;
  return '"${text.replaceAll('"', '""')}"';
}

/// One row, given its fields.
String csvRow(List<String?> fields) =>
    '${fields.map(csvField).join(',')}$csvNewline';

/// Paise as plain rupees: `124000` -> `1240.00`.
///
/// Integer arithmetic, not floating point: a ledger that exports `1239.999999`
/// for a ₹1,240 payment has lost the argument before it starts.
String csvAmount(int paise) {
  final rupees = paise ~/ 100;
  final fraction = (paise % 100).abs().toString().padLeft(2, '0');
  return '$rupees.$fraction';
}

/// `2026-10-07` in local time — the day the user experienced, not UTC's.
String csvDate(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// `20:42`, local time.
String csvTime(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

/// The whole ledger as CSV, oldest first — the order a statement is read in.
///
/// [categoryNames] and [accountNames] are the *user-facing* name for the active
/// language, because an id like `cat-grocery` means nothing in a spreadsheet.
/// A row whose category is missing or unknown keeps its id rather than an empty
/// cell: the transaction is still the user's, and losing the label would hide
/// the gap instead of showing it.
String ledgerCsv(
  List<TxnView> transactions, {
  Map<String, String> categoryNames = const <String, String>{},
  Map<String, String> accountNames = const <String, String>{},
}) {
  final rows = List<TxnView>.of(transactions)
    ..sort((a, b) => a.occurredAtMs.compareTo(b.occurredAtMs));

  final out = StringBuffer(csvBom)..write(csvRow(csvColumns));
  for (final txn in rows) {
    out.write(
      csvRow(<String?>[
        csvDate(txn.occurredAtMs),
        csvTime(txn.occurredAtMs),
        csvAmount(txn.amountPaise),
        txn.direction.wire,
        txn.merchant ?? '',
        _label(txn.categoryId, categoryNames),
        _label(txn.accountId, accountNames),
        txn.mode.wire,
        txn.source,
        txn.note ?? '',
        txn.rawText ?? '',
      ]),
    );
  }
  return out.toString();
}

/// The display name for an id, falling back to the id itself.
String _label(String? id, Map<String, String> names) {
  if (id == null || id.isEmpty) return '';
  return names[id] ?? id;
}
