import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/payment_history_table.dart';
import '../tables/piutang_table.dart';

part 'piutang_dao.g.dart';

@DriftAccessor(tables: [PiutangTable, PaymentHistoryTable])
class PiutangDao extends DatabaseAccessor<AppDatabase> with _$PiutangDaoMixin {
  PiutangDao(super.db);

  // ── Piutang CRUD ──────────────────────────────────────────────────────────

  Stream<List<PiutangData>> watchAll() =>
      (select(piutangTable)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<PiutangData>> getAll() =>
      (select(piutangTable)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<PiutangData?> getById(String id) =>
      (select(piutangTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertPiutang(PiutangTableCompanion entry) =>
      into(piutangTable).insert(entry);

  /// Sisipkan piutang hanya jika ID belum ada — aman dari duplikasi saat restore.
  Future<void> insertOrIgnore(PiutangTableCompanion entry) =>
      into(piutangTable).insert(entry, mode: InsertMode.insertOrIgnore);

  Future<bool> updatePiutang(PiutangTableCompanion entry) =>
      update(piutangTable).replace(entry);

  Future<int> deletePiutang(String id) =>
      (delete(piutangTable)..where((t) => t.id.equals(id))).go();

  // ── Payment history ───────────────────────────────────────────────────────

  Future<List<PaymentHistoryData>> getPaymentsForPiutang(String piutangId) =>
      (select(paymentHistoryTable)
            ..where((t) =>
                t.referenceId.equals(piutangId) &
                t.referenceType.equals('piutang'))
            ..orderBy([(t) => OrderingTerm.desc(t.paidAt)]))
          .get();

  Future<void> insertPayment(PaymentHistoryTableCompanion entry) =>
      into(paymentHistoryTable).insert(entry);

  /// Sisipkan record pembayaran hanya jika ID belum ada (untuk restore cloud).
  Future<void> insertPaymentOrIgnore(PaymentHistoryTableCompanion entry) =>
      into(paymentHistoryTable)
          .insert(entry, mode: InsertMode.insertOrIgnore);

  Future<int> deletePaymentsForPiutang(String piutangId) =>
      (delete(paymentHistoryTable)
            ..where((t) =>
                t.referenceId.equals(piutangId) &
                t.referenceType.equals('piutang')))
          .go();
}
