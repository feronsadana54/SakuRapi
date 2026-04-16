import 'package:drift/drift.dart';

@DataClassName('CategoryData')
class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get iconCode => integer()();
  IntColumn get colorValue => integer()();

  /// 'income', 'expense', or 'both'
  TextColumn get type => text()();

  BoolColumn get isDefault =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
