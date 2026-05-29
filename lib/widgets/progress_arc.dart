import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Circular progress arc painted behind the countdown display
// ---------------------------------------------------------------------------
class ProgressArc extends StatelessWidget {
  const ProgressArc({
    super.key,
    required this.progress,
    required this.dotProgress,
    required this.child,
    required this.isCompleted,
    this.size = 280,
    this.strokeWidth = 3.0,
  });

  /// Progress within the current interval [0.0 → 1.0]
  final double progress;

  /// Progress of the moving dot (overall session progress) [0.0 → 1.0]
  final double dotProgress;

  final Widget child;
  final double size;
  final double strokeWidth;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arc painter
          CustomPaint(
            size: Size(size, size),
            painter: _ArcPainter(
              progress: progress,
              dotProgress: dotProgress,
              strokeWidth: strokeWidth,
              isCompleted: isCompleted,
            ),
          ),
          // Content in center
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painter
// ---------------------------------------------------------------------------
class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.dotProgress,
    required this.strokeWidth,
    required this.isCompleted,
  });

  final double progress;
  final double dotProgress;
  final double strokeWidth;
  final bool isCompleted;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    // 1. Beautiful rotating sweep gradient disc representing overall progress (drawn first as background)
    // Touches the outer circle (uses radius) and has a perfectly sharp leading radial edge.
    if (!isCompleted) {
      final rotationAngle = 2 * math.pi * dotProgress.clamp(0.0, 1.0);
      final discPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: 2 * math.pi,
          colors: [
            AppColors.primary.withValues(alpha: 0.03),
            AppColors.primaryLight.withValues(alpha: 0.1),
            AppColors.accent.withValues(alpha: 0.25),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 0.999, 1.0],
          transform: GradientRotation(-math.pi / 2 + rotationAngle),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, discPaint);
    }

    // 2. Outer track ring (for current rep progress)
    final trackPaint = Paint()
      ..color = AppColors.arcTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 3. Outer progress arc showing current rep progress
    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      final arcPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweepAngle,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
            AppColors.accent,
          ],
          stops: const [0.0, 0.6, 1.0],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // start at 12 o'clock
        sweepAngle,
        false,
        arcPaint,
      );
    }

    // 4. Normal solid dot representing current rep progress (no huge glow, does not reset/disappear)
    final repSweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final repTipAngle = -math.pi / 2 + repSweepAngle;
    final repTipX = center.dx + radius * math.cos(repTipAngle);
    final repTipY = center.dy + radius * math.sin(repTipAngle);

    final repDotPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(repTipX, repTipY), strokeWidth * 1.8, repDotPaint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress ||
      old.dotProgress != dotProgress ||
      old.isCompleted != isCompleted;
}
