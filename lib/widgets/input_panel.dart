import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_scale.dart';
import 'unified_wheel_picker.dart';

class InputPanel extends ConsumerWidget {
  const InputPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ResponsiveScale.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: scale.h(4)),
        Text(
          'SET INTERVAL',
          style: TextStyle(
            fontSize: scale.sp(10),
            fontWeight: FontWeight.w500,
            letterSpacing: scale.w(5.0),
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
        SizedBox(height: scale.h(28)),

        // The unified 3-column scroll picker
        const UnifiedWheelPicker(),

        SizedBox(height: scale.h(36)),

        // Dynamic presets label
        Text(
          'PRESETS',
          style: TextStyle(
            fontSize: scale.sp(10),
            fontWeight: FontWeight.w500,
            letterSpacing: scale.w(5.0),
            color: Colors.white.withValues(alpha: 0.30),
          ),
        ),
        SizedBox(height: scale.h(14)),

        // Dynamic, horizontally scrollable presets list
        Consumer(
          builder: (context, ref, child) {
            final presets = ref.watch(presetsProvider);

            if (presets.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: scale.h(8)),
                  child: Text(
                    'No presets yet — add from Options',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: scale.sp(12),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: scale.w(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: presets.map((preset) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: scale.w(4)),
                    child: _buildPresetButton(
                      context,
                      ref,
                      label: preset.label,
                      mins: preset.minutes,
                      secs: preset.seconds,
                      reps: preset.reps,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPresetButton(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required int mins,
    required int secs,
    required int reps,
  }) {
    final currentMin = ref.watch(intervalMinutesProvider);
    final currentSec = ref.watch(intervalSecondsProvider);
    final currentRep = ref.watch(totalRepsProvider);
    final isActive = currentMin == mins && currentSec == secs && currentRep == reps;

    final scale = ResponsiveScale.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(intervalMinutesProvider.notifier).set(mins);
        ref.read(intervalSecondsProvider.notifier).set(secs);
        ref.read(totalRepsProvider.notifier).set(reps);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(scale.sp(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: scale.w(20),
              vertical: scale.h(10),
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(scale.sp(20)),
              border: Border.all(
                color: isActive
                    ? AppColors.primaryLight.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.45),
                fontSize: scale.sp(12),
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                letterSpacing: scale.w(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
