package com.keshabstudios.spendstory

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The only native entry point the app has.
 *
 * Everything here is something Flutter genuinely cannot do on its own: read the
 * "notification access" setting, open that settings screen, and drain the
 * notification buffer the listener service fills. Nothing that Dart could do
 * itself lives in this file.
 *
 * Channel: `spendstory/native`, mirroring [NativeBridge] on the Dart side. Every
 * method must be answerable in a plain `flutter test`, which is why the Dart side
 * treats "no host" as a normal answer rather than an error.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "notificationAccessGranted" ->
                    result.success(
                        SpendStoryNotificationListener.notificationAccessGranted(this),
                    )

                "enabledListenerPackages" ->
                    result.success(
                        SpendStoryNotificationListener
                            .enabledListenerPackages(this)
                            .toList(),
                    )

                "openNotificationAccessSettings" ->
                    result.success(openNotificationAccessSettings())

                "drainPendingNotifications" ->
                    result.success(SpendStoryNotificationListener.drainPending(this))

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Returns false when no activity can handle the intent, so the caller can
     * show written instructions instead of leaving the user on a button that
     * silently did nothing. Some OEM builds ship without the listener settings
     * screen reachable by this action.
     */
    private fun openNotificationAccessSettings(): Boolean {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(intent)
            true
        } catch (_: android.content.ActivityNotFoundException) {
            false
        }
    }

    private companion object {
        const val CHANNEL = "spendstory/native"
    }
}
