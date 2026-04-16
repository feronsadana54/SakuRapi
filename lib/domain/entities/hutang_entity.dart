import 'package:equatable/equatable.dart';

class PaymentRecord extends Equatable {
  final String id;
  final double amount;
  final DateTime paidAt;
  final String? catatan;

  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.catatan,
  });

  @override
  List<Object?> get props => [id, amount, paidAt, catatan];
}

class HutangEntity extends Equatable {
  final String id;
  final String namaKreditur;
  final double jumlahAwal;
  final double sisaHutang;
  final DateTime tanggalPinjam;
  final DateTime? tanggalJatuhTempo;
  final String? catatan;
  final String status; // 'aktif' | 'lunas'
  final List<PaymentRecord> riwayatPembayaran;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HutangEntity({
    required this.id,
    required this.namaKreditur,
    required this.jumlahAwal,
    required this.sisaHutang,
    required this.tanggalPinjam,
    this.tanggalJatuhTempo,
    this.catatan,
    required this.status,
    required this.riwayatPembayaran,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLunas => status == 'lunas';
  double get totalDibayar => jumlahAwal - sisaHutang;
  double get progressPersen =>
      jumlahAwal > 0 ? (totalDibayar / jumlahAwal).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [
        id,
        namaKreditur,
        jumlahAwal,
        sisaHutang,
        tanggalPinjam,
        tanggalJatuhTempo,
        catatan,
        status,
        riwayatPembayaran,
        createdAt,
        updatedAt,
      ];
}
