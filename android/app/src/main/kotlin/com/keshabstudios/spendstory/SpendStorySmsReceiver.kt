package com.keshabstudios.spendstory

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import org.json.JSONArray
import org.json.JSONObject

/**
 * Buffers incoming bank SMS so the Dart capture pipeline can parse them.
 *
 * Mirrors [SpendStoryNotificationListener]: the receiver does no parsing, only
 * hands raw (sender, body, timestamp) tuples to Dart, which owns the single
 * parser. Multi-part messages are reassembled before buffering.
 */
class SpendStorySmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
        if (messages.isEmpty()) return
        val sender = messages.firstOrNull()?.originatingAddress?.trim().orEmpty()
        if (sender.isEmpty()) return
        val body = messages.joinToString(separator = "") { it.messageBody ?: "" }
        if (body.isEmpty()) return
        val timestamp = messages.firstOrNull()?.timestampMillis
            ?: System.currentTimeMillis()
        append(
            context,
            JSONObject()
                .put("sender", sender)
                .put("body", body)
                .put("timestampMs", timestamp),
        )
    }

    companion object {
        private const val PREFS = "spendstory_native"
        private const val KEY_PENDING = "pending_sms"
        private const val MAX_PENDING = 200

        private fun append(context: Context, entry: JSONObject) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val existing = prefs.getString(KEY_PENDING, null)
            val array = try {
                if (existing.isNullOrEmpty()) JSONArray() else JSONArray(existing)
            } catch (_: Exception) {
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

        /**
         * Reads recent SMS from the device inbox. Used to catch up on messages
         * that arrived before the receiver was registered or while the app was
         * closed. Deduplication of the resulting transactions happens in Dart.
         */
        fun readSmsInbox(context: Context, sinceMs: Long): List<String> {
            val result = mutableListOf<String>()
            val uri = Telephony.Sms.Inbox.CONTENT_URI
            val projection = arrayOf(
                Telephony.Sms._ID,
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE,
            )
            val selection = "${Telephony.Sms.DATE} >= ?"
            val selectionArgs = arrayOf(sinceMs.toString())
            val sortOrder = "${Telephony.Sms.DATE} ASC"
            try {
                context.contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)
                    ?.use { cursor ->
                        val idxAddr = cursor.getColumnIndex(Telephony.Sms.ADDRESS)
                        val idxBody = cursor.getColumnIndex(Telephony.Sms.BODY)
                        val idxDate = cursor.getColumnIndex(Telephony.Sms.DATE)
                        while (cursor.moveToNext()) {
                            val addr = if (idxAddr >= 0) cursor.getString(idxAddr) else null
                            if (addr.isNullOrBlank()) continue
                            val body = if (idxBody >= 0) cursor.getString(idxBody) ?: "" else ""
                            if (body.isBlank()) continue
                            val date = if (idxDate >= 0) cursor.getLong(idxDate) else System.currentTimeMillis()
                            result.add(
                                JSONObject()
                                    .put("sender", addr)
                                    .put("body", body)
                                    .put("timestampMs", date)
                                    .toString(),
                            )
                        }
                    }
            } catch (_: Exception) {
                // Missing permission or provider unavailable: return what we have.
            }
            return result
        }
    }
}
