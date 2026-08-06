import 'dart:math';
import 'package:flutter/material.dart';

/// Glowing circular progress ring — fixes the "split color" seam by using
/// a SweepGradient whose start and end colors match, and adds a real glow
/// via layered blurred strokes instead of BoxShadow (which doesn't follow
/// curved strokes well).
class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final double size;
  final double strokeWidth;
  final Color startColor;
  final Color endColor;
  final Color trackColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 260,
    this.strokeWidth = 14,
    this.startColor = const Color(0xFFB833FF),
    this.endColor = const Color(0xFFFF3DE8),
    this.trackColor = const Color(0xFF2A2733),
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          colorStart: startColor,
          colorEnd: endColor,
          trackColor: trackColor,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color colorStart;
  final Color colorEnd;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.colorStart,
    required this.colorEnd,
    required this.trackColor,
  });

  static const double _startAngle = -pi / 2; // 12 o'clock

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * pi * progress;

    // 1. Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Gradient that starts and ends on the SAME hue family so there's no
    // visible seam where the arc begins/ends. We build a gradient spanning
    // slightly more than the sweep so the tail always blends into colorEnd.
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: sweepAngle,
      transform: GradientRotation(_startAngle),
      colors: [colorStart, colorEnd],
      stops: const [0.0, 1.0],
    );

    // 2. Outer soft glow — several blurred passes, widest/faintest first.
    final glowPasses = [
      (blur: 24.0, widthMul: 2.6, opacity: 0.20),
      (blur: 14.0, widthMul: 1.9, opacity: 0.35),
      (blur: 6.0, widthMul: 1.3, opacity: 0.55),
    ];

    for (final pass in glowPasses) {
      final glowPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * pass.widthMul
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: pass.opacity)
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, pass.blur);
      canvas.drawArc(rect, _startAngle, sweepAngle, false, glowPaint);
    }

    // 3. Crisp main stroke on top — this is what makes it read as "solid",
    // not just a blur cloud.
    final mainPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _startAngle, sweepAngle, false, mainPaint);

    // 4. Bright leading-edge dot (the little glowing head at the tip).
    final tipAngle = _startAngle + sweepAngle;
    final tipCenter = Offset(
      center.dx + radius * cos(tipAngle),
      center.dy + radius * sin(tipAngle),
    );
    final tipGlow = Paint()
      ..color = colorEnd.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(tipCenter, strokeWidth * 0.55, tipGlow);
    canvas.drawCircle(tipCenter, strokeWidth * 0.4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.colorStart != colorStart ||
        oldDelegate.colorEnd != colorEnd ||
        oldDelegate.trackColor != trackColor;
  }
}
