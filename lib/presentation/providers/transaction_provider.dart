import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../domain/entities/transaction_entity.dart';
import 'database_provider.dart';

// ── Reactive stream of all transactions ───────────────────────────────────────

final allTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

// ── Home screen aggregated summary ───────────────────────────────────────────

class HomeSummary {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final double todayIncome;
  final double todayExpense;
  final List<Transaction> recentTransactions;

  const HomeSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.todayIncome,
    required this.todayExpense,
    required this.recentTransactions,
  });

  static const empty = HomeSummary(
    totalBalance: 0,
    totalIncome: 0,
    totalExpense: 0,
    todayIncome: 0,
    todayExpense: 0,
    recentTransactions: [],
  );
}

final homeSummaryProvider = Provider<AsyncValue<HomeSummary>>((ref) {
  return ref.watch(allTransactionsProvider).whenData((txs) {
    final today = AppDateUtils.dateOnly(DateTime.now());

    double allIncome = 0;
    double allExpense = 0;
    double todayIncome = 0;
    double todayExpense = 0;

    for (final tx in txs) {
      if (tx.isIncome) {
        allIncome += tx.amount;
        if (AppDateUtils.dateOnly(tx.date) == today) todayIncome += tx.amount;
      } else {
        allExpense += tx.amount;
        if (AppDateUtils.dateOnly(tx.date) == today) todayExpense += tx.amount;
      }
    }

    return HomeSummary(
      totalBalance: allIncome - allExpense,
      totalIncome: allIncome,
      totalExpense: allExpense,
      todayIncome: todayIncome,
      todayExpense: todayExpense,
      recentTransactions: txs.take(7).toList(),
    );
  });
});
