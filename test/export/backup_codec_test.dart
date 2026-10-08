/// The backup envelope (T-705, `docs/07 §5`).
///
/// What matters here is not that AES works — it is that a backup file can be
/// trusted in the two directions a user will actually meet it: the same password
/// opens it on another phone, and any other answer (a wrong password, a file
/// with one byte changed, a file that is not ours at all) is a refusal rather
/// than a half-restored ledger.
///
/// Everything runs at 1,000 PBKDF2 iterations instead of the shipped 120,000:
/// the arithmetic is identical, and the test suite does not need to spend a
/// second per case proving it.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/export/backup_codec.dart';

const int _iterations = 1000;
const String _password = 'hunter2-hunter2';

Uint8List _plain() => Uint8List.fromList(
  utf8.encode('{"format":"spendstory-backup","version":1,"transactions":[]}'),
);

void main() {
  group('the envelope', () {
    test('comes back exactly as it went in', () {
      final envelope = BackupCodec.encrypt(
        plain: _plain(),
        password: _password,
        iterations: _iterations,
      );

      final opened = BackupCodec.decrypt(
        envelope: envelope,
        password: _password,
      );

      expect(utf8.decode(opened), utf8.decode(_plain()));
    });

    test('carries its own magic bytes, version and iteration count', () {
      final envelope = BackupCodec.encrypt(
        plain: _plain(),
        password: _password,
        iterations: _iterations,
      );

      // The header is what a future version reads, so it is checked byte by
      // byte rather than through a helper that could drift with it.
      expect(envelope.sublist(0, 4), BackupCodec.magic);
      expect(envelope[4], BackupCodec.formatVersion);
      expect(envelope[5], BackupCodec.kdfPbkdf2Sha256);
      expect(envelope.sublist(6, 10), <int>[
        _iterations >> 24,
        _iterations >> 16 & 0xFF,
        _iterations >> 8 & 0xFF,
        _iterations & 0xFF,
      ]);

      final header = BackupCodec.readHeader(envelope);
      expect(header.version, BackupCodec.formatVersion);
      expect(header.iterations, _iterations);
    });

    test('never writes the same file twice', () {
      // A fresh salt and nonce per backup: two backups of an unchanged ledger
      // must not be byte-identical, or an attacker who has one can tell that
      // the other says the same thing.
      final first = BackupCodec.encrypt(
        plain: _plain(),
        password: _password,
        iterations: _iterations,
      );
      final second = BackupCodec.encrypt(
        plain: _plain(),
        password: _password,
        iterations: _iterations,
      );

      expect(first, isNot(equals(second)));
      expect(
        utf8.decode(BackupCodec.decrypt(envelope: first, password: _password)),
        utf8.decode(_plain()),
      );
      expect(
        utf8.decode(BackupCodec.decrypt(envelope: second, password: _password)),
        utf8.decode(_plain()),
      );
    });

    test('does not store the password, or anything derived from it', () {
      final envelope = BackupCodec.encrypt(
        plain: _plain(),
        password: _password,
        iterations: _iterations,
      );

      expect(
        utf8.decode(envelope, allowMalformed: true),
        isNot(contains(_password)),
      );
      expect(utf8.decode(_plain()), isNot(contains(_password)));
    });
  });

  group('a file that will not open', () {
    test('refuses the wrong password', () {
      final envelope = BackupCodec.encrypt(
        plain: _plain(),
        password: _password,
        iterations: _iterations,
      );

      expect(
        () =>
            BackupCodec.decrypt(envelope: envelope, password: 'not-it-not-it'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a file that was edited in transit', () {
      final envelope = BackupCodec.encrypt(
        plain: _plain(),
        password: _password,
        iterations: _iterations,
      );
      // One flipped bit in the ciphertext: GCM's whole job.
      final tampered = Uint8List.fromList(envelope);
      tampered[tampered.length - 1] ^= 0x01;

      expect(
        () => BackupCodec.decrypt(envelope: tampered, password: _password),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a file that is not a backup at all', () {
      final notOurs = Uint8List.fromList(utf8.encode('{"hello":"world"}'));

      expect(
        () => BackupCodec.decrypt(envelope: notOurs, password: _password),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.reason,
            'reason',
            contains('Not a SpendStory backup'),
          ),
        ),
      );
    });

    test('refuses a file from a newer version instead of guessing', () {
      final newer = Uint8List.fromList(<int>[
        ...BackupCodec.magic,
        BackupCodec.formatVersion + 1,
        BackupCodec.kdfPbkdf2Sha256,
        0,
        0,
        0,
        1,
        ...List<int>.filled(40, 0),
      ]);

      expect(
        () => BackupCodec.decrypt(envelope: newer, password: _password),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.reason,
            'reason',
            contains('another version'),
          ),
        ),
      );
    });

    test('refuses a truncated file', () {
      final envelope = BackupCodec.encrypt(
        plain: _plain(),
        password: _password,
        iterations: _iterations,
      );

      expect(
        () => BackupCodec.decrypt(
          envelope: envelope.sublist(0, 20),
          password: _password,
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('asks for a password when there is none', () {
      final envelope = BackupCodec.encrypt(
        plain: _plain(),
        password: _password,
        iterations: _iterations,
      );

      expect(
        () => BackupCodec.decrypt(envelope: envelope, password: ''),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => BackupCodec.encrypt(plain: _plain(), password: ''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
