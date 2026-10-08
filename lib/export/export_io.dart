/// The device half of S-23's file handling (see `export_files.dart`).
///
/// A file goes out through the system share sheet, after being written to this
/// app's temporary directory with the name the receiving app will show. A file
/// comes in through the system picker, read into memory in one go — a backup is
/// a few hundred kilobytes, and reading it twice to find that out is worse than
/// holding it.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'export_files.dart';

/// This platform has a file system.
const bool canWriteFiles = true;

/// Writes the bytes to the temp directory, then hands the path to the share
/// sheet. Returns what the sheet did with it.
Future<ShareOutcome> shareBytesFromDevice({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required String subject,
}) async {
  try {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType, name: fileName)],
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
    // A phone that cannot write a temp file is a phone that cannot export. The
    // screen reports it; the ledger is untouched either way.
    return ShareOutcome.failed;
  }
}

/// Opens the system picker and reads the chosen file.
Future<PickedFile?> pickFileFromDevice({String? dialogTitle}) async {
  final picked = await FilePicker.pickFiles(
    dialogTitle: dialogTitle,
    type: FileType.any,
  );
  if (picked.isEmpty) return null;
  final file = picked.first;
  return PickedFile(name: file.name, bytes: await file.readAsBytes());
}
