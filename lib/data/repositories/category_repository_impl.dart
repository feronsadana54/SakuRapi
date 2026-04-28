import 'dart:async' show unawaited;

import 'package:uuid/uuid.dart';

import '../../core/services/sync_service.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/enums/category_type.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../database/app_database.dart';
import '../database/daos/category_dao.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  final CategoryDao _dao;
  final SyncService _sync;

  CategoryRepositoryImpl(this._dao, this._sync);

  @override
  Stream<List<Category>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toEntity).toList());

  @override
  Future<List<Category>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> insert(Category category) async {
    const uuid = Uuid();
    final id = category.id.isEmpty ? uuid.v4() : category.id;
    final companion = CategoriesTableCompanion.insert(
      id: id,
      name: category.name,
      iconCode: category.iconCode,
      colorValue: category.colorValue,
      type: category.type.value,
    );
    await _dao.insertCategory(companion);
    // Hanya kategori kustom yang disinkronisasi (isDefault=false di-cek dalam upsertCategory)
    unawaited(_sync.upsertCategory(
      Category(
        id: id,
        name: category.name,
        iconCode: category.iconCode,
        colorValue: category.colorValue,
        type: category.type,
        isDefault: category.isDefault,
      ),
    ));
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteCategory(id);
    unawaited(_sync.deleteCategory(id));
  }

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
