package com.chimeapp.chime_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.Vibrator
import android.os.VibrationEffect
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val NOTIFICATION_CHANNEL = "com.chimeapp.chime_app/notification"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register MethodChannel for custom native vibrations
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "vibratePattern" -> {
                    val patternList = call.argument<List<*>>("pattern")
                    val pattern = patternList?.map { (it as Number).toLong() }?.toLongArray()
                    val amplitudesList = call.argument<List<*>>("amplitudes")
                    val amplitudes = amplitudesList?.map { (it as Number).toInt() }?.toIntArray()

                    if (pattern != null) {
                        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && amplitudes != null) {
                            vibrator.vibrate(VibrationEffect.createWaveform(pattern, amplitudes, -1))
                        } else {
                            @Suppress("DEPRECATION")
                            vibrator.vibrate(pattern, -1)
                        }
                    }
                    result.success(null)
                }
                "vibrateCustom" -> {
                    val duration = (call.argument<Number>("duration"))?.toLong() ?: 15L
                    val amplitude = (call.argument<Number>("amplitude"))?.toInt() ?: 255
                    val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        vibrator.vibrate(VibrationEffect.createOneShot(duration, amplitude.coerceIn(1, 255)))
                    } else {
                        @Suppress("DEPRECATION")
                        vibrator.vibrate(duration)
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
