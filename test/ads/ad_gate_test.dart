/// The interstitial governor (T-602, `docs/08 §4`).
///
/// An interstitial is the ad that can cost a user, so the tests are about what
/// it is *not* allowed to do: not on a screen that was never built, not twice in
/// one session, not within four minutes of the last one, not for a Pro user, and
/// not at all when the ad request is the only thing that failed.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/ads/ad_client.dart';
import 'package:spendstory/ads/ad_gate.dart';
import 'package:spendstory/app/providers.dart';

import 'fake_ad_client.dart';

final _now = DateTime(2026, 10, 8, 20, 42);

ProviderContainer _container({
  required AdClient client,
  bool isPro = false,
  bool onboarded = true,
  DateTime? now,
}) {
  final container = ProviderContainer(
    overrides: <Override>[
      adClientProvider.overrideWithValue(client),
      proStatusProvider.overrideWith((ref) => isPro),
      nowProvider.overrideWithValue(now ?? _now),
      bootProvider.overrideWith(
        (ref) async =>
            BootState(onboarded: onboarded, demoMode: true, locale: 'en'),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('the rules', () {
    const rules = AdGateRules();

    bool allows({
      AdTrigger trigger = AdTrigger.homeToInsights,
      bool isPro = false,
      bool hasAd = true,
      bool adsVisible = true,
      int shown = 0,
      DateTime? lastShownAt,
    }) => rules.allows(
      trigger: trigger,
      isPro: isPro,
      hasAd: hasAd,
      adsVisible: adsVisible,
      shownThisSession: shown,
      lastShownAt: lastShownAt,
      now: _now,
    );

    test('the first one of a session, on the one allowed trigger', () {
      expect(allows(), isTrue);
    });

    test('never a second one in the same session', () {
      expect(allows(shown: 1), isFalse);
      expect(allows(shown: 2), isFalse);
    });

    test('never inside the four-minute floor', () {
      expect(
        allows(lastShownAt: _now.subtract(const Duration(seconds: 239))),
        isFalse,
      );
      expect(
        allows(lastShownAt: _now.subtract(const Duration(seconds: 240))),
        isFalse,
        reason: 'the floor is exclusive: strictly older than four minutes',
      );
      expect(
        allows(lastShownAt: _now.subtract(const Duration(seconds: 241))),
        isTrue,
      );
      expect(
        allows(lastShownAt: _now.subtract(const Duration(hours: 3))),
        isTrue,
      );
    });

    test('never for a Pro user, whatever else is true', () {
      expect(allows(isPro: true), isFalse);
      expect(
        allows(
          isPro: true,
          lastShownAt: _now.subtract(const Duration(hours: 9)),
        ),
        isFalse,
      );
    });

    test('never on a device that has no ads, and never before onboarding', () {
      expect(allows(hasAd: false), isFalse);
      expect(allows(adsVisible: false), isFalse);
    });

    test('the allowed trigger is a list of exactly one', () {
      expect(AdGateRules.allowedTriggers, <AdTrigger>{
        AdTrigger.homeToInsights,
      });
    });
  });

  group('the gate', () {
    test('shows one, records it, and refuses the next attempt', () async {
      final client = configuredClient();
      final container = _container(client: client);
      await container.read(bootProvider.future);

      final gate = container.read(adGateProvider);
      expect(gate.allows(AdTrigger.homeToInsights), isTrue);

      expect(await gate.maybeShow(AdTrigger.homeToInsights), isTrue);
      expect(client.interstitialConsent, hasLength(1));
      expect(gate.shownThisSession, 1);

      // The user goes back home and into Insights again: nothing.
      expect(gate.allows(AdTrigger.homeToInsights), isFalse);
      expect(await gate.maybeShow(AdTrigger.homeToInsights), isFalse);
      expect(client.interstitialConsent, hasLength(1));
    });

    test('a request that never lands does not spend the one showing', () async {
      // The load failed — no ad reached the screen, so the session has not
      // spent its interstitial and the user is not charged for the attempt.
      final client = configuredClient(showsInterstitial: false);
      final container = _container(client: client);
      await container.read(bootProvider.future);

      final gate = container.read(adGateProvider);
      expect(await gate.maybeShow(AdTrigger.homeToInsights), isFalse);
      expect(gate.shownThisSession, 0);
      expect(gate.allows(AdTrigger.homeToInsights), isTrue);
    });

    test('a Pro user never even asks the SDK', () async {
      final client = configuredClient();
      final container = _container(client: client, isPro: true);
      await container.read(bootProvider.future);

      final gate = container.read(adGateProvider);
      expect(gate.allows(AdTrigger.homeToInsights), isFalse);
      expect(await gate.maybeShow(AdTrigger.homeToInsights), isFalse);
      expect(client.interstitialConsent, isEmpty);
    });

    test(
      'a device with no ads, or a release with no ids, stays silent',
      () async {
        for (final client in <FakeAdClient>[
          FakeAdClient(hasAds: false),
          FakeAdClient(hasAds: true, interstitial: null),
        ]) {
          final container = _container(client: client);
          await container.read(bootProvider.future);
          expect(
            await container
                .read(adGateProvider)
                .maybeShow(AdTrigger.homeToInsights),
            isFalse,
          );
          expect(client.interstitialConsent, isEmpty);
        }
      },
    );

    test('before onboarding finishes there is nothing to interrupt', () async {
      final client = configuredClient();
      final container = _container(client: client, onboarded: false);
      await container.read(bootProvider.future);

      expect(
        await container
            .read(adGateProvider)
            .maybeShow(AdTrigger.homeToInsights),
        isFalse,
      );
      expect(client.interstitialConsent, isEmpty);
    });

    test('the interstitial carries the consent answer, not a ledger fact', () async {
      final client = configuredClient();
      final container = _container(client: client);
      await container.read(bootProvider.future);

      await container.read(adGateProvider).maybeShow(AdTrigger.homeToInsights);
      // False by default: the request is personalized only if consent says so.
      expect(client.interstitialConsent.single, isFalse);
    });
  });
}
