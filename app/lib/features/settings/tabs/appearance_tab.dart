import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_theme.dart';

/// Display density for cards/spacing across the app. Not yet wired into
/// every screen — start here, then thread through HomeScreen/SupportScreen
/// padding values once you're happy with the options.
enum DisplayDensity { compact, comfortable, spacious }

final displayDensityProvider = StateProvider<DisplayDensity>((ref) => DisplayDensity.comfortable);

/// Ring stroke width preference for the progress ring, in pixels.
final ringThicknessProvider = StateProvider<double>((ref) => 14.0);

class AppearanceTab extends ConsumerWidget {
  const AppearanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final density = ref.watch(displayDensityProvider);
    final ringThickness = ref.watch(ringThicknessProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Display Density',
          subtitle: 'Adjust spacing between elements',
          child: Row(
            children: DisplayDensity.values.map((d) {
              final selected = density == d;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => ref.read(displayDensityProvider.notifier).state = d,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? theme.accent.color.withValues(alpha: 0.15) : const Color(0xFF1A1726),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? theme.accent.color : const Color(0xFF26223A)),
                      ),
                      child: Text(
                        _label(d),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white60,
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Progress Ring Thickness',
          subtitle: 'How thick the ring stroke appears',
          trailing: Text(
            '${ringThickness.round()}px',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.accent.color,
              inactiveTrackColor: const Color(0xFF26223A),
              thumbColor: Colors.white,
              overlayColor: theme.accent.color.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: ringThickness,
              min: 6,
              max: 24,
              onChanged: (v) => ref.read(ringThicknessProvider.notifier).state = v,
            ),
          ),
        ),
      ],
    );
  }

  String _label(DisplayDensity d) => switch (d) {
        DisplayDensity.compact => 'Compact',
        DisplayDensity.comfortable => 'Comfortable',
        DisplayDensity.spacious => 'Spacious',
      };
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({required this.title, this.subtitle, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF15131F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF26223A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}