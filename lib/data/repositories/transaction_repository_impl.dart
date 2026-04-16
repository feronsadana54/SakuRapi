import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

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
/// Alur data (baca):
///   Provider UI mengawasi repo ini → DAO memancarkan stream query Drift →
///   [_mapRows] memetakan category_id setiap baris ke [Category] lengkap →
///   entitas domain [Transaction] dikembalikan.
///
/// Alur data (tulis):
///   UI memanggil insert/update/delete → DAO menulis ke tabel `transactions` →
///   Drift menginvalidasi stream query → [watchAll] memancar ulang → UI di-rebuild.
class TransactionRepositoryImpl implements ITransactionRepository {
  final TransactionDao _txDao;
  final CategoryDao _catDao;

  TransactionRepositoryImpl(this._txDao, this._catDao);

  /// Stream reaktif seluruh transaksi, diurutkan dari terbaru.
  /// Drift secara otomatis memancar ulang setiap kali tabel `transactions` berubah.
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
  Future<void> insert(Transaction transaction) {
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
    return _txDao.insertTransaction(companion);
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
  }

  @override
  Future<void> delete(String id) async => _txDao.deleteTransaction(id);

  // ── Mappers ──────────────────────────────────────────────────────────

  /// Mengubah daftar baris Drift mentah menjadi entitas domain [Transaction].
  ///
  /// Mengambil semua kategori sekali per batch (1 panggilan DB tanpa peduli
  /// jumlah baris) dan membangun map id→Category untuk pencarian O(1).
  /// Baris yang category_id-nya tidak ada lagi difilter secara diam-diam (orphan guard).
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
