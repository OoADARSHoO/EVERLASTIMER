import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_theme.dart';
import '../../../core/floating_widget_service.dart';

class GeneralTab extends ConsumerStatefulWidget {
  const GeneralTab({super.key});

  @override
  ConsumerState<GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends ConsumerState<GeneralTab> {
  bool _startupEnabled = false;
  bool _checkingStartup = true;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _refreshStartupState();
  }

  Future<void> _refreshStartupState() async {
    final service = ref.read(floatingWidgetServiceProvider);
    final enabled = await service.isStartupEnabled();
    if (!mounted) return;
    setState(() {
      _startupEnabled = enabled;
      _checkingStartup = false;
    });
  }

  Future<void> _handleLaunchNow() async {
    final service = ref.read(floatingWidgetServiceProvider);
    final result = await service.launchNow();
    if (!mounted) return;
    setState(() {
      _statusMessage = result == FloatingWidgetResult.success
          ? null
          : _messageFor(result, action: 'launch');
    });
  }

  Future<void> _handleStartupToggle(bool value) async {
    final service = ref.read(floatingWidgetServiceProvider);
    setState(() => _checkingStartup = true);
    final result = await service.setStartupEnabled(value);
    if (!mounted) return;
    setState(() {
      _checkingStartup = false;
      if (result == FloatingWidgetResult.success) {
        _startupEnabled = value;
        _statusMessage = null;
      } else {
        _statusMessage = _messageFor(result, action: 'update startup setting');
      }
    });
  }

  String _messageFor(FloatingWidgetResult result, {required String action}) {
    switch (result) {
      case FloatingWidgetResult.success:
        return '';
      case FloatingWidgetResult.unsupportedPlatform:
        return 'The floating widget is only available on Windows right now.';
      case FloatingWidgetResult.exeNotFound:
        return 'Couldn\'t find the widget app. Make sure EverlastimerWidget.exe is installed.';
      case FloatingWidgetResult.failed:
        return 'Couldn\'t $action. Try again, or launch the widget manually.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    final notifier = ref.read(appThemeProvider.notifier);
    final service = ref.read(floatingWidgetServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Theme ---
        _SectionCard(
          title: 'Theme',
          subtitle: 'Choose your preferred color theme',
          child: SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ThemePreset.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final preset = ThemePreset.values[i];
                return _ThemeTile(
                  preset: preset,
                  selected: theme.preset == preset,
                  accent: theme.accent.color,
                  onTap: () => notifier.setPreset(preset),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // --- Accent Color ---
        _SectionCard(
          title: 'Accent Color',
          subtitle: 'Choose an accent color',
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final accent in AccentColor.values)
                _AccentSwatch(
                  accent: accent,
                  selected: theme.accent == accent,
                  onTap: () => notifier.setAccent(accent),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- Transparency ---
        _SectionCard(
          title: 'Transparency',
          subtitle: 'Adjust the glass effect',
          trailing: Text(
            '${(theme.transparency * 100).round()}%',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: theme.accent.color,
                        inactiveTrackColor: const Color(0xFF26223A),
                        thumbColor: Colors.white,
                        overlayColor: theme.accent.color.withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: theme.transparency,
                        onChanged: notifier.setTransparency,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Less Glass', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                        Text('More Glass', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Live preview swatch of the resulting card opacity.
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1726).withValues(alpha: theme.cardOpacity),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF332E4A)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- Floating Widget ---
        _SectionCard(
          title: 'Floating Widget',
          icon: Icons.widgets_outlined,
          customSubtitle: Text(
            'A small always-on-top desktop widget showing your year progress. '
            'It runs as its own app — it keeps working even if Everlastimer is closed.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, height: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!service.isSupported) ...[
                _InfoBanner(text: 'The floating widget is only available on Windows right now.'),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: service.isSupported ? _handleLaunchNow : null,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Launch Widget Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent.color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF2A2640),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF26223A), height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Launch at Windows startup',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Widget appears automatically when you sign in to Windows.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _checkingStartup
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: theme.accent.color),
                        )
                      : Switch(
                          value: _startupEnabled,
                          onChanged: service.isSupported ? _handleStartupToggle : null,
                          activeColor: theme.accent.color,
                        ),
                ],
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                _InfoBanner(text: _statusMessage!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final ThemePreset preset;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.preset,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? accent : const Color(0xFF26223A),
                        width: selected ? 2 : 1,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: preset.previewGradient,
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 8,
                      right: 8,
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
            const SizedBox(height: 8),
            Text(
              preset.label,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final AccentColor accent;
  final bool selected;
  final VoidCallback onTap;

  const _AccentSwatch({required this.accent, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.color,
          border: selected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: selected
              ? [BoxShadow(color: accent.color.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 1)]
              : null,
        ),
        child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? customSubtitle;
  final Widget? trailing;
  final IconData? icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    this.customSubtitle,
    this.trailing,
    this.icon,
    required this.child,
  });

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFFC084FC), size: 20),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(left: icon != null ? 52 : 0),
              child: Text(subtitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
            ),
          ],
          if (customSubtitle != null) ...[
            const SizedBox(height: 8),
            customSubtitle!,
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;

  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2018),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4A3826)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFE0A458)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFFE0A458), fontSize: 12)),
          ),
        ],
      ),
    );
  }
}