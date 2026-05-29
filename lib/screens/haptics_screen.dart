import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../services/vibration_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_scale.dart';
import 'home_screen.dart'; // To reuse BackgroundGlow

class HapticsScreen extends ConsumerWidget {
  const HapticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Determine dynamic scale
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
          
          final tapsStrength = ref.watch(tapsHapticStrengthProvider) ?? 'medium';
          final scrollStrength = ref.watch(scrollHapticStrengthProvider) ?? 'heavy';
          final chimeStrength = ref.watch(chimeHapticStrengthProvider) ?? 'medium';

          return Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                // Reuse space-dark background glow
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

                        // Header with back navigation
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
                                VibrationService.vibrateForTap(ref.read(tapsHapticStrengthProvider) ?? 'medium');
                                Navigator.pop(context);
                              },
                            ),
                            Text(
                              'HAPTIC FEEDBACK',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: scale.sp(16),
                                letterSpacing: scale.w(4.0),
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            SizedBox(width: scale.w(48)), // Right balance spacing
                          ],
                        ),

                        SizedBox(height: scale.h(24)),

                        // Main list of haptic panels
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              // 1. Taps Panel
                              _buildHapticCard(
                                context,
                                ref,
                                title: 'BUTTON & ACTION TAPS',
                                description: 'Vibration feedback when pressing action buttons, navigation icons, or settings.',
                                icon: Icons.touch_app_rounded,
                                currentStrength: tapsStrength,
                                onStrengthChanged: (newStrength) {
                                  ref.read(tapsHapticStrengthProvider.notifier).set(newStrength);
                                  VibrationService.vibrateForTap(newStrength);
                                },
                              ),

                              SizedBox(height: scale.h(20)),

                              // 2. Scroll Dial Panel
                              _buildHapticCard(
                                context,
                                ref,
                                title: 'SCROLLING DIAL WHEEL',
                                description: 'Mechanical clicking feeling triggered while scrolling and selecting numbers on the time input wheels.',
                                icon: Icons.unfold_more_rounded,
                                currentStrength: scrollStrength,
                                onStrengthChanged: (newStrength) {
                                  ref.read(scrollHapticStrengthProvider.notifier).set(newStrength);
                                  VibrationService.vibrateForScroll(newStrength);
                                },
                              ),

                              SizedBox(height: scale.h(20)),

                              // 3. Chime Completed Rhythm Panel
                              _buildHapticCard(
                                context,
                                ref,
                                title: 'ALERT CHIME RHYTHM',
                                description: 'Vibration pattern matched to the rhythm of your completed chime alert sound.',
                                icon: Icons.notifications_active_rounded,
                                currentStrength: chimeStrength,
                                onStrengthChanged: (newStrength) {
                                  ref.read(chimeHapticStrengthProvider.notifier).set(newStrength);
                                  VibrationService.vibrateForChime('dragon_studio_alert', newStrength);
                                },
                              ),
                            ],
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

  Widget _buildHapticCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String description,
    required IconData icon,
    required String currentStrength,
    required ValueChanged<String> onStrengthChanged,
  }) {
    final scale = ResponsiveScale.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: scale.w(18),
        vertical: scale.h(20),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderGlass,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon + Title block
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(scale.w(8)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.accent,
                  size: scale.sp(20),
                ),
              ),
              SizedBox(width: scale.w(12)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: scale.sp(13),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: scale.h(10)),

          // Description
          Text(
            description,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: scale.sp(11.5),
              height: 1.4,
            ),
          ),

          SizedBox(height: scale.h(18)),

          // Segmented Options Control
          Row(
            children: ['off', 'light', 'medium', 'heavy'].map((strength) {
              final isSelected = currentStrength == strength;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onStrengthChanged(strength),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: scale.w(3)),
                    padding: EdgeInsets.symmetric(vertical: scale.h(10)),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : const Color(0x08FFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : const Color(0x10FFFFFF),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      strength.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: scale.sp(10),
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
