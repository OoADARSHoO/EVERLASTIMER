import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The set of destinations in the left sidebar.
///
/// Only [home] and [support] have real screens right now — [widgets],
/// [themes], and [settings] are placeholders until those screens exist.
enum AppTab { home, widgets, themes, settings, support }

/// Holds whichever [AppTab] is currently selected. The sidebar writes to
/// this; the app shell reads it to decide which screen to show.
final selectedTabProvider = StateProvider<AppTab>((ref) => AppTab.home);