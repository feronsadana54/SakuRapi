import 'category_entity.dart';
import 'transaction_entity.dart';

/// Aggregated result returned by all report use-cases.
/// The same shape is used for daily, monthly, yearly, range, and payday reports.
class SummaryResult {
  final double totalIncome;
  final double totalExpense;
  final List<Transaction> transactions;
  final Map<Category, double> expenseByCategory;
  final Map<Category, double> incomeByCategory;

  const SummaryResult({
    required this.totalIncome,
    required this.totalExpense,
    required this.transactions,
    required this.expenseByCategory,
    required this.incomeByCategory,
  });

  double get balance => totalIncome - totalExpense;

  bool get isEmpty => transactions.isEmpty;

  static const SummaryResult empty = SummaryResult(
    totalIncome: 0,
    totalExpense: 0,
    transactions: [],
    expenseByCategory: {},
    incomeByCategory: {},
  );

  /// Builds a [SummaryResult] by aggregating a flat list of [Transaction]s.
  factory SummaryResult.fromTransactions(List<Transaction> transactions) {
    double income = 0;
    double expense = 0;
    final expCat = <Category, double>{};
    final incCat = <Category, double>{};

    for (final tx in transactions) {
      if (tx.isIncome) {
        income += tx.amount;
        incCat[tx.category] = (incCat[tx.category] ?? 0) + tx.amount;
      } else {
        expense += tx.amount;
        expCat[tx.category] = (expCat[tx.category] ?? 0) + tx.amount;
      }
    }

    return SummaryResult(
      totalIncome: income,
      totalExpense: expense,
      transactions: transactions,
      expenseByCategory: expCat,
      incomeByCategory: incCat,
    );
  }
}
