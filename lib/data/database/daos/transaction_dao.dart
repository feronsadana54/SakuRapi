import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions_table.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Stream<List<TransactionData>> watchAll() =>
      (select(transactionsTable)
            ..orderBy([
              (t) => OrderingTerm.desc(t.date),
              (t) => OrderingTerm.desc(t.createdAt),
            ]))
          .watch();

  Future<List<TransactionData>> getByDateRange(
    int startEpochMs,
    int endEpochMs,
  ) =>
      (select(transactionsTable)
            ..where(
              (t) =>
                  t.date.isBiggerOrEqualValue(startEpochMs) &
                  t.date.isSmallerOrEqualValue(endEpochMs),
            )
            ..orderBy([
              (t) => OrderingTerm.desc(t.date),
              (t) => OrderingTerm.desc(t.createdAt),
            ]))
          .get();

  Future<TransactionData?> getById(String id) =>
      (select(transactionsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> insertTransaction(TransactionsTableCompanion entry) =>
      into(transactionsTable).insert(entry);

  /// Sisipkan transaksi hanya jika ID belum ada (untuk restore cloud).
  Future<void> insertOrIgnore(TransactionsTableCompanion entry) =>
      into(transactionsTable).insert(entry, mode: InsertMode.insertOrIgnore);

  /// Timpa record yang sudah ada dengan data terbaru dari cloud (realtime sync).
  Future<void> insertOrReplace(TransactionsTableCompanion entry) =>
      into(transactionsTable).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateTransaction(TransactionsTableCompanion entry) =>
      update(transactionsTable).replace(entry);

  Future<int> deleteTransaction(String id) =>
      (delete(transactionsTable)..where((t) => t.id.equals(id))).go();
}
