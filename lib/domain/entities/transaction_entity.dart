import 'package:equatable/equatable.dart';
import '../enums/transaction_type.dart';
import 'category_entity.dart';

class Transaction extends Equatable {
  final String id;
  final TransactionType type;
  final double amount;
  final Category category;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    required this.createdAt,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  @override
  List<Object?> get props =>
      [id, type, amount, category, note, date, createdAt];
}
