// CATATAN IMPORT:
// Kita menyembunyikan Firestore 'Transaction' agar tidak bentrok dengan
// domain entity 'Transaction' kita di transaction_entity.dart.
// Firestore Transaction (dipakai untuk atomic batch writes) tidak digunakan
// di file ini — semua operasi menggunakan DocumentReference.set/delete langsung.
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

// Domain entity transaksi kita — gunakan 'Transaction' secara bebas di sini.
import '../../domain/entities/transaction_entity.dart';

// Flag kFirebaseConfigured: jika false, semua metode sync langsung return.
import '../../firebase_options.dart';

/// Layanan sinkronisasi data pengguna ke Firestore Cloud.
///
/// **Kapan dipanggil:**
///   - [syncServiceProvider] (database_provider.dart) membuat instance ini
///     satu kali per sesi, dengan userId dari SharedPreferences.
///   - Setiap repository (transaction, hutang, piutang) mengambil provider ini
///     dan memanggil [upsertTransaction], [upsertHutang], [upsertPiutang], dll.
///     setelah setiap operasi tulis ke SQLite lokal.
///   - [AuthNotifier.signInWithGoogle] memanggil [fetchAllTransactions],
///     [fetchAllHutang], [fetchAllPiutang] saat login untuk memulihkan data.
///
/// **Kapan TIDAK aktif (semua metode no-op):**
///   - [kFirebaseConfigured] == false (belum jalankan flutterfire configure)
///   - Pengguna login sebagai Tamu ([_userId] == null)
///
/// Struktur data Firestore:
///   users/{userId}/transactions/{txId}  — semua transaksi pengguna
///   users/{userId}/hutang/{hutangId}    — semua hutang pengguna
///   users/{userId}/piutang/{piutangId}  — semua piutang pengguna
///
/// Strategi sinkronisasi:
///   - Upload: setiap perubahan lokal di-push ke Firestore (via upsert).
///   - Download: saat login Google di perangkat baru, fetchAll() menarik data
///     dari Firestore ke database lokal SQLite.
///   - Konflik: timestamp [updatedAt] menentukan data terbaru (last-write-wins).
///   - Toleransi error: semua operasi dibungkus try/catch — sync gagal tidak
///     mengganggu operasi lokal; data lokal selalu aman.
class SyncService {
  final FirebaseFirestore _db;
  final String? _userId;

  SyncService({FirebaseFirestore? firestore, required String? userId})
      : _db = firestore ?? FirebaseFirestore.instance,
        _userId = userId;

  /// Apakah sinkronisasi cloud tersedia (Firebase dikonfigurasi + user login Google).
  bool get isAvailable => kFirebaseConfigured && _userId != null;

  // ── Transaksi ─────────────────────────────────────────────────────────────

  /// Menyimpan satu transaksi ke Firestore.
  /// Tidak melakukan apa-apa jika sync tidak tersedia.
  Future<void> upsertTransaction(Transaction tx) async {
    if (!isAvailable) return;
    try {
      await _userCollection('transactions').doc(tx.id).set({
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
    } catch (_) {
      // Sync gagal: data lokal tetap aman, coba lagi nanti.
    }
  }

  /// Menghapus transaksi dari Firestore berdasarkan ID.
  Future<void> deleteTransaction(String id) async {
    if (!isAvailable) return;
    try {
      await _userCollection('transactions').doc(id).delete();
    } catch (_) {}
  }

  // ── Hutang ────────────────────────────────────────────────────────────────

  /// Menyimpan/memperbarui record hutang ke Firestore.
  Future<void> upsertHutang(Map<String, dynamic> data) async {
    if (!isAvailable) return;
    try {
      final id = data['id'] as String?;
      if (id == null || id.isEmpty) return;
      await _userCollection('hutang').doc(id).set({
        ...data,
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

  /// Menyimpan/memperbarui record piutang ke Firestore.
  Future<void> upsertPiutang(Map<String, dynamic> data) async {
    if (!isAvailable) return;
    try {
      final id = data['id'] as String?;
      if (id == null || id.isEmpty) return;
      await _userCollection('piutang').doc(id).set({
        ...data,
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

  // ── Pemulihan Data (saat login di perangkat baru) ─────────────────────────

  /// Mengambil semua transaksi pengguna dari Firestore.
  /// Mengembalikan list kosong jika sync tidak tersedia atau query gagal.
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

  // ── Helper ────────────────────────────────────────────────────────────────

  /// Shortcut ke sub-koleksi data pengguna di Firestore.
  CollectionReference<Map<String, dynamic>> _userCollection(
      String collectionName) {
    return _db
        .collection('users')
        .doc(_userId)
        .collection(collectionName);
  }
}
