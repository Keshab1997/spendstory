/// S-21 About & privacy (T-704) — what the notice must say, and to whom.
///
/// `docs/07 §5` is a table of DPDP obligations, and this file is that table
/// turned into assertions: the notice exists in-app and in the user's language,
/// it names every permission the manifest asks for *and* explains why, it
/// repeats the rights triad in the user's own words, it says how to delete
/// everything, and it offers a way to reach a human. The one thing it must
/// never do is invent a contact address, so that has a test of its own.
///
/// The screen is driven through the real router, because half of what makes it
/// compliant is *where it is reachable from*: Settings, and the permission
/// screen at the moment of the first ask.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/app_info.dart';
import 'package:spendstory/ui/components/ad_slot.dart';
import 'package:spendstory/ui/strings.dart';

import 'ledger_harness.dart';

const SsStrings _en = SsStrings('en');
const SsStrings _bn = SsStrings('bn');

/// Every permission S-21 has to explain in plain language, in the order
/// `docs/07 §1` lists them. The titles are what a reader scans for.
const List<String> _permissionKeys = <String>[
  'aboutPermSmsTitle',
  'aboutPermNotifyTitle',
  'aboutPermAlertsTitle',
  'aboutPermLockTitle',
  'aboutPermInternetTitle',
];

/// The rights `docs/07 §5` requires the user to be told about — access,
/// correction, erasure, withdrawal — in that order.
const List<String> _rightKeys = <String>[
  'aboutRightAccessTitle',
  'aboutRightCorrectTitle',
  'aboutRightEraseTitle',
  'aboutRightWithdrawTitle',
];

void main() {
  group('the notice says what it has to say', () {
    testWidgets('what we collect, per permission, per right, and the steps', (
      tester,
    ) async {
      await pumpAt(tester, '/about');

      // "Nothing", said in a sentence rather than a bullet.
      expect(find.text(_en['aboutCollectTitle']), findsOneWidget);
      expect(find.text(_en['aboutCollectBody']), findsOneWidget);

      for (final key in _permissionKeys) {
        expect(find.text(_en[key]), findsOneWidget, reason: key);
        expect(
          find.text(_en['${key.substring(0, key.length - 5)}Body']),
          findsOneWidget,
          reason:
              '$key has no explanation - a permission with no reason is a '
              'permission the user cannot consent to',
        );
      }

      for (final key in _rightKeys) {
        expect(find.text(_en[key]), findsOneWidget, reason: key);
      }
      for (final step in <String>[
        'aboutEraseStep1',
        'aboutEraseStep2',
        'aboutEraseStep3',
      ]) {
        expect(find.text(_en[step]), findsOneWidget, reason: step);
      }
    });

    testWidgets('it is written in the language the app is running in', (
      tester,
    ) async {
      await pumpAt(tester, '/about', locale: 'bn');

      expect(find.text(_bn['aboutScreenTitle']), findsOneWidget);
      expect(find.text(_bn['aboutCollectBody']), findsOneWidget);
      expect(find.text(_en['aboutCollectBody']), findsNothing);
      // Bengali digits on the steps, like every other number in the app.
      expect(find.text('১'), findsOneWidget);
    });

    testWidgets('the DPDP contact is stated, and no address is invented', (
      tester,
    ) async {
      await pumpAt(tester, '/about');

      expect(find.text(_en['aboutContactTitle']), findsOneWidget);
      expect(find.text(_en['aboutContactBody']), findsOneWidget);
      if (AppInfo.hasGrievanceEmail) {
        expect(find.text(AppInfo.grievanceEmail), findsOneWidget);
      } else {
        // While the address is not live the screen says so, rather than
        // showing a plausible-looking mailbox that nobody reads.
        expect(find.text(_en['aboutEmailMissing']), findsOneWidget);
      }
    });

    testWidgets('the notice carries no advertisement', (tester) async {
      // docs/03 §S-21: no ads. The audit test keeps S-21 off the AdSlot list;
      // this is the same promise from the user's side.
      await pumpAt(tester, '/about');
      expect(find.byType(AdSlot), findsNothing);
    });
  });

  group('the notice is reachable where it is needed', () {
    testWidgets('Settings opens it, and the back arrow returns', (
      tester,
    ) async {
      await pumpAt(tester, '/settings');
      expect(find.text(_en['aboutScreenTitle']), findsNothing);

      // Settings is a long scroll; the row is well below the fold, and a tap
      // outside the viewport is a tap on nothing.
      await tester.ensureVisible(find.text(_en.privacy));
      await tester.tap(find.text(_en.privacy));
      await tester.pumpAndSettle();
      expect(find.text(_en['aboutScreenTitle']), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text(_en['aboutScreenTitle']), findsNothing);
      // Settings again: its heading and its tab label both say so.
      expect(find.text(_en.settings), findsWidgets);
    });

    testWidgets('the SMS permission screen links to it before the ask', (
      tester,
    ) async {
      await pumpAt(tester, '/permission/sms');

      expect(find.text(_en['privacyReadAll']), findsOneWidget);
      await tester.ensureVisible(find.text(_en['privacyReadAll']));
      await tester.tap(find.text(_en['privacyReadAll']));
      await tester.pumpAndSettle();

      expect(find.text(_en['aboutScreenTitle']), findsOneWidget);
      expect(find.text(_en['aboutCollectTitle']), findsOneWidget);
    });

    testWidgets('the paywall summary offers the full policy', (tester) async {
      // The paywall keeps a *modal* summary - it cannot push a screen mid-flow.
      // The summary is what has to lead to S-21.
      await pumpAt(tester, '/pro');

      await tester.ensureVisible(find.text(_en.privacy));
      await tester.tap(find.text(_en.privacy));
      await tester.pumpAndSettle();
      expect(find.text(_en['privacyReadAll']), findsOneWidget);

      await tester.tap(find.text(_en['privacyReadAll']));
      await tester.pumpAndSettle();

      expect(find.text(_en['aboutScreenTitle']), findsOneWidget);
      expect(find.text(_en['aboutCollectTitle']), findsOneWidget);
    });
  });

  group('the external values behave', () {
    testWidgets('the repository row copies the URL and says so', (
      tester,
    ) async {
      final copied = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied.add(
                (call.arguments as Map<Object?, Object?>)['text']! as String,
              );
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await pumpAt(tester, '/about');
      await tester.ensureVisible(find.text(_en['aboutSourceTitle']));
      await tester.tap(find.text(_en['aboutSourceTitle']));
      await tester.pumpAndSettle();

      expect(copied, <String>[AppInfo.sourceRepo]);
      expect(find.text(_en['aboutCopied']), findsOneWidget);
      // The URL is on the screen too, so it can be read without tapping.
      expect(find.textContaining(AppInfo.sourceRepo), findsWidgets);
    });
  });
}
