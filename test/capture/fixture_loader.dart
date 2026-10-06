/// Shared fixture loading for the capture tests.
///
/// The corpus lives in `test/fixtures/sms/*.json` and is entirely synthetic —
/// no real message ever enters the repository. See `docs/06-SMS-PARSING.md` §10.
library;

import 'dart:convert';
import 'dart:io';

List<Map<String, dynamic>> loadFixture(String name) {
  final file = File('test/fixtures/sms/$name.json');
  if (!file.existsSync()) {
    throw StateError('missing fixture: ${file.path}');
  }
  final decoded = json.decode(file.readAsStringSync()) as List<dynamic>;
  return decoded.cast<Map<String, dynamic>>();
}

int isoToMs(String iso) => DateTime.parse(iso).toUtc().millisecondsSinceEpoch;

/// Date string in the *local* timezone, which is what the parser produces when
/// it reads `dd-MM-yy` out of a message.
String localDateOf(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
