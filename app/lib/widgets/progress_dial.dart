import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A speedometer-style radial dial (270° sweep) with tick marks,
/// alternate to [ProgressRing] for the "Dial" widget style.
class ProgressDial extends StatelessWidget {
  final double progress; // 0.0–1.0
  final double size;
  final Color startColor;
  final Color endColor;
  final Widget? child;

  const ProgressDial({
    super.key,
    required this.progress,
    this.size = 280,
    this.startColor = const Color(0xFFB05CFF),
    this.endColor = const Color(0xFFE957FF),
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DialPainter(
          progress: progress.clamp(0.0, 1.0),
          startColor: startColor,
          endColor: endColor,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double progress;
  final Color startColor;
  final Color endColor;

  _DialPainter({required this.progress, required this.startColor, required this.endColor});

  // 270° sweep, starting at 135° (bottom-left) and ending at 45° (bottom-right),
  // going clockwise through the top — a classic speedometer arc.
  static const double _sweepDeg = 270;
  static const double _startDeg = 135;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.05;
    final radius = (size.width - strokeWidth) / 2 - 16;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final startRad = _startDeg * math.pi / 180;
    final sweepRad = _sweepDeg * math.pi / 180;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFF1E1B2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startRad, sweepRad, false, trackPaint);

    // Tick marks around the dial
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 2;
    const tickCount = 27; // every 10% of the sweep, roughly
    for (var i = 0; i <= tickCount; i++) {
      final angle = startRad + sweepRad * (i / tickCount);
      final outer = Offset(
        center.dx + (radius + strokeWidth / 2 + 6) * math.cos(angle),
        center.dy + (radius + strokeWidth / 2 + 6) * math.sin(angle),
      );
      final inner = Offset(
        center.dx + (radius + strokeWidth / 2 + 1) * math.cos(angle),
        center.dy + (radius + strokeWidth / 2 + 1) * math.sin(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    if (progress <= 0) return;

    final progressSweep = sweepRad * progress;
    final gradientBrush = SweepGradient(
      startAngle: startRad,
      endAngle: startRad + sweepRad,
      colors: [startColor, endColor],
    );

    final fillPaint = Paint()
      ..shader = gradientBrush.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(rect, startRad, progressSweep, false, fillPaint);

    // Needle pointing at current progress.
    final needleAngle = startRad + progressSweep;
    final needleLength = radius - strokeWidth;
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );
    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.startColor != startColor ||
        oldDelegate.endColor != endColor;
  }
}