import 'dart:async' show unawaited;

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../core/services/sync_service.dart';
import '../../domain/entities/hutang_entity.dart';
import '../../domain/repositories/i_hutang_repository.dart';
import '../database/app_database.dart';
import '../database/daos/hutang_dao.dart';

class HutangRepositoryImpl implements IHutangRepository {
  final HutangDao _dao;
  final SyncService _sync;

  HutangRepositoryImpl(this._dao, this._sync);

  @override
  Stream<List<HutangEntity>> watchAll() =>
      _dao.watchAll().asyncMap(_mapRows);

  @override
  Future<List<HutangEntity>> getAll() async {
    final rows = await _dao.getAll();
    return _mapRows(rows);
  }

  @override
  Future<HutangEntity?> getById(String id) async {
    final row = await _dao.getById(id);
    if (row == null) return null;
    final payments = await _dao.getPaymentsForHutang(id);
    return _toEntity(row, payments.map(_paymentToRecord).toList());
  }

  @override
  Future<void> insert(HutangEntity hutang) async {
    const uuid = Uuid();
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = HutangTableCompanion.insert(
      id: hutang.id.isEmpty ? uuid.v4() : hutang.id,
      namaKreditur: hutang.namaKreditur,
      jumlahAwal: hutang.jumlahAwal,
      sisaHutang: hutang.sisaHutang,
      tanggalPinjam: hutang.tanggalPinjam.millisecondsSinceEpoch,
      tanggalJatuhTempo: Value(hutang.tanggalJatuhTempo?.millisecondsSinceEpoch),
      catatan: Value(hutang.catatan),
      status: Value(hutang.status),
      createdAt: hutang.createdAt.millisecondsSinceEpoch,
      updatedAt: now,
    );
    await _dao.insertHutang(companion);
    unawaited(_sync.upsertHutang(hutang));
  }

  @override
  Future<void> update(HutangEntity hutang) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = HutangTableCompanion(
      id: Value(hutang.id),
      namaKreditur: Value(hutang.namaKreditur),
      jumlahAwal: Value(hutang.jumlahAwal),
      sisaHutang: Value(hutang.sisaHutang),
      tanggalPinjam: Value(hutang.tanggalPinjam.millisecondsSinceEpoch),
      tanggalJatuhTempo: Value(hutang.tanggalJatuhTempo?.millisecondsSinceEpoch),
      catatan: Value(hutang.catatan),
      status: Value(hutang.status),
      createdAt: Value(hutang.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(now),
    );
    await _dao.updateHutang(companion);
    unawaited(_sync.upsertHutang(hutang));
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deletePaymentsForHutang(id);
    await _dao.deleteHutang(id);
    unawaited(_sync.deleteHutang(id));
  }

  @override
  Future<void> addPayment(String hutangId, PaymentRecord payment) async {
    const uuid = Uuid();
    final id = payment.id.isEmpty ? uuid.v4() : payment.id;
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final companion = PaymentHistoryTableCompanion.insert(
      id: id,
      referenceId: hutangId,
      referenceType: 'hutang',
      amount: payment.amount,
      paidAt: payment.paidAt.millisecondsSinceEpoch,
      catatan: Value(payment.catatan),
      createdAt: createdAt,
    );
    await _dao.insertPayment(companion);
    unawaited(_sync.upsertPaymentRecord(
      id: id,
      referenceId: hutangId,
      referenceType: 'hutang',
      amount: payment.amount,
      paidAt: payment.paidAt.millisecondsSinceEpoch,
      catatan: payment.catatan,
      createdAt: createdAt,
    ));
  }

  // ── Mappers ──────────────────────────────────────────────────────────────

  Future<List<HutangEntity>> _mapRows(List<HutangData> rows) async {
    final result = <HutangEntity>[];
    for (final row in rows) {
      final payments = await _dao.getPaymentsForHutang(row.id);
      result.add(_toEntity(row, payments.map(_paymentToRecord).toList()));
    }
    return result;
  }

  HutangEntity _toEntity(HutangData row, List<PaymentRecord> payments) =>
      HutangEntity(
        id: row.id,
        namaKreditur: row.namaKreditur,
        jumlahAwal: row.jumlahAwal,
        sisaHutang: row.sisaHutang,
        tanggalPinjam: DateTime.fromMillisecondsSinceEpoch(row.tanggalPinjam),
        tanggalJatuhTempo: row.tanggalJatuhTempo != null
            ? DateTime.fromMillisecondsSinceEpoch(row.tanggalJatuhTempo!)
            : null,
        catatan: row.catatan,
        status: row.status,
        riwayatPembayaran: payments,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      );

  PaymentRecord _paymentToRecord(PaymentHistoryData row) => PaymentRecord(
        id: row.id,
        amount: row.amount,
        paidAt: DateTime.fromMillisecondsSinceEpoch(row.paidAt),
        catatan: row.catatan,
      );
}
