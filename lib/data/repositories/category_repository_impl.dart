import 'package:uuid/uuid.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/enums/category_type.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../database/app_database.dart';
import '../database/daos/category_dao.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  final CategoryDao _dao;

  CategoryRepositoryImpl(this._dao);

  @override
  Stream<List<Category>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toEntity).toList());

  @override
  Future<List<Category>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> insert(Category category) {
    const uuid = Uuid();
    final companion = CategoriesTableCompanion.insert(
      id: category.id.isEmpty ? uuid.v4() : category.id,
      name: category.name,
      iconCode: category.iconCode,
      colorValue: category.colorValue,
      type: category.type.value,
    );
    return _dao.insertCategory(companion);
  }

  @override
  Future<void> delete(String id) async => _dao.deleteCategory(id);

  // ── Mapper ──────────────────────────────────────────────────────────

  Category _toEntity(CategoryData row) => Category(
        id: row.id,
        name: row.name,
        iconCode: row.iconCode,
        colorValue: row.colorValue,
        type: CategoryType.fromValue(row.type),
        isDefault: row.isDefault,
      );
}
