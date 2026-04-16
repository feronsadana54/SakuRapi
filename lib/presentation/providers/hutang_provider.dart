import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/system_categories.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/hutang_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/enums/transaction_type.dart';
import '../../domain/repositories/i_hutang_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import 'database_provider.dart';

// ── Stream provider ───────────────────────────────────────────────────────────

/// Daftar reaktif semua data hutang.
/// Memancar ulang setiap kali ada baris hutang yang berubah (insert/update/delete).
/// Diawasi oleh [HutangListScreen] dan [hutangSummaryProvider].
final hutangListProvider = StreamProvider<List<HutangEntity>>((ref) {
  return ref.watch(hutangRepositoryProvider).watchAll();
});

// ── Summary provider ──────────────────────────────────────────────────────────

class HutangSummary {
  final double totalAktif;
  final double totalLunas;
  final double totalSisa;
  final HutangEntity? nearestDue;

  const HutangSummary({
    required this.totalAktif,
    required this.totalLunas,
    required this.totalSisa,
    this.nearestDue,
  });

  static const empty = HutangSummary(
    totalAktif: 0,
    totalLunas: 0,
    totalSisa: 0,
  );
}

final hutangSummaryProvider = Provider<AsyncValue<HutangSummary>>((ref) {
  return ref.watch(hutangListProvider).whenData((list) {
    double totalAktif = 0;
    double totalLunas = 0;
    double totalSisa = 0;
    HutangEntity? nearestDue;
    final today = AppDateUtils.dateOnly(DateTime.now());

    for (final h in list) {
      if (h.isLunas) {
        totalLunas += h.jumlahAwal;
      } else {
        totalAktif += h.jumlahAwal;
        totalSisa += h.sisaHutang;

        // Find nearest due date
        if (h.tanggalJatuhTempo != null) {
          final due = AppDateUtils.dateOnly(h.tanggalJatuhTempo!);
          if (!due.isBefore(today)) {
            if (nearestDue == null ||
                due.isBefore(AppDateUtils.dateOnly(nearestDue.tanggalJatuhTempo!))) {
              nearestDue = h;
            }
          }
        }
      }
    }

    return HutangSummary(
      totalAktif: totalAktif,
      totalLunas: totalLunas,
      totalSisa: totalSisa,
      nearestDue: nearestDue,
    );
  });
});

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Menangani semua operasi tulis untuk modul Hutang.
///
/// State [AsyncValue<void>] digunakan sebagai sinyal sedang-dalam-proses:
/// - [AsyncLoading]   — saat penulisan DB sedang berlangsung.
/// - [AsyncData(null)] — sukses.
/// - [AsyncError]     — gagal (ditampilkan sebagai SnackBar oleh layar pemanggil).
///
/// Desain kunci: [addPayment] menulis ke BOTH [hutangRepository] DAN
/// [transactionRepository] sehingga setiap pembayaran hutang muncul di laporan
/// keuangan terpadu (harian, bulanan, dll.) sebagai transaksi "pengeluaran".
class HutangNotifier extends StateNotifier<AsyncValue<void>> {
  final IHutangRepository _repo;
  final ITransactionRepository _txRepo;

  HutangNotifier(this._repo, this._txRepo) : super(const AsyncData(null));

  Future<void> addHutang(HutangEntity hutang) async {
    state = const AsyncLoading();
    try {
      await _repo.insert(hutang);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateHutang(HutangEntity hutang) async {
    state = const AsyncLoading();
    try {
      await _repo.update(hutang);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteHutang(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.delete(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Merekam pembayaran parsial hutang dan membuat transaksi pengeluaran terhubung
  /// agar pembayaran ini masuk ke laporan keuangan terpadu.
  Future<void> addPayment(String hutangId, double amount, {String? catatan}) async {
    state = const AsyncLoading();
    try {
      const uuid = Uuid();
      final payment = PaymentRecord(
        id: uuid.v4(),
        amount: amount,
        paidAt: DateTime.now(),
        catatan: catatan,
      );
      await _repo.addPayment(hutangId, payment);

      // Update sisa hutang
      final hutang = await _repo.getById(hutangId);
      if (hutang != null) {
        final newSisa = (hutang.sisaHutang - amount).clamp(0.0, double.infinity);
        final updated = HutangEntity(
          id: hutang.id,
          namaKreditur: hutang.namaKreditur,
          jumlahAwal: hutang.jumlahAwal,
          sisaHutang: newSisa,
          tanggalPinjam: hutang.tanggalPinjam,
          tanggalJatuhTempo: hutang.tanggalJatuhTempo,
          catatan: hutang.catatan,
          status: newSisa <= 0 ? 'lunas' : 'aktif',
          riwayatPembayaran: hutang.riwayatPembayaran,
          createdAt: hutang.createdAt,
          updatedAt: DateTime.now(),
        );
        await _repo.update(updated);

        // Buat transaksi pengeluaran terhubung agar pembayaran terlihat di laporan
        final now = DateTime.now();
        final note = catatan != null && catatan.isNotEmpty
            ? 'Bayar hutang: ${hutang.namaKreditur} — $catatan'
            : 'Bayar hutang: ${hutang.namaKreditur}';
        await _txRepo.insert(Transaction(
          id: uuid.v4(),
          type: TransactionType.expense,
          amount: amount,
          category: SystemCategories.pembayaranHutang,
          note: note,
          date: AppDateUtils.dateOnly(now),
          createdAt: now,
        ));
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Memperbarui data hutang setelah pembayaran yang berasal dari form transaksi.
  ///
  /// BERBEDA dari [addPayment]: metode ini TIDAK membuat transaksi pengeluaran
  /// baru, karena transaksi sudah dibuat oleh [TransactionFormScreen].
  ///
  /// Dipanggil oleh [TransactionFormScreen] ketika pengguna memilih kategori
  /// "Pembayaran Hutang" dan memilih hutang yang dibayar.
  ///
  /// Alur lengkap dari form transaksi:
  ///   1. TransactionFormScreen menyimpan transaksi pengeluaran ke DB.
  ///   2. TransactionFormScreen memanggil [updateAfterPayment] di sini.
  ///   3. Metode ini mengurangi sisaHutang, menyimpan riwayat, dan memperbarui status.
  Future<void> updateAfterPayment(
    String hutangId,
    double amount, {
    String? catatan,
    DateTime? paidAt,
  }) async {
    state = const AsyncLoading();
    try {
      const uuid = Uuid();
      final hutang = await _repo.getById(hutangId);
      if (hutang == null) {
        state = const AsyncData(null);
        return;
      }

      // Simpan riwayat pembayaran
      final payment = PaymentRecord(
        id: uuid.v4(),
        amount: amount,
        paidAt: paidAt ?? DateTime.now(),
        catatan: catatan,
      );
      await _repo.addPayment(hutangId, payment);

      // Perbarui sisa dan status hutang
      final newSisa = (hutang.sisaHutang - amount).clamp(0.0, double.infinity);
      final updated = HutangEntity(
        id: hutang.id,
        namaKreditur: hutang.namaKreditur,
        jumlahAwal: hutang.jumlahAwal,
        sisaHutang: newSisa,
        tanggalPinjam: hutang.tanggalPinjam,
        tanggalJatuhTempo: hutang.tanggalJatuhTempo,
        catatan: hutang.catatan,
        status: newSisa <= 0 ? 'lunas' : 'aktif',
        riwayatPembayaran: hutang.riwayatPembayaran,
        createdAt: hutang.createdAt,
        updatedAt: DateTime.now(),
      );
      await _repo.update(updated);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markAsLunas(String hutangId) async {
    state = const AsyncLoading();
    try {
      final hutang = await _repo.getById(hutangId);
      if (hutang == null) return;

      final updated = HutangEntity(
        id: hutang.id,
        namaKreditur: hutang.namaKreditur,
        jumlahAwal: hutang.jumlahAwal,
        sisaHutang: 0,
        tanggalPinjam: hutang.tanggalPinjam,
        tanggalJatuhTempo: hutang.tanggalJatuhTempo,
        catatan: hutang.catatan,
        status: 'lunas',
        riwayatPembayaran: hutang.riwayatPembayaran,
        createdAt: hutang.createdAt,
        updatedAt: DateTime.now(),
      );
      await _repo.update(updated);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final hutangNotifierProvider =
    StateNotifierProvider<HutangNotifier, AsyncValue<void>>(
  (ref) => HutangNotifier(
    ref.watch(hutangRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);
