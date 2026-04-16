import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/responsive/app_spacing.dart';
import '../../core/responsive/app_type_scale.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/transaction_entity.dart';

/// A single row in a transaction list. Handles its own sizing; no Dismissible
/// here — callers wrap with Dismissible if swipe-to-delete is needed.
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    required this.transaction,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final isIncome = tx.isIncome;
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final iconBg = isIncome ? AppColors.incomeLight : AppColors.expenseLight;
    final iconColor = Color(tx.category.colorValue);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding(context),
          vertical: 10,
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                AppIcons.fromCode(tx.category.iconCode),
                size: 22,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),

            // Category name + note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.category.name,
                    style: TextStyle(
                      fontSize: AppTypeScale.bodyText(context),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.note?.isNotEmpty == true
                        ? tx.note!
                        : AppDateUtils.relativeLabel(tx.date),
                    style: TextStyle(
                      fontSize: AppTypeScale.caption(context),
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Amount + date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyFormatter.compact(tx.amount)}',
                  style: TextStyle(
                    fontSize: AppTypeScale.bodyText(context),
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 2),
                if (tx.note?.isNotEmpty == true)
                  Text(
                    AppDateUtils.relativeLabel(tx.date),
                    style: TextStyle(
                      fontSize: AppTypeScale.caption(context),
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin date-group divider used in [TransactionListScreen].
class DateGroupHeader extends StatelessWidget {
  final String label;

  const DateGroupHeader({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding(context), 16, AppSpacing.pagePadding(context), 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypeScale.caption(context),
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
