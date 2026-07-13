import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A single line item in the "Where your support goes" breakdown.
class CostCategory {
  final String label;
  final double amount;
  final IconData icon;

  const CostCategory({
    required this.label,
    required this.amount,
    required this.icon,
  });
}

/// All the numbers that drive the Support screen.
///
/// This is the one place to edit when real cloud-provider bills replace
/// these placeholders — everything else (budget ring, "remaining" copy,
/// category percentages and bar widths) is derived from this, so nothing
/// can drift out of sync.
class SupportConfig {
  final double monthlyBudget;
  final List<CostCategory> categories;
  final int daysRemainingInBillingCycle;
  final String donateUrl;

  const SupportConfig({
    required this.monthlyBudget,
    required this.categories,
    required this.daysRemainingInBillingCycle,
    required this.donateUrl,
  });

  double get totalSpent =>
      categories.fold(0.0, (sum, c) => sum + c.amount);

  double get remaining => (monthlyBudget - totalSpent).clamp(0, monthlyBudget);

  double get spentFraction =>
      monthlyBudget <= 0 ? 0 : (totalSpent / monthlyBudget).clamp(0.0, 1.0);

  /// Each category's share of the *budget* (not of total spent) — matches
  /// how the original design shows percentages against the $60 budget.
  double fractionOfBudget(CostCategory c) =>
      monthlyBudget <= 0 ? 0 : (c.amount / monthlyBudget).clamp(0.0, 1.0);
}

/// Dynamic support configurations loaded from Supabase database.
final supportConfigProvider = FutureProvider<SupportConfig>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('support_stats')
        .select()
        .limit(1)
        .maybeSingle();

    if (response == null) {
      throw Exception('No support statistics rows found in Supabase.');
    }

    final budget = (response['budget'] as num?)?.toDouble() ?? 60.00;
    final hosting = (response['hosting'] as num?)?.toDouble() ?? 0.00;
    final database = (response['database'] as num?)?.toDouble() ?? 0.00;
    final cdn = (response['cdn'] as num?)?.toDouble() ?? 0.00;
    final apis = (response['apis'] as num?)?.toDouble() ?? 0.00;
    final other = (response['other'] as num?)?.toDouble() ?? 0.00;

    // Calculate days remaining in the current month dynamically.
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = lastDay - now.day;

    return SupportConfig(
      monthlyBudget: budget,
      daysRemainingInBillingCycle: daysRemaining,
      donateUrl: 'https://example.com/donate', // TODO: replace with real link
      categories: [
        CostCategory(label: 'Cloud Hosting', amount: hosting, icon: Icons.cloud_outlined),
        CostCategory(label: 'Database', amount: database, icon: Icons.shield_outlined),
        CostCategory(label: 'CDN & Bandwidth', amount: cdn, icon: Icons.bolt_outlined),
        CostCategory(label: 'Services & APIs', amount: apis, icon: Icons.code_rounded),
        CostCategory(label: 'Other', amount: other, icon: Icons.pie_chart_outline),
      ],
    );
  } catch (e) {
    debugPrint('Supabase query failed: $e. Falling back to default placeholders.');
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = lastDay - now.day;
    return SupportConfig(
      monthlyBudget: 60.00,
      daysRemainingInBillingCycle: daysRemaining,
      donateUrl: 'https://example.com/donate',
      categories: const [
        CostCategory(label: 'Cloud Hosting', amount: 18.20, icon: Icons.cloud_outlined),
        CostCategory(label: 'Database', amount: 9.14, icon: Icons.shield_outlined),
        CostCategory(label: 'CDN & Bandwidth', amount: 7.68, icon: Icons.bolt_outlined),
        CostCategory(label: 'Services & APIs', amount: 7.33, icon: Icons.code_rounded),
        CostCategory(label: 'Other', amount: 0.00, icon: Icons.pie_chart_outline),
      ],
    );
  }
});