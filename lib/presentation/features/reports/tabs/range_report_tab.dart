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

class RangeReportTab extends ConsumerWidget {
  const RangeReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(selectedRangeProvider);
    final reportAsyncOrNull = ref.watch(rangeReportProvider);
    final p = AppSpacing.pagePadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Date range picker button ────────────────────────────
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range_rounded),
            label: Text(
              range == null
                  ? AppStrings.selectDateRange
                  : '${AppDateUtils.formatShort(range.start)}  →  ${AppDateUtils.formatShort(range.end)}',
              style: TextStyle(
                fontSize: AppTypeScale.bodyText(context),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                initialDateRange: range,
                locale: const Locale('id', 'ID'),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: Theme.of(ctx)
                        .colorScheme
                        .copyWith(primary: AppColors.primary),
                  ),
                  child: child!,
                ),
              );
              if (picked != null && context.mounted) {
                ref.read(selectedRangeProvider.notifier).state = picked;
              }
            },
          ),
          SizedBox(height: AppSpacing.sectionGap(context)),

          // ── Report content ───────────────────────────────────────
          if (reportAsyncOrNull == null)
            const EmptyStateWidget(
              icon: Icons.date_range_rounded,
              svgAsset: 'assets/images/empty_reports.svg',
              title: 'Pilih Rentang Tanggal',
              subtitle:
                  'Tap tombol di atas untuk memilih rentang tanggal laporan.',
            )
          else
            reportAsyncOrNull.when(
              loading: () => const SizedBox(
                height: 200,
                child: AppLoadingIndicator(),
              ),
              error: (e, _) => Center(
                child: Text(AppStrings.errorLoad,
                    style: const TextStyle(color: AppColors.expense)),
              ),
              data: (summary) {
                if (summary.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.receipt_long_rounded,
                    svgAsset: 'assets/images/empty_reports.svg',
                    title: AppStrings.noData,
                    subtitle: AppStrings.noDataDesc,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SummaryStatCards(summary: summary),
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
                );
              },
            ),
        ],
      ),
    );
  }
}
