/// The two platform halves of S-23's file handling (T-705).
///
/// `export_web.dart` is a direct import on purpose: the app reaches it through a
/// conditional import (`lib/export/export_files.dart`), which is invisible to
/// both the analyzer's dead-code pass and `tool/preflight.py`'s orphan scan. A
/// test that names it is how it stays wired up — the same reason
/// `test/ads/web_client_test.dart` imports the web ad client by name.
///
/// Nothing here calls a plugin: a share sheet needs an operating system. What is
/// checked is the contract each platform promises — whether it can write a file
/// at all, and that both halves implement the same two seams.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/export/export_files.dart'
    show PickFile, ShareBytes, canWriteFiles;
import 'package:spendstory/export/export_io.dart' as io;
import 'package:spendstory/export/export_web.dart' as web;

void main() {
  test('this test run is on the platform that has a file system', () {
    expect(canWriteFiles, isTrue);
    expect(io.canWriteFiles, isTrue);
    expect(io.canWriteFiles, canWriteFiles);
  });

  test('a browser cannot write a file, and says so', () {
    // Which is the reason the weekly auto-backup is a reminder rather than a
    // silent writer, and the reason `/export` explains itself in the preview
    // instead of writing demo data somewhere.
    expect(web.canWriteFiles, isFalse);
  });

  test('both halves implement the same seams', () {
    expect(io.shareBytesFromDevice, isA<ShareBytes>());
    expect(web.shareBytesFromDevice, isA<ShareBytes>());
    expect(io.pickFileFromDevice, isA<PickFile>());
    expect(web.pickFileFromDevice, isA<PickFile>());
  });
}
