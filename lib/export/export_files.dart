/// The two moments S-23 has to touch the outside world: handing a file to the
/// share sheet, and reading one back (`docs/03 §S-23`'s "file picker / Drive").
///
/// Both go through the OS rather than through a folder the app owns:
///
/// * **Out** — the bytes are written to this app's temporary directory and given
///   to the system share sheet. From there the user decides where the file
///   lives: their own Drive, a chat with themselves, a computer over Bluetooth.
///   SpendStory never asks for storage permission and never uploads anything —
///   there is still no server to upload it to.
/// * **In** — the system file picker returns the file the user taps; nothing is
///   read until they pick one, and the password is asked for afterwards.
///
/// The platform halves live in `export_io.dart` / `export_web.dart`, because the
/// file system does not exist in a browser and `dart:io` cannot be imported
/// there. Both are seams ([shareBytesProvider], [pickFileProvider]) so a test
/// drives the screen without a share sheet; the real implementations are the
/// defaults.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'export_io.dart'
    if (dart.library.js_interop) 'export_web.dart'
    as platform;

/// What came back from the share sheet. `unavailable` is not a failure: a phone
/// with no share sheet at all is a phone where the user has nowhere to put the
/// file, and the screen says so instead of pretending it worked.
enum ShareOutcome { shared, dismissed, unavailable, failed }

/// A file the user picked, already read into memory.
class PickedFile {
  const PickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Hands [bytes] to the share sheet under [fileName].
typedef ShareBytes = Future<ShareOutcome> Function({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required String subject,
});

/// Opens the system file picker. Null when the user cancels.
typedef PickFile = Future<PickedFile?> Function({String? dialogTitle});

/// True when this platform can write a file at all. False in a browser, where
/// the share sheet (or a download) is the only way out.
const bool canWriteFiles = platform.canWriteFiles;

/// The real share sheet, on the platform's own terms.
Future<ShareOutcome> shareBytesFromDevice({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required String subject,
}) => platform.shareBytesFromDevice(
  bytes: bytes,
  fileName: fileName,
  mimeType: mimeType,
  subject: subject,
);

/// The real picker. Any file type: a backup may have been renamed, and the
/// envelope's own magic bytes decide whether it can be opened.
Future<PickedFile?> pickFileFromDevice({String? dialogTitle}) =>
    platform.pickFileFromDevice(dialogTitle: dialogTitle);

/// Seam: overridden in tests so no share sheet is involved.
final shareBytesProvider = Provider<ShareBytes>((ref) => shareBytesFromDevice);

/// Seam: overridden in tests so no picker is involved.
final pickFileProvider = Provider<PickFile>((ref) => pickFileFromDevice);
