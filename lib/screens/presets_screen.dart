import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_scale.dart';
import '../widgets/unified_wheel_picker.dart';
import 'home_screen.dart'; // import to reuse BackgroundGlow

class PresetsScreen extends ConsumerStatefulWidget {
  const PresetsScreen({super.key});

  @override
  ConsumerState<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends ConsumerState<PresetsScreen> {
  final TextEditingController _presetNameController = TextEditingController();

  @override
  void dispose() {
    _presetNameController.dispose();
    super.dispose();
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
          final currentMin = ref.watch(intervalMinutesProvider);
          final currentSec = ref.watch(intervalSecondsProvider);
          final currentRep = ref.watch(totalRepsProvider);
          final presets = ref.watch(presetsProvider);

          return Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                // Reuse gorgeous background glow in locked dark mode
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

                        // Header with slide transition back icon
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
                              'PRESETS',
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

                        SizedBox(height: scale.h(16)),

                        // Live preset builder card
                        Text(
                          'CREATE NEW PRESET',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: scale.sp(11),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),

                        SizedBox(height: scale.h(10)),

                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: scale.w(16),
                            vertical: scale.h(16),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // The unified 3-column scroll picker from home screen
                              const UnifiedWheelPicker(),
                              
                              SizedBox(height: scale.h(16)),
                              
                              // Preset Name input
                              TextField(
                                controller: _presetNameController,
                                style: TextStyle(color: AppColors.textPrimary, fontSize: scale.sp(14)),
                                decoration: InputDecoration(
                                  hintText: 'Preset Label (e.g. Focus Time)',
                                  hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: scale.sp(13)),
                                  filled: true,
                                  fillColor: const Color(0x0AFFFFFF),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0x10FFFFFF),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: scale.w(16),
                                    vertical: scale.h(12),
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: scale.h(12)),
                              
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  minimumSize: Size(double.infinity, scale.h(44)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  String label = _presetNameController.text.trim();
                                  if (label.isEmpty) {
                                    label = '${currentMin}m ${currentSec > 0 ? '${currentSec}s ' : ''}($currentRep\u00d7)';
                                  }
                                  
                                  HapticFeedback.mediumImpact();
                                  ref.read(presetsProvider.notifier).addPreset(
                                    label: label,
                                    minutes: currentMin,
                                    seconds: currentSec,
                                    reps: currentRep,
                                  );
                                  _presetNameController.clear();
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.surfaceGlass,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: AppColors.primary, width: 1),
                                      ),
                                      content: Text(
                                        'Preset "$label" saved!',
                                        style: TextStyle(color: AppColors.textPrimary),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'SAVE PRESET',
                                  style: TextStyle(
                                    fontSize: scale.sp(12),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: scale.h(24)),

                        // Header of list
                        Text(
                          'SAVED PRESETS',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: scale.sp(11),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),

                        SizedBox(height: scale.h(10)),

                        // Presets List
                        Expanded(
                          child: presets.isEmpty
                              ? Center(
                                  child: Text(
                                    'No custom presets saved yet.',
                                    style: TextStyle(
                                      color: AppColors.textDisabled,
                                      fontSize: scale.sp(14),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: presets.length,
                                  itemBuilder: (context, index) {
                                    final preset = presets[index];
                                    final presetSetupText =
                                        '${preset.minutes}m ${preset.seconds > 0 ? '${preset.seconds}s ' : ''}(${preset.reps}\u00d7)';

                                    return Container(
                                      margin: EdgeInsets.only(bottom: scale.h(10)),
                                      decoration: BoxDecoration(
                                        color: const Color(0x0AFFFFFF),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0x10FFFFFF),
                                          width: 1,
                                        ),
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          ref
                                              .read(intervalMinutesProvider.notifier)
                                              .set(preset.minutes);
                                          ref
                                              .read(intervalSecondsProvider.notifier)
                                              .set(preset.seconds);
                                          ref
                                              .read(totalRepsProvider.notifier)
                                              .set(preset.reps);
                                          Navigator.pop(context); // Go back home
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: scale.w(16),
                                            vertical: scale.h(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(scale.w(8)),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.alarm_on_rounded,
                                                  color: AppColors.accent
                                                      .withValues(alpha: 0.8),
                                                  size: scale.sp(20),
                                                ),
                                              ),
                                              SizedBox(width: scale.w(16)),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      preset.label,
                                                      style: TextStyle(
                                                        color: AppColors.textPrimary,
                                                        fontSize: scale.sp(14),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: scale.h(2)),
                                                    Text(
                                                      presetSetupText,
                                                      style: TextStyle(
                                                        color: AppColors.textMuted,
                                                        fontSize: scale.sp(12),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: Colors.redAccent
                                                      .withValues(alpha: 0.8),
                                                  size: scale.sp(22),
                                                ),
                                                onPressed: () {
                                                  HapticFeedback.mediumImpact();
                                                  ref
                                                      .read(presetsProvider.notifier)
                                                      .deletePreset(preset.id);
                                                },
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
