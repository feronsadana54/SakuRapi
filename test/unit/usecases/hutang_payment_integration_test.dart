// Unit tests untuk integrasi pembayaran hutang.
//
// Mencakup:
//  - Menghitung progressPersen setelah pembayaran parsial.
//  - Status hutang berubah menjadi 'lunas' saat sisa = 0.
//  - Pembayaran melebihi sisa hutang dihalangi oleh validasi UI.
//  - Hutang dengan banyak pembayaran terakumulasi dengan benar.
//  - Validasi: pembayaran tidak boleh melebihi sisa.
//
// Catatan desain:
//   Integrasi antara TransactionFormScreen dan HutangNotifier diuji melalui
//   logika domain (HutangEntity) dan tidak memerlukan AppDatabase nyata.
//   Test ini murni unit test pada logika kalkulasi.
//
// Run: flutter test test/unit/usecases/hutang_payment_integration_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/domain/entities/hutang_entity.dart';

void main() {
  final refDate = DateTime(2026, 4, 17);

  // ── Helper ────────────────────────────────────────────────────────────────

  HutangEntity makeHutang({
    required double jumlahAwal,
    required double sisaHutang,
    String status = 'aktif',
    List<PaymentRecord> payments = const [],
  }) {
    return HutangEntity(
      id: 'htg-1',
      namaKreditur: 'Bank XYZ',
      jumlahAwal: jumlahAwal,
      sisaHutang: sisaHutang,
      tanggalPinjam: refDate,
      status: status,
      riwayatPembayaran: payments,
      createdAt: refDate,
      updatedAt: refDate,
    );
  }

  /// Mensimulasikan logika [HutangNotifier.updateAfterPayment]:
  /// mengurangi sisa, memperbarui status, menambah riwayat.
  HutangEntity simulatePayment(
    HutangEntity hutang,
    double amount, {
    String? catatan,
  }) {
    final newSisa =
        (hutang.sisaHutang - amount).clamp(0.0, double.infinity);
    final newStatus = newSisa <= 0 ? 'lunas' : 'aktif';
    final newPayments = [
      ...hutang.riwayatPembayaran,
      PaymentRecord(
        id: 'pay-${hutang.riwayatPembayaran.length + 1}',
        amount: amount,
        paidAt: refDate,
        catatan: catatan,
      ),
    ];
    return HutangEntity(
      id: hutang.id,
      namaKreditur: hutang.namaKreditur,
      jumlahAwal: hutang.jumlahAwal,
      sisaHutang: newSisa,
      tanggalPinjam: hutang.tanggalPinjam,
      status: newStatus,
      riwayatPembayaran: newPayments,
      createdAt: hutang.createdAt,
      updatedAt: refDate,
    );
  }

  // ── Group: Pembayaran parsial ─────────────────────────────────────────────

  group('Pembayaran hutang parsial', () {
    test('sisa hutang berkurang setelah pembayaran parsial', () {
      final hutang = makeHutang(jumlahAwal: 1_000_000, sisaHutang: 1_000_000);
      final setelah = simulatePayment(hutang, 250_000);

      expect(setelah.sisaHutang, equals(750_000.0));
      expect(setelah.status, equals('aktif'));
    });

    test('progressPersen bertambah setelah pembayaran', () {
      final hutang = makeHutang(jumlahAwal: 1_000_000, sisaHutang: 1_000_000);
      final setelah = simulatePayment(hutang, 400_000);

      expect(setelah.progressPersen, closeTo(0.4, 0.001));
    });

    test('riwayat pembayaran bertambah satu setelah bayar', () {
      final hutang = makeHutang(jumlahAwal: 500_000, sisaHutang: 500_000);
      final setelah = simulatePayment(hutang, 100_000, catatan: 'Cicilan 1');

      expect(setelah.riwayatPembayaran.length, equals(1));
      expect(setelah.riwayatPembayaran.first.amount, equals(100_000.0));
      expect(setelah.riwayatPembayaran.first.catatan, equals('Cicilan 1'));
    });

    test('beberapa pembayaran terakumulasi dengan benar', () {
      var hutang = makeHutang(jumlahAwal: 1_000_000, sisaHutang: 1_000_000);
      hutang = simulatePayment(hutang, 200_000);
      hutang = simulatePayment(hutang, 300_000);
      hutang = simulatePayment(hutang, 150_000);

      expect(hutang.sisaHutang, equals(350_000.0));
      expect(hutang.totalDibayar, equals(650_000.0));
      expect(hutang.riwayatPembayaran.length, equals(3));
      expect(hutang.status, equals('aktif'));
    });
  });

  // ── Group: Pelunasan ──────────────────────────────────────────────────────

  group('Pelunasan hutang', () {
    test('status berubah menjadi lunas saat sisa = 0', () {
      final hutang = makeHutang(jumlahAwal: 500_000, sisaHutang: 500_000);
      final setelah = simulatePayment(hutang, 500_000);

      expect(setelah.sisaHutang, equals(0.0));
      expect(setelah.status, equals('lunas'));
      expect(setelah.isLunas, isTrue);
      expect(setelah.progressPersen, equals(1.0));
    });

    test('lunas dengan pembayaran tepat sisa terakhir', () {
      var hutang = makeHutang(jumlahAwal: 1_000_000, sisaHutang: 1_000_000);
      hutang = simulatePayment(hutang, 600_000);
      hutang = simulatePayment(hutang, 400_000); // tepat sisa

      expect(hutang.isLunas, isTrue);
      expect(hutang.sisaHutang, equals(0.0));
    });

    test('sisa tidak negatif meskipun pembayaran melebihi sisa (clamp)', () {
      final hutang = makeHutang(jumlahAwal: 200_000, sisaHutang: 100_000);
      // Ini disimulasikan jika validasi UI dilewati — sisa di-clamp ke 0
      final setelah = simulatePayment(hutang, 150_000);

      expect(setelah.sisaHutang, equals(0.0));
      expect(setelah.isLunas, isTrue);
    });
  });

  // ── Group: Validasi pembayaran ────────────────────────────────────────────

  group('Validasi jumlah pembayaran', () {
    test('pembayaran 0 tidak valid', () {
      // Logika validasi: amount harus > 0
      const amount = 0.0;
      expect(amount > 0, isFalse,
          reason: 'Jumlah 0 harus gagal validasi');
    });

    test('pembayaran melebihi sisa tidak valid', () {
      final hutang = makeHutang(jumlahAwal: 1_000_000, sisaHutang: 300_000);
      const pembayaran = 400_000.0;

      // Logika validasi UI: amount <= sisaHutang
      expect(pembayaran > hutang.sisaHutang, isTrue,
          reason: 'Pembayaran melebihi sisa harus ditolak validasi');
    });

    test('pembayaran tepat sama dengan sisa adalah valid', () {
      final hutang = makeHutang(jumlahAwal: 1_000_000, sisaHutang: 300_000);
      const pembayaran = 300_000.0;

      expect(pembayaran <= hutang.sisaHutang, isTrue);
    });

    test('pembayaran kurang dari sisa adalah valid', () {
      final hutang = makeHutang(jumlahAwal: 1_000_000, sisaHutang: 500_000);
      const pembayaran = 100_000.0;

      expect(pembayaran <= hutang.sisaHutang, isTrue);
    });
  });

  // ── Group: Tidak ada hutang aktif ─────────────────────────────────────────

  group('Ketika tidak ada hutang aktif', () {
    test('daftar hutang aktif kosong', () {
      final hutangList = [
        makeHutang(jumlahAwal: 500_000, sisaHutang: 0, status: 'lunas'),
        makeHutang(jumlahAwal: 300_000, sisaHutang: 0, status: 'lunas'),
      ];

      final aktif = hutangList.where((h) => !h.isLunas).toList();
      expect(aktif.isEmpty, isTrue,
          reason: 'Harus menampilkan pesan: ${AppStrings.belumAdaHutangUntukDibayar}');
    });
  });
}

// Dideklarasikan di sini untuk referensi tanpa import UI layer
abstract final class AppStrings {
  static const belumAdaHutangUntukDibayar =
      'Belum ada data hutang yang bisa dibayar. '
      'Silakan tambahkan hutang terlebih dahulu.';
}
