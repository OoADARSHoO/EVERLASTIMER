import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';

class ThemesScreen extends ConsumerWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final notifier = ref.read(appThemeProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Themes',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pick a preset, or build your own from scratch',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateThemeDialog(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create Theme'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            const Text('Presets', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            _PresetGrid(theme: theme, notifier: notifier),

            if (theme.customThemes.isNotEmpty) ...[
              const SizedBox(height: 28),
              const Text('Your Themes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              _CustomThemeGrid(theme: theme, notifier: notifier),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const _CreateThemeDialog(),
    );
  }
}

class _PresetGrid extends StatelessWidget {
  final AppThemeState theme;
  final AppThemeNotifier notifier;

  const _PresetGrid({required this.theme, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const minTileWidth = 200.0;
        const spacing = 14.0;
        final perRow = (constraints.maxWidth / minTileWidth).floor().clamp(1, ThemePreset.values.length);
        final tileWidth = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final preset in ThemePreset.values)
              SizedBox(
                width: tileWidth,
                child: _PresetCard(
                  preset: preset,
                  accent: theme.accent.color,
                  selected: theme.activeCustomThemeId == null && theme.preset == preset,
                  onTap: () => notifier.setPreset(preset),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PresetCard extends StatelessWidget {
  final ThemePreset preset;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _PresetCard({required this.preset, required this.accent, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.15,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? accent : const Color(0xFF26223A), width: selected ? 2 : 1),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: preset.previewGradient,
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Text(
                preset.label,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (selected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomThemeGrid extends StatelessWidget {
  final AppThemeState theme;
  final AppThemeNotifier notifier;

  const _CustomThemeGrid({required this.theme, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const minTileWidth = 200.0;
        const spacing = 14.0;
        final perRow = (constraints.maxWidth / minTileWidth).floor().clamp(1, theme.customThemes.length);
        final tileWidth = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final custom in theme.customThemes)
              SizedBox(
                width: tileWidth,
                child: _CustomThemeCard(
                  custom: custom,
                  selected: theme.activeCustomThemeId == custom.id,
                  onTap: () => notifier.activateCustomTheme(custom.id),
                  onDelete: () => notifier.deleteCustomTheme(custom.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CustomThemeCard extends StatelessWidget {
  final CustomTheme custom;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CustomThemeCard({
    required this.custom,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.15,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? custom.accent.color : const Color(0xFF26223A),
                  width: selected ? 2 : 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: custom.previewGradient,
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Text(
                custom.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  if (selected)
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: custom.accent.color),
                      child: const Icon(Icons.check, size: 14, color: Colors.white),
                    ),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.4)),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateThemeDialog extends ConsumerStatefulWidget {
  const _CreateThemeDialog();

  @override
  ConsumerState<_CreateThemeDialog> createState() => _CreateThemeDialogState();
}

class _CreateThemeDialogState extends ConsumerState<_CreateThemeDialog> {
  final _nameController = TextEditingController();
  Color _background = const Color(0xFF0B0A12);
  AccentColor _accent = AccentColor.violet;

  static const _backgroundOptions = [
    Color(0xFF0B0A12),
    Color(0xFF120E1F),
    Color(0xFF0E0B1A),
    Color(0xFF11151C),
    Color(0xFF0A0A0A),
    Color(0xFF1A0F1F),
    Color(0xFF0F1A14),
    Color(0xFF1A1A0F),
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF15131F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Theme',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),

            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Theme name',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: const Color(0xFF1A1726),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),

            const Text('Background', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in _backgroundOptions)
                  GestureDetector(
                    onTap: () => setState(() => _background = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _background == color ? Colors.white : const Color(0xFF332E4A),
                          width: _background == color ? 2 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            const Text('Accent', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final accent in AccentColor.values)
                  GestureDetector(
                    onTap: () => setState(() => _accent = accent),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accent.color,
                        shape: BoxShape.circle,
                        border: _accent == accent ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: _accent == accent ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _canSave ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent.color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF332E4A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Save Theme'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  void _save() {
    ref.read(appThemeProvider.notifier).addCustomTheme(
          name: _nameController.text.trim(),
          background: _background,
          accent: _accent,
        );
    Navigator.of(context).pop();
  }
}