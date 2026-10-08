/// The web preview's store (T-605).
///
/// `billing_client_web.dart` is reached in the app only through the conditional
/// import in `billing_client.dart`, and the web preview has no Play Store at
/// all. What matters is that the stub is *honest*: it says so instead of hanging
/// or pretending, so the paywall can show its estimate note rather than an empty
/// price column, and the rest of the app keeps working.
///
/// (Importing it directly is also what keeps it out of preflight's orphan scan —
/// a file named only inside a conditional import looks unreferenced.)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/pro/billing_client.dart';
import 'package:spendstory/pro/billing_client_web.dart';
import 'package:spendstory/pro/product_ids.dart';

void main() {
  test('is a BillingClient, and it says there is no store', () {
    const client = WebBillingClient();

    expect(client, isA<BillingClient>());
    expect(client.available, isFalse);
  });

  test('opens nothing when asked to buy', () async {
    const client = WebBillingClient();

    for (final plan in ProPlan.values) {
      expect(await client.buy(plan), isFalse, reason: '$plan');
    }
  });

  test(
    'offers no products, which is what makes the screen say "estimate"',
    () async {
      const client = WebBillingClient();

      expect(await client.products(), isEmpty);
    },
  );

  test('has no stream to listen to, and restoring changes nothing', () async {
    const client = WebBillingClient();

    expect(await client.events.isEmpty, isTrue);
    await client.restore();
    expect(await client.events.isEmpty, isTrue);
  });

  test('initializes quietly, however many times it is asked', () async {
    const client = WebBillingClient();

    await client.initialize();
    await client.initialize();
  });

  test('is const, so every web build shares the one instance', () {
    const a = WebBillingClient();
    const b = WebBillingClient();

    expect(identical(a, b), isTrue);
  });
}
