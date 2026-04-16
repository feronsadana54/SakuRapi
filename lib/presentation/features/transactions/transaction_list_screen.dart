import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/responsive/app_spacing.dart';
import '../../../core/responsive/app_type_scale.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../presentation/providers/database_provider.dart';
import '../../../presentation/providers/transaction_provider.dart';
import '../../../presentation/widgets/transaction_tile.dart';
import '../../../router/app_router.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState
    extends ConsumerState<TransactionListScreen> {
  // ── Filter state ────────────────────────────────────────────────────────
  TransactionType? _filter;

  // ── Multi-select state ──────────────────────────────────────────────────
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

  // ── Filter helpers ───────────────────────────────────────────────────────

  void _setFilter(TransactionType? f) {
    setState(() {
      _filter = f;
      // Exit selection mode when filter changes to avoid confusion.
      if (_isSelectMode) _exitSelectMode();
    });
  }

  List<Transaction> _applyFilter(List<Transaction> txs) {
    if (_filter == null) return txs;
    return txs.where((t) => t.type == _filter).toList();
  }

  /// Groups transactions by relative date label (Hari Ini, Kemarin, …).
  List<_ListItem> _buildItems(List<Transaction> txs) {
    final items = <_ListItem>[];
    String? lastLabel;
    for (final tx in txs) {
      final label = AppDateUtils.relativeLabel(tx.date);
      if (label != lastLabel) {
        items.add(_ListItem.header(label));
        lastLabel = label;
      }
      items.add(_ListItem.transaction(tx));
    }
    return items;
  }

  // ── Single delete (existing behaviour) ──────────────────────────────────

  Future<void> _deleteTransaction(Transaction tx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteTransactionTitle),
        content: const Text(AppStrings.deleteTransactionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(transactionRepositoryProvider).delete(tx.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaksi dihapus.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Selection mode ───────────────────────────────────────────────────────

  /// Enters selection mode and immediately selects [tx].
  void _enterSelectMode(Transaction tx) {
    setState(() {
      _isSelectMode = true;
      _selectedIds.add(tx.id);
    });
  }

  /// Exits selection mode and clears all selections.
  void _exitSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedIds.clear();
    });
  }

  /// Toggles [tx] in the selection set.
  /// Automatically exits selection mode when the set becomes empty.
  void _toggleSelect(Transaction tx) {
    setState(() {
      if (_selectedIds.contains(tx.id)) {
        _selectedIds.remove(tx.id);
        if (_selectedIds.isEmpty) _isSelectMode = false;
      } else {
        _selectedIds.add(tx.id);
      }
    });
  }

  // ── Bulk delete ──────────────────────────────────────────────────────────

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    if (count == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.bulkDeleteTitle),
        content:
            Text('$count ${AppStrings.bulkDeleteBody}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final repo = ref.read(transactionRepositoryProvider);
    // Copy to a local list first so we iterate a stable collection.
    final ids = _selectedIds.toList();
    for (final id in ids) {
      await repo.delete(id);
    }

    if (!mounted) return;
    _exitSelectMode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count transaksi dihapus.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  void _openEdit(Transaction tx) {
    context.push(AppRoutes.transactionEdit, extra: tx);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(allTransactionsProvider);
    final isTablet = context.isTablet;

    // On Android, intercept the back button to exit selection mode gracefully.
    return PopScope(
      canPop: !_isSelectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelectMode) _exitSelectMode();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _isSelectMode && !isTablet
            ? _buildSelectionAppBar()
            : _buildDefaultAppBar(),
        body: txAsync.when(
          loading: () => const AppLoadingIndicator(),
          error: (e, _) => Center(child: Text(AppStrings.errorLoad)),
          data: (allTxs) {
            final filtered = _applyFilter(allTxs);

            if (filtered.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.receipt_long_rounded,
                svgAsset: 'assets/images/empty_transactions.svg',
                title: AppStrings.noTransactions,
                subtitle: AppStrings.noTransactionsDesc,
                actionLabel: AppStrings.addTransaction,
                onAction: () => context.push(AppRoutes.transactionAdd),
              );
            }

            final items = _buildItems(filtered);

            if (isTablet) {
              // Tablet uses its own two-column layout; bulk select is mobile-only.
              return _TabletLayout(
                items: items,
                onEdit: _openEdit,
                onDelete: _deleteTransaction,
              );
            }

            return _MobileList(
              items: items,
              onEdit: _openEdit,
              onDelete: _deleteTransaction,
              isSelectMode: _isSelectMode,
              selectedIds: _selectedIds,
              onEnterSelectMode: _enterSelectMode,
              onToggleSelect: _toggleSelect,
            );
          },
        ),
        floatingActionButton: _isSelectMode
            ? null // Hide FAB in selection mode to avoid accidental taps.
            : FloatingActionButton(
                onPressed: () => context.push(AppRoutes.transactionAdd),
                tooltip: AppStrings.addTransaction,
                child: const Icon(Icons.add_rounded),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildDefaultAppBar() {
    return AppBar(
      title: const Text(AppStrings.navTransactions),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: _FilterBar(
          current: _filter,
          onChanged: _setFilter,
        ),
      ),
    );
  }

  /// AppBar shown while in multi-select mode.
  PreferredSizeWidget _buildSelectionAppBar() {
    final count = _selectedIds.length;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: _exitSelectMode,
        tooltip: AppStrings.cancel,
      ),
      title: Text(
        '$count dipilih',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        if (count > 0)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.expense,
            onPressed: _deleteSelected,
            tooltip: AppStrings.delete,
          ),
      ],
    );
  }
}

// ── Mobile list ────────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  final List<_ListItem> items;
  final ValueChanged<Transaction> onEdit;
  final ValueChanged<Transaction> onDelete;

  // Selection-mode state (read-only from the parent)
  final bool isSelectMode;
  final Set<String> selectedIds;
  final ValueChanged<Transaction> onEnterSelectMode;
  final ValueChanged<Transaction> onToggleSelect;

  const _MobileList({
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.isSelectMode,
    required this.selectedIds,
    required this.onEnterSelectMode,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, i) {
        final item = items[i];
        if (item.isHeader) return DateGroupHeader(label: item.label!);

        final tx = item.transaction!;

        if (isSelectMode) {
          return _SelectableTile(
            key: ValueKey('sel-${tx.id}'),
            tx: tx,
            isSelected: selectedIds.contains(tx.id),
            onTap: () => onToggleSelect(tx),
          );
        }

        // Normal mode: swipe-to-delete + long-press to enter selection mode.
        return GestureDetector(
          onLongPress: () => onEnterSelectMode(tx),
          child: Dismissible(
            key: ValueKey(tx.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: AppColors.expenseLight,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.expense),
            ),
            confirmDismiss: (_) async {
              onDelete(tx);
              return false; // deletion handled manually
            },
            child: _TileWithDivider(
              tx: tx,
              onTap: () => onEdit(tx),
            ),
          ),
        );
      },
    );
  }
}

// ── Selectable tile (used in selection mode) ──────────────────────────────────

class _SelectableTile extends StatelessWidget {
  final Transaction tx;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableTile({
    required this.tx,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.09)
          : Colors.transparent,
      child: Column(
        children: [
          Row(
            children: [
              // Checkbox on the leading edge
              SizedBox(
                width: 48,
                height: 56,
                child: Center(
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              // Transaction tile fills remaining space; tapping it also toggles.
              Expanded(
                child: TransactionTile(transaction: tx, onTap: onTap),
              ),
            ],
          ),
          const Divider(height: 1, indent: 72),
        ],
      ),
    );
  }
}

// ── Tablet two-column layout ──────────────────────────────────────────────────

class _TabletLayout extends StatefulWidget {
  final List<_ListItem> items;
  final ValueChanged<Transaction> onEdit;
  final ValueChanged<Transaction> onDelete;

  const _TabletLayout({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_TabletLayout> createState() => _TabletLayoutState();
}

class _TabletLayoutState extends State<_TabletLayout> {
  Transaction? _selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: list
        SizedBox(
          width: 340,
          child: ListView.builder(
            itemCount: widget.items.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, i) {
              final item = widget.items[i];
              if (item.isHeader) return DateGroupHeader(label: item.label!);
              final tx = item.transaction!;
              final isSelected = _selected?.id == tx.id;
              return ColoredBox(
                color: isSelected
                    ? AppColors.primaryContainer
                    : Colors.transparent,
                child: _TileWithDivider(
                  tx: tx,
                  onTap: () => setState(() => _selected = tx),
                ),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        // Right: detail or placeholder
        Expanded(
          child: _selected == null
              ? const Center(
                  child: Text(
                    'Pilih transaksi untuk melihat detail.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : _TransactionDetail(
                  transaction: _selected!,
                  onEdit: () => widget.onEdit(_selected!),
                  onDelete: () => widget.onDelete(_selected!),
                ),
        ),
      ],
    );
  }
}

class _TransactionDetail extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionDetail({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final isIncome = tx.isIncome;
    final amountColor = isIncome ? AppColors.income : AppColors.expense;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.pagePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isIncome ? AppStrings.income : AppStrings.expense,
                style: TextStyle(
                  fontSize: AppTypeScale.caption(context),
                  color: amountColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                    tooltip: AppStrings.edit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppColors.expense,
                    onPressed: onDelete,
                    tooltip: AppStrings.delete,
                  ),
                ],
              ),
            ],
          ),
          Text(
            '${isIncome ? '+' : '-'}${CurrencyFormatter.full(tx.amount)}',
            style: TextStyle(
              fontSize: AppTypeScale.balanceDisplay(context),
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(icon: Icons.category_outlined, label: tx.category.name),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: AppDateUtils.formatFull(tx.date),
          ),
          if (tx.note != null) ...[
            const SizedBox(height: 8),
            _DetailRow(icon: Icons.notes_rounded, label: tx.note!),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypeScale.bodyText(context),
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TransactionType? current;
  final ValueChanged<TransactionType?> onChanged;

  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding(context), vertical: 8),
      child: Row(
        children: [
          _Chip(
              label: 'Semua',
              active: current == null,
              onTap: () => onChanged(null)),
          const SizedBox(width: 8),
          _Chip(
            label: AppStrings.income,
            active: current == TransactionType.income,
            onTap: () => onChanged(TransactionType.income),
            color: AppColors.income,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: AppStrings.expense,
            active: current == TransactionType.expense,
            onTap: () => onChanged(TransactionType.expense),
            color: AppColors.expense,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;

  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : AppColors.divider,
            width: active ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTypeScale.caption(context),
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Helper types ──────────────────────────────────────────────────────────────

class _ListItem {
  final String? label;
  final Transaction? transaction;

  const _ListItem._({this.label, this.transaction});

  factory _ListItem.header(String label) => _ListItem._(label: label);
  factory _ListItem.transaction(Transaction tx) =>
      _ListItem._(transaction: tx);

  bool get isHeader => label != null;
}

class _TileWithDivider extends StatelessWidget {
  final Transaction tx;
  final VoidCallback onTap;

  const _TileWithDivider({required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TransactionTile(transaction: tx, onTap: onTap),
        const Divider(height: 1, indent: 72),
      ],
    );
  }
}
