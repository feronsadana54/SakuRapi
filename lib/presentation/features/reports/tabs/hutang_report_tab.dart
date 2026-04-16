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
import '../../../../domain/entities/hutang_entity.dart';
import '../../../../presentation/providers/hutang_provider.dart';

class HutangReportTab extends ConsumerWidget {
  const HutangReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hutangAsync = ref.watch(hutangListProvider);
    final summaryAsync = ref.watch(hutangSummaryProvider);
    final p = AppSpacing.pagePadding(context);

    return hutangAsync.when(
      loading: () => const AppLoadingIndicator(),
      error: (e, _) => Center(
        child: Text(AppStrings.errorLoad,
            style: const TextStyle(color: AppColors.expense)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.money_off_rounded,
            title: AppStrings.belumAdaHutang,
            subtitle: 'Belum ada data hutang untuk ditampilkan.',
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary cards ────────────────────────────────────
              summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
                data: (summary) => _HutangSummaryCards(summary: summary),
              ),
              SizedBox(height: AppSpacing.sectionGap(context)),

              // ── Nearest due ──────────────────────────────────────
              summaryAsync.maybeWhen(
                data: (summary) => summary.nearestDue != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.jatuhTempoTerdekat,
                            style: TextStyle(
                              fontSize: AppTypeScale.sectionTitle(context),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _NearestDueCard(hutang: summary.nearestDue!),
                          SizedBox(height: AppSpacing.sectionGap(context)),
                        ],
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),

              // ── Hutang list sorted by sisa ───────────────────────
              Text(
                'Daftar Hutang (berdasarkan sisa)',
                style: TextStyle(
                  fontSize: AppTypeScale.sectionTitle(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...([...list]..sort(
                      (a, b) => b.sisaHutang.compareTo(a.sisaHutang)))
                  .map((h) => _HutangReportRow(hutang: h)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _HutangSummaryCards extends StatelessWidget {
  final HutangSummary summary;
  const _HutangSummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final gap = AppSpacing.cardGap(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: AppStrings.totalSisaHutang,
                value: CurrencyFormatter.compact(summary.totalSisa),
                color: AppColors.debt,
                bgColor: AppColors.debtLight,
                icon: Icons.money_off_rounded,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _SummaryCard(
                label: AppStrings.totalHutangAktif,
                value: CurrencyFormatter.compact(summary.totalAktif),
                color: AppColors.textSecondary,
                bgColor: AppColors.surfaceVariant,
                icon: Icons.pending_outlined,
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        _SummaryCard(
          label: AppStrings.totalHutangLunas,
          value: CurrencyFormatter.compact(summary.totalLunas),
          color: AppColors.income,
          bgColor: AppColors.incomeLight,
          icon: Icons.check_circle_outline_rounded,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final bool fullWidth;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
                  maxLines: 2,
                ),
                Text(
                  value,
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

class _NearestDueCard extends StatelessWidget {
  final HutangEntity hutang;
  const _NearestDueCard({required this.hutang});

  @override
  Widget build(BuildContext context) {
    final daysLeft = hutang.tanggalJatuhTempo!
        .difference(DateTime.now())
        .inDays;
    final isUrgent = daysLeft <= 7;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.expenseLight : AppColors.debtLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent
              ? AppColors.expense.withValues(alpha: 0.3)
              : AppColors.debt.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_rounded,
            color: isUrgent ? AppColors.expense : AppColors.debt,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hutang.namaKreditur,
                  style: TextStyle(
                    fontSize: AppTypeScale.bodyText(context),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  AppDateUtils.formatShort(hutang.tanggalJatuhTempo!),
                  style: TextStyle(
                    fontSize: AppTypeScale.caption(context),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.compact(hutang.sisaHutang),
                style: TextStyle(
                  fontSize: AppTypeScale.bodyText(context),
                  fontWeight: FontWeight.w700,
                  color: AppColors.debt,
                ),
              ),
              Text(
                daysLeft == 0
                    ? 'Hari ini!'
                    : '$daysLeft hari lagi',
                style: TextStyle(
                  fontSize: AppTypeScale.caption(context),
                  color: isUrgent ? AppColors.expense : AppColors.textSecondary,
                  fontWeight: isUrgent ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HutangReportRow extends StatelessWidget {
  final HutangEntity hutang;
  const _HutangReportRow({required this.hutang});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hutang.namaKreditur,
                style: TextStyle(
                  fontSize: AppTypeScale.bodyText(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                CurrencyFormatter.compact(hutang.sisaHutang),
                style: TextStyle(
                  fontSize: AppTypeScale.bodyText(context),
                  fontWeight: FontWeight.w700,
                  color: hutang.isLunas ? AppColors.income : AppColors.debt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: hutang.progressPersen,
              backgroundColor: AppColors.debtLight,
              color: hutang.isLunas ? AppColors.income : AppColors.debt,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(hutang.progressPersen * 100).toStringAsFixed(0)}% terbayar',
                style: TextStyle(
                  fontSize: AppTypeScale.caption(context),
                  color: AppColors.textSecondary,
                ),
              ),
              if (hutang.isLunas)
                Text(
                  AppStrings.statusLunas,
                  style: TextStyle(
                    fontSize: AppTypeScale.caption(context),
                    color: AppColors.income,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
