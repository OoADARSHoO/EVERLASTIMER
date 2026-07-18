import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/floating_widget_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
        return ''; // Callers only invoke this for non-success results.
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
    final service = ref.read(floatingWidgetServiceProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),

            Container(
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B2E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.widgets_outlined, color: Color(0xFFC084FC), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Floating Widget',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A small always-on-top desktop widget showing your year progress. '
                    'It runs as its own app — it keeps working even if Everlastimer is closed.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, height: 1.4),
                  ),
                  if (!service.isSupported) ...[
                    const SizedBox(height: 12),
                    _InfoBanner(text: 'The floating widget is only available on Windows right now.'),
                  ],
                  const SizedBox(height: 18),

                  // Launch now
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: service.isSupported ? _handleLaunchNow : null,
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Launch Widget Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF2A2640),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF26223A), height: 1),
                  const SizedBox(height: 16),

                  // Startup toggle
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
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)),
                            )
                          : Switch(
                              value: _startupEnabled,
                              onChanged: service.isSupported ? _handleStartupToggle : null,
                              activeColor: const Color(0xFF8B5CF6),
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
        ),
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