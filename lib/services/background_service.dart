import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vibration_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String notificationChannelId = 'tickr_timer_channel';
const int notificationId = 888;

/// MethodChannel for native notification with PendingIntent action buttons.
/// Registered on both the main engine (MainActivity) and the background
/// service engine (TickrBackgroundService).


@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse details) {
  final service = FlutterBackgroundService();
  if (details.actionId == 'pause') {
    service.invoke('notificationPause');
  } else if (details.actionId == 'resume') {
    service.invoke('notificationResume');
  } else if (details.actionId == 'stop') {
    service.invoke('notificationStop');
  }
}

Future<void> initBackgroundService() async {

  final service = FlutterBackgroundService();

  // Create notifications channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'tickr active timer',
    description: 'Displays tickr timer countdown in notification drawer.',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  const AndroidNotificationChannel completedChannel = AndroidNotificationChannel(
    'tickr_completed_channel',
    'tickr Completed Alerts',
    description: 'Displays notification when tickr timer completes.',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(completedChannel);

  // Initialize notifications (main isolate — for completion notification only)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse details) {},
    onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
  );

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
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

  late final void Function() startLocalTimer;

  // ── Initialize flutter_local_notifications in background isolate ──
  const AndroidNotificationChannel bgChannel = AndroidNotificationChannel(
    notificationChannelId,
    'tickr active timer',
    description: 'Displays tickr timer countdown in notification drawer.',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(bgChannel);

  const AndroidInitializationSettings bgInitAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const InitializationSettings bgInitSettings =
      InitializationSettings(android: bgInitAndroid);

  // Initialize notifications registering our top-level Dart callback for actions
  await flutterLocalNotificationsPlugin.initialize(
    bgInitSettings,
    onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
  );

  // ── Timer control functions ──

  Future<void> updateNotification() async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final minutes = (remainingSeconds / 60).floor().toString().padLeft(2, '0');
        final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

        final String titleText = isRunning ? 'tickr Timer running' : 'tickr Timer paused';
        final String statusText = isRunning
            ? 'Interval: $minutes:$seconds | Rep: $currentRep/$totalReps'
            : 'Paused | Rep: $currentRep/$totalReps';

        final List<AndroidNotificationAction> actions = [];
        if (isRunning) {
          actions.add(const AndroidNotificationAction(
            'pause',
            'Pause',
            showsUserInterface: false,
            cancelNotification: false,
          ));
        } else {
          actions.add(const AndroidNotificationAction(
            'resume',
            'Resume',
            showsUserInterface: false,
            cancelNotification: false,
          ));
        }
        actions.add(const AndroidNotificationAction(
          'stop',
          'Stop',
          showsUserInterface: false,
          cancelNotification: false,
        ));

        try {
          await flutterLocalNotificationsPlugin.show(
            notificationId,
            titleText,
            statusText,
            NotificationDetails(
              android: AndroidNotificationDetails(
                notificationChannelId,
                'tickr active timer',
                channelDescription: 'Displays tickr timer countdown in notification drawer.',
                ongoing: true,
                icon: '@mipmap/launcher_icon',
                importance: Importance.low,
                priority: Priority.low,
                showWhen: false,
                playSound: false,
                enableVibration: false,
                actions: actions,
              ),
            ),
          );
        } catch (e) {
          debugPrint('Error showing local notification: $e');
        }
      }
    }
  }

  void stopLocalTimer() {
    ticker?.cancel();
    isRunning = false;
  }

  Future<void> playChime() async {
    try {
      await backgroundPlayer.stop();
      
      // Read chime haptic strength dynamically from SharedPreferences in background
      final prefs = await SharedPreferences.getInstance();
      final chimeHapticStrength = prefs.getString('chime_haptic_strength') ?? 'medium';

      // Trigger vibration in the rhythm of the chime
      VibrationService.vibrateForChime(selectedChimeType ?? 'dragon_studio_alert', chimeHapticStrength);

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

  startLocalTimer = () {
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
        currentRep++;
        playChime();

        if (currentRep > totalReps) {
          stopLocalTimer();

          Future.delayed(const Duration(milliseconds: 1500), () {
            service.invoke('timerCompleted');

            if (service is AndroidServiceInstance) {
              flutterLocalNotificationsPlugin.show(
                889,
                'tickr Completed!',
                'All $totalReps repetitions completed.',
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'tickr_completed_channel',
                    'tickr Completed Alerts',
                    ongoing: false,
                    icon: '@mipmap/launcher_icon',
                    importance: Importance.low,
                    priority: Priority.low,
                    playSound: false,
                    enableVibration: false,
                  ),
                ),
              );
              Future.delayed(const Duration(seconds: 5), () {
                service.stopSelf();
              });
            }
          });
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
  };

  // ── Service event listeners (from UI-side) ──

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
    updateNotification();
  });

  service.on('resumeTimer').listen((event) {
    startLocalTimer();
    updateNotification();
  });

  service.on('stopTimer').listen((event) {
    stopLocalTimer();
    if (service is AndroidServiceInstance) {
      service.stopSelf();
    }
  });

  // Legacy listeners for backward compatibility
  service.on('notificationPause').listen((event) {
    stopLocalTimer();
    service.invoke('timerTick', {
      'remainingSeconds': remainingSeconds,
      'currentRep': currentRep,
      'status': 'paused',
    });
    updateNotification();
  });

  service.on('notificationResume').listen((event) {
    startLocalTimer();
    updateNotification();
  });

  service.on('notificationStop').listen((event) {
    stopLocalTimer();
    flutterLocalNotificationsPlugin.cancel(notificationId);
    service.invoke('timerTick', {
      'remainingSeconds': 0,
      'currentRep': 0,
      'status': 'idle',
    });
    if (service is AndroidServiceInstance) {
      service.stopSelf();
    }
  });
}
