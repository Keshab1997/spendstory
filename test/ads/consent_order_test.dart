/// The launch order, through the real app (T-607).
///
/// `test/ads/ad_consent_test.dart` checks the controller in isolation. What this
/// file checks is the thing that is easy to get wrong in a shell and impossible
/// to see in a screenshot: that opening the app runs the consent flow, sets the
/// flag every request carries, and *starts the SDK only if the answer allows it*.
///
/// It uses the real `MainShell`, so the ordering asserted here is the ordering
/// the app actually has.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/ads/ad_client.dart';
import 'package:spendstory/ads/ad_consent.dart';
import 'package:spendstory/app/app.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/pro/rewards.dart';

import 'fake_ad_client.dart';

Future<ProviderContainer> _boot(
  WidgetTester tester,
  FakeAdClient client, {
  bool isPro = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: <Override>[
      appDbProvider.overrideWithValue(null),
      adClientProvider.overrideWithValue(client),
      if (isPro) proStatusProvider.overrideWith((ref) => true),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SpendStoryApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('the shell asks for consent, then starts the SDK', (
    tester,
  ) async {
    final client = FakeAdClient();
    final container = await _boot(tester, client);

    // The shell's post-frame work only runs once the app is past the splash.
    expect(client.consentChecks, 1);
    expect(client.initializeCalls, 1);
    expect(container.read(consentStateProvider), ConsentState.notRequired);
  });

  testWidgets('a user who declined gets no ad SDK started at all', (
    tester,
  ) async {
    final client = FakeAdClient(consentState: ConsentState.required);
    final container = await _boot(tester, client);

    expect(client.consentChecks, 1);
    expect(client.initializeCalls, 0);
    expect(container.read(consentStateProvider), ConsentState.required);
  });

  testWidgets('a Pro user is asked nothing and starts nothing', (tester) async {
    // The ad-free promise covers the consent form too: a paying user is not
    // interrupted by an ad flow, and their phone never starts the SDK.
    final client = FakeAdClient();
    await _boot(tester, client, isPro: true);

    expect(client.consentChecks, 0);
    expect(client.initializeCalls, 0);
  });

  testWidgets('the Indian default is written into every request', (
    tester,
  ) async {
    final client = FakeAdClient();
    final container = await _boot(tester, client);

    // The test VM reports no country, so this is the "not India" default; the
    // India case is asserted in `ad_consent_test.dart` where the country can be
    // handed in.
    expect(container.read(nonPersonalizedAdsProvider), isFalse);

    await container.read(consentControllerProvider).setPersonalized(false);
    expect(container.read(nonPersonalizedAdsProvider), isTrue);
  });

  testWidgets('today’s reward counters are read on launch', (tester) async {
    final client = FakeAdClient();
    final container = await _boot(tester, client);

    // The ledger publishes what it has granted, which is what the offer button
    // reads to decide between a button and a sentence.
    expect(container.read(rewardGrantedTodayProvider), isEmpty);
    expect(container.read(pdfExportCreditsProvider), 0);
  });
}
