import 'package:drift/drift.dart';

@DataClassName('HutangData')
class HutangTable extends Table {
  @override
  String get tableName => 'hutang';

  TextColumn get id => text()();
  TextColumn get namaKreditur => text()();
  RealColumn get jumlahAwal => real()();
  RealColumn get sisaHutang => real()();
  IntColumn get tanggalPinjam => integer()();      // epoch ms
  IntColumn get tanggalJatuhTempo => integer().nullable()();
  TextColumn get catatan => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('aktif'))(); // 'aktif' | 'lunas'
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
