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

  /// Triggers a vibration matching the given chime type with customized strength.
  static Future<void> vibrateForChime(String chimeType, [String strength = 'medium']) async {
    if (strength == 'off') return;

    final pattern = _patterns[chimeType] ?? _patterns['custom']!;

    // Translate strength to amplitude (1 to 255)
    int amplitude = 255;
    if (strength == 'light') {
      amplitude = 75;
    } else if (strength == 'medium') {
      amplitude = 165;
    } else if (strength == 'heavy') {
      amplitude = 255;
    }

    // Generate amplitudes: even indices are delay phases (0), odd indices are vibration phases (amplitude)
    final amplitudes = List<int>.generate(
      pattern.length,
      (i) => i % 2 == 1 ? amplitude : 0,
    );

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('vibratePattern', {
          'pattern': pattern,
          'amplitudes': amplitudes,
        });
      } catch (e) {
        await _vibrateDartFallback(pattern, strength);
      }
    } else {
      await _vibrateDartFallback(pattern, strength);
    }
  }

  /// Triggers a precise haptic vibration for UI taps based on strength.
  static Future<void> vibrateForTap(String strength) async {
    if (strength == 'off') return;
    
    try {
      if (strength == 'light') {
        await HapticFeedback.lightImpact();
      } else if (strength == 'medium') {
        await HapticFeedback.mediumImpact();
      } else if (strength == 'heavy') {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  /// Triggers a robust haptic vibration for the scrolling wheel picker.
  /// Standard selectionClick can feel weak, so this uses a brief high-amplitude custom pulse 
  /// on Android and crisp standard fallbacks on other platforms.
  static Future<void> vibrateForScroll(String strength) async {
    if (strength == 'off') return;

    if (Platform.isAndroid) {
      int durationMs = 15;
      int amplitude = 255;
      if (strength == 'light') {
        durationMs = 10;
        amplitude = 80;
      } else if (strength == 'medium') {
        durationMs = 16;
        amplitude = 170;
      } else if (strength == 'heavy') {
        durationMs = 24;
        amplitude = 255;
      }
      try {
        await _channel.invokeMethod('vibrateCustom', {
          'duration': durationMs,
          'amplitude': amplitude,
        });
      } catch (e) {
        await _vibrateScrollFallback(strength);
      }
    } else {
      await _vibrateScrollFallback(strength);
    }
  }

  /// Fallback scroll vibration for non-Android platforms.
  static Future<void> _vibrateScrollFallback(String strength) async {
    try {
      if (strength == 'light') {
        await HapticFeedback.selectionClick();
      } else if (strength == 'medium') {
        await HapticFeedback.lightImpact();
      } else if (strength == 'heavy') {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  /// Portable fallback using sequential HapticFeedback calls with precise delays.
  static Future<void> _vibrateDartFallback(List<int> pattern, String strength) async {
    for (int i = 0; i < pattern.length; i++) {
      final ms = pattern[i];
      if (ms <= 0) continue;
      
      if (i % 2 == 1) {
        // Odd indices are vibration durations
        try {
          if (strength == 'light') {
            await HapticFeedback.lightImpact();
          } else if (strength == 'medium') {
            await HapticFeedback.mediumImpact();
          } else if (strength == 'heavy') {
            await HapticFeedback.heavyImpact();
          }
        } catch (_) {}
        await Future.delayed(Duration(milliseconds: ms));
      } else {
        // Even indices (except 0) are delay intervals
        await Future.delayed(Duration(milliseconds: ms));
      }
    }
  }
}
