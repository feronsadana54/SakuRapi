import 'package:equatable/equatable.dart';

import 'hutang_entity.dart';

class PiutangEntity extends Equatable {
  final String id;
  final String namaPeminjam;
  final double jumlahAwal;
  final double sisaPiutang;
  final DateTime tanggalPinjam;
  final DateTime? tanggalJatuhTempo;
  final String? catatan;
  final String status; // 'aktif' | 'lunas'
  final List<PaymentRecord> riwayatPembayaran;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PiutangEntity({
    required this.id,
    required this.namaPeminjam,
    required this.jumlahAwal,
    required this.sisaPiutang,
    required this.tanggalPinjam,
    this.tanggalJatuhTempo,
    this.catatan,
    required this.status,
    required this.riwayatPembayaran,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLunas => status == 'lunas';
  double get totalDiterima => jumlahAwal - sisaPiutang;
  double get progressPersen =>
      jumlahAwal > 0 ? (totalDiterima / jumlahAwal).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [
        id,
        namaPeminjam,
        jumlahAwal,
        sisaPiutang,
        tanggalPinjam,
        tanggalJatuhTempo,
        catatan,
        status,
        riwayatPembayaran,
        createdAt,
        updatedAt,
      ];
}
