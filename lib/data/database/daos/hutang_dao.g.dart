// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hutang_dao.dart';

// ignore_for_file: type=lint
mixin _$HutangDaoMixin on DatabaseAccessor<AppDatabase> {
  $HutangTableTable get hutangTable => attachedDatabase.hutangTable;
  $PaymentHistoryTableTable get paymentHistoryTable =>
      attachedDatabase.paymentHistoryTable;
  HutangDaoManager get managers => HutangDaoManager(this);
}

class HutangDaoManager {
  final _$HutangDaoMixin _db;
  HutangDaoManager(this._db);
  $$HutangTableTableTableManager get hutangTable =>
      $$HutangTableTableTableManager(_db.attachedDatabase, _db.hutangTable);
  $$PaymentHistoryTableTableTableManager get paymentHistoryTable =>
      $$PaymentHistoryTableTableTableManager(
        _db.attachedDatabase,
        _db.paymentHistoryTable,
      );
}
