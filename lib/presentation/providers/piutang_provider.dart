import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/system_categories.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/hutang_entity.dart';
import '../../domain/entities/piutang_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/enums/transaction_type.dart';
import '../../domain/repositories/i_piutang_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import 'database_provider.dart';

// ── Stream provider ───────────────────────────────────────────────────────────

/// Daftar reaktif semua data piutang.
/// Memancar ulang setiap kali ada baris piutang yang berubah (insert/update/delete).
/// Diawasi oleh [PiutangListScreen] dan [piutangSummaryProvider].
final piutangListProvider = StreamProvider<List<PiutangEntity>>((ref) {
  return ref.watch(piutangRepositoryProvider).watchAll();
});

// ── Summary provider ──────────────────────────────────────────────────────────

class PiutangSummary {
  final double totalAktif;
  final double totalLunas;
  final double totalSisa;
  final PiutangEntity? nearestDue;

  const PiutangSummary({
    required this.totalAktif,
    required this.totalLunas,
    required this.totalSisa,
    this.nearestDue,
  });

  static const empty = PiutangSummary(
    totalAktif: 0,
    totalLunas: 0,
    totalSisa: 0,
  );
}

final piutangSummaryProvider = Provider<AsyncValue<PiutangSummary>>((ref) {
  return ref.watch(piutangListProvider).whenData((list) {
    double totalAktif = 0;
    double totalLunas = 0;
    double totalSisa = 0;
    PiutangEntity? nearestDue;
    final today = AppDateUtils.dateOnly(DateTime.now());

    for (final p in list) {
      if (p.isLunas) {
        totalLunas += p.jumlahAwal;
      } else {
        totalAktif += p.jumlahAwal;
        totalSisa += p.sisaPiutang;

        if (p.tanggalJatuhTempo != null) {
          final due = AppDateUtils.dateOnly(p.tanggalJatuhTempo!);
          if (!due.isBefore(today)) {
            if (nearestDue == null ||
                due.isBefore(AppDateUtils.dateOnly(nearestDue.tanggalJatuhTempo!))) {
              nearestDue = p;
            }
          }
        }
      }
    }

    return PiutangSummary(
      totalAktif: totalAktif,
      totalLunas: totalLunas,
      totalSisa: totalSisa,
      nearestDue: nearestDue,
    );
  });
});

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Menangani semua operasi tulis untuk modul Piutang.
///
/// Cerminan dari [HutangNotifier] untuk sisi piutang (yang kamu pinjamkan).
///
/// Desain kunci: [addPayment] menulis ke BOTH [piutangRepository] DAN
/// [transactionRepository] sehingga setiap penerimaan cicilan piutang muncul
/// di laporan keuangan terpadu sebagai transaksi "pemasukan".
class PiutangNotifier extends StateNotifier<AsyncValue<void>> {
  final IPiutangRepository _repo;
  final ITransactionRepository _txRepo;

  PiutangNotifier(this._repo, this._txRepo) : super(const AsyncData(null));

  /// Mencatat piutang baru DAN membuat transaksi pengeluaran otomatis.
  ///
  /// Ketika pengguna meminjamkan uang, uang tersebut keluar dari saldo.
  /// Oleh karena itu, mencatat piutang baru SELALU menghasilkan dua entri:
  ///   1. Record piutang di tabel piutang (untuk pelacakan pelunasan).
  ///   2. Transaksi pengeluaran dengan kategori "Memberi Pinjaman" (untuk saldo).
  ///
  /// Dipanggil oleh [PiutangFormScreen] saat pengguna menyimpan piutang baru.
  Future<void> addPiutang(PiutangEntity piutang) async {
    state = const AsyncLoading();
    try {
      // 1. Simpan record piutang
      await _repo.insert(piutang);

      // 2. Buat transaksi pengeluaran otomatis — uang dipinjamkan = keluar
      const uuid = Uuid();
      final now = DateTime.now();
      final note = piutang.catatan != null && piutang.catatan!.isNotEmpty
          ? 'Memberi pinjaman ke: ${piutang.namaPeminjam} — ${piutang.catatan}'
          : 'Memberi pinjaman ke: ${piutang.namaPeminjam}';
      await _txRepo.insert(Transaction(
        id: uuid.v4(),
        type: TransactionType.expense,
        amount: piutang.jumlahAwal,
        category: SystemCategories.memberiPinjaman,
        note: note,
        date: AppDateUtils.dateOnly(piutang.tanggalPinjam),
        createdAt: now,
      ));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updatePiutang(PiutangEntity piutang) async {
    state = const AsyncLoading();
    try {
      await _repo.update(piutang);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deletePiutang(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.delete(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Merekam penerimaan pembayaran piutang dan membuat transaksi pemasukan terhubung
  /// agar penerimaan ini masuk ke laporan keuangan terpadu.
  Future<void> addPayment(String piutangId, double amount, {String? catatan}) async {
    state = const AsyncLoading();
    try {
      const uuid = Uuid();
      final payment = PaymentRecord(
        id: uuid.v4(),
        amount: amount,
        paidAt: DateTime.now(),
        catatan: catatan,
      );
      await _repo.addPayment(piutangId, payment);

      // Update sisa piutang
      final piutang = await _repo.getById(piutangId);
      if (piutang != null) {
        final newSisa = (piutang.sisaPiutang - amount).clamp(0.0, double.infinity);
        final updated = PiutangEntity(
          id: piutang.id,
          namaPeminjam: piutang.namaPeminjam,
          jumlahAwal: piutang.jumlahAwal,
          sisaPiutang: newSisa,
          tanggalPinjam: piutang.tanggalPinjam,
          tanggalJatuhTempo: piutang.tanggalJatuhTempo,
          catatan: piutang.catatan,
          status: newSisa <= 0 ? 'lunas' : 'aktif',
          riwayatPembayaran: piutang.riwayatPembayaran,
          createdAt: piutang.createdAt,
          updatedAt: DateTime.now(),
        );
        await _repo.update(updated);

        // Buat transaksi pemasukan terhubung agar penerimaan terlihat di laporan
        final now = DateTime.now();
        final note = catatan != null && catatan.isNotEmpty
            ? 'Terima piutang: ${piutang.namaPeminjam} — $catatan'
            : 'Terima piutang: ${piutang.namaPeminjam}';
        await _txRepo.insert(Transaction(
          id: uuid.v4(),
          type: TransactionType.income,
          amount: amount,
          category: SystemCategories.penerimaanPiutang,
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

  Future<void> markAsLunas(String piutangId) async {
    state = const AsyncLoading();
    try {
      final piutang = await _repo.getById(piutangId);
      if (piutang == null) return;

      final updated = PiutangEntity(
        id: piutang.id,
        namaPeminjam: piutang.namaPeminjam,
        jumlahAwal: piutang.jumlahAwal,
        sisaPiutang: 0,
        tanggalPinjam: piutang.tanggalPinjam,
        tanggalJatuhTempo: piutang.tanggalJatuhTempo,
        catatan: piutang.catatan,
        status: 'lunas',
        riwayatPembayaran: piutang.riwayatPembayaran,
        createdAt: piutang.createdAt,
        updatedAt: DateTime.now(),
      );
      await _repo.update(updated);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final piutangNotifierProvider =
    StateNotifierProvider<PiutangNotifier, AsyncValue<void>>(
  (ref) => PiutangNotifier(
    ref.watch(piutangRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);
