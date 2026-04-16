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
import '../../../domain/entities/hutang_entity.dart';
import '../../../presentation/providers/hutang_provider.dart';
import '../../../router/app_router.dart';

class HutangListScreen extends ConsumerStatefulWidget {
  const HutangListScreen({super.key});

  @override
  ConsumerState<HutangListScreen> createState() => _HutangListScreenState();
}

class _HutangListScreenState extends ConsumerState<HutangListScreen>
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
    final hutangAsync = ref.watch(hutangListProvider);
    final summaryAsync = ref.watch(hutangSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.hutang),
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
          // ── Summary cards ──────────────────────────────────────────
          summaryAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
            data: (summary) => _HutangSummaryBanner(summary: summary),
          ),

          // ── Tabbed list ────────────────────────────────────────────
          Expanded(
            child: hutangAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (e, _) => Center(
                child: Text(AppStrings.errorLoad,
                    style: const TextStyle(color: AppColors.expense)),
              ),
              data: (list) {
                final aktif = list.where((h) => !h.isLunas).toList();
                final lunas = list.where((h) => h.isLunas).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _HutangTab(
                      list: aktif,
                      emptyTitle: AppStrings.belumAdaHutang,
                      emptySubtitle: 'Ketuk + untuk mencatat hutang baru.',
                    ),
                    _HutangTab(
                      list: lunas,
                      emptyTitle: 'Tidak Ada Hutang Lunas',
                      emptySubtitle: 'Hutang yang sudah lunas akan muncul di sini.',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.hutangAdd),
        tooltip: AppStrings.tambahHutang,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ── Summary banner ────────────────────────────────────────────────────────────

class _HutangSummaryBanner extends StatelessWidget {
  final HutangSummary summary;
  const _HutangSummaryBanner({required this.summary});

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
              label: AppStrings.totalSisaHutang,
              value: CurrencyFormatter.compact(summary.totalSisa),
              color: AppColors.debt,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryChip(
              label: AppStrings.totalHutangAktif,
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

// ── Hutang tab content ────────────────────────────────────────────────────────

class _HutangTab extends ConsumerWidget {
  final List<HutangEntity> list;
  final String emptyTitle;
  final String emptySubtitle;

  const _HutangTab({
    required this.list,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (list.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.money_off_rounded,
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
        final hutang = list[index];
        return Dismissible(
          key: Key(hutang.id),
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
                title: const Text(AppStrings.deleteHutang),
                content: const Text(AppStrings.deleteHutangBody),
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
            ref.read(hutangNotifierProvider.notifier).deleteHutang(hutang.id);
          },
          child: _HutangCard(
            hutang: hutang,
            onTap: () => context.push(AppRoutes.hutangDetail, extra: hutang),
          ),
        );
      },
    );
  }
}

// ── Hutang card ───────────────────────────────────────────────────────────────

class _HutangCard extends StatelessWidget {
  final HutangEntity hutang;
  final VoidCallback onTap;

  const _HutangCard({required this.hutang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOverdue = hutang.tanggalJatuhTempo != null &&
        DateTime.now().isAfter(hutang.tanggalJatuhTempo!) &&
        !hutang.isLunas;

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
                    color: AppColors.debtLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.money_off_rounded,
                      color: AppColors.debt, size: 20),
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
                        'Pinjam: ${AppDateUtils.formatShort(hutang.tanggalPinjam)}',
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
                        color: hutang.isLunas ? AppColors.income : AppColors.debt,
                      ),
                    ),
                    if (hutang.isLunas)
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
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: hutang.progressPersen,
                backgroundColor: AppColors.debtLight,
                color: hutang.isLunas ? AppColors.income : AppColors.debt,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dibayar: ${CurrencyFormatter.compact(hutang.totalDibayar)}',
                  style: TextStyle(
                    fontSize: AppTypeScale.caption(context),
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${(hutang.progressPersen * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: AppTypeScale.caption(context),
                    fontWeight: FontWeight.w600,
                    color: hutang.isLunas ? AppColors.income : AppColors.debt,
                  ),
                ),
              ],
            ),
            if (hutang.tanggalJatuhTempo != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 13,
                    color: isOverdue ? AppColors.expense : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Jatuh tempo: ${AppDateUtils.formatShort(hutang.tanggalJatuhTempo!)}',
                    style: TextStyle(
                      fontSize: AppTypeScale.caption(context),
                      color: isOverdue ? AppColors.expense : AppColors.textSecondary,
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
