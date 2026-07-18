import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/home_widget_style.dart';
import '../../core/year_progress.dart';
import '../../core/year_progress_provider.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/progress_dial.dart';
import '../../widgets/progress_ring.dart';

class WidgetsScreen extends ConsumerWidget {
  const WidgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(yearProgressProvider);
    final theme = ref.watch(appThemeProvider);
    final selected = ref.watch(homeWidgetStyleProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Widgets',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how your year progress is displayed on the Home screen',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 24),

            progressAsync.when(
              data: (yp) => _StyleGrid(
                yearProgress: yp,
                theme: theme,
                selected: selected,
                onSelect: (style) => ref.read(homeWidgetStyleProvider.notifier).state = style,
              ),
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(color: theme.accent.color),
                ),
              ),
              error: (err, _) => Text(
                'Couldn\'t load preview data: $err',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleGrid extends StatelessWidget {
  final YearProgress yearProgress;
  final AppThemeState theme;
  final HomeWidgetStyle selected;
  final ValueChanged<HomeWidgetStyle> onSelect;

  const _StyleGrid({
    required this.yearProgress,
    required this.theme,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const minTileWidth = 280.0;
        const spacing = 16.0;
        final perRow = (constraints.maxWidth / minTileWidth).floor().clamp(1, HomeWidgetStyle.values.length);
        final tileWidth = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
              for (final style in HomeWidgetStyle.values)
                SizedBox(
                  width: tileWidth,
                  child: _StyleTile(
                    style: style,
                    yearProgress: yearProgress,
                    theme: theme,
                    selected: selected == style,
                    available: style == HomeWidgetStyle.ring,
                    onTap: () => onSelect(style),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _StyleTile extends StatelessWidget {
  final HomeWidgetStyle style;
  final YearProgress yearProgress;
  final AppThemeState theme;
  final bool selected;
  final bool available;
  final VoidCallback onTap;

  const _StyleTile({
    required this.style,
    required this.yearProgress,
    required this.theme,
    required this.selected,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = theme.accent;

    return GestureDetector(
      onTap: available ? onTap : null,
      child: Stack(
        children: [
          Opacity(
            opacity: available ? 1.0 : 0.35,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF15131F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? accent.color : const Color(0xFF26223A),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  // Live mini preview
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: _previewFor(style, accent),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFF26223A))),
                    ),
                    child: Row(
                      children: [
                        Icon(style.icon, size: 16, color: selected ? accent.color : Colors.white60),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                              Text(
                                style.description,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: accent.color),
                            child: const Icon(Icons.check, size: 14, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!available)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _previewFor(HomeWidgetStyle style, AccentColor accent) {
    final yp = yearProgress;

    switch (style) {
      case HomeWidgetStyle.ring:
        return ProgressRing(
          progress: yp.fraction,
          size: 150,
          strokeWidth: 9,
          startColor: accent.color,
          endColor: accent.gradientPartner,
          child: Text(
            '${yp.percentComplete.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
        );
      case HomeWidgetStyle.bar:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${yp.percentComplete.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ProgressBar(
              progress: yp.fraction,
              height: 12,
              startColor: accent.color,
              endColor: accent.gradientPartner,
            ),
          ],
        );
      case HomeWidgetStyle.dial:
        return ProgressDial(
          progress: yp.fraction,
          size: 150,
          startColor: accent.color,
          endColor: accent.gradientPartner,
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              '${yp.percentComplete.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        );
      case HomeWidgetStyle.minimal:
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [accent.color, accent.gradientPartner],
          ).createShader(bounds),
          child: Text(
            '${yp.percentComplete.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
          ),
        );
    }
  }
}