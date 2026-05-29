package com.chimeapp.chime_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Vibrator
import android.os.VibrationEffect
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val NOTIFICATION_CHANNEL = "com.chimeapp.chime_app/notification"

        /**
         * Static helper so any Flutter engine (main or background service)
         * can show a notification with real PendingIntent action buttons.
         */
        fun showTimerNotification(
            context: Context,
            notificationId: Int,
            channelId: String,
            title: String,
            body: String,
            isRunning: Boolean
        ) {
            // Build PendingIntent for Pause/Resume action
            val pauseResumeIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                action = "com.chimeapp.NOTIFICATION_ACTION"
                putExtra("tickr_action", if (isRunning) "pause" else "resume")
            }
            val pauseResumePending = PendingIntent.getBroadcast(
                context,
                1001,
                pauseResumeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Build PendingIntent for Stop action
            val stopIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                action = "com.chimeapp.NOTIFICATION_ACTION"
                putExtra("tickr_action", "stop")
            }
            val stopPending = PendingIntent.getBroadcast(
                context,
                1002,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Open the app when tapping the notification body
            val contentIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val contentPending = PendingIntent.getActivity(
                context,
                1000,
                contentIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val builder = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setOngoing(true)
                .setShowWhen(false)
                .setSilent(true)
                .setContentIntent(contentPending)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .addAction(
                    0,
                    if (isRunning) "Pause" else "Resume",
                    pauseResumePending
                )
                .addAction(
                    0,
                    "Stop",
                    stopPending
                )

            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(notificationId, builder.build())
        }

        /**
         * Reads and clears the pending notification action from SharedPreferences.
         */
        fun consumePendingAction(context: Context): String? {
            val prefs = context.getSharedPreferences(
                "tickr_notification_actions", Context.MODE_PRIVATE
            )
            val action = prefs.getString("pending_action", null)
            if (action != null) {
                prefs.edit().remove("pending_action").apply()
            }
            return action
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register MethodChannel for the main engine
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "showTimerNotification" -> {
                    showTimerNotification(
                        applicationContext,
                        call.argument<Int>("notificationId") ?: 888,
                        call.argument<String>("channelId") ?: "tickr_timer_channel",
                        call.argument<String>("title") ?: "tickr Timer",
                        call.argument<String>("body") ?: "",
                        call.argument<Boolean>("isRunning") ?: true
                    )
                    result.success(null)
                }
                "consumePendingAction" -> {
                    result.success(consumePendingAction(applicationContext))
                }
                "vibratePattern" -> {
                    val patternList = call.argument<List<*>>("pattern")
                    val pattern = patternList?.map { (it as Number).toLong() }?.toLongArray()
                    if (pattern != null) {
                        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
                        } else {
                            @Suppress("DEPRECATION")
                            vibrator.vibrate(pattern, -1)
                        }
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "chime_timer_channel",
                "Chime Timer",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows timer status while the Chime app is running"
                setSound(null, null)
                enableVibration(false)
            }
            val notificationManager =
                getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
