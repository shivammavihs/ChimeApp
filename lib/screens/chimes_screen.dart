import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/settings_provider.dart';
import '../services/vibration_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_scale.dart';
import 'home_screen.dart'; // import to reuse BackgroundGlow

class ChimesScreen extends ConsumerStatefulWidget {
  const ChimesScreen({super.key});

  @override
  ConsumerState<ChimesScreen> createState() => _ChimesScreenState();
}

class _ChimesScreenState extends ConsumerState<ChimesScreen> {
  final AudioPlayer _previewPlayer = AudioPlayer();

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  void _previewSound(String key, String? customPath) async {
    try {
      // Trigger vibration in the rhythm of the chime
      VibrationService.vibrateForChime(key);

      if (key == 'custom' && customPath != null && File(customPath).existsSync()) {
        await _previewPlayer.play(DeviceFileSource(customPath));
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
        final assetPath = builtInChimes[key] ?? 'audio/dragon_studio_alert.mp3';
        await _previewPlayer.play(AssetSource(assetPath));
      }
    } catch (e) {
      debugPrint('Error previewing sound: $e');
    }
  }

  Future<void> _pickCustomSound(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final pickedFile = File(result.files.single.path!);
        final ext = pickedFile.path.split('.').last;
        final appDir = await getApplicationDocumentsDirectory();

        final savedFile = await pickedFile.copy(
          '${appDir.path}/custom_chime.$ext',
        );

        ref.read(customChimeSoundPathProvider.notifier).set(savedFile.path);

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceGlass,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.primary, width: 1),
            ),
            content: Text(
              'Custom chime sound set successfully!',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
          content: Text('Failed to pick sound: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Determine layout scale dynamically
    final isTablet = screenWidth >= 600;
    final layoutWidth = isTablet ? 500.0 : screenWidth;
    
    final scaleX = (layoutWidth / 375.0).clamp(0.85, 1.4);
    final scaleY = (screenHeight / 812.0).clamp(0.85, 1.4);
    final scaleFactor = ((scaleX + scaleY) / 2.0).clamp(0.85, 1.4);

    return ResponsiveScale(
      scaleX: scaleX,
      scaleY: scaleY,
      scaleFactor: scaleFactor,
      child: Builder(
        builder: (context) {
          final scale = ResponsiveScale.of(context);
          final selectedType = ref.watch(selectedChimeTypeProvider) ?? 'dragon_studio_alert';
          final customSoundPath = ref.watch(customChimeSoundPathProvider);
          final customFileName = customSoundPath != null
              ? customSoundPath.split('/').last
              : 'No file selected';

          final List<(String, String, String)> soundOptions = [
            (
              'custom',
              'Custom Audio File',
              customSoundPath != null
                  ? 'File: $customFileName'
                  : 'Select a custom sound from device'
            ),
            ('dragon_studio_alert', 'Dragon Studio Alert', 'Electronic synth alert chime'),
            ('notification_message_alert', 'Message Alert', 'Soft high-pitched bubble notification'),
            ('clear_mobile_notification', 'Clear Notification', 'Clean modern electronic chime'),
            ('mysterious_ringtone', 'Mysterious Ringtone', 'Atmospheric mysterious melody'),
            ('new_notification_030', 'Modern Chime 30', 'Short bright notification sound'),
            ('new_notification_050', 'Modern Chime 50', 'Double-ping ambient chime'),
            ('new_notification_060', 'Modern Chime 60', 'Fast ascending alert chime'),
            ('new_notification_061', 'Modern Chime 61', 'Fast descending alert chime'),
          ];

          return Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                // Locked dark background glow
                const BackgroundGlow(isDark: true),

                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: scale.w(24),
                      vertical: scale.h(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: scale.h(12)),

                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.chevron_left_rounded,
                                color: AppColors.textPrimary,
                                size: scale.sp(28),
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                            ),
                            Text(
                              'CHIME SOUNDS',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: scale.sp(16),
                                letterSpacing: scale.w(6.0),
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            SizedBox(width: scale.w(48)), // Right spacing balance
                          ],
                        ),

                        SizedBox(height: scale.h(24)),

                        // Curated options label
                        Text(
                          'SELECT ALERT CHIME',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: scale.sp(11),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),

                        SizedBox(height: scale.h(16)),

                        // Chimes sound options list
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: soundOptions.length,
                            itemBuilder: (context, index) {
                              final opt = soundOptions[index];
                              final key = opt.$1;
                              final name = opt.$2;
                              final desc = opt.$3;
                              final isSelected = selectedType == key;

                              return Container(
                                margin: EdgeInsets.only(bottom: scale.h(12)),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : const Color(0x12FFFFFF),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : const Color(0x1AFFFFFF),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    if (key == 'custom' && customSoundPath == null) {
                                      _pickCustomSound(context);
                                      ref
                                          .read(selectedChimeTypeProvider.notifier)
                                          .set('custom');
                                    } else {
                                      ref
                                          .read(selectedChimeTypeProvider.notifier)
                                          .set(key);
                                      _previewSound(key, customSoundPath);
                                    }
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: scale.w(18),
                                      vertical: scale.h(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(scale.w(8)),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.accent
                                                    .withValues(alpha: 0.15)
                                                : const Color(0x0AFFFFFF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            key == 'custom'
                                                ? Icons.folder_open_rounded
                                                : Icons.music_note_rounded,
                                            color: isSelected
                                                ? AppColors.accent
                                                : AppColors.textMuted,
                                            size: scale.sp(22),
                                          ),
                                        ),
                                        SizedBox(width: scale.w(16)),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: scale.sp(14),
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: scale.h(4)),
                                              Text(
                                                desc,
                                                style: TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: scale.sp(12),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (key == 'custom' &&
                                            customSoundPath != null) ...[
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit_note_rounded,
                                              color: AppColors.accent,
                                              size: scale.sp(22),
                                            ),
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              _pickCustomSound(context);
                                            },
                                          ),
                                        ],
                                        Icon(
                                          isSelected
                                              ? Icons.radio_button_checked_rounded
                                              : Icons.radio_button_off_rounded,
                                          color: isSelected
                                              ? AppColors.accent
                                              : AppColors.textDisabled,
                                          size: scale.sp(22),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
