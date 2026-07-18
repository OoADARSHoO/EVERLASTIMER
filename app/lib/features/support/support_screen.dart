import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../core/support_config.dart';
import '../../widgets/progress_ring.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(supportConfigProvider);
    final accent = ref.watch(appThemeProvider).accent;
    final now = DateTime.now();
    final monthLabel = _monthLabel(now);

    return SafeArea(
      child: configAsync.when(
        data: (config) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Support',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Help keep Everlastimer running and improving.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.invalidate(supportConfigProvider),
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white60),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _AppCostsCard(config: config, monthLabel: monthLabel, accent: accent),
              const SizedBox(height: 16),
              _DonateCard(donateUrl: config.donateUrl, accent: accent),
              const SizedBox(height: 16),
              _BreakdownCard(config: config, accent: accent),
              const SizedBox(height: 20),

              Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Thanks to everyone who supports Everlastimer. You\'re part of the journey. '),
                      const TextSpan(text: '💜'),
                    ],
                  ),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accent.color),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading support data: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(supportConfigProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent.color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _monthLabel(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _AppCostsCard extends StatelessWidget {
  final SupportConfig config;
  final String monthLabel;
  final AccentColor accent;

  const _AppCostsCard({required this.config, required this.monthLabel, required this.accent});

  @override
  Widget build(BuildContext context) {
    final percent = (config.spentFraction * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF15131F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF26223A)),
      ),
      child: Stack(
        children: [
          // Subtle glow backdrop, contained to this card.
          Positioned(
            right: -40,
            top: -40,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.color.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'App costs for this month',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF332E4A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white60),
                        const SizedBox(width: 8),
                        Text(monthLabel, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: ProgressRing(
                      progress: config.spentFraction,
                      size: 160,
                      strokeWidth: 10,
                      startColor: accent.color,
                      endColor: accent.gradientPartner,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percent%',
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'of monthly budget',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  _figure('Spent', '\$${config.totalSpent.toStringAsFixed(2)}', 'of \$${config.monthlyBudget.toStringAsFixed(2)}'),
                  Container(width: 1, height: 48, color: const Color(0xFF26223A), margin: const EdgeInsets.symmetric(horizontal: 32)),
                  _figure('Remaining', '\$${config.remaining.toStringAsFixed(2)}', 'for ${config.daysRemainingInBillingCycle} days'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _figure(String label, String value, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
      ],
    );
  }
}

class _DonateCard extends StatelessWidget {
  final String donateUrl;
  final AccentColor accent;

  const _DonateCard({required this.donateUrl, required this.accent});

  Future<void> _openDonateUrl(BuildContext context) async {
    final uri = Uri.parse(donateUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the donation link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
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
              border: Border.all(color: accent.color.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(color: accent.color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: Icon(Icons.favorite, color: accent.gradientPartner, size: 24),
          ),
          const SizedBox(height: 20),
          const Text(
            'Enjoying Everlastimer?',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Your support helps keep the app online,\nimprove features and build the future.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _openDonateUrl(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Donate Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(width: 8),
                Icon(Icons.favorite, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 12, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(
                'One-time support  •  Cancel anytime',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final SupportConfig config;
  final AccentColor accent;

  const _BreakdownCard({required this.config, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF15131F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF26223A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where your support goes',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Wrap to multiple rows on narrower windows instead of
              // squeezing 5 cards into too little width.
              const minCardWidth = 180.0;
              final perRow = (constraints.maxWidth / minCardWidth).floor().clamp(1, config.categories.length);
              final spacing = 12.0;
              final cardWidth = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final category in config.categories)
                    SizedBox(
                      width: cardWidth,
                      child: _CategoryTile(category: category, config: config, accent: accent),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CostCategory category;
  final SupportConfig config;
  final AccentColor accent;

  const _CategoryTile({required this.category, required this.config, required this.accent});

  @override
  Widget build(BuildContext context) {
    final fraction = config.fractionOfBudget(category);
    final percentLabel = '${(fraction * 100).round()}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1726),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF26223A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 16, color: Colors.white.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.label,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${category.amount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                percentLabel,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: const Color(0xFF2A2640),
              valueColor: AlwaysStoppedAnimation(accent.color),
            ),
          ),
        ],
      ),
    );
  }
}