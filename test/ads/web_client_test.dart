/// The web / no-SDK client (T-601).
///
/// The web preview is the build Keshab actually looks at between apk builds, and
/// it has no AdMob at all. This file is the contract for that build: every
/// question about ads answers "nothing", and nothing about it throws — which is
/// also what makes the preview a real test of the degraded path the release
/// build falls into when the live ids are not filled in yet.
///
/// It is a direct import on purpose: the app reaches this file through a
/// conditional import (`lib/ads/ad_client.dart`), which is invisible to both the
/// analyzer's dead-code pass and `tool/preflight.py`'s orphan scan. A test that
/// names it is how it stays wired up.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/ads/ad_client.dart'
    show AdClient, ConsentState, RewardedOutcome;
import 'package:spendstory/ads/ad_client_web.dart'
    show WebAdClient, createAdClient;
import 'package:spendstory/ads/ad_placement.dart';

void main() {
  test('the factory hands back the web client', () {
    expect(createAdClient(), isA<WebAdClient>());
  });

  group('on a platform with no ads', () {
    const client = WebAdClient();

    test('there is nothing to show', () {
      expect(client.hasAds, isFalse);
      expect(client.appId, isNull);
      expect(client.interstitialUnitId, isNull);
    });

    test('no placement has a unit, not even the test one', () {
      for (final placement in AdPlacement.values) {
        // Not Google's test id either: the preview must not ask the SDK for
        // anything, and it must not pretend a test unit exists.
        expect(client.unitIdFor(placement), isNull, reason: '$placement');
      }
    });

    test('there is no widget to mount, and no interstitial to show', () async {
      var outcomes = 0;
      expect(
        client.adView(
          placement: AdPlacement.homeBanner,
          nonPersonalized: false,
          onOutcome: (_) => outcomes += 1,
        ),
        isNull,
      );
      // Nothing was created, so there is no outcome to report — a slot that
      // never reports would sit on a blank box forever.
      expect(outcomes, 0);

      expect(await client.showInterstitial(nonPersonalized: false), isFalse);
    });

    test('there is no rewarded ad to watch either (T-606)', () async {
      expect(client.rewardedUnitId, isNull);
      expect(
        await client.showRewarded(nonPersonalized: true),
        RewardedOutcome.unavailable,
      );
    });

    test(
      'there is nothing to consent to, and no privacy door to offer (T-607)',
      () async {
        // `notRequired`, not `unknown`: the preview must not be stuck in the
        // "consent has not run, request nothing" state that the mobile client
        // starts in, because it has nothing to request either way.
        expect(await client.ensureConsent(), ConsentState.notRequired);
        expect(await client.privacyOptionsRequired(), isFalse);
      },
    );

    test('initializing is a no-op rather than a crash', () async {
      await client.initialize();
      await client.initialize(); // idempotent, like the real SDK call
      expect(client.hasAds, isFalse);
    });

    test('the client is a real AdClient, and const, so it costs nothing', () {
      const client = WebAdClient();
      expect(client, isA<AdClient>());
    });
  });
}
