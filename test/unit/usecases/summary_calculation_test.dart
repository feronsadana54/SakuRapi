import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/domain/entities/category_entity.dart';
import 'package:finance_tracker/domain/entities/summary_result.dart';
import 'package:finance_tracker/domain/entities/transaction_entity.dart';
import 'package:finance_tracker/domain/enums/category_type.dart';
import 'package:finance_tracker/domain/enums/transaction_type.dart';

void main() {
  final catFood = Category(
    id: 'c1',
    name: 'Makanan',
    iconCode: 0xe56c,
    colorValue: 0xFFE53935,
    type: CategoryType.expense,
    isDefault: true,
  );

  final catSalary = Category(
    id: 'c2',
    name: 'Gaji',
    iconCode: 0xe227,
    colorValue: 0xFF2E7D32,
    type: CategoryType.income,
    isDefault: true,
  );

  final catTransport = Category(
    id: 'c3',
    name: 'Transportasi',
    iconCode: 0xe531,
    colorValue: 0xFF1565C0,
    type: CategoryType.expense,
    isDefault: true,
  );

  Transaction makeTx({
    required String id,
    required TransactionType type,
    required double amount,
    required Category category,
  }) {
    return Transaction(
      id: id,
      type: type,
      amount: amount,
      category: category,
      date: DateTime(2026, 4, 1),
      createdAt: DateTime(2026, 4, 1),
    );
  }

  group('SummaryResult.fromTransactions', () {
    test('returns empty for empty list', () {
      final result = SummaryResult.fromTransactions([]);
      expect(result.totalIncome, 0);
      expect(result.totalExpense, 0);
      expect(result.balance, 0);
      expect(result.isEmpty, true);
    });

    test('sums income correctly', () {
      final txs = [
        makeTx(id: '1', type: TransactionType.income, amount: 5000000, category: catSalary),
        makeTx(id: '2', type: TransactionType.income, amount: 1000000, category: catSalary),
      ];
      final result = SummaryResult.fromTransactions(txs);
      expect(result.totalIncome, 6000000);
      expect(result.totalExpense, 0);
      expect(result.balance, 6000000);
    });

    test('sums expense correctly', () {
      final txs = [
        makeTx(id: '1', type: TransactionType.expense, amount: 50000, category: catFood),
        makeTx(id: '2', type: TransactionType.expense, amount: 20000, category: catTransport),
      ];
      final result = SummaryResult.fromTransactions(txs);
      expect(result.totalExpense, 70000);
      expect(result.totalIncome, 0);
      expect(result.balance, -70000);
    });

    test('computes net balance (income - expense)', () {
      final txs = [
        makeTx(id: '1', type: TransactionType.income, amount: 5000000, category: catSalary),
        makeTx(id: '2', type: TransactionType.expense, amount: 1500000, category: catFood),
      ];
      final result = SummaryResult.fromTransactions(txs);
      expect(result.balance, 3500000);
    });

    test('aggregates expenseByCategory correctly', () {
      final txs = [
        makeTx(id: '1', type: TransactionType.expense, amount: 50000, category: catFood),
        makeTx(id: '2', type: TransactionType.expense, amount: 30000, category: catFood),
        makeTx(id: '3', type: TransactionType.expense, amount: 20000, category: catTransport),
      ];
      final result = SummaryResult.fromTransactions(txs);
      expect(result.expenseByCategory[catFood], 80000);
      expect(result.expenseByCategory[catTransport], 20000);
      expect(result.incomeByCategory.isEmpty, true);
    });

    test('aggregates incomeByCategory correctly', () {
      final txs = [
        makeTx(id: '1', type: TransactionType.income, amount: 5000000, category: catSalary),
        makeTx(id: '2', type: TransactionType.income, amount: 200000, category: catSalary),
      ];
      final result = SummaryResult.fromTransactions(txs);
      expect(result.incomeByCategory[catSalary], 5200000);
    });

    test('mixed transactions — both maps populated', () {
      final txs = [
        makeTx(id: '1', type: TransactionType.income, amount: 5000000, category: catSalary),
        makeTx(id: '2', type: TransactionType.expense, amount: 150000, category: catFood),
        makeTx(id: '3', type: TransactionType.expense, amount: 50000, category: catTransport),
      ];
      final result = SummaryResult.fromTransactions(txs);
      expect(result.totalIncome, 5000000);
      expect(result.totalExpense, 200000);
      expect(result.balance, 4800000);
      expect(result.expenseByCategory.length, 2);
      expect(result.incomeByCategory.length, 1);
    });

    test('isEmpty is false when transactions exist', () {
      final txs = [
        makeTx(id: '1', type: TransactionType.expense, amount: 10000, category: catFood),
      ];
      final result = SummaryResult.fromTransactions(txs);
      expect(result.isEmpty, false);
    });
  });

  group('SummaryResult.empty', () {
    test('has all zeros', () {
      const e = SummaryResult.empty;
      expect(e.totalIncome, 0);
      expect(e.totalExpense, 0);
      expect(e.balance, 0);
      expect(e.isEmpty, true);
    });
  });
}
