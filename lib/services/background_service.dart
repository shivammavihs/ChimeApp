import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String notificationChannelId = 'tickr_timer_channel';
const int notificationId = 888;

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  // Create notifications channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'tickr active timer',
    description: 'Displays tickr timer countdown in notification drawer.',
    importance: Importance.low, // low importance so it ticks silently without chiming on every tick
    playSound: false,
    enableVibration: false,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // Start manually when user clicks START
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'tickr Timer',
      initialNotificationContent: 'Preparing...',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Background audio player
  final AudioPlayer backgroundPlayer = AudioPlayer();

  // Variables to hold state in background
  int remainingSeconds = 0;
  int currentRep = 0;
  int totalReps = 0;
  int intervalSeconds = 0;
  String? customSoundPath;
  String? selectedChimeType;
  Timer? ticker;
  bool isRunning = false;

  Future<void> updateNotification() async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final minutes = (remainingSeconds / 60).floor().toString().padLeft(2, '0');
        final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
        
        final String statusText = 'Interval: $minutes:$seconds | Rep: $currentRep/$totalReps';
        
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'tickr Timer running',
          statusText,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'tickr active timer',
              channelDescription: 'Displays tickr timer countdown in notification drawer.',
              ongoing: true,
              icon: '@mipmap/ic_launcher',
              importance: Importance.low,
              priority: Priority.low,
              showWhen: false,
              playSound: false,
              enableVibration: false,
            ),
          ),
        );
      }
    }
  }

  void stopLocalTimer() {
    ticker?.cancel();
    isRunning = false;
  }

  void playChime() async {
    try {
      if (selectedChimeType == 'custom' && customSoundPath != null && File(customSoundPath!).existsSync()) {
        await backgroundPlayer.play(DeviceFileSource(customSoundPath!));
      } else {
        final Map<String, String> builtInChimes = {
          'dragon_studio_alert': 'audio/dragon_studio_alert.mp3',
          'notification_message_alert': 'audio/notification_message_alert.mp3',
          'clear_mobile_notification': 'audio/clear_mobile_notification.mp3',
          'mysterious_ringtone': 'audio/mysterious_ringtone.mp3',
          'new_notification_030': 'audio/new_notification_030.mp3',
          'new_notification_050': 'audio/new_notification_050.mp3',
          'new_notification_060': 'audio/new_notification_060.mp3',
          'new_notification_061': 'audio/new_notification_061.mp3',
        };
        final assetPath = builtInChimes[selectedChimeType ?? 'dragon_studio_alert'] ?? 'audio/dragon_studio_alert.mp3';
        await backgroundPlayer.play(AssetSource(assetPath));
      }
    } catch (e) {
      debugPrint('Error playing background audio: $e');
    }
  }

  void startLocalTimer() {
    ticker?.cancel();
    isRunning = true;
    ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isRunning) return;

      remainingSeconds--;

      // IPC Tick Broadcast
      service.invoke('timerTick', {
        'remainingSeconds': remainingSeconds,
        'currentRep': currentRep,
        'status': 'running',
      });

      updateNotification();

      if (remainingSeconds <= 0) {
        playChime();
        currentRep++;

        if (currentRep > totalReps) {
          stopLocalTimer();
          service.invoke('timerCompleted');
          
          if (service is AndroidServiceInstance) {
            flutterLocalNotificationsPlugin.show(
              notificationId,
              'tickr Completed!',
              'All $totalReps repetitions completed.',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  notificationChannelId,
                  'tickr active timer',
                  ongoing: false,
                  icon: '@mipmap/ic_launcher',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
            );
            service.stopSelf();
          }
        } else {
          remainingSeconds = intervalSeconds;
          service.invoke('timerTick', {
            'remainingSeconds': remainingSeconds,
            'currentRep': currentRep,
            'status': 'running',
          });
          updateNotification();
        }
      }
    });
  }

  service.on('startTimer').listen((event) {
    if (event != null) {
      intervalSeconds = event['intervalSeconds'] as int;
      totalReps = event['totalReps'] as int;
      customSoundPath = event['customChimeSoundPath'] as String?;
      selectedChimeType = event['selectedChimeType'] as String? ?? 'dragon_studio_alert';
      
      remainingSeconds = intervalSeconds;
      currentRep = 1;
      
      startLocalTimer();
      updateNotification();
    }
  });

  service.on('pauseTimer').listen((event) {
    stopLocalTimer();
    service.invoke('timerTick', {
      'remainingSeconds': remainingSeconds,
      'currentRep': currentRep,
      'status': 'paused',
    });
  });

  service.on('resumeTimer').listen((event) {
    startLocalTimer();
  });

  service.on('stopTimer').listen((event) {
    stopLocalTimer();
    if (service is AndroidServiceInstance) {
      service.stopSelf();
    }
  });
}
