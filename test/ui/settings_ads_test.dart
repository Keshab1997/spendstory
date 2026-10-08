/// The ads half of Settings (T-610, `docs/07 §6`, `docs/03 §S-20`).
///
/// `docs/07 §6` asks for one thing in India: an in-app control over
/// personalized ads, in the spirit of the DPDP rules even before they bite. The
/// tests here hold the three properties that make it a real control rather than
/// a decoration — it starts off, it writes the choice down, and the flag every
/// ad request carries follows it. Plus the door UMP sometimes requires, which
/// must exist exactly when it is required and never otherwise.
///
/// Settings carries no ad of its own: S-20 says so, and the audit test in
/// `test/ads/ad_request_audit_test.dart` enforces it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/ads/ad_client.dart' show adClientProvider;
import 'package:spendstory/ads/ad_consent.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/data/db.dart';

import '../ads/fake_ad_client.dart';
import 'ledger_harness.dart';

/// The Settings screen, with the ads seams faked and a real (in-memory)
/// database, because half of this feature *is* the record.
Future<(ProviderContainer, AppDb)> _pumpSettings(
  WidgetTester tester, {
  FakeAdClient? client,
  bool privacyOptions = false,
}) async {
  final db = AppDb.memory();
  addTearDown(db.close);
  // What an Indian install has after its first launch: the default written
  // down, which is what the launch reads. (The harness device reports no
  // country, so the default has to come from the record — which is also the
  // path a real device takes once the user has ever touched the switch.)
  await db.setMeta(ConsentController.metaKey, 'off');

  final container = await pumpAt(
    tester,
    '/settings',
    extra: <Override>[
      appDbProvider.overrideWithValue(db),
      adClientProvider.overrideWithValue(
        client ?? FakeAdClient(privacyOptions: privacyOptions),
      ),
    ],
  );
  return (container, db);
}

void main() {
  group('personalized ads', () {
    testWidgets('is offered, and starts off in India', (tester) async {
      await _pumpSettings(tester);

      await tester.ensureVisible(find.text('Personalized ads'));
      await tester.pumpAndSettle();

      expect(find.text('Personalized ads'), findsOneWidget);
      final toggle = tester.widget<Switch>(switchInTile('Personalized ads'));
      expect(
        toggle.value,
        isFalse,
        reason: 'docs/07 §6: off is the default this app ships with in India',
      );
    });

    testWidgets('turning it on writes the choice down and flips the flag', (
      tester,
    ) async {
      final (container, db) = await _pumpSettings(tester);

      await tester.ensureVisible(find.text('Personalized ads'));
      await tester.pumpAndSettle();
      await tester.tap(switchInTile('Personalized ads'));
      await tester.pumpAndSettle();

      // The choice is the user's, it is stored, and every request carries it —
      // all three, or the control is a lie.
      expect(container.read(consentControllerProvider).personalized, isTrue);
      expect(container.read(nonPersonalizedAdsProvider), isFalse);
      expect(await db.meta(ConsentController.metaKey), 'on');

      // And it can be turned back off, which is the point of having it.
      await tester.tap(switchInTile('Personalized ads'));
      await tester.pumpAndSettle();
      expect(await db.meta(ConsentController.metaKey), 'off');
      expect(container.read(nonPersonalizedAdsProvider), isTrue);
    });

    testWidgets('tapping the row toggles it too, like every other setting', (
      tester,
    ) async {
      final (container, _) = await _pumpSettings(tester);

      await tester.ensureVisible(find.text('Personalized ads'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Personalized ads'));
      await tester.pumpAndSettle();

      expect(container.read(consentControllerProvider).personalized, isTrue);
    });

    testWidgets('says what off means', (tester) async {
      await _pumpSettings(tester);

      // The body names the default and the promise about the ledger — the whole
      // point of the row in `docs/07 §6`.
      final body = find.textContaining('Off by default in India');
      await tester.ensureVisible(body);
      await tester.pumpAndSettle();
      expect(body, findsOneWidget);
      expect(
        find.textContaining('Your spending is never sent'),
        findsOneWidget,
      );
    });
  });

  group('a Pro user', () {
    testWidgets('is not shown an ads control, because they see no ads', (
      tester,
    ) async {
      // The Pro card is what a paying user gets instead; a switch about what
      // ads know would be noise next to it (`docs/07 §6`).
      final db = AppDb.memory();
      addTearDown(db.close);
      await pumpAt(
        tester,
        '/settings',
        extra: <Override>[
          appDbProvider.overrideWithValue(db),
          proStatusProvider.overrideWith((ref) => true),
          adClientProvider.overrideWithValue(FakeAdClient()),
        ],
      );

      await tester.ensureVisible(find.text('SpendStory Pro'));
      await tester.pumpAndSettle();
      expect(find.text('Personalized ads'), findsNothing);
    });
  });

  group('the privacy-options door', () {
    testWidgets('does not exist when the platform does not ask for it', (
      tester,
    ) async {
      await _pumpSettings(tester);

      expect(find.text('Ad privacy options'), findsNothing);
    });

    testWidgets('exists when UMP says it must, and opens the form', (
      tester,
    ) async {
      final client = FakeAdClient(privacyOptions: true);
      await _pumpSettings(tester, client: client, privacyOptions: true);

      await tester.ensureVisible(find.text('Ad privacy options'));
      await tester.pumpAndSettle();
      expect(find.text('Ad privacy options'), findsOneWidget);

      await tester.tap(find.text('Ad privacy options'));
      await tester.pumpAndSettle();

      expect(client.privacyFormCalls, 1);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Your choices are open.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('is offered to a Pro user too, because consent is not a plan', (
      tester,
    ) async {
      // A user who consented before buying Pro has the same right to withdraw it
      // after. The door is the app's obligation, not the ad slot's.
      final db = AppDb.memory();
      addTearDown(db.close);
      await pumpAt(
        tester,
        '/settings',
        extra: <Override>[
          appDbProvider.overrideWithValue(db),
          proStatusProvider.overrideWith((ref) => true),
          adClientProvider.overrideWithValue(
            FakeAdClient(privacyOptions: true),
          ),
        ],
      );

      await tester.ensureVisible(find.text('Ad privacy options'));
      await tester.pumpAndSettle();
      expect(find.text('Ad privacy options'), findsOneWidget);
    });
  });
}
