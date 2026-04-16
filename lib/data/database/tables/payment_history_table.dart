import 'package:drift/drift.dart';

@DataClassName('PaymentHistoryData')
class PaymentHistoryTable extends Table {
  @override
  String get tableName => 'payment_history';

  TextColumn get id => text()();
  TextColumn get referenceId => text()(); // hutang or piutang id
  TextColumn get referenceType => text()(); // 'hutang' | 'piutang'
  RealColumn get amount => real()();
  IntColumn get paidAt => integer()(); // epoch ms
  TextColumn get catatan => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
