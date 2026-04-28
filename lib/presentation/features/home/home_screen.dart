import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/finance_quotes.dart';
import '../../../core/responsive/app_spacing.dart';
import '../../../core/responsive/app_type_scale.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/responsive/responsive_container.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/transaction_provider.dart';
import '../../../presentation/widgets/transaction_tile.dart';
import '../../../router/app_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeSummaryProvider);
    final isSyncing = ref.watch(isBackgroundSyncingProvider);
    final displayName = ref.watch(currentUserProvider).valueOrNull?.displayName
        ?? AppStrings.appName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppDateUtils.greeting()},',
              style: TextStyle(
                fontSize: AppTypeScale.caption(context),
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              displayName,
              style: TextStyle(
                fontSize: AppTypeScale.sectionTitle(context),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isSyncing ? const _SyncBanner() : const SizedBox.shrink(),
          ),
          Expanded(
            child: summaryAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (e, _) => Center(
                child: Text(AppStrings.errorLoad,
                    style: const TextStyle(color: AppColors.expense)),
              ),
              data: (summary) => SafeArea(
                child: ResponsiveContainer(
                  child: context.isTablet
                      ? _TabletLayout(summary: summary)
                      : _MobileLayout(summary: summary),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.transactionAdd),
        tooltip: AppStrings.addTransaction,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ── Sync Banner ───────────────────────────────────────────────────────────────

class _SyncBanner extends StatelessWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('sync_banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.incomeLight,
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.income,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Sedang memulihkan data dari cloud...',
            style: TextStyle(
              fontSize: AppTypeScale.caption(context),
              color: AppColors.income,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final HomeSummary summary;

  const _MobileLayout({required this.summary});

  @override
  Widget build(BuildContext context) {
    final p = AppSpacing.pagePadding(context);
    final gap = AppSpacing.cardGap(context);
    final sectionGap = AppSpacing.sectionGap(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(p, p, p, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BalanceCard(summary: summary),
          SizedBox(height: gap),
          _TodaySummaryRow(summary: summary),
          SizedBox(height: sectionGap),
          const _QuoteCarousel(),
          SizedBox(height: sectionGap),
          const _RecentHeader(),
          SizedBox(height: AppSpacing.sm),
          _RecentList(transactions: summary.recentTransactions),
        ],
      ),
    );
  }
}

// ── Tablet layout ─────────────────────────────────────────────────────────────

class _TabletLayout extends StatelessWidget {
  final HomeSummary summary;

  const _TabletLayout({required this.summary});

  @override
  Widget build(BuildContext context) {
    final p = AppSpacing.pagePadding(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(p),
            child: Column(
              children: [
                _BalanceCard(summary: summary),
                SizedBox(height: AppSpacing.cardGap(context)),
                _TodaySummaryRow(summary: summary),
                SizedBox(height: AppSpacing.sectionGap(context)),
                const _QuoteCarousel(),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(p, p, p, 0),
                child: const _RecentHeader(),
              ),
              Expanded(
                child: _RecentList(transactions: summary.recentTransactions),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Balance card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final HomeSummary summary;
  const _BalanceCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.balance,
            style: TextStyle(
              fontSize: AppTypeScale.caption(context),
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.full(summary.totalBalance),
            style: TextStyle(
              fontSize: AppTypeScale.balanceDisplay(context),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _BalanceStat(
                label: AppStrings.income,
                amount: CurrencyFormatter.compact(summary.totalIncome),
                icon: Icons.arrow_downward_rounded,
                color: const Color(0xFF81C784),
              ),
              const SizedBox(width: 24),
              _BalanceStat(
                label: AppStrings.expense,
                amount: CurrencyFormatter.compact(summary.totalExpense),
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFFEF9A9A),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _BalanceStat({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: AppTypeScale.caption(context),
                    color: Colors.white70)),
            Text(amount,
                style: TextStyle(
                    fontSize: AppTypeScale.bodyText(context),
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

// ── Today summary row ─────────────────────────────────────────────────────────

class _TodaySummaryRow extends StatelessWidget {
  final HomeSummary summary;
  const _TodaySummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: '${AppStrings.today} — ${AppStrings.income}',
            amount: CurrencyFormatter.compact(summary.todayIncome),
            icon: Icons.arrow_downward_rounded,
            color: AppColors.income,
            bgColor: AppColors.incomeLight,
          ),
        ),
        SizedBox(width: AppSpacing.cardGap(context)),
        Expanded(
          child: _StatCard(
            label: '${AppStrings.today} — ${AppStrings.expense}',
            amount: CurrencyFormatter.compact(summary.todayExpense),
            icon: Icons.arrow_upward_rounded,
            color: AppColors.expense,
            bgColor: AppColors.expenseLight,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String amount;
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
                      fontSize: AppTypeScale.caption(context) - 1,
                      color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  amount,
                  style: TextStyle(
                      fontSize: AppTypeScale.bodyText(context),
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Auto-rotating quote carousel ──────────────────────────────────────────────

class _QuoteCarousel extends StatefulWidget {
  const _QuoteCarousel();

  @override
  State<_QuoteCarousel> createState() => _QuoteCarouselState();
}

class _QuoteCarouselState extends State<_QuoteCarousel> {
  late int _index;
  late Timer _timer;

  static const _rotateInterval = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _index = FinanceQuotes.todayIndex; // Start at today's quote.
    _timer = Timer.periodic(_rotateInterval, (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % FinanceQuotes.quotes.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded,
              size: 26, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    )),
                    child: child,
                  ),
                );
              },
              child: Text(
                FinanceQuotes.quotes[_index],
                key: ValueKey(_index),
                style: TextStyle(
                  fontSize: AppTypeScale.caption(context),
                  color: AppColors.textPrimary,
                  fontStyle: FontStyle.italic,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent transactions ───────────────────────────────────────────────────────

class _RecentHeader extends ConsumerWidget {
  const _RecentHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.recentTransactions,
          style: TextStyle(
            fontSize: AppTypeScale.sectionTitle(context),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.transactionList),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            AppStrings.seeAll,
            style: TextStyle(
                fontSize: AppTypeScale.caption(context),
                color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _RecentList extends ConsumerWidget {
  final List<Transaction> transactions;
  const _RecentList({required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long_rounded,
        svgAsset: 'assets/images/empty_transactions.svg',
        title: AppStrings.noTransactions,
        subtitle: AppStrings.noTransactionsDesc,
      );
    }

    return Column(
      children: transactions
          .map((tx) => Column(
                children: [
                  TransactionTile(
                    transaction: tx,
                    onTap: () => context.push(
                      AppRoutes.transactionEdit,
                      extra: tx,
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                ],
              ))
          .toList(),
    );
  }
}
