import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One of the preset visual themes shown in the Theme picker.
///
/// Each preset currently maps to a background gradient/color used behind
/// cards — "Glass Purple" and "Arctic" lean on [isGlassy] to get a frosted
/// look once we add real blur surfaces; for now it's tracked so the UI
/// can react to it later without another migration.
enum ThemePreset { midnight, nebula, glassPurple, arctic, mono }

extension ThemePresetX on ThemePreset {
  String get label => switch (this) {
        ThemePreset.midnight => 'Midnight',
        ThemePreset.nebula => 'Nebula',
        ThemePreset.glassPurple => 'Glass Purple',
        ThemePreset.arctic => 'Arctic',
        ThemePreset.mono => 'Mono',
      };

  bool get isGlassy =>
      this == ThemePreset.glassPurple || this == ThemePreset.arctic;

  /// Background swatch gradient shown in the picker tile itself.
  List<Color> get previewGradient => switch (this) {
        ThemePreset.midnight => [const Color(0xFF1A1530), const Color(0xFF0B0A12)],
        ThemePreset.nebula => [const Color(0xFF4338CA), const Color(0xFF7C3AED)],
        ThemePreset.glassPurple => [const Color(0xFF8B5CF6), const Color(0xFF312E81)],
        ThemePreset.arctic => [const Color(0xFF94A3B8), const Color(0xFF475569)],
        ThemePreset.mono => [const Color(0xFF262626), const Color(0xFF0A0A0A)],
      };

  /// Base app background used behind every screen when this preset is
  /// active. Kept close to the original near-black so existing screens
  /// don't shift drastically — presets mostly differ by accent and glow.
  Color get backgroundColor => switch (this) {
        ThemePreset.midnight => const Color(0xFF0B0A12),
        ThemePreset.nebula => const Color(0xFF0E0B1A),
        ThemePreset.glassPurple => const Color(0xFF120E1F),
        ThemePreset.arctic => const Color(0xFF11151C),
        ThemePreset.mono => const Color(0xFF0A0A0A),
      };
}

/// One of the accent color swatches. The first (violet) is the app's
/// original default, matching what every screen was hardcoded to before
/// this provider existed.
enum AccentColor { violet, rose, coral, amber, gold, emerald, teal, blue, indigo }

extension AccentColorX on AccentColor {
  Color get color => switch (this) {
        AccentColor.violet => const Color(0xFF8B5CF6),
        AccentColor.rose => const Color(0xFFD6336C),
        AccentColor.coral => const Color(0xFFE5564B),
        AccentColor.amber => const Color(0xFFE8862E),
        AccentColor.gold => const Color(0xFFE0B832),
        AccentColor.emerald => const Color(0xFF3FAE6E),
        AccentColor.teal => const Color(0xFF2BAFAE),
        AccentColor.blue => const Color(0xFF4D7CF5),
        AccentColor.indigo => const Color(0xFF6C5CE0),
      };

  /// A lighter partner color, used as the second stop in gradient rings
  /// (mirrors how the original violet-to-magenta ring gradient worked).
  Color get gradientPartner => switch (this) {
        AccentColor.violet => const Color(0xFFE957FF),
        AccentColor.rose => const Color(0xFFFF7AA8),
        AccentColor.coral => const Color(0xFFFF9B7A),
        AccentColor.amber => const Color(0xFFFFB85C),
        AccentColor.gold => const Color(0xFFFFE08A),
        AccentColor.emerald => const Color(0xFF7BE3A8),
        AccentColor.teal => const Color(0xFF6EE6E0),
        AccentColor.blue => const Color(0xFF8FACFF),
        AccentColor.indigo => const Color(0xFFA89BFF),
      };
}

@immutable
class CustomTheme {
  final String id;
  final String name;
  final Color background;
  final AccentColor accent;

  const CustomTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.accent,
  });

  List<Color> get previewGradient => [
        Color.lerp(background, accent.color, 0.35) ?? background,
        background,
      ];
}

@immutable
class AppThemeState {
  final ThemePreset preset;
  final AccentColor accent;

  /// 0.0 (least glassy / most opaque cards) to 1.0 (most glassy / most
  /// transparent cards). Screenshot shows 42% as the example default.
  final double transparency;

  /// User-created themes from the Themes gallery page. Empty by default.
  /// Kept separate from [ThemePreset] (the 5 built-ins) since custom
  /// themes carry their own background + accent pairing rather than
  /// mapping onto the fixed enum.
  final List<CustomTheme> customThemes;

  /// If set, a custom theme is active instead of [preset]. Null means
  /// one of the built-in presets is active.
  final String? activeCustomThemeId;

  const AppThemeState({
    this.preset = ThemePreset.midnight,
    this.accent = AccentColor.violet,
    this.transparency = 0.42,
    this.customThemes = const [],
    this.activeCustomThemeId,
  });

  AppThemeState copyWith({
    ThemePreset? preset,
    AccentColor? accent,
    double? transparency,
    List<CustomTheme>? customThemes,
    String? activeCustomThemeId,
    bool clearActiveCustomTheme = false,
  }) {
    return AppThemeState(
      preset: preset ?? this.preset,
      accent: accent ?? this.accent,
      transparency: transparency ?? this.transparency,
      customThemes: customThemes ?? this.customThemes,
      activeCustomThemeId:
          clearActiveCustomTheme ? null : (activeCustomThemeId ?? this.activeCustomThemeId),
    );
  }

  /// The custom theme object currently active, if any.
  CustomTheme? get activeCustomTheme {
    if (activeCustomThemeId == null) return null;
    for (final t in customThemes) {
      if (t.id == activeCustomThemeId) return t;
    }
    return null;
  }

  /// Effective background color, accounting for an active custom theme.
  Color get backgroundColor => activeCustomTheme?.background ?? preset.backgroundColor;

  /// Card background opacity derived from transparency — higher
  /// transparency means lower opacity (more glass, more see-through).
  double get cardOpacity => 1.0 - (transparency * 0.6).clamp(0.0, 0.6);
}

class AppThemeNotifier extends Notifier<AppThemeState> {
  @override
  AppThemeState build() => const AppThemeState();

  void setPreset(ThemePreset preset) {
    state = state.copyWith(preset: preset, clearActiveCustomTheme: true);
  }

  void setAccent(AccentColor accent) {
    state = state.copyWith(accent: accent);
  }

  void setTransparency(double value) {
    state = state.copyWith(transparency: value.clamp(0.0, 1.0));
  }

  /// Creates a new custom theme and immediately activates it.
  void addCustomTheme({required String name, required Color background, required AccentColor accent}) {
    final theme = CustomTheme(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      background: background,
      accent: accent,
    );
    state = state.copyWith(
      customThemes: [...state.customThemes, theme],
      accent: accent,
      activeCustomThemeId: theme.id,
    );
  }

  void activateCustomTheme(String id) {
    CustomTheme? theme;
    for (final t in state.customThemes) {
      if (t.id == id) {
        theme = t;
        break;
      }
    }
    if (theme == null) return;
    state = state.copyWith(activeCustomThemeId: id, accent: theme.accent);
  }

  void deleteCustomTheme(String id) {
    final remaining = state.customThemes.where((t) => t.id != id).toList();
    final wasActive = state.activeCustomThemeId == id;
    state = state.copyWith(
      customThemes: remaining,
      clearActiveCustomTheme: wasActive,
    );
  }
}

final appThemeProvider = NotifierProvider<AppThemeNotifier, AppThemeState>(
  AppThemeNotifier.new,
);