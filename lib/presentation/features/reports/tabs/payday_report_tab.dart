import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/responsive/app_spacing.dart';
import '../../../../core/responsive/app_type_scale.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../presentation/providers/report_provider.dart';
import '../../../../presentation/widgets/report_widgets.dart';

class PaydayReportTab extends ConsumerWidget {
  const PaydayReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleAsync = ref.watch(paydayCycleReportProvider);
    final p = AppSpacing.pagePadding(context);

    return cycleAsync.when(
      loading: () => const AppLoadingIndicator(),
      error: (e, _) => Center(
        child: Text(AppStrings.errorLoad,
            style: const TextStyle(color: AppColors.expense)),
      ),
      data: (tuple) {
        final (summary, cycleStart, cycleEnd) = tuple;
        final totalDays =
            cycleEnd.difference(cycleStart).inDays + 1;
        final elapsed =
            AppDateUtils.dateOnly(DateTime.now())
                .difference(cycleStart)
                .inDays +
            1;
        final progress =
            (elapsed / totalDays).clamp(0.0, 1.0);

        return SingleChildScrollView(
          padding: EdgeInsets.all(p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cycle header ──────────────────────────────────────
              _CycleHeaderCard(
                cycleStart: cycleStart,
                cycleEnd: cycleEnd,
                elapsed: elapsed,
                totalDays: totalDays,
                progress: progress,
              ),
              SizedBox(height: AppSpacing.sectionGap(context)),

              if (summary.isEmpty)
                const EmptyStateWidget(
                  icon: Icons.account_balance_wallet_rounded,
                  svgAsset: 'assets/images/empty_reports.svg',
                  title: AppStrings.noData,
                  subtitle: AppStrings.noDataDesc,
                )
              else ...[
                SummaryStatCards(summary: summary),
                SizedBox(height: AppSpacing.sectionGap(context)),

                // ── Daily burn rate ────────────────────────────────
                if (summary.totalExpense > 0)
                  _BurnRateCard(
                    totalExpense: summary.totalExpense,
                    elapsedDays: elapsed,
                    remainingDays: totalDays - elapsed,
                  ),
                SizedBox(height: AppSpacing.sectionGap(context)),

                if (summary.expenseByCategory.isNotEmpty) ...[
                  CategoryBreakdownSection(
                    byCategory: summary.expenseByCategory,
                    total: summary.totalExpense,
                    barColor: AppColors.expense,
                    title: AppStrings.expense,
                  ),
                  SizedBox(height: AppSpacing.sectionGap(context)),
                ],
                if (summary.incomeByCategory.isNotEmpty) ...[
                  CategoryBreakdownSection(
                    byCategory: summary.incomeByCategory,
                    total: summary.totalIncome,
                    barColor: AppColors.income,
                    title: AppStrings.income,
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CycleHeaderCard extends StatelessWidget {
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final int elapsed;
  final int totalDays;
  final double progress;

  const _CycleHeaderCard({
    required this.cycleStart,
    required this.cycleEnd,
    required this.elapsed,
    required this.totalDays,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.currentCycle,
            style: TextStyle(
              fontSize: AppTypeScale.caption(context),
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppDateUtils.formatShort(cycleStart)}  –  ${AppDateUtils.formatShort(cycleEnd)}',
            style: TextStyle(
              fontSize: AppTypeScale.bodyText(context),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hari ke-$elapsed dari $totalDays hari',
            style: TextStyle(
              fontSize: AppTypeScale.caption(context),
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _BurnRateCard extends StatelessWidget {
  final double totalExpense;
  final int elapsedDays;
  final int remainingDays;

  const _BurnRateCard({
    required this.totalExpense,
    required this.elapsedDays,
    required this.remainingDays,
  });

  @override
  Widget build(BuildContext context) {
    final dailyAvg = elapsedDays > 0 ? totalExpense / elapsedDays : 0.0;
    final projected = dailyAvg * (elapsedDays + remainingDays);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimasi Pengeluaran',
            style: TextStyle(
              fontSize: AppTypeScale.sectionTitle(context),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _Row(
            label: 'Rata-rata per hari',
            value: CurrencyFormatter.compact(dailyAvg),
          ),
          _Row(
            label: 'Proyeksi akhir siklus',
            value: CurrencyFormatter.compact(projected),
            valueColor: projected > totalExpense
                ? AppColors.expense
                : AppColors.income,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: AppTypeScale.bodyText(context),
                color: AppColors.textSecondary,
              )),
          Text(value,
              style: TextStyle(
                fontSize: AppTypeScale.bodyText(context),
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}
