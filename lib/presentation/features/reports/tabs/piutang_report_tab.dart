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
import '../../../../domain/entities/piutang_entity.dart';
import '../../../../presentation/providers/piutang_provider.dart';

class PiutangReportTab extends ConsumerWidget {
  const PiutangReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final piutangAsync = ref.watch(piutangListProvider);
    final summaryAsync = ref.watch(piutangSummaryProvider);
    final p = AppSpacing.pagePadding(context);

    return piutangAsync.when(
      loading: () => const AppLoadingIndicator(),
      error: (e, _) => Center(
        child: Text(AppStrings.errorLoad,
            style: const TextStyle(color: AppColors.expense)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.attach_money_rounded,
            title: AppStrings.belumAdaPiutang,
            subtitle: 'Belum ada data piutang untuk ditampilkan.',
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
                data: (summary) => _PiutangSummaryCards(summary: summary),
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
                          _NearestDueCard(piutang: summary.nearestDue!),
                          SizedBox(height: AppSpacing.sectionGap(context)),
                        ],
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),

              // ── Piutang list sorted by sisa ──────────────────────
              Text(
                'Daftar Piutang (berdasarkan sisa)',
                style: TextStyle(
                  fontSize: AppTypeScale.sectionTitle(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...([...list]..sort(
                      (a, b) => b.sisaPiutang.compareTo(a.sisaPiutang)))
                  .map((p) => _PiutangReportRow(piutang: p)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _PiutangSummaryCards extends StatelessWidget {
  final PiutangSummary summary;
  const _PiutangSummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final gap = AppSpacing.cardGap(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: AppStrings.totalSisaPiutang,
                value: CurrencyFormatter.compact(summary.totalSisa),
                color: AppColors.receivable,
                bgColor: AppColors.receivableLight,
                icon: Icons.attach_money_rounded,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _SummaryCard(
                label: AppStrings.totalPiutangAktif,
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
          label: AppStrings.totalPiutangLunas,
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
  final PiutangEntity piutang;
  const _NearestDueCard({required this.piutang});

  @override
  Widget build(BuildContext context) {
    final daysLeft = piutang.tanggalJatuhTempo!
        .difference(DateTime.now())
        .inDays;
    final isUrgent = daysLeft <= 7;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.expenseLight : AppColors.receivableLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent
              ? AppColors.expense.withValues(alpha: 0.3)
              : AppColors.receivable.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_rounded,
            color: isUrgent ? AppColors.expense : AppColors.receivable,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  piutang.namaPeminjam,
                  style: TextStyle(
                    fontSize: AppTypeScale.bodyText(context),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  AppDateUtils.formatShort(piutang.tanggalJatuhTempo!),
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
                CurrencyFormatter.compact(piutang.sisaPiutang),
                style: TextStyle(
                  fontSize: AppTypeScale.bodyText(context),
                  fontWeight: FontWeight.w700,
                  color: AppColors.receivable,
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

class _PiutangReportRow extends StatelessWidget {
  final PiutangEntity piutang;
  const _PiutangReportRow({required this.piutang});

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
                piutang.namaPeminjam,
                style: TextStyle(
                  fontSize: AppTypeScale.bodyText(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                CurrencyFormatter.compact(piutang.sisaPiutang),
                style: TextStyle(
                  fontSize: AppTypeScale.bodyText(context),
                  fontWeight: FontWeight.w700,
                  color: piutang.isLunas ? AppColors.income : AppColors.receivable,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: piutang.progressPersen,
              backgroundColor: AppColors.receivableLight,
              color: piutang.isLunas ? AppColors.income : AppColors.receivable,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(piutang.progressPersen * 100).toStringAsFixed(0)}% kembali',
                style: TextStyle(
                  fontSize: AppTypeScale.caption(context),
                  color: AppColors.textSecondary,
                ),
              ),
              if (piutang.isLunas)
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
