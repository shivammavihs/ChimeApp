package com.chimeapp.chime_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Native BroadcastReceiver that handles notification action button taps.
 *
 * When the user taps Pause/Resume/Stop in the notification, Android delivers
 * an Intent to this receiver. The receiver writes the requested action to
 * a dedicated SharedPreferences file that the background service reads via
 * a MethodChannel (consumePendingAction).
 */
class NotificationActionReceiver : BroadcastReceiver() {

    companion object {
        const val PREFS_NAME = "tickr_notification_actions"
        const val KEY_PENDING_ACTION = "pending_action"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.getStringExtra("tickr_action") ?: return

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_PENDING_ACTION, action).apply()
    }
}
