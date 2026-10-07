/// Permission state for the two optional powers the app can ask for.
///
/// Two rules govern everything in this file, both from
/// `docs/07-PERMISSIONS-POLICY.md`:
///
/// 1. **Nothing is ever blocked behind a permission.** Denying SMS or
///    notification access lands the user on a working app with manual entry —
///    not on a wall. The permission screens say so out loud.
/// 2. **Denial is remembered, never nagged.** `smsPermAsked` in `app_meta` means
///    the app asks once, and afterwards only offers it again from Settings.
library;

import 'package:permission_handler/permission_handler.dart';

import 'native_bridge.dart';

enum SmsAccess {
  /// Never asked, or asked and not yet answered.
  unknown,

  /// READ_SMS granted.
  granted,

  /// Denied, or denied permanently.
  denied,
}

enum NotificationAccess {
  /// The host cannot tell us — web, desktop, or a broken bridge.
  unknown,
  granted,
  denied,
}

/// The pair of permissions the capture pipeline wants, plus the honest reading
/// of what the user has actually allowed.
class PermissionState {
  const PermissionState({
    required this.sms,
    required this.notifications,
    this.enabledListeners = const <String>{},
  });

  final SmsAccess sms;
  final NotificationAccess notifications;

  /// Which of the six payment packages the listener currently sees.
  final Set<String> enabledListeners;

  bool get smsGranted => sms == SmsAccess.granted;
  bool get notificationsGranted => notifications == NotificationAccess.granted;

  /// True when at least one capture channel is live. Drives the "capture is on"
  /// line on Home; a user with neither is not broken, just manual.
  bool get anyCaptureLive => smsGranted || notificationsGranted;

  static const PermissionState unknown = PermissionState(
    sms: SmsAccess.unknown,
    notifications: NotificationAccess.unknown,
  );

  PermissionState copyWith({
    SmsAccess? sms,
    NotificationAccess? notifications,
    Set<String>? enabledListeners,
  }) => PermissionState(
    sms: sms ?? this.sms,
    notifications: notifications ?? this.notifications,
    enabledListeners: enabledListeners ?? this.enabledListeners,
  );
}

class Permissions {
  const Permissions._();

  /// Reads the current state. Never throws: `flutter test` and the web build
  /// have no plugin host, and an exception here would take down the flow that is
  /// supposed to be robust to exactly this.
  static Future<PermissionState> current() async {
    final sms = await _smsStatus();
    final granted = await NativeBridge.notificationAccessGranted();
    final listeners = await NativeBridge.enabledListenerPackages();

    return PermissionState(
      sms: sms,
      notifications: granted == null
          ? NotificationAccess.unknown
          : (granted ? NotificationAccess.granted : NotificationAccess.denied),
      enabledListeners: listeners ?? const <String>{},
    );
  }

  static Future<SmsAccess> _smsStatus() async {
    if (!hasNativeHost) return SmsAccess.unknown;
    try {
      final status = await Permission.sms.status;
      return status.isGranted ? SmsAccess.granted : SmsAccess.denied;
    } catch (_) {
      // MissingPluginException in tests, or a host without the plugin.
      return SmsAccess.unknown;
    }
  }

  /// Asks for SMS access.
  ///
  /// Returns the resulting state. A denial is a normal outcome, not an error —
  /// the flow continues either way.
  static Future<SmsAccess> requestSms() async {
    if (!hasNativeHost) return SmsAccess.unknown;
    try {
      final status = await Permission.sms.request();
      return status.isGranted ? SmsAccess.granted : SmsAccess.denied;
    } catch (_) {
      return SmsAccess.unknown;
    }
  }

  /// Opens the app's own settings page, for the case where the user denied
  /// permanently and the dialog can no longer appear.
  static Future<bool> openAppSettingsPage() async {
    if (!hasNativeHost) return false;
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Opens the system notification-access list.
  static Future<bool> openNotificationSettings() =>
      NativeBridge.openNotificationAccessSettings();
}

/// What the screens are allowed to ask for.
///
/// The screens depend on this interface rather than on the statics above for one
/// reason: a widget test has no Android host, and `permission_handler`'s request
/// never resolves there — it waits for a lifecycle event that a test never sends.
/// That is not a bug to route around; it is the difference between "we asked and
/// the platform answered" and "we asked and the platform is not there", and the
/// screens have to behave correctly for both. Injecting the answer is how both
/// get tested without a device.
abstract class PermissionsApi {
  const PermissionsApi();

  Future<PermissionState> current();
  Future<SmsAccess> requestSms();
  Future<bool> openNotificationSettings();
  Future<bool> openAppSettingsPage();
}

/// The real implementation: everything goes to Android.
class DevicePermissions extends PermissionsApi {
  const DevicePermissions();

  @override
  Future<PermissionState> current() => Permissions.current();

  @override
  Future<SmsAccess> requestSms() => Permissions.requestSms();

  @override
  Future<bool> openNotificationSettings() =>
      Permissions.openNotificationSettings();

  @override
  Future<bool> openAppSettingsPage() => Permissions.openAppSettingsPage();
}
