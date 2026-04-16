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

  Future<int> deletePaymentsForPiutang(String piutangId) =>
      (delete(paymentHistoryTable)
            ..where((t) =>
                t.referenceId.equals(piutangId) &
                t.referenceType.equals('piutang')))
          .go();
}
