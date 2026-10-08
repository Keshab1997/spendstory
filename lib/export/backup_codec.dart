/// The encryption behind an S-23 backup (T-705, `docs/07 §5`).
///
/// A backup is a file the user carries to a new phone, a laptop or a chat app.
/// That is precisely what the rest of this app never does with their data, so
/// the file is the one place where "we keep it safe" has to mean something
/// cryptographic rather than architectural: **AES-256-GCM under a key derived
/// from their password** — `docs/07 §5`'s security row, and the only form of
/// backup this app will ever write.
///
/// The envelope is binary and self-describing, because a restore has to work on
/// a phone that has never seen this code before:
///
/// ```
///  0               4      5      6            10        11         27    28
///  +---------------+------+------+-------------+---------+----------+-----+
///  | "SSBK"        | ver  | kdf  | iterations  | salt 16 | nonce 12 | ct  |
///  +---------------+------+------+-------------+---------+----------+-----+
///                    1      1      u32 big endian          (GCM tag trails ct)
/// ```
///
/// Everything a future version might want to change — the KDF, the iteration
/// count, the nonce size — is a number in the header rather than an assumption
/// in the code, so a file written today still opens after the defaults move. The
/// associated data binds the ciphertext to this file format, so a blob from
/// somewhere else cannot be passed off as one of ours.
///
/// Wrong password, truncated file and edited file are deliberately the *same*
/// failure to the caller: GCM cannot tell them apart, and pretending otherwise
/// would leak information about the plaintext.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// The file is not a SpendStory backup, was damaged, or the password is wrong.
class BackupFormatException implements Exception {
  const BackupFormatException(this.reason);

  /// A sentence for the screen, not a stack trace.
  final String reason;

  @override
  String toString() => 'BackupFormatException: $reason';
}

/// AES-256-GCM over a PBKDF2-HMAC-SHA256 key.
abstract final class BackupCodec {
  /// "SSBK" — SpendStory BacKup. Four printable bytes, so a hex dump is obvious.
  static const List<int> magic = <int>[0x53, 0x53, 0x42, 0x4B];

  /// Bumped when the envelope changes shape in a way old readers cannot guess.
  static const int formatVersion = 1;

  /// Key-derivation ids. 1 = PBKDF2-HMAC-SHA256.
  static const int kdfPbkdf2Sha256 = 1;

  /// Iterations for a *new* file. A phone has to derive this key once, by hand,
  /// in Dart, so the count is a compromise between an attacker's electricity
  /// bill and a user who is waiting for their backup to finish. Old files carry
  /// their own count and stay readable whatever this says.
  static const int defaultIterations = 120000;

  static const int _saltBytes = 16;
  static const int _nonceBytes = 12;
  static const int _keyBytes = 32;
  static const int _tagBits = 128;

  /// Bound into the tag: a ciphertext can only be decrypted as this format.
  static final Uint8List _aad = Uint8List.fromList(
    utf8.encode('SpendStory backup v$formatVersion'),
  );

  /// Encrypts [plain]. [iterations] exists for tests and for a future "make it
  /// slower" setting; the default is what ships.
  static Uint8List encrypt({
    required List<int> plain,
    required String password,
    int iterations = defaultIterations,
    Random? random,
    List<int>? salt,
    List<int>? nonce,
  }) {
    if (password.isEmpty) {
      throw ArgumentError.value(password, 'password', 'must not be empty');
    }
    if (iterations <= 0) {
      throw ArgumentError.value(iterations, 'iterations', 'must be positive');
    }
    final rng = random ?? Random.secure();
    final usedSalt = salt ?? _random(rng, _saltBytes);
    final usedNonce = nonce ?? _random(rng, _nonceBytes);
    if (usedSalt.length != _saltBytes) {
      throw ArgumentError.value(usedSalt.length, 'salt', 'must be $_saltBytes');
    }
    if (usedNonce.length != _nonceBytes) {
      throw ArgumentError.value(
        usedNonce.length,
        'nonce',
        'must be $_nonceBytes',
      );
    }

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(_deriveKey(password, usedSalt, iterations)),
          _tagBits,
          Uint8List.fromList(usedNonce),
          _aad,
        ),
      );
    final cipherText = cipher.process(Uint8List.fromList(plain));

    final out = BytesBuilder(copy: false)
      ..add(magic)
      ..addByte(formatVersion)
      ..addByte(kdfPbkdf2Sha256)
      ..add(_u32(iterations))
      ..addByte(_saltBytes)
      ..add(usedSalt)
      ..addByte(_nonceBytes)
      ..add(usedNonce)
      ..add(cipherText);
    return out.takeBytes();
  }

  /// Reverses [encrypt]. Throws [BackupFormatException] when the file is not
  /// ours, is damaged, or the password does not fit.
  static Uint8List decrypt({
    required List<int> envelope,
    required String password,
  }) {
    if (password.isEmpty) {
      throw const BackupFormatException('Enter the password for the backup.');
    }
    final bytes = Uint8List.fromList(envelope);
    // The magic bytes first: "this is not one of ours" and "this is a truncated
    // one of ours" are different sentences for the user.
    if (bytes.length < magic.length) {
      throw const BackupFormatException('Not a SpendStory backup file.');
    }
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) {
        throw const BackupFormatException('Not a SpendStory backup file.');
      }
    }
    if (bytes.length < 4 + 1 + 1 + 4 + 1 + _saltBytes + 1 + _nonceBytes) {
      throw const BackupFormatException('This file is too short to be one.');
    }
    if (bytes[4] != formatVersion) {
      throw BackupFormatException(
        'This backup was written by another version of the app.',
      );
    }
    if (bytes[5] != kdfPbkdf2Sha256) {
      throw const BackupFormatException('Unknown key derivation.');
    }
    final iterations = _readU32(bytes, 6);
    if (iterations <= 0) {
      throw const BackupFormatException('Damaged header.');
    }
    var at = 10;
    final saltLength = bytes[at];
    if (saltLength != _saltBytes) {
      throw const BackupFormatException('Damaged header.');
    }
    final salt = _readBlock(bytes, at, saltLength);
    at += 1 + saltLength;
    final nonceLength = bytes[at];
    if (nonceLength != _nonceBytes) {
      throw const BackupFormatException('Damaged header.');
    }
    final nonce = _readBlock(bytes, at, nonceLength);
    at += 1 + nonceLength;
    final cipherText = bytes.sublist(at);
    if (cipherText.length <= _tagBits ~/ 8) {
      throw const BackupFormatException('This file is cut short.');
    }

    try {
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(_deriveKey(password, salt, iterations)),
            _tagBits,
            nonce,
            _aad,
          ),
        );
      return cipher.process(cipherText);
    } on InvalidCipherTextException {
      throw const BackupFormatException(
        'Wrong password, or this file has been damaged.',
      );
    }
  }

  /// The header, read without the password — enough for a restore screen to say
  /// what it is about to open before asking the user to type anything.
  static BackupHeader readHeader(List<int> envelope) {
    final bytes = Uint8List.fromList(envelope);
    if (bytes.length < 16 || bytes[4] != formatVersion) {
      throw const BackupFormatException('Not a SpendStory backup file.');
    }
    return BackupHeader(
      iterations: _readU32(bytes, 6),
      kdf: bytes[5],
      version: bytes[4],
    );
  }

  static Uint8List _deriveKey(String password, List<int> salt, int iterations) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(Uint8List.fromList(salt), iterations, _keyBytes));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List _random(Random rng, int length) =>
      Uint8List.fromList(List<int>.generate(length, (_) => rng.nextInt(256)));

  static List<int> _u32(int value) => <int>[
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];

  static int _readU32(Uint8List bytes, int at) =>
      (bytes[at] << 24) |
      (bytes[at + 1] << 16) |
      (bytes[at + 2] << 8) |
      bytes[at + 3];

  static Uint8List _readBlock(Uint8List bytes, int at, int length) =>
      bytes.sublist(at + 1, at + 1 + length);
}

/// What [BackupCodec.readHeader] can tell without the password.
class BackupHeader {
  const BackupHeader({
    required this.version,
    required this.kdf,
    required this.iterations,
  });

  final int version;
  final int kdf;
  final int iterations;
}
