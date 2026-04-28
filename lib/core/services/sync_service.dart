// Sembunyikan Firestore 'Transaction' agar tidak bentrok dengan
// domain entity 'Transaction' kita di transaction_entity.dart.
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/entities/hutang_entity.dart';
import '../../domain/entities/piutang_entity.dart';
import '../../domain/entities/transaction_entity.dart';
/// Layanan sinkronisasi data pengguna ke Firestore Cloud (write-only).
///
/// **Kapan aktif:**
///   [isAvailable] == true jika pengguna login dengan Google atau Email Link
///   (mode = 'google' | 'emailLink' di SharedPreferences).
///   Guest user (mode='guest') tidak pernah sync.
///
/// **Lazy userId** — userId dan auth mode dibaca langsung dari SharedPreferences
/// setiap kali [isAvailable] diperiksa. Ini memastikan SyncService otomatis
/// aktif setelah login *tanpa* perlu recreate provider.
///
/// **Toleransi error** — semua operasi dibungkus try/catch. Sync gagal tidak
/// pernah mengganggu operasi SQLite lokal.
///
/// Struktur data Firestore:
///   users/{userId}/transactions/{txId}
///   users/{userId}/hutang/{hutangId}
///   users/{userId}/piutang/{piutangId}
///   users/{userId}/categories/{categoryId}    ← hanya kategori kustom
///   users/{userId}/payment_history/{paymentId}
class SyncService {
  final FirebaseFirestore _db;
  final SharedPreferences _prefs;

  static const _keyAuthId = 'saku_auth_id';
  static const _keyAuthMode = 'saku_auth_mode';

  SyncService({FirebaseFirestore? firestore, required SharedPreferences prefs})
      : _db = firestore ?? FirebaseFirestore.instance,
        _prefs = prefs;

  /// Dibaca lazy setiap kali diakses — otomatis terupdate setelah login Google.
  String? get _userId => _prefs.getString(_keyAuthId);

  /// Sync aktif untuk pengguna Google dan Email Link.
  /// Guest user (mode='guest') tidak pernah sync meski userId non-null.
  bool get isAvailable {
    final mode = _prefs.getString(_keyAuthMode);
    return _userId != null && (mode == 'google' || mode == 'emailLink');
  }

  // ── Transaksi ─────────────────────────────────────────────────────────────

  /// Menyimpan satu transaksi ke Firestore, sekaligus memastikan kategorinya ada.
  ///
  /// Kategori dan transaksi ditulis dalam satu WriteBatch sehingga atomik:
  /// keduanya berhasil atau keduanya gagal. Ini menjamin collections
  /// `categories` selalu terisi sehingga restore ke perangkat baru dapat
  /// mencocokkan transaksi berdasarkan categoryId tanpa bergantung pada fallback.
  Future<void> upsertTransaction(Transaction tx) async {
    if (!isAvailable) return;
    try {
      final batch = _db.batch();
      batch.set(_userCollection('categories').doc(tx.category.id), {
        'id': tx.category.id,
        'name': tx.category.name,
        'iconCode': tx.category.iconCode,
        'colorValue': tx.category.colorValue,
        'type': tx.category.type.value,
        'isDefault': tx.category.isDefault,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(_userCollection('transactions').doc(tx.id), {
        'id': tx.id,
        'type': tx.type.value,
        'amount': tx.amount,
        'categoryId': tx.category.id,
        'categoryName': tx.category.name,
        'note': tx.note,
        'date': tx.date.millisecondsSinceEpoch,
        'createdAt': tx.createdAt.millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (_) {
      // Sync gagal: data lokal tetap aman.
    }
  }

  /// Menghapus transaksi dari Firestore.
  Future<void> deleteTransaction(String id) async {
    if (!isAvailable) return;
    try {
      await _userCollection('transactions').doc(id).delete();
    } catch (_) {}
  }

  // ── Hutang ────────────────────────────────────────────────────────────────

  /// Menyimpan/memperbarui record hutang ke Firestore dari entitas domain.
  Future<void> upsertHutang(HutangEntity hutang) async {
    if (!isAvailable) return;
    try {
      await _userCollection('hutang').doc(hutang.id).set({
        'id': hutang.id,
        'namaKreditur': hutang.namaKreditur,
        'jumlahAwal': hutang.jumlahAwal,
        'sisaHutang': hutang.sisaHutang,
        'tanggalPinjam': hutang.tanggalPinjam.millisecondsSinceEpoch,
        'tanggalJatuhTempo': hutang.tanggalJatuhTempo?.millisecondsSinceEpoch,
        'catatan': hutang.catatan,
        'status': hutang.status,
        'createdAt': hutang.createdAt.millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Menghapus record hutang dari Firestore.
  Future<void> deleteHutang(String id) async {
    if (!isAvailable) return;
    try {
      await _userCollection('hutang').doc(id).delete();
    } catch (_) {}
  }

  // ── Piutang ───────────────────────────────────────────────────────────────

  /// Menyimpan/memperbarui record piutang ke Firestore dari entitas domain.
  Future<void> upsertPiutang(PiutangEntity piutang) async {
    if (!isAvailable) return;
    try {
      await _userCollection('piutang').doc(piutang.id).set({
        'id': piutang.id,
        'namaPeminjam': piutang.namaPeminjam,
        'jumlahAwal': piutang.jumlahAwal,
        'sisaPiutang': piutang.sisaPiutang,
        'tanggalPinjam': piutang.tanggalPinjam.millisecondsSinceEpoch,
        'tanggalJatuhTempo': piutang.tanggalJatuhTempo?.millisecondsSinceEpoch,
        'catatan': piutang.catatan,
        'status': piutang.status,
        'createdAt': piutang.createdAt.millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Menghapus record piutang dari Firestore.
  Future<void> deletePiutang(String id) async {
    if (!isAvailable) return;
    try {
      await _userCollection('piutang').doc(id).delete();
    } catch (_) {}
  }

  // ── Kategori kustom ───────────────────────────────────────────────────────

  /// Menyimpan kategori kustom ke Firestore.
  /// Kategori default (isDefault=true) tidak disinkronisasi.
  Future<void> upsertCategory(Category category) async {
    if (!isAvailable) return;
    if (category.isDefault) return; // hanya kategori kustom
    try {
      await _userCollection('categories').doc(category.id).set({
        'id': category.id,
        'name': category.name,
        'iconCode': category.iconCode,
        'colorValue': category.colorValue,
        'type': category.type.value,
        'isDefault': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Menghapus kategori kustom dari Firestore.
  Future<void> deleteCategory(String id) async {
    if (!isAvailable) return;
    try {
      await _userCollection('categories').doc(id).delete();
    } catch (_) {}
  }

  // ── Riwayat pembayaran ────────────────────────────────────────────────────

  /// Menyimpan satu record pembayaran hutang/piutang ke Firestore.
  Future<void> upsertPaymentRecord({
    required String id,
    required String referenceId,
    required String referenceType,
    required double amount,
    required int paidAt,
    String? catatan,
    required int createdAt,
  }) async {
    if (!isAvailable) return;
    try {
      await _userCollection('payment_history').doc(id).set({
        'id': id,
        'referenceId': referenceId,
        'referenceType': referenceType,
        'amount': amount,
        'paidAt': paidAt,
        'catatan': catatan,
        'createdAt': createdAt,
      });
    } catch (_) {}
  }

  // ── Fetch dari Cloud (untuk restore data saat login di perangkat baru) ────

  /// Mengambil semua transaksi pengguna dari Firestore.
  Future<List<Map<String, dynamic>>> fetchAllTransactions() async {
    if (!isAvailable) return [];
    try {
      final snapshot = await _userCollection('transactions').get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Mengambil semua hutang pengguna dari Firestore.
  Future<List<Map<String, dynamic>>> fetchAllHutang() async {
    if (!isAvailable) return [];
    try {
      final snapshot = await _userCollection('hutang').get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Mengambil semua piutang pengguna dari Firestore.
  Future<List<Map<String, dynamic>>> fetchAllPiutang() async {
    if (!isAvailable) return [];
    try {
      final snapshot = await _userCollection('piutang').get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Mengambil semua kategori kustom pengguna dari Firestore.
  Future<List<Map<String, dynamic>>> fetchAllCategories() async {
    if (!isAvailable) return [];
    try {
      final snapshot = await _userCollection('categories').get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Mengambil semua riwayat pembayaran pengguna dari Firestore.
  Future<List<Map<String, dynamic>>> fetchAllPaymentHistory() async {
    if (!isAvailable) return [];
    try {
      final snapshot = await _userCollection('payment_history').get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Migrasi data tamu ke cloud ────────────────────────────────────────────

  /// Mengunggah semua data lokal pengguna tamu ke Firestore setelah mereka
  /// berhasil upgrade ke akun Google.
  ///
  /// **Strategi merge**: "local wins" — setiap record ditulis (upsert) ke Firestore
  /// dengan ID yang sama. Jika akun Google sudah memiliki data dari sebelumnya
  /// (login di perangkat lain), record dengan ID yang sama akan di-overwrite dengan
  /// versi lokal; record dengan ID berbeda akan ditambahkan di sisi cloud.
  ///
  /// **Optimasi batch**: Semua dokumen dikumpulkan terlebih dahulu lalu dikirim
  /// dalam batch Firestore (maks 500 per batch). Ini jauh lebih cepat daripada
  /// sequential individual writes karena mengurangi round-trip jaringan dari N
  /// menjadi ceil(N/500).
  ///
  /// Kegagalan migrasi bersifat non-fatal — data lokal tetap aman di SQLite.
  Future<void> migrateGuestData({
    required List<Transaction> transactions,
    required List<HutangEntity> hutangList,
    required List<PiutangEntity> piutangList,
    List<Category> categories = const [],
  }) async {
    if (!isAvailable) return;

    const tag = 'SyncService.migrateGuestData';
    final sw = Stopwatch()..start();

    // Kumpulkan semua (docRef, data) yang perlu ditulis — hindari sequential awaits.
    final docRefs = <DocumentReference<Map<String, dynamic>>>[];
    final docDatas = <Map<String, dynamic>>[];

    void addWrite(
        DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic> data) {
      docRefs.add(ref);
      docDatas.add(data);
    }

    // Semua kategori — termasuk default, karena transaksi mereferensikan
    // category IDs mereka dan restore ke perangkat lain membutuhkan data ini.
    for (final cat in categories) {
      addWrite(_userCollection('categories').doc(cat.id), {
        'id': cat.id,
        'name': cat.name,
        'iconCode': cat.iconCode,
        'colorValue': cat.colorValue,
        'type': cat.type.value,
        'isDefault': cat.isDefault,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Transaksi
    for (final tx in transactions) {
      addWrite(_userCollection('transactions').doc(tx.id), {
        'id': tx.id,
        'type': tx.type.value,
        'amount': tx.amount,
        'categoryId': tx.category.id,
        'categoryName': tx.category.name,
        'note': tx.note,
        'date': tx.date.millisecondsSinceEpoch,
        'createdAt': tx.createdAt.millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Hutang + riwayat pembayaran
    for (final hutang in hutangList) {
      addWrite(_userCollection('hutang').doc(hutang.id), {
        'id': hutang.id,
        'namaKreditur': hutang.namaKreditur,
        'jumlahAwal': hutang.jumlahAwal,
        'sisaHutang': hutang.sisaHutang,
        'tanggalPinjam': hutang.tanggalPinjam.millisecondsSinceEpoch,
        'tanggalJatuhTempo': hutang.tanggalJatuhTempo?.millisecondsSinceEpoch,
        'catatan': hutang.catatan,
        'status': hutang.status,
        'createdAt': hutang.createdAt.millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      for (final payment in hutang.riwayatPembayaran) {
        addWrite(_userCollection('payment_history').doc(payment.id), {
          'id': payment.id,
          'referenceId': hutang.id,
          'referenceType': 'hutang',
          'amount': payment.amount,
          'paidAt': payment.paidAt.millisecondsSinceEpoch,
          'catatan': payment.catatan,
          'createdAt': payment.paidAt.millisecondsSinceEpoch,
        });
      }
    }

    // Piutang + riwayat pembayaran
    for (final piutang in piutangList) {
      addWrite(_userCollection('piutang').doc(piutang.id), {
        'id': piutang.id,
        'namaPeminjam': piutang.namaPeminjam,
        'jumlahAwal': piutang.jumlahAwal,
        'sisaPiutang': piutang.sisaPiutang,
        'tanggalPinjam': piutang.tanggalPinjam.millisecondsSinceEpoch,
        'tanggalJatuhTempo': piutang.tanggalJatuhTempo?.millisecondsSinceEpoch,
        'catatan': piutang.catatan,
        'status': piutang.status,
        'createdAt': piutang.createdAt.millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      for (final payment in piutang.riwayatPembayaran) {
        addWrite(_userCollection('payment_history').doc(payment.id), {
          'id': payment.id,
          'referenceId': piutang.id,
          'referenceType': 'piutang',
          'amount': payment.amount,
          'paidAt': payment.paidAt.millisecondsSinceEpoch,
          'catatan': payment.catatan,
          'createdAt': payment.paidAt.millisecondsSinceEpoch,
        });
      }
    }

    if (docRefs.isEmpty) {
      dev.log('Tidak ada data tamu untuk dimigrasi', name: tag);
      return;
    }

    // Commit dalam batch Firestore (maks 500 per batch)
    const batchLimit = 500;
    var batchCount = 0;
    try {
      for (var i = 0; i < docRefs.length; i += batchLimit) {
        final end = (i + batchLimit).clamp(0, docRefs.length);
        final batch = _db.batch();
        for (var j = i; j < end; j++) {
          batch.set(docRefs[j], docDatas[j]);
        }
        await batch.commit();
        batchCount++;
      }
    } catch (e) {
      dev.log('Batch commit gagal (non-fatal): $e', name: tag, level: 900);
    }

    sw.stop();
    dev.log(
      'Migrasi batch selesai: ${docRefs.length} dokumen, '
      '$batchCount batch dalam ${sw.elapsedMilliseconds}ms '
      '(${transactions.length} tx, ${hutangList.length} hutang, '
      '${piutangList.length} piutang, '
      '${categories.length} kategori — ${categories.where((c) => !c.isDefault).length} kustom)',
      name: tag,
    );
  }

  // ── Bootstrap / bulk sync ─────────────────────────────────────────────────

  /// Upload semua kategori lokal ke Firestore dalam satu atau beberapa batch.
  ///
  /// Dipanggil setelah login (Google / Email Link) agar koleksi `categories`
  /// di Firestore selalu terisi, sehingga perangkat lain dapat me-restore
  /// transaksi tanpa bergantung sepenuhnya pada fallback [categoryName].
  ///
  /// Menggunakan [batch.set] (bukan add) — idempotent dan aman dipanggil
  /// berkali-kali. Kegagalan bersifat non-fatal.
  Future<void> syncAllLocalCategories(List<Category> categories) async {
    if (!isAvailable || categories.isEmpty) return;
    const tag = 'SyncService.syncAllLocalCategories';
    final sw = Stopwatch()..start();
    try {
      const batchLimit = 500;
      for (var i = 0; i < categories.length; i += batchLimit) {
        final end = (i + batchLimit).clamp(0, categories.length);
        final batch = _db.batch();
        for (final cat in categories.sublist(i, end)) {
          batch.set(_userCollection('categories').doc(cat.id), {
            'id': cat.id,
            'name': cat.name,
            'iconCode': cat.iconCode,
            'colorValue': cat.colorValue,
            'type': cat.type.value,
            'isDefault': cat.isDefault,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
      sw.stop();
      dev.log(
        '${categories.length} kategori disinkronisasi dalam ${sw.elapsedMilliseconds}ms',
        name: tag,
      );
    } catch (e, st) {
      dev.log(
        'Gagal sinkronisasi kategori: $e',
        name: tag,
        error: e,
        stackTrace: st,
        level: 900,
      );
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _userCollection(
      String collectionName) {
    return _db
        .collection('users')
        .doc(_userId)
        .collection(collectionName);
  }
}
