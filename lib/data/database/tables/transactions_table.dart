import 'package:drift/drift.dart';
import 'categories_table.dart';

@DataClassName('TransactionData')
class TransactionsTable extends Table {
  @override
  String get tableName => 'transactions';

  TextColumn get id => text()();

  /// 'income' or 'expense'
  TextColumn get type => text()();

  RealColumn get amount => real()();

  TextColumn get categoryId =>
      text().references(CategoriesTable, #id)();

  TextColumn get note => text().nullable()();

  /// User-selected date stored as epoch milliseconds (UTC midnight).
  IntColumn get date => integer()();

  /// Row creation timestamp as epoch milliseconds.
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
