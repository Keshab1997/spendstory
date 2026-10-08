/// The Dart side of the native bridge.
///
/// Exactly one MethodChannel, `spendstory/native`, and every method on it is
/// optional: on the web, on desktop, and inside `flutter test` there is no
/// Android host, so each call returns its documented "unknown" value instead of
/// throwing. That property is what lets the same onboarding flow run in the web
/// preview and in a widget test without a single `if (kIsWeb)` in the UI layer.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('spendstory/native');

/// True when a real Android host is present to answer the channel.
bool get hasNativeHost =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Everything the app needs from Kotlin, wrapped so nothing above this file has
/// to know whether the host exists.
class NativeBridge {
  const NativeBridge._();

  /// Whether the user has granted notification access to SpendStory.
  ///
  /// Returns null when the host cannot tell us — never a guess, because the UI
  /// says different things for "not granted" and "cannot check".
  static Future<bool?> notificationAccessGranted() async {
    if (!hasNativeHost) return null;
    try {
      return await _channel.invokeMethod<bool>('notificationAccessGranted');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Posts one budget alert.
  ///
  /// False is a real answer, not an error: on the web, in `flutter test`, and
  /// on a phone where POST_NOTIFICATIONS was never granted, the notification
  /// does not go out. The caller keeps the alert owed rather than marking it
  /// delivered, so a warning is never lost to a missing permission.
  static Future<bool> postNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!hasNativeHost) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'postNotification',
            <String, Object?>{'id': id, 'title': title, 'body': body},
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Opens the system "notification access" list. Returns false when there is
  /// nothing to open — the caller then shows the manual instructions instead of
  /// a button that does nothing.
  static Future<bool> openNotificationAccessSettings() async {
    if (!hasNativeHost) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'openNotificationAccessSettings',
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// The package names the app currently listens to, so the whitelist screen can
  /// show what is actually enabled rather than what we hope is enabled.
  static Future<Set<String>?> enabledListenerPackages() async {
    if (!hasNativeHost) return null;
    try {
      final list = await _channel.invokeListMethod<String>(
        'enabledListenerPackages',
      );
      return list?.toSet();
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

/// The six payment packages the notification listener is allowed to look at.
///
/// Kept in Dart as well as Kotlin on purpose: the Dart copy drives the UI (which
/// apps are explained to the user), the Kotlin copy is the actual filter. A test
/// asserts they have not drifted apart.
const Set<String> kNotificationWhitelist = <String>{
  'com.google.android.apps.nbu.paisa.user',
  'com.phonepe.app',
  'net.one97.paytm',
  'in.org.npci.upiapp',
  'com.dreamplug.androidapp',
  'in.amazon.mShop.android.shopping',
};

/// Human names for the whitelist, for the permission screen.
const Map<String, String> kNotificationAppNames = <String, String>{
  'com.google.android.apps.nbu.paisa.user': 'Google Pay',
  'com.phonepe.app': 'PhonePe',
  'net.one97.paytm': 'Paytm',
  'in.org.npci.upiapp': 'BHIM',
  'com.dreamplug.androidapp': 'CRED',
  'in.amazon.mShop.android.shopping': 'Amazon Pay',
};
