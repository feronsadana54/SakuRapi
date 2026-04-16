import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/hutang_table.dart';
import '../tables/payment_history_table.dart';

part 'hutang_dao.g.dart';

@DriftAccessor(tables: [HutangTable, PaymentHistoryTable])
class HutangDao extends DatabaseAccessor<AppDatabase> with _$HutangDaoMixin {
  HutangDao(super.db);

  // ── Hutang CRUD ───────────────────────────────────────────────────────────

  Stream<List<HutangData>> watchAll() =>
      (select(hutangTable)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<HutangData>> getAll() =>
      (select(hutangTable)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<HutangData?> getById(String id) =>
      (select(hutangTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertHutang(HutangTableCompanion entry) =>
      into(hutangTable).insert(entry);

  Future<bool> updateHutang(HutangTableCompanion entry) =>
      update(hutangTable).replace(entry);

  Future<int> deleteHutang(String id) =>
      (delete(hutangTable)..where((t) => t.id.equals(id))).go();

  // ── Payment history ───────────────────────────────────────────────────────

  Future<List<PaymentHistoryData>> getPaymentsForHutang(String hutangId) =>
      (select(paymentHistoryTable)
            ..where((t) =>
                t.referenceId.equals(hutangId) &
                t.referenceType.equals('hutang'))
            ..orderBy([(t) => OrderingTerm.desc(t.paidAt)]))
          .get();

  Future<void> insertPayment(PaymentHistoryTableCompanion entry) =>
      into(paymentHistoryTable).insert(entry);

  Future<int> deletePaymentsForHutang(String hutangId) =>
      (delete(paymentHistoryTable)
            ..where((t) =>
                t.referenceId.equals(hutangId) &
                t.referenceType.equals('hutang')))
          .go();
}
