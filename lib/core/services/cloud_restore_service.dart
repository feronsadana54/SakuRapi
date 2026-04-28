// Sembunyikan Firestore 'Transaction' agar tidak bentrok dengan
// domain entity 'Transaction' kita.
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:drift/drift.dart' show Value;

import '../../data/database/app_database.dart';
import '../../data/database/daos/category_dao.dart';
import '../../data/database/daos/hutang_dao.dart';
import '../../data/database/daos/piutang_dao.dart';
import '../../data/database/daos/transaction_dao.dart';
import 'sync_service.dart';

/// Hasil operasi restore dari cloud.
class CloudRestoreResult {
  final int categoriesRestored;
  final int transactionsRestored;
  /// Transaksi yang dilewati karena kategorinya belum ada lokal saat restore.
  /// Beda dengan [failures] yang merupakan error teknis (exception).
  /// Nilai > 0 berarti perlu retry setelah kategori ter-bootstrap ke Firestore.
  final int transactionsSkipped;
  final int hutangRestored;
  final int piutangRestored;
  final int paymentsRestored;
  final int failures;

  const CloudRestoreResult({
    this.categoriesRestored = 0,
    this.transactionsRestored = 0,
    this.transactionsSkipped = 0,
    this.hutangRestored = 0,
    this.piutangRestored = 0,
    this.paymentsRestored = 0,
    this.failures = 0,
  });

  int get total =>
      categoriesRestored +
      transactionsRestored +
      hutangRestored +
      piutangRestored +
      paymentsRestored;
}

/// Layanan yang mengambil semua data pengguna dari Firestore dan
/// memulihkannya ke SQLite lokal secara aman (tanpa duplikasi).
///
/// **Kapan dipanggil:**
///   - Saat login Google atau Email Link berhasil (login baru atau re-login)
///   - Setelah migrasi data tamu → akun terautentikasi (sebagai langkah kedua)
///
/// **Strategi merge per tabel:**
///   - Kategori kustom : INSERT OR IGNORE (lokal menang)
///   - Transaksi        : INSERT OR IGNORE (tidak ada updatedAt, immutable)
///   - Hutang/Piutang   : last-write-wins by updatedAt (cloud menang jika lebih baru)
///   - Riwayat bayar    : INSERT OR IGNORE (immutable setelah dicatat)
///
/// **Fallback categoryName untuk transaksi:**
///   Jika categoryId dari cloud tidak ditemukan lokal (terjadi saat restore ke
///   perangkat baru sebelum migrasi v5), layanan ini mencari kategori lokal
///   berdasarkan (categoryName|type). Ini memastikan transaksi lama tetap
///   dapat dipulihkan meski categoryId berbeda antar perangkat.
///
/// **Kenapa bypass repository:**
///   Repository menggunakan unawaited(sync.upsert*()) setiap kali insert/update.
///   Kita tidak ingin memicu re-upload saat restore — data sudah ada di cloud.
///   Maka restore langsung ke DAO, melewati repository.
class CloudRestoreService {
  final SyncService _sync;
  final CategoryDao _categoryDao;
  final TransactionDao _transactionDao;
  final HutangDao _hutangDao;
  final PiutangDao _piutangDao;

  CloudRestoreService({
    required SyncService sync,
    required CategoryDao categoryDao,
    required TransactionDao transactionDao,
    required HutangDao hutangDao,
    required PiutangDao piutangDao,
  })  : _sync = sync,
        _categoryDao = categoryDao,
        _transactionDao = transactionDao,
        _hutangDao = hutangDao,
        _piutangDao = piutangDao;

  /// Ambil semua data dari Firestore dan pulihkan ke SQLite lokal.
  ///
  /// **Optimasi**: Kelima koleksi Firestore difetch secara paralel dengan
  /// [Future.wait], lalu ditulis ke SQLite secara berurutan (kategori → transaksi
  /// → hutang → piutang → pembayaran) agar foreign key tidak gagal.
  ///
  /// Selalu mengembalikan hasil, tidak pernah melempar exception.
  Future<CloudRestoreResult> restoreFromCloud() async {
    if (!_sync.isAvailable) return const CloudRestoreResult();

    const tag = 'CloudRestoreService';
    final sw = Stopwatch()..start();
    dev.log('[restore] Memulai restore dari cloud...', name: tag);

    // Fetch semua koleksi secara paralel — hemat 4 round-trip jaringan.
    final fetchSw = Stopwatch()..start();
    final fetched = await Future.wait([
      _sync.fetchAllCategories(),
      _sync.fetchAllTransactions(),
      _sync.fetchAllHutang(),
      _sync.fetchAllPiutang(),
      _sync.fetchAllPaymentHistory(),
    ]);
    fetchSw.stop();

    final cloudCategories = fetched[0];
    final cloudTx        = fetched[1];
    final cloudHutang    = fetched[2];
    final cloudPiutang   = fetched[3];
    final cloudPayments  = fetched[4];

    dev.log(
      '[restore] Fetch selesai dalam ${fetchSw.elapsedMilliseconds}ms — '
      '${cloudCategories.length} kategori, ${cloudTx.length} tx, '
      '${cloudHutang.length} hutang, ${cloudPiutang.length} piutang, '
      '${cloudPayments.length} pembayaran',
      name: tag,
    );

    var categoriesRestored = 0;
    var transactionsRestored = 0;
    var transactionsSkipped = 0;
    var hutangRestored = 0;
    var piutangRestored = 0;
    var paymentsRestored = 0;
    var failures = 0;

    // ── 1. Kategori (INSERT OR IGNORE) ────────────────────────────────────
    //
    // Restore semua kategori dari Firestore, dengan satu pengecualian:
    // kategori default (isDefault=true) dengan ID tidak stabil (UUID acak
    // dari versi sebelum v5) dilewati untuk menghindari duplikat. Kategori
    // tersebut sudah ada di lokal dengan ID stabil (def-* / sys-*) setelah
    // migrasi v5. Transaksi yang mereferensikan ID acak ditangani via
    // fallback categoryName di bagian restore transaksi di bawah.
    for (final data in cloudCategories) {
      final id = data['id'] as String? ?? '?';
      try {
        final cloudIsDefault = data['isDefault'] as bool? ?? false;

        if (cloudIsDefault &&
            !id.startsWith('def-') &&
            !id.startsWith('sys-')) {
          dev.log(
            '[restore] Kategori default lama "$id" (${data['name']}) '
            'dilewati — ID tidak stabil, ditangani via fallback',
            name: tag,
          );
          continue;
        }

        final companion = CategoriesTableCompanion.insert(
          id: id,
          name: data['name'] as String,
          iconCode: data['iconCode'] as int,
          colorValue: data['colorValue'] as int,
          type: data['type'] as String,
          isDefault: Value(cloudIsDefault),
        );
        await _categoryDao.insertOrIgnore(companion);
        categoriesRestored++;
      } catch (e, st) {
        dev.log(
          '[restore] Gagal menyisipkan kategori $id: $e',
          name: tag,
          error: e,
          stackTrace: st,
          level: 900,
        );
        failures++;
      }
    }

    // ── 2. Transaksi (INSERT OR IGNORE) dengan fallback categoryName ───────
    //
    // Sebelum v5, categoryId di Firestore bisa berupa UUID acak yang tidak
    // cocok dengan ID kategori di perangkat baru. Jika demikian, kita coba
    // cocokkan berdasarkan (categoryName|type) sebagai fallback.

    // Bangun lookup lokal sekali — lebih hemat daripada query per-transaksi.
    final localCats = await _categoryDao.getAll();
    final localCatById   = {for (final c in localCats) c.id: c};
    final localCatByName = {
      for (final c in localCats) '${c.name}|${c.type}': c
    };

    for (final data in cloudTx) {
      final txId = data['id'] as String? ?? '?';
      try {
        final cloudCatId   = data['categoryId']  as String;
        final cloudCatName = data['categoryName'] as String?;
        final cloudTxType  = data['type']         as String;

        // Tentukan categoryId lokal yang valid
        String localCatId;
        if (localCatById.containsKey(cloudCatId)) {
          // Kasus normal: ID cocok langsung
          localCatId = cloudCatId;
        } else if (cloudCatName != null &&
            localCatByName.containsKey('$cloudCatName|$cloudTxType')) {
          // Fallback: cocokkan berdasarkan (nama|tipe) — menangani data lama
          // dengan UUID acak yang dibuat sebelum migrasi v5
          final matched = localCatByName['$cloudCatName|$cloudTxType']!;
          localCatId = matched.id;
          dev.log(
            '[restore] tx $txId: categoryId "$cloudCatId" tidak ada lokal, '
            'diganti "$localCatId" berdasarkan nama "$cloudCatName"',
            name: tag,
          );
        } else {
          // Kategori tidak dapat dicocokkan — lewati transaksi ini.
          // Ini BUKAN error teknis; dicatat terpisah di transactionsSkipped
          // agar AuthNotifier dapat memicu retry pass setelah kategori tersedia.
          dev.log(
            '[restore] tx $txId: kategori "$cloudCatName" ($cloudCatId) '
            'tidak ditemukan lokal, transaksi dilewati (akan di-retry)',
            name: tag,
            level: 900,
          );
          transactionsSkipped++;
          continue;
        }

        final companion = TransactionsTableCompanion.insert(
          id: txId,
          type: cloudTxType,
          amount: (data['amount'] as num).toDouble(),
          categoryId: localCatId,
          note: Value(data['note'] as String?),
          date: data['date'] as int,
          createdAt: data['createdAt'] as int,
        );
        await _transactionDao.insertOrIgnore(companion);
        transactionsRestored++;
      } catch (e, st) {
        dev.log(
          '[restore] Gagal menyisipkan transaksi $txId: $e',
          name: tag,
          error: e,
          stackTrace: st,
          level: 900,
        );
        failures++;
      }
    }

    // ── 3. Hutang (last-write-wins by updatedAt) ──────────────────────────
    for (final data in cloudHutang) {
      final id = data['id'] as String? ?? '?';
      try {
        final cloudUpdatedAt = _parseTimestamp(data['updatedAt']);

        final existing = await _hutangDao.getById(id);
        if (existing == null) {
          final companion = HutangTableCompanion.insert(
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
          );
          await _hutangDao.insertOrIgnore(companion);
          hutangRestored++;
        } else if (cloudUpdatedAt > existing.updatedAt) {
          final companion = HutangTableCompanion(
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
          );
          await _hutangDao.updateHutang(companion);
          hutangRestored++;
        }
      } catch (e, st) {
        dev.log(
          '[restore] Gagal menyisipkan hutang $id: $e',
          name: tag,
          error: e,
          stackTrace: st,
          level: 900,
        );
        failures++;
      }
    }

    // ── 4. Piutang (last-write-wins by updatedAt) ─────────────────────────
    for (final data in cloudPiutang) {
      final id = data['id'] as String? ?? '?';
      try {
        final cloudUpdatedAt = _parseTimestamp(data['updatedAt']);

        final existing = await _piutangDao.getById(id);
        if (existing == null) {
          final companion = PiutangTableCompanion.insert(
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
          );
          await _piutangDao.insertOrIgnore(companion);
          piutangRestored++;
        } else if (cloudUpdatedAt > existing.updatedAt) {
          final companion = PiutangTableCompanion(
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
          );
          await _piutangDao.updatePiutang(companion);
          piutangRestored++;
        }
      } catch (e, st) {
        dev.log(
          '[restore] Gagal menyisipkan piutang $id: $e',
          name: tag,
          error: e,
          stackTrace: st,
          level: 900,
        );
        failures++;
      }
    }

    // ── 5. Riwayat pembayaran (INSERT OR IGNORE) ──────────────────────────
    for (final data in cloudPayments) {
      final id = data['id'] as String? ?? '?';
      try {
        final companion = PaymentHistoryTableCompanion.insert(
          id: id,
          referenceId: data['referenceId'] as String,
          referenceType: data['referenceType'] as String,
          amount: (data['amount'] as num).toDouble(),
          paidAt: data['paidAt'] as int,
          catatan: Value(data['catatan'] as String?),
          createdAt: data['createdAt'] as int,
        );
        await _hutangDao.insertPaymentOrIgnore(companion);
        paymentsRestored++;
      } catch (e, st) {
        dev.log(
          '[restore] Gagal menyisipkan pembayaran $id: $e',
          name: tag,
          error: e,
          stackTrace: st,
          level: 900,
        );
        failures++;
      }
    }

    sw.stop();
    final total = categoriesRestored + transactionsRestored +
        hutangRestored + piutangRestored + paymentsRestored;

    final skipInfo = transactionsSkipped > 0
        ? ', $transactionsSkipped tx dilewati (butuh retry)'
        : '';
    final failInfo = failures > 0 ? ', $failures error teknis' : '';

    if (failures > 0 || transactionsSkipped > 0) {
      dev.log(
        '[restore] Selesai dalam ${sw.elapsedMilliseconds}ms — '
        '$total dipulihkan ($categoriesRestored kategori, '
        '$transactionsRestored tx, $hutangRestored hutang, '
        '$piutangRestored piutang, $paymentsRestored pembayaran)'
        '$skipInfo$failInfo',
        name: tag,
        level: 900,
      );
    } else if (total > 0) {
      dev.log(
        '[restore] Selesai dalam ${sw.elapsedMilliseconds}ms — '
        '$categoriesRestored kategori, $transactionsRestored tx, '
        '$hutangRestored hutang, $piutangRestored piutang, '
        '$paymentsRestored pembayaran dipulihkan',
        name: tag,
      );
    } else {
      dev.log(
        '[restore] Selesai dalam ${sw.elapsedMilliseconds}ms — tidak ada data baru',
        name: tag,
      );
    }

    return CloudRestoreResult(
      categoriesRestored: categoriesRestored,
      transactionsRestored: transactionsRestored,
      transactionsSkipped: transactionsSkipped,
      hutangRestored: hutangRestored,
      piutangRestored: piutangRestored,
      paymentsRestored: paymentsRestored,
      failures: failures,
    );
  }

  /// Mengubah field `updatedAt` dari Firestore menjadi epoch milliseconds.
  ///
  /// Firestore menyimpan `FieldValue.serverTimestamp()` dan mengembalikannya
  /// sebagai [Timestamp] saat di-fetch. Field ini bisa juga berupa [int] jika
  /// data ditulis secara manual atau dari versi lama.
  int _parseTimestamp(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    // Fallback: jangan overwrite data lokal jika format tidak dikenal
    return 0;
  }
}
