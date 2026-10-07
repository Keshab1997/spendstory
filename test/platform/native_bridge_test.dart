/// The native bridge has two halves that can silently drift: the Dart whitelist
/// the user is *shown*, and the Kotlin whitelist the listener *enforces*.
///
/// A drift would be a privacy bug, and a quiet one. If Dart lists six apps but
/// Kotlin filters eight, the permission screen is telling the user something
/// untrue about what the app reads; if Kotlin lists fewer, payments stop being
/// captured and the user sees nothing at all. Neither shows up in a widget test,
/// because neither side can see the other.
///
/// So this test reads the Kotlin source directly. That is unusual, and it is
/// deliberate: the alternative is a build-step-generated constant, which is more
/// machinery than a six-line list can justify.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/platform/native_bridge.dart';
import 'package:spendstory/platform/permissions.dart';

const String _listenerPath =
    'android/app/src/main/kotlin/com/keshabstudios/spendstory/'
    'SpendStoryNotificationListener.kt';
const String _activityPath =
    'android/app/src/main/kotlin/com/keshabstudios/spendstory/MainActivity.kt';
const String _manifestPath = 'android/app/src/main/AndroidManifest.xml';

void main() {
  // The bridge goes through a MethodChannel, and reading a channel needs a
  // binding — without this the *no-host* tests fail for the wrong reason.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('whitelist parity between Dart and Kotlin', () {
    test('every Dart package is in the Kotlin whitelist, and no extras', () {
      final kotlin = File(_listenerPath).readAsStringSync();
      // The list ends at the first line that is just a closing paren — a plain
      // `kotlin.indexOf(')')` would stop early, because the comments name apps
      // like "Google Pay (India)".
      final start = kotlin.indexOf('val WHITELIST = setOf(');
      final end = kotlin.indexOf(RegExp(r'^\s*\)', multiLine: true), start);
      final block = kotlin.substring(start, end);
      final inKotlin = RegExp(r'"([^"]+)"')
          .allMatches(block)
          .map((m) => m.group(1)!)
          .toSet();

      expect(
        inKotlin,
        kNotificationWhitelist,
        reason:
            'the packages the user is told about and the packages actually '
            'filtered must be identical — update both files together',
      );
      expect(inKotlin.length, kNotificationWhitelist.length);
    });

    test('every whitelisted package has a human name for the UI', () {
      for (final pkg in kNotificationWhitelist) {
        expect(
          kNotificationAppNames[pkg],
          isNotNull,
          reason: '$pkg would be shown to the user as a raw package name',
        );
      }
      expect(kNotificationAppNames.keys.toSet(), kNotificationWhitelist);
    });

    test('the manifest declares exactly the SMS permissions the feature needs', () {
      final manifest = File(_manifestPath).readAsStringSync();
      expect(manifest, contains('android.permission.READ_SMS'));
      expect(manifest, contains('android.permission.RECEIVE_SMS'));
      // Anything beyond these two would need its own justification and its own
      // Play declaration, so the absence is asserted.
      expect(manifest, isNot(contains('android.permission.SEND_SMS')));
      expect(manifest, isNot(contains('android.permission.CALL_PHONE')));
      expect(manifest, isNot(contains('android.permission.READ_CONTACTS')));

      // The listener has to be declared, and has to be unexported: only the
      // system may bind to it.
      expect(
        manifest,
        contains(
          'android.service.notification.'
          'NotificationListenerService',
        ),
      );
      expect(manifest, contains('BIND_NOTIFICATION_LISTENER_SERVICE'));
      expect(manifest, contains('android:exported="false"'));
    });

    test('the Dart channel name matches the one Kotlin answers on', () {
      final activity = File(_activityPath).readAsStringSync();
      expect(activity, contains('"spendstory/native"'));
      for (final method in <String>[
        'notificationAccessGranted',
        'enabledListenerPackages',
        'openNotificationAccessSettings',
      ]) {
        expect(
          activity,
          contains('"$method"'),
          reason:
              'NativeBridge calls $method but MainActivity does not handle it',
        );
      }
    });
  });

  group('no host, no crash', () {
    // These run in a plain `flutter test`, which *is* the no-host case: the
    // bridge must answer (null / false) rather than throw, because the same code
    // runs in the web preview and on desktop.
    test('notification access reads as unknown', () async {
      expect(await NativeBridge.notificationAccessGranted(), isNull);
      expect(await NativeBridge.enabledListenerPackages(), isNull);
    });

    test('opening settings reports that it could not', () async {
      expect(await NativeBridge.openNotificationAccessSettings(), isFalse);
      expect(await Permissions.openAppSettingsPage(), isFalse);
    });

    test('the permission snapshot is unknown/unknown, never a guess', () async {
      final state = await Permissions.current();
      expect(state.sms, SmsAccess.unknown);
      expect(state.notifications, NotificationAccess.unknown);
      expect(state.anyCaptureLive, isFalse);
      expect(state.enabledListeners, isEmpty);
    });

    test('asking for SMS returns unknown rather than a fake denial', () async {
      expect(await Permissions.requestSms(), SmsAccess.unknown);
    });
  });

  group('PermissionState', () {
    test('copyWith leaves untouched fields alone', () {
      const base = PermissionState(
        sms: SmsAccess.denied,
        notifications: NotificationAccess.denied,
      );
      final updated = base.copyWith(sms: SmsAccess.granted);
      expect(updated.sms, SmsAccess.granted);
      expect(updated.notifications, NotificationAccess.denied);
    });

    test('anyCaptureLive is true when either channel is on', () {
      const smsOnly = PermissionState(
        sms: SmsAccess.granted,
        notifications: NotificationAccess.denied,
      );
      const notifOnly = PermissionState(
        sms: SmsAccess.denied,
        notifications: NotificationAccess.granted,
      );
      const neither = PermissionState(
        sms: SmsAccess.denied,
        notifications: NotificationAccess.denied,
      );
      expect(smsOnly.anyCaptureLive, isTrue);
      expect(notifOnly.anyCaptureLive, isTrue);
      expect(neither.anyCaptureLive, isFalse);
    });
  });
}
