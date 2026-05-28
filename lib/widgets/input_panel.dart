import 'package:flutter/material.dart';
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
        SizedBox(height: scale.h(8)),
        Text(
          'SET INTERVAL',
          style: TextStyle(
            fontSize: scale.sp(10),
            fontWeight: FontWeight.w500,
            letterSpacing: scale.w(4.0),
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        SizedBox(height: scale.h(36)),

        // The unified 3-column scroll picker
        const UnifiedWheelPicker(),

        SizedBox(height: scale.h(48)),

        // Dynamic presets label
        Text(
          'PRESETS',
          style: TextStyle(
            fontSize: scale.sp(10),
            fontWeight: FontWeight.w600,
            letterSpacing: scale.w(4.0),
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
        SizedBox(height: scale.h(18)),

        // Preset buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPresetButton(
              context,
              ref,
              label: '1m (5x)',
              mins: 1,
              secs: 0,
              reps: 5,
            ),
            SizedBox(width: scale.w(12)),
            _buildPresetButton(
              context,
              ref,
              label: '3m (5x)',
              mins: 3,
              secs: 0,
              reps: 5,
            ),
            SizedBox(width: scale.w(12)),
            _buildPresetButton(
              context,
              ref,
              label: '5m (10x)',
              mins: 5,
              secs: 0,
              reps: 10,
            ),
          ],
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
        ref.read(intervalMinutesProvider.notifier).set(mins);
        ref.read(intervalSecondsProvider.notifier).set(secs);
        ref.read(totalRepsProvider.notifier).set(reps);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: scale.w(22),
          vertical: scale.h(11),
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(scale.sp(22)),
          border: Border.all(
            color: isActive
                ? AppColors.primaryLight.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
            fontSize: scale.sp(12),
            fontWeight: FontWeight.w400,
            letterSpacing: scale.w(0.5),
          ),
        ),
      ),
    );
  }
}
