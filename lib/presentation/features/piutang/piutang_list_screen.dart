import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/responsive/app_spacing.dart';
import '../../../core/responsive/app_type_scale.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../domain/entities/piutang_entity.dart';
import '../../../presentation/providers/piutang_provider.dart';
import '../../../router/app_router.dart';

class PiutangListScreen extends ConsumerStatefulWidget {
  const PiutangListScreen({super.key});

  @override
  ConsumerState<PiutangListScreen> createState() => _PiutangListScreenState();
}

class _PiutangListScreenState extends ConsumerState<PiutangListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final piutangAsync = ref.watch(piutangListProvider);
    final summaryAsync = ref.watch(piutangSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.piutang),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: AppStrings.statusAktif),
            Tab(text: AppStrings.statusLunas),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: Column(
        children: [
          summaryAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
            data: (summary) => _PiutangSummaryBanner(summary: summary),
          ),
          Expanded(
            child: piutangAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (e, _) => Center(
                child: Text(AppStrings.errorLoad,
                    style: const TextStyle(color: AppColors.expense)),
              ),
              data: (list) {
                final aktif = list.where((p) => !p.isLunas).toList();
                final lunas = list.where((p) => p.isLunas).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _PiutangTab(
                      list: aktif,
                      emptyTitle: AppStrings.belumAdaPiutang,
                      emptySubtitle: 'Ketuk + untuk mencatat piutang baru.',
                    ),
                    _PiutangTab(
                      list: lunas,
                      emptyTitle: 'Tidak Ada Piutang Lunas',
                      emptySubtitle: 'Piutang yang sudah lunas akan muncul di sini.',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.piutangAdd),
        tooltip: AppStrings.tambahPiutang,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _PiutangSummaryBanner extends StatelessWidget {
  final PiutangSummary summary;
  const _PiutangSummaryBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    final p = AppSpacing.pagePadding(context);
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(p, 12, p, 12),
      child: Row(
        children: [
          Expanded(
            child: _SummaryChip(
              label: AppStrings.totalSisaPiutang,
              value: CurrencyFormatter.compact(summary.totalSisa),
              color: AppColors.receivable,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryChip(
              label: AppStrings.totalPiutangAktif,
              value: CurrencyFormatter.compact(summary.totalAktif),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypeScale.caption(context),
              color: AppColors.textSecondary,
            ),
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
    );
  }
}

class _PiutangTab extends ConsumerWidget {
  final List<PiutangEntity> list;
  final String emptyTitle;
  final String emptySubtitle;

  const _PiutangTab({
    required this.list,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (list.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.attach_money_rounded,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding(context),
        vertical: 12,
      ),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final piutang = list[index];
        return Dismissible(
          key: Key(piutang.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.expense,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text(AppStrings.deletePiutang),
                content: const Text(AppStrings.deletePiutangBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text(AppStrings.cancel),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.expense),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(AppStrings.delete),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            ref
                .read(piutangNotifierProvider.notifier)
                .deletePiutang(piutang.id);
          },
          child: _PiutangCard(
            piutang: piutang,
            onTap: () =>
                context.push(AppRoutes.piutangDetail, extra: piutang),
          ),
        );
      },
    );
  }
}

class _PiutangCard extends StatelessWidget {
  final PiutangEntity piutang;
  final VoidCallback onTap;

  const _PiutangCard({required this.piutang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOverdue = piutang.tanggalJatuhTempo != null &&
        DateTime.now().isAfter(piutang.tanggalJatuhTempo!) &&
        !piutang.isLunas;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOverdue
                ? AppColors.expense.withValues(alpha: 0.4)
                : AppColors.divider,
            width: isOverdue ? 1.2 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.receivableLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.attach_money_rounded,
                      color: AppColors.receivable, size: 20),
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
                        'Pinjam: ${AppDateUtils.formatShort(piutang.tanggalPinjam)}',
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
                        color: piutang.isLunas
                            ? AppColors.income
                            : AppColors.receivable,
                      ),
                    ),
                    if (piutang.isLunas)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.incomeLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppStrings.statusLunas,
                          style: TextStyle(
                            fontSize: AppTypeScale.caption(context) - 1,
                            color: AppColors.income,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (isOverdue)
                      Text(
                        'Jatuh Tempo!',
                        style: TextStyle(
                          fontSize: AppTypeScale.caption(context),
                          color: AppColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: piutang.progressPersen,
                backgroundColor: AppColors.receivableLight,
                color: piutang.isLunas ? AppColors.income : AppColors.receivable,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Diterima: ${CurrencyFormatter.compact(piutang.totalDiterima)}',
                  style: TextStyle(
                    fontSize: AppTypeScale.caption(context),
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${(piutang.progressPersen * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: AppTypeScale.caption(context),
                    fontWeight: FontWeight.w600,
                    color: piutang.isLunas
                        ? AppColors.income
                        : AppColors.receivable,
                  ),
                ),
              ],
            ),
            if (piutang.tanggalJatuhTempo != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 13,
                    color: isOverdue
                        ? AppColors.expense
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Jatuh tempo: ${AppDateUtils.formatShort(piutang.tanggalJatuhTempo!)}',
                    style: TextStyle(
                      fontSize: AppTypeScale.caption(context),
                      color: isOverdue
                          ? AppColors.expense
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
