import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/capture/merchant_normalizer.dart';

void main() {
  group('matchKey', () {
    test('lowercases and strips punctuation', () {
      expect(matchKey('BigBasket'), 'bigbasket');
      expect(matchKey('Amazon Pay'), 'amazon pay');
      expect(matchKey('ramesh.kumar'), 'ramesh kumar');
      expect(matchKey('ACME-SERVICES (P) LTD.'), 'acme services p ltd');
      expect(matchKey('  Swiggy  '), 'swiggy');
    });

    test('leaves Devanagari and Bengali text intact', () {
      expect(matchKey('দীপা'), 'দীপা');
      expect(matchKey('रमेश'), 'रमेश');
    });

    test('is idempotent', () {
      const raw = 'Big-Basket India Pvt. Ltd.';
      expect(matchKey(matchKey(raw)), matchKey(raw));
    });
  });

  group('isGeneric', () {
    test('payment rails and bank words are generic', () {
      for (final w in ['UPI', 'neft', 'at', 'the', 'A/c', 'ATM', 'wallet']) {
        expect(isGeneric(w), isTrue, reason: w);
      }
    });

    test('account fragments and reference numbers are generic', () {
      expect(isGeneric('XX4521'), isTrue);
      expect(isGeneric('123456789'), isTrue);
      expect(isGeneric('REF987654'), isTrue);
    });

    test('real merchant words are not generic', () {
      for (final w in ['Swiggy', 'BigBasket', 'Ramesh', 'Deepa']) {
        expect(isGeneric(w), isFalse, reason: w);
      }
    });

    test('very short fragments are generic', () {
      expect(isGeneric('a'), isTrue);
      expect(isGeneric('ok'), isTrue);
      expect(isGeneric(''), isTrue);
    });
  });

  group('canonical', () {
    test('maps known merchants to their display spelling', () {
      expect(canonical('bigbasket'), 'BigBasket');
      expect(canonical('BIG BASKET'), 'BigBasket');
      expect(canonical('phonepe'), 'PhonePe');
      expect(canonical('phone pe'), 'PhonePe');
      expect(canonical('grofers'), 'Blinkit');
      expect(canonical('jio'), 'Jio');
      expect(canonical('1mg'), 'Tata 1mg');
      expect(canonical('dominos'), 'Domino\'s');
    });

    test('the leftmost known merchant wins in a phrase', () {
      // "Amazon Refund" is a refund *from Amazon*, not a merchant called Refund.
      expect(canonical('Amazon Refund'), 'Amazon');
      expect(canonical('Swiggy Refund'), 'Swiggy');
    });

    test('a longer key breaks a tie at the same position', () {
      expect(canonical('amazon pay'), 'Amazon Pay');
      expect(canonical('prime video'), 'Prime Video');
      expect(canonical('bajaj finserv emi'), 'Bajaj Finserv');
    });

    test('merchant words inside a longer phrase are found', () {
      expect(canonical('paytm wallet'), 'Paytm');
      expect(canonical('BigBasket Online'), 'BigBasket');
    });

    test('unknown names are title-cased and cleaned', () {
      expect(canonical('ramesh kumar'), 'Ramesh Kumar');
      expect(canonical('DEEPA GIFT'), 'Deepa Gift');
      expect(canonical('sharma provision'), 'Sharma Provision');
    });

    test('returns null when there is no merchant at all', () {
      expect(canonical(null), isNull);
      expect(canonical(''), isNull);
      expect(canonical('A/c'), isNull);
      expect(canonical('UPI'), isNull);
      expect(canonical('your account 123456789'), isNull);
      expect(canonical('xx4521'), isNull);
    });
  });
}
