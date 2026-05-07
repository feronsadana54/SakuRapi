// test/unit/sync/transaction_restore_test.dart
//
// Unit tests untuk perilaku TransactionRepositoryImpl saat restore cloud:
//   - Transaksi TIDAK di-drop ketika kategori-nya belum tiba (placeholder
//     "Lainnya" diberikan, sehingga UI tetap menampilkan transaksi).
//   - Stream re-emit ketika kategori akhirnya ditambahkan (memakai
//     FakeStreamController untuk memverifikasi pola subscribe ulang).
//
// Dirancang agar tidak bergantung pada Drift native sqlite — memakai fake
// DAO ringan yang cukup untuk memverifikasi mapper dan placeholder logic.
//
// Run: flutter test test/unit/sync/transaction_restore_test.dart

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/core/services/sync_service.dart';
import 'package:finance_tracker/data/database/app_database.dart';
import 'package:finance_tracker/data/database/daos/category_dao.dart';
import 'package:finance_tracker/data/database/daos/transaction_dao.dart';
import 'package:finance_tracker/data/repositories/transaction_repository_impl.dart';

class _FakeSyncService extends Fake implements SyncService {
  @override
  bool get isAvailable => false;
}

class _FakeTransactionDao extends Fake implements TransactionDao {
  final _ctrl = StreamController<List<TransactionData>>.broadcast();
  List<TransactionData> _rows = [];

  void emit(List<TransactionData> rows) {
    _rows = rows;
    _ctrl.add(List.unmodifiable(rows));
  }

  @override
  Stream<List<TransactionData>> watchAllReactive() => _ctrl.stream;

  @override
  Stream<List<TransactionData>> watchAll() => _ctrl.stream;

  @override
  Future<List<TransactionData>> getByDateRange(int s, int e) async => _rows;

  @override
  Future<TransactionData?> getById(String id) async =>
      _rows.where((r) => r.id == id).cast<TransactionData?>().firstOrNull;

  void dispose() => _ctrl.close();
}

class _FakeCategoryDao extends Fake implements CategoryDao {
  List<CategoryData> _rows = [];

  void setRows(List<CategoryData> rows) => _rows = rows;

  @override
  Future<List<CategoryData>> getAll() async => List.unmodifiable(_rows);
}

TransactionData _txRow({
  required String id,
  required String type,
  required String categoryId,
  double amount = 50000,
}) =>
    TransactionData(
      id: id,
      type: type,
      amount: amount,
      categoryId: categoryId,
      date: DateTime(2026, 4, 1).millisecondsSinceEpoch,
      createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
    );

CategoryData _catRow({
  required String id,
  required String name,
  required String type,
}) =>
    CategoryData(
      id: id,
      name: name,
      iconCode: 0xe5d3,
      colorValue: 0xFF000000,
      type: type,
      isDefault: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeTransactionDao txDao;
  late _FakeCategoryDao catDao;
  late TransactionRepositoryImpl repo;

  setUp(() {
    txDao = _FakeTransactionDao();
    catDao = _FakeCategoryDao();
    repo = TransactionRepositoryImpl(txDao, catDao, _FakeSyncService());
  });

  tearDown(() => txDao.dispose());

  test(
      'transaksi tetap muncul (placeholder "Lainnya") saat kategori belum '
      'tersedia di lokal', () async {
    catDao.setRows([]); // belum ada kategori
    final emissions = <List>[];
    final sub = repo.watchAll().listen(emissions.add);

    txDao.emit([
      _txRow(id: 'tx-1', type: 'expense', categoryId: 'kategori-belum-ada'),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(emissions, isNotEmpty);
    final list = emissions.last;
    expect(list.length, 1, reason: 'transaksi tidak boleh di-drop');
    expect(list.first.id, 'tx-1');
    expect(list.first.category.name, 'Lainnya',
        reason: 'placeholder kategori harus dipakai');
    expect(list.first.category.id, 'kategori-belum-ada',
        reason: 'placeholder mempertahankan ID asli untuk konsistensi');

    await sub.cancel();
  });

  test('stream re-emit dengan kategori yang benar setelah kategori tiba',
      () async {
    catDao.setRows([]);
    final emissions = <List>[];
    final sub = repo.watchAll().listen(emissions.add);

    txDao.emit([
      _txRow(id: 'tx-2', type: 'income', categoryId: 'cat-belakangan'),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(emissions.last.first.category.name, 'Lainnya');

    // Sekarang kategori asli tiba; trigger stream lewat emit ulang DAO.
    catDao.setRows([
      _catRow(id: 'cat-belakangan', name: 'Gaji Bulanan', type: 'income'),
    ]);
    txDao.emit([
      _txRow(id: 'tx-2', type: 'income', categoryId: 'cat-belakangan'),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(emissions.last.length, 1);
    expect(emissions.last.first.category.name, 'Gaji Bulanan',
        reason: 'kategori asli wajib menggantikan placeholder');

    await sub.cancel();
  });

  test('transaksi dengan kategori yang sudah ada tetap menggunakan kategori asli',
      () async {
    catDao.setRows([
      _catRow(id: 'cat-1', name: 'Makan & Minum', type: 'expense'),
    ]);
    final emissions = <List>[];
    final sub = repo.watchAll().listen(emissions.add);

    txDao.emit([
      _txRow(id: 'tx-3', type: 'expense', categoryId: 'cat-1'),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(emissions.last.first.category.name, 'Makan & Minum');
    expect(emissions.last.first.category.isDefault, isFalse);

    await sub.cancel();
  });
}
