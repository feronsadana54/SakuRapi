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

  Future<CategoryData?> getById(String id) =>
      (select(categoriesTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> insertCategory(CategoriesTableCompanion entry) =>
      into(categoriesTable).insert(entry);

  /// Sisipkan kategori hanya jika ID belum ada (untuk restore cloud).
  Future<void> insertOrIgnore(CategoriesTableCompanion entry) =>
      into(categoriesTable).insert(entry, mode: InsertMode.insertOrIgnore);

  /// Timpa kategori kustom yang sudah ada dengan data terbaru dari cloud.
  Future<void> insertOrReplace(CategoriesTableCompanion entry) =>
      into(categoriesTable).insert(entry, mode: InsertMode.insertOrReplace);

  Future<int> deleteCategory(String id) =>
      (delete(categoriesTable)..where((t) => t.id.equals(id))).go();
}
