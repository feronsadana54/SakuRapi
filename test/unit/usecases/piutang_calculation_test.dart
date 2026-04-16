import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/domain/entities/piutang_entity.dart';
import 'package:finance_tracker/domain/entities/hutang_entity.dart';

void main() {
  final now = DateTime(2026, 4, 16);

  PiutangEntity makePiutang({
    required double jumlahAwal,
    required double sisaPiutang,
    required String status,
    List<PaymentRecord> payments = const [],
  }) {
    return PiutangEntity(
      id: 'test-piutang-1',
      namaPeminjam: 'Budi Santoso',
      jumlahAwal: jumlahAwal,
      sisaPiutang: sisaPiutang,
      tanggalPinjam: now,
      status: status,
      riwayatPembayaran: payments,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('PiutangEntity.progressPersen', () {
    test('returns 0.0 when nothing has been returned', () {
      final piutang = makePiutang(
        jumlahAwal: 1000000,
        sisaPiutang: 1000000,
        status: 'aktif',
      );
      expect(piutang.progressPersen, 0.0);
    });

    test('returns 0.25 when a quarter has been returned', () {
      final piutang = makePiutang(
        jumlahAwal: 1000000,
        sisaPiutang: 750000,
        status: 'aktif',
      );
      expect(piutang.progressPersen, 0.25);
    });

    test('returns 1.0 when fully returned', () {
      final piutang = makePiutang(
        jumlahAwal: 1000000,
        sisaPiutang: 0,
        status: 'lunas',
      );
      expect(piutang.progressPersen, 1.0);
    });

    test('clamps to 1.0 if sisaPiutang goes negative (safety)', () {
      final piutang = makePiutang(
        jumlahAwal: 1000000,
        sisaPiutang: -500,
        status: 'lunas',
      );
      expect(piutang.progressPersen, 1.0);
    });

    test('returns 0.0 when jumlahAwal is zero', () {
      final piutang = makePiutang(
        jumlahAwal: 0,
        sisaPiutang: 0,
        status: 'lunas',
      );
      expect(piutang.progressPersen, 0.0);
    });
  });

  group('PiutangEntity.totalDiterima', () {
    test('calculates total received correctly', () {
      final piutang = makePiutang(
        jumlahAwal: 3000000,
        sisaPiutang: 1000000,
        status: 'aktif',
      );
      expect(piutang.totalDiterima, 2000000);
    });

    test('is zero when nothing has been returned', () {
      final piutang = makePiutang(
        jumlahAwal: 500000,
        sisaPiutang: 500000,
        status: 'aktif',
      );
      expect(piutang.totalDiterima, 0.0);
    });
  });

  group('PiutangEntity.isLunas', () {
    test('returns true when status is lunas', () {
      final piutang = makePiutang(
        jumlahAwal: 1000000,
        sisaPiutang: 0,
        status: 'lunas',
      );
      expect(piutang.isLunas, isTrue);
    });

    test('returns false when status is aktif', () {
      final piutang = makePiutang(
        jumlahAwal: 1000000,
        sisaPiutang: 400000,
        status: 'aktif',
      );
      expect(piutang.isLunas, isFalse);
    });
  });

  group('PiutangEntity value equality', () {
    test('two entities with same data are equal', () {
      final p1 = makePiutang(
          jumlahAwal: 500000, sisaPiutang: 200000, status: 'aktif');
      final p2 = makePiutang(
          jumlahAwal: 500000, sisaPiutang: 200000, status: 'aktif');
      expect(p1, equals(p2));
    });

    test('two entities with different sisaPiutang are not equal', () {
      final p1 = makePiutang(
          jumlahAwal: 500000, sisaPiutang: 200000, status: 'aktif');
      final p2 = makePiutang(
          jumlahAwal: 500000, sisaPiutang: 150000, status: 'aktif');
      expect(p1, isNot(equals(p2)));
    });
  });

  group('PiutangEntity with payment history', () {
    test('riwayatPembayaran is reflected in entity', () {
      final payment = PaymentRecord(
        id: 'pay-piutang-1',
        amount: 300000,
        paidAt: now,
        catatan: 'Cicilan pertama',
      );
      final piutang = makePiutang(
        jumlahAwal: 1000000,
        sisaPiutang: 700000,
        status: 'aktif',
        payments: [payment],
      );
      expect(piutang.riwayatPembayaran.length, 1);
      expect(piutang.riwayatPembayaran.first.amount, 300000);
      expect(piutang.riwayatPembayaran.first.catatan, 'Cicilan pertama');
    });
  });
}
