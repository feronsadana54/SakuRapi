import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/responsive/app_spacing.dart';
import '../../core/responsive/app_type_scale.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/summary_result.dart';

// ── Summary stat cards row ────────────────────────────────────────────────────

class SummaryStatCards extends StatelessWidget {
  final SummaryResult summary;

  const SummaryStatCards({required this.summary, super.key});

  @override
  Widget build(BuildContext context) {
    final gap = AppSpacing.cardGap(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: AppStrings.totalIncome,
                amount: summary.totalIncome,
                icon: Icons.arrow_downward_rounded,
                color: AppColors.income,
                bgColor: AppColors.incomeLight,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _StatCard(
                label: AppStrings.totalExpense,
                amount: summary.totalExpense,
                icon: Icons.arrow_upward_rounded,
                color: AppColors.expense,
                bgColor: AppColors.expenseLight,
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        _NetBalanceCard(balance: summary.balance),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypeScale.caption(context),
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  CurrencyFormatter.compact(amount),
                  style: TextStyle(
                    fontSize: AppTypeScale.bodyText(context),
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NetBalanceCard extends StatelessWidget {
  final double balance;
  const _NetBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final color = isPositive ? AppColors.income : AppColors.expense;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.incomeLight : AppColors.expenseLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.netBalance,
            style: TextStyle(
              fontSize: AppTypeScale.bodyText(context),
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${CurrencyFormatter.full(balance)}',
            style: TextStyle(
              fontSize: AppTypeScale.bodyText(context),
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category breakdown list ───────────────────────────────────────────────────

class CategoryBreakdownSection extends StatelessWidget {
  final Map<Category, double> byCategory;
  final double total;
  final Color barColor;
  final String title;

  const CategoryBreakdownSection({
    required this.byCategory,
    required this.total,
    required this.barColor,
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (byCategory.isEmpty) return const SizedBox.shrink();

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppTypeScale.sectionTitle(context),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...sorted.map((e) => _CategoryRow(
              category: e.key,
              amount: e.value,
              total: total,
              barColor: barColor,
            )),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  final double amount;
  final double total;
  final Color barColor;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.total,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(category.colorValue).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.fromCode(category.iconCode),
                  size: 16,
                  color: Color(category.colorValue),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: AppTypeScale.bodyText(context),
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.compact(amount),
                style: TextStyle(
                  fontSize: AppTypeScale.bodyText(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: AppTypeScale.caption(context),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surfaceVariant,
              color: barColor,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

/// A bar chart where each bar represents one period bucket.
/// [buckets] → list of (label, expense, income) in display order.
class PeriodBarChart extends StatelessWidget {
  final List<({String label, double expense, double income})> buckets;
  final bool showIncome;

  const PeriodBarChart({
    required this.buckets,
    this.showIncome = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) return const SizedBox.shrink();

    final maxY = buckets.fold<double>(
      0,
      (m, b) => [m, b.expense, if (showIncome) b.income].reduce(
        (a, v) => a > v ? a : v,
      ),
    );

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < buckets.length; i++) {
      final b = buckets[i];
      final rods = <BarChartRodData>[
        BarChartRodData(
          toY: b.expense,
          color: AppColors.expense,
          width: showIncome ? 5 : 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
        if (showIncome)
          BarChartRodData(
            toY: b.income,
            color: AppColors.income,
            width: 5,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(3)),
          ),
      ];
      groups.add(BarChartGroupData(
        x: i,
        barRods: rods,
        barsSpace: showIncome ? 2 : 0,
      ));
    }

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY > 0 ? maxY * 1.2 : 1,
          gridData: FlGridData(
            show: true,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: AppColors.divider,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, meta) {
                  if (v == 0 || v == meta.max) return const SizedBox.shrink();
                  return Text(
                    _abbreviate(v),
                    style: TextStyle(
                      fontSize: AppTypeScale.caption(context) - 1,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: _bottomInterval(buckets.length),
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= buckets.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      buckets[idx].label,
                      style: TextStyle(
                        fontSize: AppTypeScale.caption(context) - 2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: groups,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.textPrimary.withValues(alpha: 0.85),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  CurrencyFormatter.compact(rod.toY),
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Show every label when ≤7, every 5th when ≤31, every 3rd when ≤12.
  double _bottomInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 12) return 3;
    if (count <= 31) return 5;
    return (count / 6).ceilToDouble();
  }

  /// Abbreviates large numbers: 1.5jt, 500rb, etc.
  String _abbreviate(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class ReportSectionLabel extends StatelessWidget {
  final String label;
  const ReportSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: AppTypeScale.sectionTitle(context),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
