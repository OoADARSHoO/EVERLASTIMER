import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/home_widget_style.dart';
import '../../core/year_progress.dart';
import '../../core/year_progress_provider.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/progress_dial.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/stat_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(yearProgressProvider);
    final theme = ref.watch(appThemeProvider);
    final style = ref.watch(homeWidgetStyleProvider);

    return progressAsync.when(
      data: (yp) => _HomeContent(yearProgress: yp, theme: theme, style: style),
      loading: () => Center(
        child: CircularProgressIndicator(color: theme.accent.color),
      ),
      error: (err, _) => Center(
        child: Text(
          'Something went wrong: $err',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final YearProgress yearProgress;
  final AppThemeState theme;
  final HomeWidgetStyle style;

  const _HomeContent({
    required this.yearProgress,
    required this.theme,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          children: [
            const Text(
              'EVERLASTIMER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: _buildForStyle(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForStyle(BuildContext context) {
    switch (style) {
      case HomeWidgetStyle.ring:
        return _RingLayout(yearProgress: yearProgress, theme: theme);
      case HomeWidgetStyle.bar:
        return _BarLayout(yearProgress: yearProgress, theme: theme);
      case HomeWidgetStyle.dial:
        return _DialLayout(yearProgress: yearProgress, theme: theme);
      case HomeWidgetStyle.minimal:
        return _MinimalLayout(yearProgress: yearProgress, theme: theme);
    }
  }
}

/// Full original layout: ring + year label + completed/remaining pills +
/// month/week/day/hour stat grid.
class _RingLayout extends StatelessWidget {
  final YearProgress yearProgress;
  final AppThemeState theme;

  const _RingLayout({required this.yearProgress, required this.theme});

  @override
  Widget build(BuildContext context) {
    final yp = yearProgress;
    final accent = theme.accent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'YEAR ${yp.year}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        ProgressRing(
          progress: yp.fraction,
          size: 280,
          strokeWidth: 14,
          startColor: accent.color,
          endColor: accent.gradientPartner,
          child: _PercentLabel(yp: yp),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            StatPill(value: '${yp.daysCompleted}', label: 'days completed'),
            const SizedBox(width: 14),
            StatPill(value: '${yp.daysRemaining}', label: 'days remaining'),
          ],
        ),
        const SizedBox(height: 14),
        _StatGrid(yp: yp),
      ],
    );
  }
}

/// Compact layout: a horizontal bar with the percentage above it and a
/// trimmed-down stat row beneath — no full grid, no big stat pills.
class _BarLayout extends StatelessWidget {
  final YearProgress yearProgress;
  final AppThemeState theme;

  const _BarLayout({required this.yearProgress, required this.theme});

  @override
  Widget build(BuildContext context) {
    final yp = yearProgress;
    final accent = theme.accent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'YEAR ${yp.year}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        _PercentLabel(yp: yp, fontSize: 40),
        const SizedBox(height: 24),
        ProgressBar(
          progress: yp.fraction,
          startColor: accent.color,
          endColor: accent.gradientPartner,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${yp.daysCompleted} days done',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            Text('${yp.daysRemaining} days left',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 28),
        _StatGrid(yp: yp),
      ],
    );
  }
}

/// Speedometer-style dial with a needle and tick marks.
class _DialLayout extends StatelessWidget {
  final YearProgress yearProgress;
  final AppThemeState theme;

  const _DialLayout({required this.yearProgress, required this.theme});

  @override
  Widget build(BuildContext context) {
    final yp = yearProgress;
    final accent = theme.accent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'YEAR ${yp.year}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ProgressDial(
          progress: yp.fraction,
          size: 280,
          startColor: accent.color,
          endColor: accent.gradientPartner,
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: _PercentLabel(yp: yp),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            StatPill(value: '${yp.daysCompleted}', label: 'days completed'),
            const SizedBox(width: 14),
            StatPill(value: '${yp.daysRemaining}', label: 'days remaining'),
          ],
        ),
      ],
    );
  }
}

/// Just the number — nothing else. For people who want zero visual noise.
class _MinimalLayout extends StatelessWidget {
  final YearProgress yearProgress;
  final AppThemeState theme;

  const _MinimalLayout({required this.yearProgress, required this.theme});

  @override
  Widget build(BuildContext context) {
    final yp = yearProgress;
    final accent = theme.accent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [accent.color, accent.gradientPartner],
          ).createShader(bounds),
          child: Text(
            '${yp.percentComplete.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white, fontSize: 96, fontWeight: FontWeight.w800, height: 1),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'of ${yp.year} completed',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
        ),
      ],
    );
  }
}

class _PercentLabel extends StatelessWidget {
  final YearProgress yp;
  final double fontSize;

  const _PercentLabel({required this.yp, this.fontSize = 48});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: yp.percentComplete.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              TextSpan(
                text: '%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize * 0.46,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'of year completed',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  final YearProgress yp;

  const _StatGrid({required this.yp});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatCard(
          icon: Icons.calendar_today_outlined,
          label: 'MONTH',
          value: '${yp.currentMonth}',
          suffix: 'of 12',
        ),
        const SizedBox(width: 12),
        StatCard(
          icon: Icons.calendar_view_week_outlined,
          label: 'WEEK',
          value: '${yp.currentWeek}',
          suffix: 'of ${yp.totalWeeksInYear}',
        ),
        const SizedBox(width: 12),
        StatCard(
          icon: Icons.my_location_outlined,
          label: 'DAY',
          value: '${yp.currentDayOfYear}',
          suffix: 'of ${yp.totalDaysInYear}',
        ),
        const SizedBox(width: 12),
        StatCard(
          icon: Icons.access_time_rounded,
          label: 'HOUR',
          value: '${yp.hoursCompleted}',
          suffix: 'of ${yp.totalHoursInYear}',
        ),
      ],
    );
  }
}