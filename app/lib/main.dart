import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/app_tab.dart';
import 'core/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/support/support_screen.dart';
import 'features/themes_gallery/themes_screen.dart';
import 'features/widgets_gallery/widgets_screen.dart';
import 'widgets/app_sidebar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: Size(900, 600),
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
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
      home: const AppShell(),
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
          GestureDetector(
            onPanStart: (_) => windowManager.startDragging(),
            child: Container(height: 8, color: Colors.transparent),
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
