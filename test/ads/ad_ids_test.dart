/// AdMob ids and the flavor switch (T-601, `docs/08 §2`, §9).
///
/// Two failures this file exists to prevent, both of them fatal to an AdMob
/// account rather than to the app: a **test id in a release build**, and a
/// **live id in a debug build**. They are the same mistake in opposite
/// directions, so both directions are asserted here.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/ads/ad_ids.dart';
import 'package:spendstory/ads/ad_placement.dart';

void main() {
  group('the inventory', () {
    test('every placement in docs/08 §2 has a unit name and a shape', () {
      expect(AdPlacement.values, hasLength(6));

      final names = <String>{};
      for (final placement in AdPlacement.values) {
        final name = unitNameOf(placement);
        // The console reads `ss_…`, and two placements sharing a name would
        // silently merge their reports.
        expect(name, startsWith('ss_'));
        expect(names.add(name), isTrue, reason: '$name appears twice');
      }
    });

    test('the reserved height fits the shape it reserves for', () {
      for (final placement in AdPlacement.values) {
        final height = reservedHeightOf(placement);
        switch (formatOf(placement)) {
          // 320×50 inside 56 leaves the label its room.
          case AdFormat.banner:
            expect(height, 56);
          case AdFormat.native:
            expect(height, greaterThanOrEqualTo(84));
          case AdFormat.interstitial || AdFormat.rewarded:
            fail('a placement is never a whole-screen format');
        }
      }
    });

    test('no placement claims a whole-screen format', () {
      for (final placement in AdPlacement.values) {
        expect(
          formatOf(placement),
          anyOf(AdFormat.banner, AdFormat.native),
          reason: '$placement',
        );
      }
    });
  });

  group('debug builds', () {
    test('get Google test ids, on both platforms, per shape', () {
      expect(
        unitIdFor(AdPlacement.homeBanner, testIds: true, android: true),
        AdTestIds.bannerAndroid,
      );
      expect(
        unitIdFor(AdPlacement.insightsBanner, testIds: true, android: false),
        AdTestIds.bannerIos,
      );
      expect(
        unitIdFor(AdPlacement.budgetNative, testIds: true, android: true),
        AdTestIds.nativeAndroid,
      );
      expect(
        unitIdFor(AdPlacement.recurringNative, testIds: true, android: false),
        AdTestIds.nativeIos,
      );
    });

    test('never resolve to a live id', () {
      for (final placement in AdPlacement.values) {
        for (final android in <bool>[true, false]) {
          final id = unitIdFor(placement, testIds: true, android: android)!;
          expect(id, startsWith('ca-app-pub-3940256099942544/'));
        }
      }
    });

    test('carry the test app id, which is the one the manifest gets', () {
      expect(appIdFor(testIds: true), AdTestIds.appId);
      expect(AdTestIds.appId, endsWith('~3347511713'));
    });

    test(
      'the interstitial and rewarded units exist for the gate and the export',
      () {
        expect(interstitialUnitId(testIds: true), AdTestIds.interstitial);
        expect(rewardedUnitId(testIds: true), AdTestIds.rewarded);
      },
    );

    test('this build is a debug one, so the app is running on test ids', () {
      // `flutter test` is not a release build; if this ever fails, the flavor
      // switch has been hard-wired and the tests below are lying.
      expect(adTestMode, isTrue);
    });
  });

  group('release builds', () {
    test('ask for nothing until the live ids are filled in', () {
      // AdLiveIds is empty in the repo on purpose: Keshab creates the units in
      // the console first. An empty id must mean "no ad", never a request with
      // a test id in it.
      for (final placement in AdPlacement.values) {
        final id = unitIdFor(placement, testIds: false, android: true);
        expect(
          id,
          anyOf(isNull, isNot(startsWith('ca-app-pub-3940256099942544/'))),
          reason: '$placement',
        );
      }
    });

    test('have no app id and no whole-screen units yet either', () {
      expect(appIdFor(testIds: false), anyOf(isNull, isNotEmpty));
      expect(
        interstitialUnitId(testIds: false),
        anyOf(isNull, isNot(startsWith('ca-app-pub-3940256099942544/'))),
      );
      expect(
        rewardedUnitId(testIds: false),
        anyOf(isNull, isNot(startsWith('ca-app-pub-3940256099942544/'))),
      );
    });

    test('are "not configured" while the live app id is empty', () {
      if (AdLiveIds.appId.isEmpty) {
        expect(adIdsConfigured, isFalse);
      }
    });
  });
}
