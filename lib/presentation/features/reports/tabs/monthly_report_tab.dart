import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/responsive/app_spacing.dart';
import '../../../../core/responsive/app_type_scale.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../presentation/providers/report_provider.dart';
import '../../../../presentation/widgets/report_widgets.dart';

class MonthlyReportTab extends ConsumerWidget {
  const MonthlyReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final reportAsync = ref.watch(monthlyReportProvider);
    final p = AppSpacing.pagePadding(context);

    // Build daily expense/income buckets for the chart
    final int daysInMonth =
        AppDateUtils.lastDayOfMonth(selectedMonth).day;

    return Column(
      children: [
        // ── Month navigator ─────────────────────────────────────────
        _MonthNavigator(
          month: selectedMonth,
          onPrev: () {
            final prev = DateTime(
                selectedMonth.year, selectedMonth.month - 1, 1);
            ref.read(selectedMonthProvider.notifier).state = prev;
          },
          onNext: () {
            final now = DateTime.now();
            final next = DateTime(
                selectedMonth.year, selectedMonth.month + 1, 1);
            if (!next.isAfter(DateTime(now.year, now.month, 1))) {
              ref.read(selectedMonthProvider.notifier).state = next;
            }
          },
          canGoNext: () {
            final now = DateTime.now();
            final next = DateTime(
                selectedMonth.year, selectedMonth.month + 1, 1);
            return !next.isAfter(DateTime(now.year, now.month, 1));
          }(),
        ),
        // ── Content ─────────────────────────────────────────────────
        Expanded(
          child: reportAsync.when(
            loading: () => const AppLoadingIndicator(),
            error: (e, _) => Center(
              child: Text(AppStrings.errorLoad,
                  style: const TextStyle(color: AppColors.expense)),
            ),
            data: (summary) {
              if (summary.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.calendar_month_rounded,
                  svgAsset: 'assets/images/empty_reports.svg',
                  title: AppStrings.noData,
                  subtitle: AppStrings.noDataDesc,
                );
              }

              // Build per-day buckets
              final expensePerDay = <int, double>{};
              final incomePerDay = <int, double>{};
              for (final tx in summary.transactions) {
                final d = tx.date.day;
                if (tx.isExpense) {
                  expensePerDay[d] = (expensePerDay[d] ?? 0) + tx.amount;
                } else {
                  incomePerDay[d] = (incomePerDay[d] ?? 0) + tx.amount;
                }
              }

              final buckets = List.generate(daysInMonth, (i) {
                final day = i + 1;
                return (
                  label: '$day',
                  expense: expensePerDay[day] ?? 0.0,
                  income: incomePerDay[day] ?? 0.0,
                );
              });

              return SingleChildScrollView(
                padding: EdgeInsets.all(p),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SummaryStatCards(summary: summary),
                    SizedBox(height: AppSpacing.sectionGap(context)),
                    ReportSectionLabel('Pengeluaran per Hari'),
                    const SizedBox(height: 12),
                    PeriodBarChart(buckets: buckets),
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoNext;

  const _MonthNavigator({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrev,
            color: AppColors.primary,
          ),
          Expanded(
            child: Text(
              AppDateUtils.formatMonth(month),
              style: TextStyle(
                fontSize: AppTypeScale.bodyText(context),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: canGoNext ? onNext : null,
            color: canGoNext ? AppColors.primary : AppColors.divider,
          ),
        ],
      ),
    );
  }
}
