import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/domain/entities/hutang_entity.dart';

void main() {
  final now = DateTime(2026, 4, 16);

  HutangEntity makeHutang({
    required double jumlahAwal,
    required double sisaHutang,
    required String status,
    List<PaymentRecord> payments = const [],
  }) {
    return HutangEntity(
      id: 'test-hutang-1',
      namaKreditur: 'Bank ABC',
      jumlahAwal: jumlahAwal,
      sisaHutang: sisaHutang,
      tanggalPinjam: now,
      status: status,
      riwayatPembayaran: payments,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('HutangEntity.progressPersen', () {
    test('returns 0.0 when nothing has been paid', () {
      final hutang = makeHutang(
        jumlahAwal: 1000000,
        sisaHutang: 1000000,
        status: 'aktif',
      );
      expect(hutang.progressPersen, 0.0);
    });

    test('returns 0.5 when half has been paid', () {
      final hutang = makeHutang(
        jumlahAwal: 1000000,
        sisaHutang: 500000,
        status: 'aktif',
      );
      expect(hutang.progressPersen, 0.5);
    });

    test('returns 1.0 when fully paid', () {
      final hutang = makeHutang(
        jumlahAwal: 1000000,
        sisaHutang: 0,
        status: 'lunas',
      );
      expect(hutang.progressPersen, 1.0);
    });

    test('clamps to 1.0 if sisaHutang goes negative (safety)', () {
      final hutang = makeHutang(
        jumlahAwal: 1000000,
        sisaHutang: -100,
        status: 'lunas',
      );
      expect(hutang.progressPersen, 1.0);
    });

    test('returns 0.0 when jumlahAwal is zero', () {
      final hutang = makeHutang(
        jumlahAwal: 0,
        sisaHutang: 0,
        status: 'lunas',
      );
      expect(hutang.progressPersen, 0.0);
    });
  });

  group('HutangEntity.totalDibayar', () {
    test('calculates total paid correctly', () {
      final hutang = makeHutang(
        jumlahAwal: 2000000,
        sisaHutang: 800000,
        status: 'aktif',
      );
      expect(hutang.totalDibayar, 1200000);
    });

    test('is zero when nothing has been paid', () {
      final hutang = makeHutang(
        jumlahAwal: 500000,
        sisaHutang: 500000,
        status: 'aktif',
      );
      expect(hutang.totalDibayar, 0.0);
    });
  });

  group('HutangEntity.isLunas', () {
    test('returns true when status is lunas', () {
      final hutang = makeHutang(
        jumlahAwal: 1000000,
        sisaHutang: 0,
        status: 'lunas',
      );
      expect(hutang.isLunas, isTrue);
    });

    test('returns false when status is aktif', () {
      final hutang = makeHutang(
        jumlahAwal: 1000000,
        sisaHutang: 300000,
        status: 'aktif',
      );
      expect(hutang.isLunas, isFalse);
    });
  });

  group('HutangEntity value equality', () {
    test('two entities with same data are equal', () {
      final h1 = makeHutang(
          jumlahAwal: 500000, sisaHutang: 200000, status: 'aktif');
      final h2 = makeHutang(
          jumlahAwal: 500000, sisaHutang: 200000, status: 'aktif');
      expect(h1, equals(h2));
    });

    test('two entities with different sisaHutang are not equal', () {
      final h1 = makeHutang(
          jumlahAwal: 500000, sisaHutang: 200000, status: 'aktif');
      final h2 = makeHutang(
          jumlahAwal: 500000, sisaHutang: 100000, status: 'aktif');
      expect(h1, isNot(equals(h2)));
    });
  });

  group('PaymentRecord', () {
    test('creates with required fields', () {
      final payment = PaymentRecord(
        id: 'pay-1',
        amount: 250000,
        paidAt: now,
      );
      expect(payment.amount, 250000);
      expect(payment.catatan, isNull);
    });

    test('two records with same data are equal', () {
      final p1 = PaymentRecord(id: 'pay-1', amount: 100000, paidAt: now);
      final p2 = PaymentRecord(id: 'pay-1', amount: 100000, paidAt: now);
      expect(p1, equals(p2));
    });
  });
}
