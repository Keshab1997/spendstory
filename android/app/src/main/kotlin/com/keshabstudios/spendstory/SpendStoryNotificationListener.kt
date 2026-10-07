package com.keshabstudios.spendstory

import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

/**
 * Captures payment notifications from a fixed whitelist of apps.
 *
 * Why this exists at all: a UPI payment often reaches the phone as an app
 * notification *before* (or instead of) the bank's SMS. Google Pay's "You paid
 * ₹250 to X" would otherwise be missed until the bank alert arrives minutes
 * later — or never, when the sender is not on the SMS allowlist.
 *
 * Two rules the whole class is built around:
 *
 *  1. **The whitelist is the filter, not a heuristic.** Anything posted by a
 *     package outside [WHITELIST] is dropped on arrival and never stored. There
 *     is no "read everything and filter later", because "later" is where a
 *     WhatsApp message ends up in a JSON file on disk.
 *  2. **Nothing is parsed here.** The service's whole job is to hand raw
 *     `(package, title, text, postedAt)` tuples to Dart, which owns the single
 *     parser the app's accuracy tests exercise. A second parser in Kotlin would
 *     be a second thing to keep correct, and the one with no tests would drift.
 *
 * Batch 5 drains [drainPending] into the capture pipeline. Until then the
 * buffer simply accumulates (bounded, see [MAX_PENDING]) so that a user who
 * grants access during onboarding does not lose the payments made before the
 * pipeline was wired up.
 */
class SpendStoryNotificationListener : NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()
        connected = true
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        connected = false
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val notification = sbn?.notification ?: return
        val pkg = sbn.packageName ?: return
        if (pkg !in WHITELIST) return

        val extras = notification.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty()
        // A notification with neither a title nor a body carries no amount, so
        // there is nothing worth buffering.
        if (title.isEmpty() && text.isEmpty()) return

        append(
            applicationContext,
            JSONObject()
                .put("pkg", pkg)
                .put("title", title)
                .put("text", text)
                .put("postedAt", if (sbn.postTime > 0) sbn.postTime else System.currentTimeMillis()),
        )
    }

    companion object {
        /**
         * Payment apps whose notifications can contain a transaction. Kept in
         * step with `kNotificationWhitelist` in `lib/platform/native_bridge.dart`
         * — the Dart side renders this exact list to the user, so a package added
         * on one side only would mean the explainer screen lies.
         */
        val WHITELIST = setOf(
            "com.google.android.apps.nbu.paisa.user", // Google Pay (India)
            "com.phonepe.app", // PhonePe
            "net.one97.paytm", // Paytm
            "in.org.npci.upiapp", // BHIM
            "com.dreamplug.androidapp", // CRED
            "in.amazon.mShop.android.shopping", // Amazon Pay
        )

        private const val PREFS = "spendstory_native"
        private const val KEY_PENDING = "pending_notifications"

        /**
         * Deliberately small. A phone that is left alone for a week should not
         * let this grow without bound, and a backlog this size is already far
         * more than a single drain needs.
         */
        private const val MAX_PENDING = 200

        @Volatile
        private var connected = false

        /**
         * Whether the OS currently has our listener bound. Note this is *runtime*
         * state, so it is false before the first notification arrives even when
         * access is granted — which is why [notificationAccessGranted] checks the
         * settings string instead of this flag.
         */
        fun isConnected(): Boolean = connected

        /**
         * True when the user has ticked SpendStory in Notification access.
         *
         * Reading the setting is the only reliable signal: the OS does not tell a
         * plain app whether its listener component is enabled, and the component
         * list is a better answer than `isConnected` for a UI that is opened
         * before any notification has been posted.
         */
        fun notificationAccessGranted(context: Context): Boolean =
            enabledListenerPackages(context).contains(context.packageName)

        /** Package names of every app the user has enabled notification access for. */
        fun enabledListenerPackages(context: Context): Set<String> {
            val flat = Settings.Secure.getString(
                context.contentResolver,
                "enabled_notification_listeners",
            )
            if (flat.isNullOrEmpty()) return emptySet()
            return flat.split(':').mapNotNull { entry ->
                ComponentName.unflattenFromString(entry)?.packageName
            }.toSet()
        }

        /** The settings screen Android gives no public Intent constant for pre-API 30. */
        fun notificationAccessSettingsAction(): String =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS
            } else {
                "android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS"
            }

        private fun append(context: Context, entry: JSONObject) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val existing = prefs.getString(KEY_PENDING, null)
            val array = try {
                if (existing.isNullOrEmpty()) JSONArray() else JSONArray(existing)
            } catch (_: Exception) {
                // A truncated write would leave unparseable JSON; dropping it is
                // better than crashing the listener service on the next payment.
                JSONArray()
            }
            array.put(entry)
            val trimmed = if (array.length() <= MAX_PENDING) {
                array
            } else {
                JSONArray().also { out ->
                    for (i in array.length() - MAX_PENDING until array.length()) {
                        out.put(array.get(i))
                    }
                }
            }
            prefs.edit().putString(KEY_PENDING, trimmed.toString()).apply()
        }

        /**
         * Returns everything buffered so far and clears the buffer.
         *
         * Read-and-clear rather than read: a notification that has already been
         * turned into a transaction must not be turned into a second one when the
         * app is reopened.
         */
        fun drainPending(context: Context): List<String> {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val raw = prefs.getString(KEY_PENDING, null) ?: return emptyList()
            prefs.edit().remove(KEY_PENDING).apply()
            val array = try {
                JSONArray(raw)
            } catch (_: Exception) {
                return emptyList()
            }
            return (0 until array.length()).mapNotNull { array.optJSONObject(it)?.toString() }
        }
    }
}
