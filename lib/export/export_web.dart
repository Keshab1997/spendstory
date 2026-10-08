/// The browser half of S-23's file handling (see `export_files.dart`).
///
/// There is no file system here, so nothing is written and nothing is read from
/// a directory. The share sheet is the browser's own (`navigator.share`, and a
/// download when the browser has no share sheet), the picker is the browser's
/// file input, and the bytes never touch a path.
///
/// In practice the web preview never gets this far: it runs on the bundled demo
/// ledger with no database, so `/export` tells the user that a backup needs the
/// installed app rather than exporting demo data that means nothing.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'export_files.dart';

/// A browser cannot write a file the app owns.
const bool canWriteFiles = false;

/// Hands the bytes to the browser's share sheet, which falls back to a download
/// when the browser has no share sheet — a real file either way.
Future<ShareOutcome> shareBytesFromDevice({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required String subject,
}) async {
  try {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
        fileNameOverrides: [fileName],
        subject: subject,
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => ShareOutcome.shared,
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.unavailable => ShareOutcome.unavailable,
    };
  } on Exception {
    return ShareOutcome.failed;
  }
}

/// The browser's file input.
Future<PickedFile?> pickFileFromDevice({String? dialogTitle}) async {
  final picked = await FilePicker.pickFiles(dialogTitle: dialogTitle);
  if (picked.isEmpty) return null;
  final file = picked.first;
  return PickedFile(name: file.name, bytes: await file.readAsBytes());
}
