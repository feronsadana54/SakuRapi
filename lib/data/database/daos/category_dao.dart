import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Stream<List<CategoryData>> watchAll() =>
      (select(categoriesTable)
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<List<CategoryData>> getAll() =>
      (select(categoriesTable)
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<void> insertCategory(CategoriesTableCompanion entry) =>
      into(categoriesTable).insert(entry);

  Future<int> deleteCategory(String id) =>
      (delete(categoriesTable)..where((t) => t.id.equals(id))).go();
}
