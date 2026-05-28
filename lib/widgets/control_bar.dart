import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_scale.dart';

// ---------------------------------------------------------------------------
// Control bar — Start / Pause / Resume / Stop buttons
// ---------------------------------------------------------------------------
class ControlBar extends ConsumerWidget {
  const ControlBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: _buildButtons(context, state, notifier),
    );
  }

  Widget _buildButtons(
    BuildContext context,
    ChimeState state,
    ChimeTimerNotifier notifier,
  ) {
    final scale = ResponsiveScale.of(context);

    if (state.isCompleted) {
      return Row(
        key: const ValueKey('completed_controls'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Reset button
          _GhostPillButton(
            label: 'RESET',
            icon: Icons.refresh_rounded,
            onTap: notifier.stop,
            color: AppColors.textMuted,
          ),

          SizedBox(width: scale.w(16)),

          // Restart button
          _PrimaryPillButton(
            label: 'RESTART',
            icon: Icons.play_arrow_rounded,
            onTap: notifier.start,
          ),
        ],
      );
    }

    if (state.isIdle) {
      return _StartButton(
        key: const ValueKey('start'),
        label: 'START',
        onTap: notifier.start,
      );
    }

    // Running or paused: show pause/resume + stop
    return Row(
      key: const ValueKey('controls'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop button
        _GhostPillButton(
          label: 'STOP',
          icon: Icons.stop_rounded,
          onTap: notifier.stop,
          color: AppColors.textMuted,
        ),

        SizedBox(width: scale.w(16)),

        // Pause / Resume
        if (state.isRunning)
          _PrimaryPillButton(
            label: 'PAUSE',
            icon: Icons.pause_rounded,
            onTap: notifier.pause,
          )
        else
          _PrimaryPillButton(
            label: 'RESUME',
            icon: Icons.play_arrow_rounded,
            onTap: notifier.resume,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Large gradient START button
// ---------------------------------------------------------------------------
class _StartButton extends StatefulWidget {
  const _StartButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _glowCtrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _glow = Tween<double>(begin: 8.0, end: 22.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = ResponsiveScale.of(context);
    final btnSize = scale.sp(80);

    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_scale, _glow]),
        builder: (context, child) {
          return ScaleTransition(
            scale: _ctrl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient ring container — outer ring is the gradient border
                Container(
                  width: btnSize,
                  height: btnSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent,
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        blurRadius: _glow.value * scale.scaleFactor,
                        spreadRadius: 1 * scale.scaleFactor,
                      ),
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.10),
                        blurRadius: (_glow.value * 2) * scale.scaleFactor,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(1.5 * scale.scaleFactor), // ring width
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.9,
                        colors: AppColors.isDark
                            ? [
                                const Color(0xFF0C1228),
                                const Color(0xFF060A18),
                              ]
                            : [
                                Colors.white,
                                const Color(0xFFF0F2F8),
                              ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.isDark
                          ? Colors.white.withValues(alpha: 0.95)
                          : AppColors.primary,
                      size: scale.sp(40),
                    ),
                  ),
                ),
                SizedBox(height: scale.h(14)),
                // Text label below the button
                Text(
                  'S T A R T',
                  style: TextStyle(
                    color: AppColors.isDark
                        ? AppColors.accent.withValues(alpha: 0.7)
                        : AppColors.primary,
                    fontSize: scale.sp(11),
                    fontWeight: FontWeight.w500,
                    letterSpacing: scale.w(4.0),
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

// ---------------------------------------------------------------------------
// Primary pill button (pause / resume)
// ---------------------------------------------------------------------------
class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = ResponsiveScale.of(context);

    return _GlassPill(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: scale.sp(18), color: AppColors.primaryLight),
          SizedBox(width: scale.w(8)),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primaryLight,
                  fontSize: scale.sp(14),
                  letterSpacing: scale.w(1.0),
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ghost pill button (stop)
// ---------------------------------------------------------------------------
class _GhostPillButton extends StatelessWidget {
  const _GhostPillButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scale = ResponsiveScale.of(context);

    return _GlassPill(
      onTap: onTap,
      borderColor: color.withValues(alpha: 0.3),
      bgColor: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: scale.sp(18), color: color),
          SizedBox(width: scale.w(8)),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontSize: scale.sp(14),
                  letterSpacing: scale.w(1.0),
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Base glass pill container
// ---------------------------------------------------------------------------
class _GlassPill extends StatefulWidget {
  const _GlassPill({
    required this.child,
    required this.onTap,
    this.bgColor,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color? bgColor;
  final Color? borderColor;

  @override
  State<_GlassPill> createState() => _GlassPillState();
}

class _GlassPillState extends State<_GlassPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = ResponsiveScale.of(context);

    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(scale.sp(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: scale.w(24),
                vertical: scale.h(14),
              ),
              decoration: BoxDecoration(
                color: widget.bgColor ?? AppColors.surfaceGlass,
                borderRadius: BorderRadius.circular(scale.sp(30)),
                border: Border.all(
                  color: widget.borderColor ?? AppColors.borderGlass,
                  width: 1 * scale.scaleFactor,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
