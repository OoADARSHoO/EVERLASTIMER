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

    // Background track — full dim circle.
    final trackPaint = Paint()
      ..color = _trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress;
    // Start at the top (12 o'clock = -90deg) and sweep clockwise.
    const startAngle = -math.pi / 2;

    // Rotate the canvas itself so the arc we draw always starts at local
    // angle 0 (3 o'clock). This sidesteps any ambiguity in how
    // GradientRotation composes with the SweepGradient's own angle frame
    // — after this rotation, "angle 0 in local space" IS "12 o'clock,
    // clockwise" in screen space, and a plain SweepGradient with
    // startAngle: 0 lines up with it exactly, every time, with no
    // separate rotation transform needed.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(startAngle);
    canvas.translate(-center.dx, -center.dy);

    // Gradient defined in this rotated local space: 0.0 -> startColor at
    // local angle 0 (which is now screen-12-o'clock), fading to endColor
    // at local angle == sweepAngle (the visible end of the arc), then
    // holding flat at endColor beyond that (irrelevant since drawArc
    // below only paints up to sweepAngle).
    final localProgressAngle = sweepAngle / (2 * math.pi);
    final gradientShader = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: 2 * math.pi,
      colors: [startColor, endColor, endColor],
      stops: [0.0, localProgressAngle, localProgressAngle],
    ).createShader(rect);

    // Soft glow pass: wider, blurred stroke underneath the sharp arc.
    final glowPaint = Paint()
      ..shader = gradientShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawArc(rect, 0, sweepAngle, false, glowPaint);

    // Sharp gradient arc on top — round caps on both ends.
    final arcPaint = Paint()
      ..shader = gradientShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, sweepAngle, false, arcPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.startColor != startColor ||
        oldDelegate.endColor != endColor;
  }
}