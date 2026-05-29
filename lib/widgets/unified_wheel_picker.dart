import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_scale.dart';

class UnifiedWheelPicker extends ConsumerStatefulWidget {
  const UnifiedWheelPicker({super.key});

  @override
  ConsumerState<UnifiedWheelPicker> createState() => _UnifiedWheelPickerState();
}

class _UnifiedWheelPickerState extends ConsumerState<UnifiedWheelPicker> {
  late FixedExtentScrollController _minController;
  late FixedExtentScrollController _secController;
  late FixedExtentScrollController _repController;

  // Track the current values internally to animate only when changed from outside (e.g. presets)
  int _lastMin = -1;
  int _lastSec = -1;
  int _lastRep = -1;

  @override
  void initState() {
    super.initState();
    final initialMin = ref.read(intervalMinutesProvider);
    final initialSec = ref.read(intervalSecondsProvider);
    final initialRep = ref.read(totalRepsProvider);

    _minController = FixedExtentScrollController(initialItem: initialMin);
    _secController = FixedExtentScrollController(initialItem: initialSec);
    _repController = FixedExtentScrollController(initialItem: initialRep - 1); // 1-indexed

    _lastMin = initialMin;
    _lastSec = initialSec;
    _lastRep = initialRep;
  }

  @override
  void dispose() {
    _minController.dispose();
    _secController.dispose();
    _repController.dispose();
    super.dispose();
  }

  void _animateTo(FixedExtentScrollController controller, int targetValue) {
    if (controller.hasClients) {
      controller.animateToItem(
        targetValue,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = ResponsiveScale.of(context);

    // Watch settings to animate wheels if they change externally (like clicking a preset)
    final currentMin = ref.watch(intervalMinutesProvider);
    final currentSec = ref.watch(intervalSecondsProvider);
    final currentRep = ref.watch(totalRepsProvider);

    // Sync from state to wheel animation if state changes externally
    if (currentMin != _lastMin) {
      _lastMin = currentMin;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateTo(_minController, currentMin);
      });
    }
    if (currentSec != _lastSec) {
      _lastSec = currentSec;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateTo(_secController, currentSec);
      });
    }
    if (currentRep != _lastRep) {
      _lastRep = currentRep;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateTo(_repController, currentRep - 1); // 1-indexed
      });
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: scale.w(16)),
      child: Column(
        children: [
          // Column Headers (Labels)
          Row(
            children: [
              _buildColumnLabel('Min', scale),
              // Colon spacing helper to match wheels row exactly
              Opacity(
                opacity: 0,
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 34 * scale.scaleFactor,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
              _buildColumnLabel('Sec', scale),
              // × spacing helper to match wheels row exactly
              Opacity(
                opacity: 0,
                child: Text(
                  '×',
                  style: TextStyle(
                    fontSize: 30 * scale.scaleFactor,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
              _buildColumnLabel('Reps', scale),
            ],
          ),
          SizedBox(height: scale.h(6)),

          // 3-Column Wheels Row
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  child: SizedBox(
                    height: 66 * scale.scaleFactor,
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 2 * scale.scaleFactor),
                              child: _buildGradientLine(scale),
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: 0,
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 34 * scale.scaleFactor,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 2 * scale.scaleFactor),
                              child: _buildGradientLine(scale),
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: 0,
                          child: Text(
                            '×',
                            style: TextStyle(
                              fontSize: 30 * scale.scaleFactor,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 2 * scale.scaleFactor),
                              child: _buildGradientLine(scale),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black,
                        Colors.black,
                        Colors.black.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.22, 0.78, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Row(
                    children: [
                      // Minutes Wheel
                      Expanded(
                        child: _buildWheel(
                          scale: scale,
                          controller: _minController,
                          currentVal: currentMin,
                          minVal: 0,
                          maxVal: 60,
                          onChanged: (val) {
                            if (_lastMin != val) {
                              _lastMin = val;
                              ref.read(intervalMinutesProvider.notifier).set(val);
                              HapticFeedback.selectionClick();
                            }
                          },
                        ),
                      ),

                      // Colon separator
                      Text(
                        ':',
                        style: TextStyle(
                          color: AppColors.selectedItem.withValues(alpha: 0.4),
                          fontSize: 34 * scale.scaleFactor,
                          fontWeight: FontWeight.w200,
                        ),
                      ),

                      // Seconds Wheel
                      Expanded(
                        child: _buildWheel(
                          scale: scale,
                          controller: _secController,
                          currentVal: currentSec,
                          minVal: 0,
                          maxVal: 59,
                          onChanged: (val) {
                            if (_lastSec != val) {
                              _lastSec = val;
                              ref.read(intervalSecondsProvider.notifier).set(val);
                              HapticFeedback.selectionClick();
                            }
                          },
                        ),
                      ),

                      // Reps multiplier separator
                      Text(
                        '×',
                        style: TextStyle(
                          color: AppColors.selectedItem.withValues(alpha: 0.3),
                          fontSize: 30 * scale.scaleFactor,
                          fontWeight: FontWeight.w200,
                        ),
                      ),

                      // Repetitions Wheel
                      Expanded(
                        child: _buildWheel(
                          scale: scale,
                          controller: _repController,
                          currentVal: currentRep,
                          minVal: 1,
                          maxVal: 99,
                          onChanged: (val) {
                            if (_lastRep != val) {
                              _lastRep = val;
                              ref.read(totalRepsProvider.notifier).set(val);
                              HapticFeedback.selectionClick();
                            }
                          },
                          isReps: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnLabel(String label, ResponsiveScale scale) {
    return Expanded(
      child: Center(
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: scale.sp(12),
            fontWeight: FontWeight.w600,
            letterSpacing: scale.w(3.0),
            color: AppColors.textMuted.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientLine(ResponsiveScale scale) {
    return Container(
      width: scale.w(58),
      height: 1.0,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(0.5),
      ),
    );
  }

  Widget _buildWheel({
    required ResponsiveScale scale,
    required FixedExtentScrollController controller,
    required int currentVal,
    required int minVal,
    required int maxVal,
    required ValueChanged<int> onChanged,
    bool isReps = false,
  }) {
    final count = maxVal - minVal + 1;

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 52 * scale.scaleFactor,
      perspective: 0.004,
      diameterRatio: 1.8,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        onChanged(index + minVal);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          final itemVal = index + minVal;
          final isSelected = itemVal == currentVal;

          return Center(
            child: Text(
              itemVal.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: isSelected ? 48 * scale.scaleFactor : 32 * scale.scaleFactor,
                fontWeight: isSelected ? FontWeight.w400 : FontWeight.w200,
                color: isSelected
                    ? AppColors.selectedItem
                    : AppColors.unselectedItem.withValues(alpha: 0.5),
                letterSpacing: -0.5 * scale.scaleFactor,
                shadows: isSelected
                    ? [
                        Shadow(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
