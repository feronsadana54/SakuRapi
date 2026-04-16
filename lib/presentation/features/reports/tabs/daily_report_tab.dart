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
import '../../../../presentation/widgets/transaction_tile.dart';
import '../../../../router/app_router.dart';
import 'package:go_router/go_router.dart';

class DailyReportTab extends ConsumerWidget {
  const DailyReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final reportAsync = ref.watch(dailyReportProvider);
    final p = AppSpacing.pagePadding(context);

    return Column(
      children: [
        // ── Date navigation ─────────────────────────────────────────
        _DayNavigator(
          day: selectedDay,
          onPrev: () => ref.read(selectedDayProvider.notifier).state =
              selectedDay.subtract(const Duration(days: 1)),
          onNext: () {
            final next = selectedDay.add(const Duration(days: 1));
            final today = AppDateUtils.dateOnly(DateTime.now());
            if (!next.isAfter(today)) {
              ref.read(selectedDayProvider.notifier).state = next;
            }
          },
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDay,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
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
              ref.read(selectedDayProvider.notifier).state =
                  AppDateUtils.dateOnly(picked);
            }
          },
          canGoNext: !selectedDay
              .isAtSameMomentAs(AppDateUtils.dateOnly(DateTime.now())),
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
                  icon: Icons.today_rounded,
                  svgAsset: 'assets/images/empty_reports.svg',
                  title: AppStrings.noData,
                  subtitle: AppStrings.noDataDesc,
                );
              }
              return SingleChildScrollView(
                padding: EdgeInsets.all(p),
                child: Column(
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
                      SizedBox(height: AppSpacing.sectionGap(context)),
                    ],
                    ReportSectionLabel(AppStrings.navTransactions),
                    const SizedBox(height: 8),
                    ...summary.transactions.map(
                      (tx) => TransactionTile(
                        transaction: tx,
                        onTap: () => context.push(
                          AppRoutes.transactionEdit,
                          extra: tx,
                        ),
                      ),
                    ),
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

class _DayNavigator extends StatelessWidget {
  final DateTime day;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTap;
  final bool canGoNext;

  const _DayNavigator({
    required this.day,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
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
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                children: [
                  Text(
                    AppDateUtils.relativeLabel(day),
                    style: TextStyle(
                      fontSize: AppTypeScale.bodyText(context),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    AppDateUtils.formatFull(day),
                    style: TextStyle(
                      fontSize: AppTypeScale.caption(context),
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
