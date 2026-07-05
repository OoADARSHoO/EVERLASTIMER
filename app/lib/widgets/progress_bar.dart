import 'package:flutter/material.dart';

/// A horizontal progress bar with a gradient fill and soft glow,
/// alternate to [ProgressRing] for the "Bar" widget style.
class ProgressBar extends StatelessWidget {
  final double progress; // 0.0–1.0
  final double height;
  final Color startColor;
  final Color endColor;

  const ProgressBar({
    super.key,
    required this.progress,
    this.height = 18,
    this.startColor = const Color(0xFFB05CFF),
    this.endColor = const Color(0xFFE957FF),
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fillWidth = constraints.maxWidth * clamped;

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              // Track
              Container(
                width: double.infinity,
                height: height,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B2E),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              // Glow pass
              if (clamped > 0)
                Container(
                  width: fillWidth,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    gradient: LinearGradient(colors: [startColor, endColor]),
                    boxShadow: [
                      BoxShadow(color: startColor.withValues(alpha: 0.5), blurRadius: 14, spreadRadius: 1),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}