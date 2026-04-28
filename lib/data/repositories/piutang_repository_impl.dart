import 'dart:async' show unawaited;

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../core/services/sync_service.dart';
import '../../domain/entities/hutang_entity.dart';
import '../../domain/entities/piutang_entity.dart';
import '../../domain/repositories/i_piutang_repository.dart';
import '../database/app_database.dart';
import '../database/daos/piutang_dao.dart';

class PiutangRepositoryImpl implements IPiutangRepository {
  final PiutangDao _dao;
  final SyncService _sync;

  PiutangRepositoryImpl(this._dao, this._sync);

  @override
  Stream<List<PiutangEntity>> watchAll() =>
      _dao.watchAll().asyncMap(_mapRows);

  @override
  Future<List<PiutangEntity>> getAll() async {
    final rows = await _dao.getAll();
    return _mapRows(rows);
  }

  @override
  Future<PiutangEntity?> getById(String id) async {
    final row = await _dao.getById(id);
    if (row == null) return null;
    final payments = await _dao.getPaymentsForPiutang(id);
    return _toEntity(row, payments.map(_paymentToRecord).toList());
  }

  @override
  Future<void> insert(PiutangEntity piutang) async {
    const uuid = Uuid();
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = PiutangTableCompanion.insert(
      id: piutang.id.isEmpty ? uuid.v4() : piutang.id,
      namaPeminjam: piutang.namaPeminjam,
      jumlahAwal: piutang.jumlahAwal,
      sisaPiutang: piutang.sisaPiutang,
      tanggalPinjam: piutang.tanggalPinjam.millisecondsSinceEpoch,
      tanggalJatuhTempo: Value(piutang.tanggalJatuhTempo?.millisecondsSinceEpoch),
      catatan: Value(piutang.catatan),
      status: Value(piutang.status),
      createdAt: piutang.createdAt.millisecondsSinceEpoch,
      updatedAt: now,
    );
    await _dao.insertPiutang(companion);
    unawaited(_sync.upsertPiutang(piutang));
  }

  @override
  Future<void> update(PiutangEntity piutang) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = PiutangTableCompanion(
      id: Value(piutang.id),
      namaPeminjam: Value(piutang.namaPeminjam),
      jumlahAwal: Value(piutang.jumlahAwal),
      sisaPiutang: Value(piutang.sisaPiutang),
      tanggalPinjam: Value(piutang.tanggalPinjam.millisecondsSinceEpoch),
      tanggalJatuhTempo: Value(piutang.tanggalJatuhTempo?.millisecondsSinceEpoch),
      catatan: Value(piutang.catatan),
      status: Value(piutang.status),
      createdAt: Value(piutang.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(now),
    );
    await _dao.updatePiutang(companion);
    unawaited(_sync.upsertPiutang(piutang));
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deletePaymentsForPiutang(id);
    await _dao.deletePiutang(id);
    unawaited(_sync.deletePiutang(id));
  }

  @override
  Future<void> addPayment(String piutangId, PaymentRecord payment) async {
    const uuid = Uuid();
    final id = payment.id.isEmpty ? uuid.v4() : payment.id;
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final companion = PaymentHistoryTableCompanion.insert(
      id: id,
      referenceId: piutangId,
      referenceType: 'piutang',
      amount: payment.amount,
      paidAt: payment.paidAt.millisecondsSinceEpoch,
      catatan: Value(payment.catatan),
      createdAt: createdAt,
    );
    await _dao.insertPayment(companion);
    unawaited(_sync.upsertPaymentRecord(
      id: id,
      referenceId: piutangId,
      referenceType: 'piutang',
      amount: payment.amount,
      paidAt: payment.paidAt.millisecondsSinceEpoch,
      catatan: payment.catatan,
      createdAt: createdAt,
    ));
  }

  // ── Mappers ──────────────────────────────────────────────────────────────

  Future<List<PiutangEntity>> _mapRows(List<PiutangData> rows) async {
    final result = <PiutangEntity>[];
    for (final row in rows) {
      final payments = await _dao.getPaymentsForPiutang(row.id);
      result.add(_toEntity(row, payments.map(_paymentToRecord).toList()));
    }
    return result;
  }

  PiutangEntity _toEntity(PiutangData row, List<PaymentRecord> payments) =>
      PiutangEntity(
        id: row.id,
        namaPeminjam: row.namaPeminjam,
        jumlahAwal: row.jumlahAwal,
        sisaPiutang: row.sisaPiutang,
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
