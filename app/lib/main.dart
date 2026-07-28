import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'core/app_tab.dart';
import 'core/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/support/support_screen.dart';
import 'features/themes_gallery/themes_screen.dart';
import 'features/widgets_gallery/widgets_screen.dart';
import 'widgets/app_sidebar.dart' show AppSidebar, sidebarCollapsedProvider;
import 'widgets/update_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ujfbihyjvxaxbpvholee.supabase.co',
    publishableKey: 'sb_publishable_-RVAdYtvbCwP_qZWr0YbAg_CYVGg9Mm',
  );
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: Size(900, 600),
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setResizable(true);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: EverlastimerApp()));
}

class EverlastimerApp extends ConsumerWidget {
  const EverlastimerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = ref.watch(appThemeProvider).backgroundColor;

    return MaterialApp(
      title: 'Everlastimer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,
        fontFamily: 'Inter',
      ),
      home: const UpdateOverlay(child: AppShell()),
    );
  }
}

/// Hosts the persistent sidebar and swaps the main content area based on
/// [selectedTabProvider]. Screens that don't exist yet fall back to a
/// simple "coming soon" placeholder instead of crashing.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final backgroundColor = ref.watch(appThemeProvider).backgroundColor;
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    final Widget content = switch (selectedTab) {
      AppTab.home => const HomeScreen(),
      AppTab.support => const SupportScreen(),
      AppTab.settings => const SettingsScreen(),
      AppTab.widgets => const WidgetsScreen(),
      AppTab.themes => const ThemesScreen(),
    };

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Global title bar — single drag region across the full window
          // width. This avoids the dead zones that per-screen drag
          // GestureDetectors had (they were inset by SafeArea padding).
          GestureDetector(
            onPanStart: (_) => windowManager.startDragging(),
            behavior: HitTestBehavior.translucent,
            child: Container(
              height: 44,
              color: Colors.transparent,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => ref.read(sidebarCollapsedProvider.notifier).update((state) => !state),
                    icon: Icon(
                      isCollapsed ? Icons.menu : Icons.menu_open,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Everlastimer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => windowManager.minimize(),
                    icon: const Icon(Icons.minimize_rounded, color: Colors.white60, size: 18),
                  ),
                  IconButton(
                    onPressed: () => windowManager.close(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                const AppSidebar(),
                Expanded(child: content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
