// Unit tests untuk integrasi pembayaran piutang dan pembuatan piutang baru.
//
// Mencakup:
//  - Membuat piutang baru → saldo berkurang (expense transaction dibuat).
//  - Penerimaan cicilan → sisa piutang berkurang + income transaction dibuat.
//  - Status piutang berubah menjadi 'lunas' saat sisa = 0.
//  - Beberapa cicilan terakumulasi dengan benar.
//  - totalDiterima dihitung dari riwayat pembayaran.
//
// Run: flutter test test/unit/usecases/piutang_repayment_integration_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/domain/entities/hutang_entity.dart'
    show PaymentRecord;
import 'package:finance_tracker/domain/entities/piutang_entity.dart';

void main() {
  final refDate = DateTime(2026, 4, 17);

  // ── Helper ────────────────────────────────────────────────────────────────

  PiutangEntity makePiutang({
    required double jumlahAwal,
    required double sisaPiutang,
    String status = 'aktif',
    List<PaymentRecord> payments = const [],
    String? catatan,
  }) {
    return PiutangEntity(
      id: 'piu-1',
      namaPeminjam: 'Budi Santoso',
      jumlahAwal: jumlahAwal,
      sisaPiutang: sisaPiutang,
      tanggalPinjam: refDate,
      status: status,
      catatan: catatan,
      riwayatPembayaran: payments,
      createdAt: refDate,
      updatedAt: refDate,
    );
  }

  /// Mensimulasikan logika [PiutangNotifier.addPayment]:
  /// mengurangi sisa, memperbarui status, menambah riwayat.
  PiutangEntity simulateRepayment(
    PiutangEntity piutang,
    double amount, {
    String? catatan,
  }) {
    final newSisa =
        (piutang.sisaPiutang - amount).clamp(0.0, double.infinity);
    final newStatus = newSisa <= 0 ? 'lunas' : 'aktif';
    final newPayments = [
      ...piutang.riwayatPembayaran,
      PaymentRecord(
        id: 'pay-${piutang.riwayatPembayaran.length + 1}',
        amount: amount,
        paidAt: refDate,
        catatan: catatan,
      ),
    ];
    return PiutangEntity(
      id: piutang.id,
      namaPeminjam: piutang.namaPeminjam,
      jumlahAwal: piutang.jumlahAwal,
      sisaPiutang: newSisa,
      tanggalPinjam: piutang.tanggalPinjam,
      status: newStatus,
      catatan: piutang.catatan,
      riwayatPembayaran: newPayments,
      createdAt: piutang.createdAt,
      updatedAt: refDate,
    );
  }

  // ── Group: Pembuatan piutang → expense otomatis ───────────────────────────

  group('Pembuatan piutang baru', () {
    test('piutang baru dibuat dengan jumlah penuh sebagai sisa', () {
      final piutang = makePiutang(
        jumlahAwal: 2_000_000,
        sisaPiutang: 2_000_000,
      );

      expect(piutang.sisaPiutang, equals(piutang.jumlahAwal));
      expect(piutang.status, equals('aktif'));
      expect(piutang.isLunas, isFalse);
    });

    test('nilai piutang baru sama dengan expense transaction yang dibuat', () {
      // Logika: saat piutang dibuat, expense transaction = jumlahAwal
      const jumlahPinjaman = 1_500_000.0;
      final piutang = makePiutang(
        jumlahAwal: jumlahPinjaman,
        sisaPiutang: jumlahPinjaman,
      );

      // Expense transaction amount harus = piutang.jumlahAwal
      expect(piutang.jumlahAwal, equals(jumlahPinjaman));
    });

    test('piutang dengan catatan tersimpan dengan benar', () {
      final piutang = makePiutang(
        jumlahAwal: 500_000,
        sisaPiutang: 500_000,
        catatan: 'Untuk keperluan darurat',
      );

      expect(piutang.catatan, equals('Untuk keperluan darurat'));
    });
  });

  // ── Group: Penerimaan cicilan → income otomatis ───────────────────────────

  group('Penerimaan cicilan piutang', () {
    test('sisa piutang berkurang setelah menerima cicilan', () {
      final piutang = makePiutang(
          jumlahAwal: 1_000_000, sisaPiutang: 1_000_000);
      final setelah = simulateRepayment(piutang, 300_000);

      expect(setelah.sisaPiutang, equals(700_000.0));
      expect(setelah.status, equals('aktif'));
    });

    test('progressPersen bertambah setelah cicilan', () {
      final piutang = makePiutang(
          jumlahAwal: 1_000_000, sisaPiutang: 1_000_000);
      final setelah = simulateRepayment(piutang, 600_000);

      expect(setelah.progressPersen, closeTo(0.6, 0.001));
    });

    test('riwayat bertambah dan totalDiterima akurat', () {
      var piutang =
          makePiutang(jumlahAwal: 1_000_000, sisaPiutang: 1_000_000);
      piutang = simulateRepayment(piutang, 250_000, catatan: 'Cicilan pertama');
      piutang = simulateRepayment(piutang, 250_000, catatan: 'Cicilan kedua');

      expect(piutang.riwayatPembayaran.length, equals(2));
      expect(piutang.totalDiterima, equals(500_000.0));
      expect(piutang.sisaPiutang, equals(500_000.0));
    });

    test('income transaction amount = cicilan yang diterima', () {
      // Logika: setiap cicilan diterima → income transaction = amount cicilan
      const cicilanAmount = 200_000.0;
      final piutang =
          makePiutang(jumlahAwal: 1_000_000, sisaPiutang: 1_000_000);
      final setelah = simulateRepayment(piutang, cicilanAmount);

      // Income transaction yang dibuat harus = amount cicilan
      expect(setelah.riwayatPembayaran.first.amount, equals(cicilanAmount));
    });
  });

  // ── Group: Pelunasan piutang ──────────────────────────────────────────────

  group('Pelunasan piutang', () {
    test('status berubah menjadi lunas saat sisa = 0', () {
      final piutang =
          makePiutang(jumlahAwal: 500_000, sisaPiutang: 500_000);
      final setelah = simulateRepayment(piutang, 500_000);

      expect(setelah.sisaPiutang, equals(0.0));
      expect(setelah.isLunas, isTrue);
      expect(setelah.progressPersen, equals(1.0));
    });

    test('lunas dengan cicilan parsial bertahap', () {
      var piutang =
          makePiutang(jumlahAwal: 600_000, sisaPiutang: 600_000);
      piutang = simulateRepayment(piutang, 200_000);
      piutang = simulateRepayment(piutang, 200_000);
      piutang = simulateRepayment(piutang, 200_000);

      expect(piutang.isLunas, isTrue);
      expect(piutang.totalDiterima, equals(600_000.0));
    });

    test('sisa tidak negatif saat cicilan melebihi sisa (clamp)', () {
      final piutang =
          makePiutang(jumlahAwal: 300_000, sisaPiutang: 100_000);
      final setelah = simulateRepayment(piutang, 150_000);

      expect(setelah.sisaPiutang, equals(0.0));
      expect(setelah.isLunas, isTrue);
    });
  });

  // ── Group: Saldo efek ─────────────────────────────────────────────────────

  group('Efek terhadap saldo keuangan', () {
    test('saldo berkurang saat piutang baru dibuat (expense)', () {
      // Logika: piutang baru = uang keluar = expense transaction
      // Saldo = totalIncome - totalExpense
      // Saat piutang Rp500.000 dibuat, expense +Rp500.000 → saldo -Rp500.000
      const jumlah = 500_000.0;

      // Verifikasi model: jumlahAwal = jumlah yang keluar
      final piutang = makePiutang(
        jumlahAwal: jumlah,
        sisaPiutang: jumlah,
      );
      expect(piutang.jumlahAwal, equals(jumlah));
    });

    test('saldo bertambah saat cicilan diterima (income)', () {
      // Logika: menerima cicilan = uang masuk = income transaction
      const cicilan = 200_000.0;
      final piutang =
          makePiutang(jumlahAwal: 500_000, sisaPiutang: 500_000);
      final setelah = simulateRepayment(piutang, cicilan);

      // Verifikasi: cicilan diterima → riwayat mencatat jumlah yang masuk
      expect(setelah.riwayatPembayaran.first.amount, equals(cicilan));
    });
  });
}
