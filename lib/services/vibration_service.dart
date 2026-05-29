import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class VibrationService {
  static const MethodChannel _channel =
      MethodChannel('com.chimeapp.chime_app/notification');

  /// Custom vibration patterns matching each chime type's rhythm.
  /// Format: [delay, vibrate, delay, vibrate, ...] in milliseconds.
  static final Map<String, List<int>> _patterns = {
    'dragon_studio_alert': [0, 120, 100, 120, 100, 200],
    'notification_message_alert': [0, 60, 80, 60],
    'clear_mobile_notification': [0, 150],
    'mysterious_ringtone': [0, 250, 150, 250, 150, 250],
    'new_notification_030': [0, 80],
    'new_notification_050': [0, 80, 120, 150],
    'new_notification_060': [0, 60, 80, 100, 80, 180],
    'new_notification_061': [0, 180, 80, 100, 80, 60],
    'custom': [0, 100, 120, 200],
  };

  /// Triggers a vibration matching the given chime type.
  static Future<void> vibrateForChime(String chimeType) async {
    final pattern = _patterns[chimeType] ?? _patterns['custom']!;

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('vibratePattern', {'pattern': pattern});
      } catch (e) {
        // Fallback to Dart loop if MethodChannel fails or on other platforms
        await _vibrateDartFallback(pattern);
      }
    } else {
      // iOS / Fallback using sequential haptic feedback calls
      await _vibrateDartFallback(pattern);
    }
  }

  /// Portable fallback using sequential HapticFeedback calls with precise delays.
  static Future<void> _vibrateDartFallback(List<int> pattern) async {
    for (int i = 0; i < pattern.length; i++) {
      final ms = pattern[i];
      if (ms <= 0) continue;
      
      if (i % 2 == 1) {
        // Odd indices are vibration durations
        if (ms < 100) {
          await HapticFeedback.lightImpact();
        } else if (ms < 180) {
          await HapticFeedback.mediumImpact();
        } else {
          await HapticFeedback.heavyImpact();
        }
        await Future.delayed(Duration(milliseconds: ms));
      } else {
        // Even indices (except 0) are delay intervals
        await Future.delayed(Duration(milliseconds: ms));
      }
    }
  }
}
