import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_scale.dart';
import 'progress_arc.dart';

// ---------------------------------------------------------------------------
// Countdown display — the hero element of the UI
// ---------------------------------------------------------------------------
class CountdownDisplay extends ConsumerStatefulWidget {
  const CountdownDisplay({super.key, this.arcSize = 280});

  final double arcSize;

  @override
  ConsumerState<CountdownDisplay> createState() => _CountdownDisplayState();
}

class _CountdownDisplayState extends ConsumerState<CountdownDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<Color?> _flashColor;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flashColor = ColorTween(
      begin: AppColors.textPrimary,
      end: AppColors.chimeFlash,
    ).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
    ));

    // Listen for chime events to trigger flash
    ref.listenManual(chimeEventProvider, (prev, next) {
      _flashController.forward().then((_) => _flashController.reverse());
    });
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timerProvider);
    final scale = ResponsiveScale.of(context);

    // Calculate dot progress (overall progress across all reps)
    double dotProgress = 0.0;
    if (state.isCompleted) {
      dotProgress = 1.0;
    } else if (!state.isIdle && state.totalReps > 0) {
      dotProgress = (state.currentRep - 1 + state.intervalProgress) / state.totalReps;
    }

    final targetProgress = state.intervalProgress;
    final targetDotProgress = dotProgress;

    // Use TweenAnimationBuilder to animate dotProgress (overall rotating disc) smoothly.
    // We animate at linear speed over 1 second (matching the 1-second timer ticker) for perfect continuity.
    // If the timer is not running (e.g. idle/paused/completed), duration is zero for instant response.
    final animateDuration = state.isRunning ? const Duration(seconds: 1) : Duration.zero;

    return TweenAnimationBuilder<double>(
      key: const ValueKey('dotProgressTween'),
      tween: Tween<double>(begin: 0.0, end: targetDotProgress),
      duration: animateDuration,
      curve: Curves.linear,
      builder: (context, animatedDotProgress, child) {
        return ProgressArc(
          progress: targetProgress,
          dotProgress: animatedDotProgress,
          size: widget.arcSize,
          child: child!,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- Countdown digits ----
          AnimatedBuilder(
            animation: _flashColor,
            builder: (context, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  key: ValueKey(state.remainingSeconds),
                  _formatTime(state),
                  style: _timerTextStyle(context, widget.arcSize, scale).copyWith(
                    color: state.isCompleted
                        ? AppColors.success
                        : _flashColor.value,
                  ),
                ),
              );
            },
          ),

          SizedBox(height: scale.h(8)),

          // ---- Status / rep subtitle ----
          _StatusBadge(state: state),
        ],
      ),
    );
  }

  String _formatTime(ChimeState state) {
    if (state.isIdle) {
      // Show the configured interval
      final totalSecs = state.intervalSeconds;
      final m = totalSecs ~/ 60;
      final s = totalSecs % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    if (state.isCompleted) return '✓';
    final m = state.remainingSeconds ~/ 60;
    final s = state.remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  TextStyle _timerTextStyle(BuildContext context, double arcSize, ResponsiveScale scale) {
    final theme = Theme.of(context);
    TextStyle baseStyle;
    if (arcSize >= 280) {
      baseStyle = theme.textTheme.displayLarge!;
    } else if (arcSize >= 220) {
      baseStyle = theme.textTheme.displayMedium!;
    } else {
      baseStyle = theme.textTheme.displaySmall!;
    }
    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize! * scale.scaleFactor,
      letterSpacing: baseStyle.letterSpacing != null ? baseStyle.letterSpacing! * scale.scaleFactor : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge below countdown
// ---------------------------------------------------------------------------
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});

  final ChimeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ResponsiveScale.of(context);
    final (label, color) = _statusInfo();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey('${state.status}-${state.currentRep}'),
        children: [
          if (state.isRunning || state.isPaused) ...[
            Text(
              'REP ${state.currentRep} OF ${state.totalReps}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: (theme.textTheme.titleMedium?.fontSize ?? 11) * scale.scaleFactor,
                letterSpacing: (theme.textTheme.titleMedium?.letterSpacing ?? 2.0) * scale.scaleFactor,
              ),
            ),
            SizedBox(height: scale.h(6)),
          ],
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: scale.w(14),
              vertical: scale.h(5),
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(scale.sp(20)),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1 * scale.scaleFactor),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: scale.sp(10),
                letterSpacing: scale.w(2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _statusInfo() {
    return switch (state.status) {
      ChimeStatus.idle => ('READY', AppColors.textMuted),
      ChimeStatus.running => ('RUNNING', AppColors.primaryLight),
      ChimeStatus.paused => ('PAUSED', AppColors.accent),
      ChimeStatus.completed => ('COMPLETE', AppColors.success),
    };
  }
}
