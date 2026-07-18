import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A circular progress ring with a gradient stroke and soft outer glow,
/// matching the Everlastimer home-screen design: a dim full-circle track
/// with a bright accent-colored arc drawn on top for the completed
/// fraction.
class ProgressRing extends StatelessWidget {
  final double progress; // 0.0–1.0
  final double size;
  final double strokeWidth;
  final Widget? child;
  final Color startColor;
  final Color endColor;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 280,
    this.strokeWidth = 14,
    this.child,
    this.startColor = const Color(0xFFB05CFF),
    this.endColor = const Color(0xFFE957FF),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProgressRingPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          startColor: startColor,
          endColor: endColor,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color startColor;
  final Color endColor;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.startColor,
    required this.endColor,
  });

  static const _trackColor = Color(0xFF1E1B2E);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track — full dim circle drawn as a circle (not arc) to
    // avoid any seam from overlapping round caps at the 0/2π boundary.
    final trackPaint = Paint()
      ..color = _trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    const startAngle = -math.pi / 2; // 12 o'clock
    final sweepAngle = 2 * math.pi * progress;

    // Gradient sweeps from startAngle clockwise for a full circle so the
    // transition from startColor → endColor lands exactly at [progress].
    final gradientShader = SweepGradient(
      center: Alignment.center,
      startAngle: startAngle,
      endAngle: startAngle + 2 * math.pi,
      colors: [startColor, endColor, endColor],
      stops: [0.0, progress, progress],
    ).createShader(rect);

    // Soft glow pass: wider, blurred stroke underneath the sharp arc.
    final glowPaint = Paint()
      ..shader = gradientShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // Sharp gradient arc on top — round caps on both ends.
    final arcPaint = Paint()
      ..shader = gradientShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.startColor != startColor ||
        oldDelegate.endColor != endColor;
  }
}