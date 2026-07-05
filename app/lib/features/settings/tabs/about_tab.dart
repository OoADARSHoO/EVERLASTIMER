import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_theme.dart';

class AboutTab extends ConsumerWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF15131F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF26223A)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [theme.accent.color, theme.accent.gradientPartner]),
                ),
                child: const Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 16),
              const Text(
                'Everlastimer',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                'Stay aware. Make it count.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _LinkTile(
          icon: Icons.groups_outlined,
          label: 'Join the Discord community',
          onTap: () => _open('https://example.com/discord'),
        ),
        const SizedBox(height: 10),
        _LinkTile(
          icon: Icons.bug_report_outlined,
          label: 'Report a bug',
          onTap: () => _open('https://example.com/bug-report'),
        ),
        const SizedBox(height: 10),
        _LinkTile(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          onTap: () => _open('https://example.com/privacy'),
        ),
      ],
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF15131F),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF26223A)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.white60),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}