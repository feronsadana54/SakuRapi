import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/responsive/app_spacing.dart';
import '../../../../core/responsive/app_type_scale.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../presentation/providers/report_provider.dart';
import '../../../../presentation/widgets/report_widgets.dart';

class YearlyReportTab extends ConsumerWidget {
  const YearlyReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYear = ref.watch(selectedYearProvider);
    final reportAsync = ref.watch(yearlyReportProvider);
    final p = AppSpacing.pagePadding(context);
    final currentYear = DateTime.now().year;

    return Column(
      children: [
        // ── Year navigator ──────────────────────────────────────────
        _YearNavigator(
          year: selectedYear,
          onPrev: () => ref.read(selectedYearProvider.notifier).state =
              selectedYear - 1,
          onNext: () {
            if (selectedYear < currentYear) {
              ref.read(selectedYearProvider.notifier).state =
                  selectedYear + 1;
            }
          },
          canGoNext: selectedYear < currentYear,
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
                  icon: Icons.bar_chart_rounded,
                  svgAsset: 'assets/images/empty_reports.svg',
                  title: AppStrings.noData,
                  subtitle: AppStrings.noDataDesc,
                );
              }

              // Build per-month buckets
              final expensePerMonth = <int, double>{};
              final incomePerMonth = <int, double>{};
              for (final tx in summary.transactions) {
                final m = tx.date.month;
                if (tx.isExpense) {
                  expensePerMonth[m] =
                      (expensePerMonth[m] ?? 0) + tx.amount;
                } else {
                  incomePerMonth[m] =
                      (incomePerMonth[m] ?? 0) + tx.amount;
                }
              }

              final monthAbbr = DateFormat('MMM', 'id_ID');
              final buckets = List.generate(12, (i) {
                final month = i + 1;
                final d = DateTime(selectedYear, month, 1);
                return (
                  label: monthAbbr.format(d),
                  expense: expensePerMonth[month] ?? 0.0,
                  income: incomePerMonth[month] ?? 0.0,
                );
              });

              return SingleChildScrollView(
                padding: EdgeInsets.all(p),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SummaryStatCards(summary: summary),
                    SizedBox(height: AppSpacing.sectionGap(context)),
                    ReportSectionLabel('Pengeluaran & Pemasukan per Bulan'),
                    const SizedBox(height: 12),
                    PeriodBarChart(
                      buckets: buckets,
                      showIncome: true,
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _YearNavigator extends StatelessWidget {
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoNext;

  const _YearNavigator({
    required this.year,
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
              '$year',
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
