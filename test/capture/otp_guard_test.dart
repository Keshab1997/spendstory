import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/capture/otp_guard.dart';

import 'fixture_loader.dart';

void main() {
  group('OtpGuard', () {
    test('every OTP message in the corpus is rejected (gate: 0 leaks)', () {
      final corpus = loadFixture('otp');
      expect(corpus, isNotEmpty);

      final leaked = <String>[];
      for (final item in corpus) {
        final body = item['body'] as String;
        if (!isOtpOrCredential(body)) {
          leaked.add('${item['note']}: $body');
        }
      }
      expect(
        leaked,
        isEmpty,
        reason:
            'OTP messages must never reach the parser:\n'
            '${leaked.join('\n')}',
      );
    });

    test('no genuine transaction message is mistaken for an OTP (gate: 0 false positives)', () {
      final falsePositives = <String>[];

      for (final name in ['debit', 'credit', 'edge']) {
        for (final item in loadFixture(name)) {
          final body = item['body'] as String;
          if (isOtpOrCredential(body)) {
            falsePositives.add('$name · ${item['note']}: $body');
          }
        }
      }
      for (final item in loadFixture('notifications')) {
        if (item['expect'] == 'otp') continue;
        final body = '${item['title']} ${item['body']}';
        if (isOtpOrCredential(body)) {
          falsePositives.add('notifications · ${item['note']}: $body');
        }
      }

      expect(
        falsePositives,
        isEmpty,
        reason:
            'these transactions would have been dropped:\n'
            '${falsePositives.join('\n')}',
      );
    });

    test(
      'bare short code with no currency and no money verb is a credential',
      () {
        expect(isOtpOrCredential('4321 is your code'), isTrue);
        expect(isOtpOrCredential('Use 998877 to continue'), isTrue);
      },
    );

    test(
      'a reference number inside a real transaction is not a credential',
      () {
        expect(
          isOtpOrCredential(
            'Rs.1,100.00 debited from A/c XX8899 (UPI Ref 99887). Avl Bal Rs.4,000.',
          ),
          isFalse,
        );
      },
    );

    test('Hindi and Bengali credential phrasing is caught', () {
      expect(isOtpOrCredential('यह आपका ओटीपी है'), isTrue);
      expect(isOtpOrCredential('এটি আপনার ওটিপি'), isTrue);
      expect(isOtpOrCredential('कार्ड PIN साझा न करें'), isTrue);
    });

    test('CVV and MPIN never pass', () {
      expect(isOtpOrCredential('CVV 345'), isTrue);
      expect(isOtpOrCredential('Your MPIN is 9988'), isTrue);
    });

    test('empty input is rejected rather than parsed', () {
      expect(isOtpOrCredential(''), isTrue);
    });
  });
}
