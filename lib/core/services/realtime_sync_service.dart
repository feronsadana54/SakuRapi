// Sembunyikan Firestore 'Transaction' agar tidak bentrok dengan
// domain entity 'Transaction' kita.
import 'dart:async';
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:drift/drift.dart' show Value;

import '../../data/database/app_database.dart';
import '../../data/database/daos/category_dao.dart';
import '../../data/database/daos/hutang_dao.dart';
import '../../data/database/daos/piutang_dao.dart';
import '../../data/database/daos/transaction_dao.dart';

/// Mengelola listener Firestore realtime untuk sinkronisasi multi-perangkat.
///
/// **Cara kerja:**
///   Saat [startListening] dipanggil, service ini berlangganan ke 5 koleksi
///   Firestore milik pengguna. Setiap perubahan — baik dari perangkat lain
///   maupun dari server setelah konfirmasi — otomatis ditulis ke SQLite lokal.
///
/// **Pencegahan write-back loop:**
///   Listener menggunakan `includeMetadataChanges: true` dan mengabaikan
///   perubahan dengan `hasPendingWrites == true`. Ini berarti echo dari
///   tulisan lokal yang belum dikonfirmasi server dilewati, sehingga
///   SQLite tidak ditulis ulang secara tidak perlu.
///
/// **Strategi merge per koleksi:**
///   - transactions  : `added` → INSERT OR IGNORE; `modified` → INSERT OR REPLACE
///   - categories    : `added` → INSERT OR IGNORE; `modified` → INSERT OR REPLACE
///   - hutang        : last-write-wins by `updatedAt`
///   - piutang       : last-write-wins by `updatedAt`
///   - payment_history: INSERT OR IGNORE (immutable setelah dicatat)
///
/// **Bypass repository:**
///   Menulis langsung ke DAO agar tidak memicu re-upload ke Firestore
///   (repository menggunakan `unawaited(sync.upsert*())` pada setiap write).
///
/// **Lifecycle:**
///   - [startListening] dipanggil saat login berhasil (lihat _RealtimeSyncHandler di app.dart)
///   - [stopListening] dipanggil saat logout
///   - Provider melakukan [stopListening] otomatis saat dispose
class RealtimeSyncService {
  final FirebaseFirestore _db;
  final CategoryDao _categoryDao;
  final TransactionDao _transactionDao;
  final HutangDao _hutangDao;
  final PiutangDao _piutangDao;

  String? _activeUserId;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subs =
      [];

  static const _tag = 'RealtimeSyncService';

  RealtimeSyncService({
    FirebaseFirestore? firestore,
    required CategoryDao categoryDao,
    required TransactionDao transactionDao,
    required HutangDao hutangDao,
    required PiutangDao piutangDao,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _categoryDao = categoryDao,
        _transactionDao = transactionDao,
        _hutangDao = hutangDao,
        _piutangDao = piutangDao;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  /// Mulai mendengarkan 5 koleksi Firestore milik [userId].
  ///
  /// Jika listener untuk [userId] yang sama sudah aktif, metode ini tidak
  /// melakukan apa-apa. Jika userId berbeda (misalnya re-login akun lain),
  /// listener lama dihentikan terlebih dahulu.
  void startListening(String userId) {
    if (_activeUserId == userId && _subs.isNotEmpty) return;
    stopListening();
    _activeUserId = userId;

    final userRef = _db.collection('users').doc(userId);

    _subs.addAll([
      userRef
          .collection('transactions')
          .snapshots(includeMetadataChanges: true)
          .listen(
            _onTransactionSnapshot,
            onError: (Object e) =>
                dev.log('transactions error: $e', name: _tag, level: 900),
          ),
      userRef
          .collection('categories')
          .snapshots(includeMetadataChanges: true)
          .listen(
            _onCategorySnapshot,
            onError: (Object e) =>
                dev.log('categories error: $e', name: _tag, level: 900),
          ),
      userRef
          .collection('hutang')
          .snapshots(includeMetadataChanges: true)
          .listen(
            _onHutangSnapshot,
            onError: (Object e) =>
                dev.log('hutang error: $e', name: _tag, level: 900),
          ),
      userRef
          .collection('piutang')
          .snapshots(includeMetadataChanges: true)
          .listen(
            _onPiutangSnapshot,
            onError: (Object e) =>
                dev.log('piutang error: $e', name: _tag, level: 900),
          ),
      userRef
          .collection('payment_history')
          .snapshots(includeMetadataChanges: true)
          .listen(
            _onPaymentSnapshot,
            onError: (Object e) =>
                dev.log('payment_history error: $e', name: _tag, level: 900),
          ),
    ]);

    dev.log('Listener aktif untuk uid=$userId (5 koleksi)', name: _tag);
  }

  /// Hentikan semua listener Firestore. Dipanggil saat logout atau dispose.
  void stopListening() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    if (_activeUserId != null) {
      dev.log('Listener dihentikan (uid=$_activeUserId)', name: _tag);
    }
    _activeUserId = null;
  }

  // ── Snapshot handlers ────────────────────────────────────────────────────────

  Future<void> _onTransactionSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot) async {
    final changes = snapshot.docChanges
        .where((c) => !c.doc.metadata.hasPendingWrites)
        .toList();
    if (changes.isEmpty) return;
    final sw = Stopwatch()..start();
    for (final change in changes) {
      try {
        if (change.type == DocumentChangeType.removed) {
          await _transactionDao.deleteTransaction(change.doc.id);
        } else {
          final data = change.doc.data();
          if (data == null) continue;
          final companion = TransactionsTableCompanion.insert(
            id: data['id'] as String,
            type: data['type'] as String,
            amount: (data['amount'] as num).toDouble(),
            categoryId: data['categoryId'] as String,
            note: Value(data['note'] as String?),
            date: data['date'] as int,
            createdAt: data['createdAt'] as int,
          );
          // added: jangan timpa data lokal yang baru dibuat;
          // modified: terima versi cloud (multi-device edit).
          if (change.type == DocumentChangeType.added) {
            await _transactionDao.insertOrIgnore(companion);
          } else {
            await _transactionDao.insertOrReplace(companion);
          }
        }
      } catch (e) {
        dev.log('Error handle transaction change: $e',
            name: _tag, level: 900);
      }
    }
    dev.log(
      'transactions: ${changes.length} perubahan selesai dalam ${sw.elapsedMilliseconds}ms',
      name: _tag,
    );
  }

  Future<void> _onCategorySnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot) async {
    final changes = snapshot.docChanges
        .where((c) => !c.doc.metadata.hasPendingWrites)
        .toList();
    if (changes.isEmpty) return;
    final sw = Stopwatch()..start();
    for (final change in changes) {
      try {
        if (change.type == DocumentChangeType.removed) {
          await _categoryDao.deleteCategory(change.doc.id);
        } else {
          final data = change.doc.data();
          if (data == null) continue;
          final isDefault = data['isDefault'] as bool? ?? false;
          if (isDefault) continue; // kategori sistem dikelola lokal, bukan cloud
          final companion = CategoriesTableCompanion.insert(
            id: data['id'] as String,
            name: data['name'] as String,
            iconCode: data['iconCode'] as int,
            colorValue: data['colorValue'] as int,
            type: data['type'] as String,
          );
          if (change.type == DocumentChangeType.added) {
            await _categoryDao.insertOrIgnore(companion);
          } else {
            await _categoryDao.insertOrReplace(companion);
          }
        }
      } catch (e) {
        dev.log('Error handle category change: $e', name: _tag, level: 900);
      }
    }
    dev.log(
      'categories: ${changes.length} perubahan selesai dalam ${sw.elapsedMilliseconds}ms',
      name: _tag,
    );
  }

  Future<void> _onHutangSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot) async {
    final changes = snapshot.docChanges
        .where((c) => !c.doc.metadata.hasPendingWrites)
        .toList();
    if (changes.isEmpty) return;
    final sw = Stopwatch()..start();
    for (final change in changes) {
      try {
        if (change.type == DocumentChangeType.removed) {
          await _hutangDao.deleteHutang(change.doc.id);
        } else {
          final data = change.doc.data();
          if (data == null) continue;
          await _upsertHutangFromCloud(data);
        }
      } catch (e) {
        dev.log('Error handle hutang change: $e', name: _tag, level: 900);
      }
    }
    dev.log(
      'hutang: ${changes.length} perubahan selesai dalam ${sw.elapsedMilliseconds}ms',
      name: _tag,
    );
  }

  Future<void> _onPiutangSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot) async {
    final changes = snapshot.docChanges
        .where((c) => !c.doc.metadata.hasPendingWrites)
        .toList();
    if (changes.isEmpty) return;
    final sw = Stopwatch()..start();
    for (final change in changes) {
      try {
        if (change.type == DocumentChangeType.removed) {
          await _piutangDao.deletePiutang(change.doc.id);
        } else {
          final data = change.doc.data();
          if (data == null) continue;
          await _upsertPiutangFromCloud(data);
        }
      } catch (e) {
        dev.log('Error handle piutang change: $e', name: _tag, level: 900);
      }
    }
    dev.log(
      'piutang: ${changes.length} perubahan selesai dalam ${sw.elapsedMilliseconds}ms',
      name: _tag,
    );
  }

  Future<void> _onPaymentSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot) async {
    final changes = snapshot.docChanges
        .where((c) => !c.doc.metadata.hasPendingWrites)
        .toList();
    if (changes.isEmpty) return;
    final sw = Stopwatch()..start();
    for (final change in changes) {
      try {
        if (change.type == DocumentChangeType.removed) {
          await _hutangDao.deletePayment(change.doc.id);
        } else {
          final data = change.doc.data();
          if (data == null) continue;
          final companion = PaymentHistoryTableCompanion.insert(
            id: data['id'] as String,
            referenceId: data['referenceId'] as String,
            referenceType: data['referenceType'] as String,
            amount: (data['amount'] as num).toDouble(),
            paidAt: data['paidAt'] as int,
            catatan: Value(data['catatan'] as String?),
            createdAt: data['createdAt'] as int,
          );
          // Pembayaran bersifat immutable — INSERT OR IGNORE untuk semua event.
          await _hutangDao.insertPaymentOrIgnore(companion);
        }
      } catch (e) {
        dev.log('Error handle payment change: $e', name: _tag, level: 900);
      }
    }
    dev.log(
      'payment_history: ${changes.length} perubahan selesai dalam ${sw.elapsedMilliseconds}ms',
      name: _tag,
    );
  }

  // ── Last-write-wins helpers ──────────────────────────────────────────────────

  /// Upsert hutang dari cloud ke SQLite dengan strategi last-write-wins by updatedAt.
  Future<void> _upsertHutangFromCloud(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    final cloudUpdatedAt = _parseTimestamp(data['updatedAt']);
    final existing = await _hutangDao.getById(id);

    if (existing == null) {
      await _hutangDao.insertOrIgnore(HutangTableCompanion.insert(
        id: id,
        namaKreditur: data['namaKreditur'] as String,
        jumlahAwal: (data['jumlahAwal'] as num).toDouble(),
        sisaHutang: (data['sisaHutang'] as num).toDouble(),
        tanggalPinjam: data['tanggalPinjam'] as int,
        tanggalJatuhTempo: Value(data['tanggalJatuhTempo'] as int?),
        catatan: Value(data['catatan'] as String?),
        status: Value(data['status'] as String? ?? 'aktif'),
        createdAt: data['createdAt'] as int,
        updatedAt: cloudUpdatedAt,
      ));
    } else if (cloudUpdatedAt > existing.updatedAt) {
      // Cloud lebih baru → perbarui lokal
      await _hutangDao.updateHutang(HutangTableCompanion(
        id: Value(id),
        namaKreditur: Value(data['namaKreditur'] as String),
        jumlahAwal: Value((data['jumlahAwal'] as num).toDouble()),
        sisaHutang: Value((data['sisaHutang'] as num).toDouble()),
        tanggalPinjam: Value(data['tanggalPinjam'] as int),
        tanggalJatuhTempo: Value(data['tanggalJatuhTempo'] as int?),
        catatan: Value(data['catatan'] as String?),
        status: Value(data['status'] as String? ?? 'aktif'),
        createdAt: Value(data['createdAt'] as int),
        updatedAt: Value(cloudUpdatedAt),
      ));
    }
    // cloudUpdatedAt <= existing.updatedAt → lokal lebih baru, biarkan.
  }

  /// Upsert piutang dari cloud ke SQLite dengan strategi last-write-wins by updatedAt.
  Future<void> _upsertPiutangFromCloud(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    final cloudUpdatedAt = _parseTimestamp(data['updatedAt']);
    final existing = await _piutangDao.getById(id);

    if (existing == null) {
      await _piutangDao.insertOrIgnore(PiutangTableCompanion.insert(
        id: id,
        namaPeminjam: data['namaPeminjam'] as String,
        jumlahAwal: (data['jumlahAwal'] as num).toDouble(),
        sisaPiutang: (data['sisaPiutang'] as num).toDouble(),
        tanggalPinjam: data['tanggalPinjam'] as int,
        tanggalJatuhTempo: Value(data['tanggalJatuhTempo'] as int?),
        catatan: Value(data['catatan'] as String?),
        status: Value(data['status'] as String? ?? 'aktif'),
        createdAt: data['createdAt'] as int,
        updatedAt: cloudUpdatedAt,
      ));
    } else if (cloudUpdatedAt > existing.updatedAt) {
      await _piutangDao.updatePiutang(PiutangTableCompanion(
        id: Value(id),
        namaPeminjam: Value(data['namaPeminjam'] as String),
        jumlahAwal: Value((data['jumlahAwal'] as num).toDouble()),
        sisaPiutang: Value((data['sisaPiutang'] as num).toDouble()),
        tanggalPinjam: Value(data['tanggalPinjam'] as int),
        tanggalJatuhTempo: Value(data['tanggalJatuhTempo'] as int?),
        catatan: Value(data['catatan'] as String?),
        status: Value(data['status'] as String? ?? 'aktif'),
        createdAt: Value(data['createdAt'] as int),
        updatedAt: Value(cloudUpdatedAt),
      ));
    }
  }

  /// Mengubah field `updatedAt` Firestore (Timestamp atau int) ke epoch milliseconds.
  int _parseTimestamp(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }
}
