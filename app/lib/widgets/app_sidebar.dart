import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_tab.dart';
import '../core/app_theme.dart';

final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  static const _items = [
    (tab: AppTab.home, icon: Icons.home_rounded, label: 'Home'),
    (tab: AppTab.widgets, icon: Icons.widgets_outlined, label: 'Widgets'),
    (tab: AppTab.themes, icon: Icons.palette_outlined, label: 'Themes'),
    (tab: AppTab.settings, icon: Icons.settings_outlined, label: 'Settings'),
    (tab: AppTab.support, icon: Icons.favorite_border_rounded, label: 'Support'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    final selectedTab = ref.watch(selectedTabProvider);
    final accent = ref.watch(appThemeProvider).accent.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.fastOutSlowIn,
      clipBehavior: Clip.hardEdge,
      width: isCollapsed ? 72 : 220,
      color: const Color(0xFF0B0A12),
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 12 : 16,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in _items) ...[
            _NavTile(
              icon: item.icon,
              label: item.label,
              selected: selectedTab == item.tab,
              accent: accent,
              isCollapsed: isCollapsed,
              onTap: () => ref.read(selectedTabProvider.notifier).state = item.tab,
            ),
            const SizedBox(height: 6),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 0 : 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF211D33) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected ? Border.all(color: accent.withValues(alpha: 0.4)) : null,
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? accent : Colors.white60,
              ),
              Flexible(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  alignment: Alignment.centerLeft,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: isCollapsed ? 0.0 : 1.0,
                    curve: Curves.easeInOut,
                    child: SizedBox(
                      width: isCollapsed ? 0 : 120,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: TextStyle(
                                    color: selected ? Colors.white : Colors.white60,
                                    fontSize: 14,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

