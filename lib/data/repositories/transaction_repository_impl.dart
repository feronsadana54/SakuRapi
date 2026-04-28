import 'dart:async' show unawaited;

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../core/services/sync_service.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/enums/category_type.dart';
import '../../domain/enums/transaction_type.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../database/app_database.dart';
import '../database/daos/category_dao.dart';
import '../database/daos/transaction_dao.dart';

/// Implementasi konkret [ITransactionRepository] berbasis Drift SQLite.
///
/// Setiap operasi tulis juga memicu sinkronisasi ke Firestore via [SyncService]
/// secara fire-and-forget (tidak memblokir UI). Jika sync gagal, data lokal
/// SQLite tetap aman — sync dicoba lagi saat operasi berikutnya.
class TransactionRepositoryImpl implements ITransactionRepository {
  final TransactionDao _txDao;
  final CategoryDao _catDao;
  final SyncService _sync;

  TransactionRepositoryImpl(this._txDao, this._catDao, this._sync);

  @override
  Stream<List<Transaction>> watchAll() => _txDao.watchAll().asyncMap(_mapRows);

  @override
  Future<List<Transaction>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final rows = await _txDao.getByDateRange(
      startDate.millisecondsSinceEpoch,
      endDate.millisecondsSinceEpoch,
    );
    return _mapRows(rows);
  }

  @override
  Future<Transaction?> getById(String id) async {
    final row = await _txDao.getById(id);
    if (row == null) return null;
    final cats = await _catDao.getAll();
    final catRow = cats.firstWhere((c) => c.id == row.categoryId);
    return _toEntity(row, _catRowToEntity(catRow));
  }

  @override
  Future<void> insert(Transaction transaction) async {
    const uuid = Uuid();
    final companion = TransactionsTableCompanion.insert(
      id: transaction.id.isEmpty ? uuid.v4() : transaction.id,
      type: transaction.type.value,
      amount: transaction.amount,
      categoryId: transaction.category.id,
      note: Value(transaction.note),
      date: transaction.date.millisecondsSinceEpoch,
      createdAt: transaction.createdAt.millisecondsSinceEpoch,
    );
    await _txDao.insertTransaction(companion);
    unawaited(_sync.upsertTransaction(transaction));
  }

  @override
  Future<void> update(Transaction transaction) async {
    final companion = TransactionsTableCompanion(
      id: Value(transaction.id),
      type: Value(transaction.type.value),
      amount: Value(transaction.amount),
      categoryId: Value(transaction.category.id),
      note: Value(transaction.note),
      date: Value(transaction.date.millisecondsSinceEpoch),
      createdAt: Value(transaction.createdAt.millisecondsSinceEpoch),
    );
    await _txDao.updateTransaction(companion);
    unawaited(_sync.upsertTransaction(transaction));
  }

  @override
  Future<void> delete(String id) async {
    await _txDao.deleteTransaction(id);
    unawaited(_sync.deleteTransaction(id));
  }

  // ── Mappers ──────────────────────────────────────────────────────────

  Future<List<Transaction>> _mapRows(List<TransactionData> rows) async {
    if (rows.isEmpty) return [];
    final catRows = await _catDao.getAll();
    final catMap = {for (final c in catRows) c.id: _catRowToEntity(c)};
    return rows
        .where((r) => catMap.containsKey(r.categoryId))
        .map((r) => _toEntity(r, catMap[r.categoryId]!))
        .toList();
  }

  Transaction _toEntity(TransactionData row, Category category) => Transaction(
        id: row.id,
        type: TransactionType.fromValue(row.type),
        amount: row.amount,
        category: category,
        note: row.note,
        date: DateTime.fromMillisecondsSinceEpoch(row.date),
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      );

  Category _catRowToEntity(CategoryData row) => Category(
        id: row.id,
        name: row.name,
        iconCode: row.iconCode,
        colorValue: row.colorValue,
        type: CategoryType.fromValue(row.type),
        isDefault: row.isDefault,
      );
}
