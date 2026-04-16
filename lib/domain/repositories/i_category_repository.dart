import '../entities/category_entity.dart';

abstract interface class ICategoryRepository {
  Stream<List<Category>> watchAll();

  Future<List<Category>> getAll();

  Future<void> insert(Category category);

  Future<void> delete(String id);
}
