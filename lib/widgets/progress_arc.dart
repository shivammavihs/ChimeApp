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
    required this.child,
    this.size = 280,
    this.strokeWidth = 3.0,
  });

  /// Progress within the current interval [0.0 → 1.0]
  final double progress;

  final Widget child;
  final double size;
  final double strokeWidth;

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
              strokeWidth: strokeWidth,
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
  _ArcPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    // Track ring
    final trackPaint = Paint()
      ..color = AppColors.arcTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Progress arc — sweep clockwise from top
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepAngle,
        colors: const [
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

    // Glowing dot at arc tip
    if (progress > 0.01) {
      final tipAngle = -math.pi / 2 + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);

      final dotPaint = Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(tipX, tipY), strokeWidth * 1.8, dotPaint);

      // Glow
      final glowPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(Offset(tipX, tipY), strokeWidth * 3, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
