package com.chimeapp.chime_app

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Vibrator
import android.os.VibrationEffect
import androidx.core.app.NotificationCompat
import id.flutter.flutter_background_service.BackgroundService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Custom BackgroundService that registers a MethodChannel for building
 * native notifications with real PendingIntent action buttons, and for
 * reading/clearing pending actions written by NotificationActionReceiver.
 *
 * This class overrides flutter_background_service's BackgroundService to
 * inject a MethodChannel into the background engine BEFORE Dart code runs.
 */
class TickrBackgroundService : BackgroundService() {

    companion object {
        const val METHOD_CHANNEL = "com.chimeapp.chime_app/notification"
    }

    override fun onCreate() {
        super.onCreate()

        try {
            val field = BackgroundService::class.java.getDeclaredField("backgroundEngine")
            field.isAccessible = true
            val flutterEngine = field.get(this) as? FlutterEngine
            if (flutterEngine != null) {
                MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    METHOD_CHANNEL
                ).setMethodCallHandler { call, result ->
                    when (call.method) {
                        "showTimerNotification" -> {
                            val notificationId = call.argument<Int>("notificationId") ?: 888
                            val channelId = call.argument<String>("channelId") ?: "tickr_timer_channel"
                            val title = call.argument<String>("title") ?: "tickr Timer"
                            val body = call.argument<String>("body") ?: ""
                            val isRunning = call.argument<Boolean>("isRunning") ?: true

                            showTimerNotification(notificationId, channelId, title, body, isRunning)
                            result.success(null)
                        }
                        "consumePendingAction" -> {
                            val prefs = applicationContext.getSharedPreferences(
                                "tickr_notification_actions", Context.MODE_PRIVATE
                            )
                            val action = prefs.getString("pending_action", null)
                            if (action != null) {
                                prefs.edit().remove("pending_action").apply()
                            }
                            result.success(action)
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
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun showTimerNotification(
        notificationId: Int,
        channelId: String,
        title: String,
        body: String,
        isRunning: Boolean
    ) {
        val context = applicationContext

        // PendingIntent for Pause/Resume action → NotificationActionReceiver
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

        // PendingIntent for Stop action → NotificationActionReceiver
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
            .addAction(0, if (isRunning) "Pause" else "Resume", pauseResumePending)
            .addAction(0, "Stop", stopPending)

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, builder.build())
    }
}
