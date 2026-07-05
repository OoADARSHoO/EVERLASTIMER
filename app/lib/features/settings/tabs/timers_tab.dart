import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_theme.dart';

enum WeekStart { sunday, monday }

final weekStartProvider = StateProvider<WeekStart>((ref) => WeekStart.monday);

class TimersTab extends ConsumerWidget {
  const TimersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final weekStart = ref.watch(weekStartProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Week Starts On',
          subtitle: 'Affects week-number calculations on the Home screen',
          child: Row(
            children: [
              Expanded(
                child: _ChoiceChip(
                  label: 'Sunday',
                  selected: weekStart == WeekStart.sunday,
                  accent: theme.accent.color,
                  onTap: () => ref.read(weekStartProvider.notifier).state = WeekStart.sunday,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChoiceChip(
                  label: 'Monday',
                  selected: weekStart == WeekStart.monday,
                  accent: theme.accent.color,
                  onTap: () => ref.read(weekStartProvider.notifier).state = WeekStart.monday,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Update Frequency',
          subtitle: 'How often the year-progress ring refreshes',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1726),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF26223A)),
            ),
            child: Row(
              children: [
                Icon(Icons.refresh_rounded, size: 18, color: theme.accent.color),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Every minute — enough resolution for year-scale progress without unnecessary redraws.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _ChoiceChip({required this.label, required this.selected, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.15) : const Color(0xFF1A1726),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? accent : const Color(0xFF26223A)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({required this.title, this.subtitle, required this.child});

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
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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