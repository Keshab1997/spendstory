/// The one widget an ad can appear in (T-608, `docs/08 §3`, §9).
///
/// The contract, in the order it is checked below: a Pro user gets nothing, an
/// un-onboarded user gets nothing, a failed load leaves nothing behind, a
/// screen with no ads for this build gets nothing on a device, and whatever *is*
/// shown is labelled and sits in a box of the reserved height.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/ads/ad_client.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/ui/components/ad_slot.dart';

import 'fake_ad_client.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

List<Override> _boot({required bool onboarded}) => <Override>[
  bootProvider.overrideWith(
    (ref) async =>
        BootState(onboarded: onboarded, demoMode: true, locale: 'en'),
  ),
  localeProvider.overrideWith((ref) => 'en'),
];

void main() {
  group('S-09 … S-19 the slot renders', () {
    testWidgets('an ad that loaded, in a box of the reserved height', (
      tester,
    ) async {
      final client = configuredClient();
      final container = await pumpIn(
        tester,
        _host(const AdSlot(placement: AdPlacement.homeBanner)),
        overrides: <Override>[
          ..._boot(onboarded: true),
          adClientProvider.overrideWithValue(client),
        ],
      );
      await container.read(bootProvider.future);
      await tester.pumpAndSettle();

      expect(find.text('FAKE AD'), findsOneWidget);
      expect(client.views.single, AdPlacement.homeBanner);

      final box = tester.getSize(
        find
            .ancestor(
              of: find.text('FAKE AD'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(
        box.height,
        greaterThanOrEqualTo(AdSlot.heightFor(AdPlacement.homeBanner)),
      );
    });

    testWidgets('every ad carries its label, above the creative', (
      tester,
    ) async {
      final container = await pumpIn(
        tester,
        _host(const AdSlot(placement: AdPlacement.budgetNative)),
        overrides: <Override>[
          ..._boot(onboarded: true),
          adClientProvider.overrideWithValue(configuredClient()),
        ],
      );
      await container.read(bootProvider.future);
      await tester.pumpAndSettle();

      // "Advertisement" — the policy wants it on the unit, not in a doc.
      expect(find.text('Advertisement'), findsOneWidget);

      // And painted *over* the creative: a label tucked under the ad's own
      // pixels is the same as no label at all.
      final stack = tester.widget<Stack>(
        find
            .ancestor(
              of: find.text('Advertisement'),
              matching: find.byType(Stack),
            )
            .first,
      );
      expect(stack.children.last, isA<Positioned>());
      expect(find.text('FAKE AD'), findsOneWidget);
    });

    testWidgets('an ad that never loads leaves nothing behind', (tester) async {
      final client = configuredClient(loads: false);
      final container = await pumpIn(
        tester,
        _host(const AdSlot(placement: AdPlacement.insightsBanner)),
        overrides: <Override>[
          ..._boot(onboarded: true),
          adClientProvider.overrideWithValue(client),
        ],
      );
      await container.read(bootProvider.future);
      await tester.pumpAndSettle();

      // The request went out and failed; the page closes up rather than
      // reserving space for something that will never arrive.
      expect(client.views, hasLength(1));
      expect(find.text('FAKE AD'), findsNothing);
      expect(
        tester.getSize(find.byType(AdSlot)).height,
        0,
        reason: 'a failed ad must not leave a 56px hole',
      );
    });

    testWidgets('a native unit is never asked to shrink below its floor', (
      tester,
    ) async {
      final container = await pumpIn(
        tester,
        _host(const AdSlot(placement: AdPlacement.recurringNative)),
        overrides: <Override>[
          ..._boot(onboarded: true),
          adClientProvider.overrideWithValue(configuredClient()),
        ],
      );
      await container.read(bootProvider.future);
      await tester.pumpAndSettle();

      final box = tester.widget<ConstrainedBox>(
        find
            .ancestor(
              of: find.text('FAKE AD'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(
        box.constraints.minHeight,
        AdSlot.heightFor(AdPlacement.recurringNative),
      );
      // A native template brings its own height; the floor is a floor, not a
      // ceiling, or the ad's own click target would be clipped.
      expect(box.constraints.maxHeight, double.infinity);
    });
  });

  group('S-22 … the slot stays empty', () {
    testWidgets('for a Pro user, on every placement', (tester) async {
      final client = configuredClient();
      for (final placement in AdPlacement.values) {
        final container = await pumpIn(
          tester,
          _host(AdSlot(placement: placement)),
          overrides: <Override>[
            ..._boot(onboarded: true),
            adClientProvider.overrideWithValue(client),
            proStatusProvider.overrideWith((ref) => true),
          ],
        );
        await container.read(bootProvider.future);
        await tester.pumpAndSettle();

        expect(find.text('FAKE AD'), findsNothing, reason: '$placement');
        expect(find.text('Advertisement'), findsNothing, reason: '$placement');
        expect(
          tester.getSize(find.byType(AdSlot)).height,
          0,
          reason: '$placement',
        );
      }
      // Not one request was made for any of them.
      expect(client.views, isEmpty);
    });

    testWidgets('before onboarding has finished', (tester) async {
      final client = configuredClient();
      final container = await pumpIn(
        tester,
        _host(const AdSlot(placement: AdPlacement.homeBanner)),
        overrides: <Override>[
          ..._boot(onboarded: false),
          adClientProvider.overrideWithValue(client),
        ],
      );
      await container.read(bootProvider.future);
      await tester.pumpAndSettle();

      expect(find.text('FAKE AD'), findsNothing);
      expect(
        tester.getSize(find.byType(AdSlot)).height,
        0,
        reason: 'onboarding is ad-free by policy',
      );
      expect(client.views, isEmpty);
    });

    testWidgets('when the build has no unit for this placement', (
      tester,
    ) async {
      // A device with ads but an empty live-id table — a release build before
      // the AdMob console has been filled in. Nothing is requested.
      final client = FakeAdClient(unitIds: const <AdPlacement, String>{});
      final container = await pumpIn(
        tester,
        _host(const AdSlot(placement: AdPlacement.accountsBanner)),
        overrides: <Override>[
          ..._boot(onboarded: true),
          adClientProvider.overrideWithValue(client),
        ],
      );
      await container.read(bootProvider.future);
      await tester.pumpAndSettle();

      expect(client.views, isEmpty);
      expect(find.text('FAKE AD'), findsNothing);
      // Debug builds show the labelled placeholder instead, so the placement
      // can still be reviewed before there is an AdMob account.
      expect(find.textContaining('Advertisement'), findsOneWidget);
      expect(find.textContaining('ss_accounts_banner'), findsOneWidget);
    });

    testWidgets('and on a platform with no SDK at all', (tester) async {
      final container = await pumpIn(
        tester,
        _host(const AdSlot(placement: AdPlacement.insightsBanner)),
        overrides: <Override>[
          ..._boot(onboarded: true),
          adClientProvider.overrideWithValue(FakeAdClient(hasAds: false)),
        ],
      );
      await container.read(bootProvider.future);
      await tester.pumpAndSettle();

      expect(find.text('FAKE AD'), findsNothing);
      expect(find.textContaining('ss_insights_banner'), findsOneWidget);
    });
  });
}
