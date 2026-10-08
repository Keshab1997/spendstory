/// Consent before the first ad request (T-607, `docs/08 §7`).
///
/// Two things are being checked here, and they are different claims:
///
/// * the **pure** rules — what the default is for a country, what a stored
///   choice does to it, and when an ad may be requested at all;
/// * the **controller** — that a launch reads the choice, sets the flag every
///   request carries, runs Google's flow, and starts the SDK *only* when the
///   flow says it may.
///
/// The second one is the one that matters: an ad shown without consent is the
/// expensive mistake, and it is invisible in a UI test.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/ads/ad_client.dart';
import 'package:spendstory/ads/ad_consent.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/data/db.dart';

import 'fake_ad_client.dart';

void main() {
  group('the default for a country', () {
    test('is not personalized in India', () {
      expect(personalizedAdsDefaultFor('IN'), isFalse);
      expect(personalizedAdsDefaultFor('in'), isFalse);
    });

    test('is personalized everywhere else, and when the region is unknown', () {
      // Not a policy statement about those countries — it is what their store
      // listings and the consent form already assume.
      expect(personalizedAdsDefaultFor('GB'), isTrue);
      expect(personalizedAdsDefaultFor('DE'), isTrue);
      expect(personalizedAdsDefaultFor(null), isTrue);
    });

    test('a stored choice always beats the region', () {
      expect(personalizedChoiceFrom('on', countryCode: 'IN'), isTrue);
      expect(personalizedChoiceFrom('off', countryCode: 'GB'), isFalse);
    });

    test('anything unreadable falls back to the region, not to "on"', () {
      for (final stored in <String?>[null, '', 'yes', 'TRUE', '1']) {
        expect(
          personalizedChoiceFrom(stored, countryCode: 'IN'),
          isFalse,
          reason: '$stored',
        );
      }
    });
  });

  group('may an ad be requested', () {
    test('when consent was obtained or is not required', () {
      expect(adsAllowedFor(ConsentState.obtained), isTrue);
      expect(adsAllowedFor(ConsentState.notRequired), isTrue);
    });

    test('not when the user was asked and did not agree', () {
      expect(adsAllowedFor(ConsentState.required), isFalse);
    });

    test('on a platform with no consent SDK, where the client decides', () {
      // `unknown` is "the flow has not run here". The mobile client starts
      // closed and opens only on a real answer, so this is a readable statement
      // of that rule rather than a second gate that could disagree with it.
      expect(adsAllowedFor(ConsentState.unknown), isTrue);
    });
  });

  group('a launch', () {
    late AppDb db;

    setUp(() async => db = AppDb.memory());
    tearDown(() async => db.close());

    ProviderContainer container(FakeAdClient client) {
      final c = ProviderContainer(
        overrides: <Override>[
          appDbProvider.overrideWithValue(db),
          adClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('asks Google, then starts the SDK — in that order', () async {
      final client = FakeAdClient(consentState: ConsentState.obtained);
      final c = container(client);

      await c.read(consentControllerProvider).start(countryCode: 'GB');

      expect(client.consentChecks, 1);
      expect(client.initializeCalls, 1);
      expect(c.read(consentStateProvider), ConsentState.obtained);
    });

    test('does not start the SDK at all when consent was refused', () async {
      final client = FakeAdClient(consentState: ConsentState.required);
      final c = container(client);

      await c.read(consentControllerProvider).start(countryCode: 'DE');

      expect(client.consentChecks, 1);
      expect(
        client.initializeCalls,
        0,
        reason: 'a user who said no must not have the SDK started behind them',
      );
      expect(c.read(consentStateProvider), ConsentState.required);
    });

    test(
      'sets the flag every request carries, from the Indian default',
      () async {
        final c = container(FakeAdClient());

        await c.read(consentControllerProvider).start(countryCode: 'IN');
        expect(c.read(nonPersonalizedAdsProvider), isTrue);

        // …and a device with another region is left personalized until the user
        // says otherwise (T-610 puts that switch in Settings).
        await c.read(consentControllerProvider).start(countryCode: 'GB');
        expect(c.read(nonPersonalizedAdsProvider), isFalse);
      },
    );

    test('a stored choice survives the launch, and beats the region', () async {
      await db.setMeta('personalizedAds', 'on');

      final c = container(FakeAdClient());
      await c.read(consentControllerProvider).start(countryCode: 'IN');

      expect(c.read(nonPersonalizedAdsProvider), isFalse);
      expect(c.read(consentControllerProvider).personalized, isTrue);
    });

    test('turning it off writes the choice down', () async {
      final c = container(FakeAdClient());
      await c.read(consentControllerProvider).setPersonalized(true);
      expect(await db.meta('personalizedAds'), 'on');

      await c.read(consentControllerProvider).setPersonalized(false);
      expect(await db.meta('personalizedAds'), 'off');
      expect(c.read(nonPersonalizedAdsProvider), isTrue);
    });

    test(
      'knows whether the platform requires a privacy-options door',
      () async {
        final c = container(FakeAdClient(privacyOptions: true));
        expect(
          await c.read(consentControllerProvider).privacyOptionsRequired(),
          isTrue,
        );
      },
    );
  });

  test('a platform with no ad SDK reports "no form needed"', () async {
    // The real client, not a fake — on this VM (and on the web) it has no ads to
    // ask about, and `ad_client_web.dart` says the same thing for the preview.
    final c = ProviderContainer(
      overrides: <Override>[appDbProvider.overrideWithValue(null)],
    );
    addTearDown(c.dispose);

    await c.read(consentControllerProvider).start(countryCode: 'IN');

    expect(c.read(consentStateProvider), ConsentState.notRequired);
    expect(c.read(nonPersonalizedAdsProvider), isTrue);
  });
}
