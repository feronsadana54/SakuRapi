// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'piutang_dao.dart';

// ignore_for_file: type=lint
mixin _$PiutangDaoMixin on DatabaseAccessor<AppDatabase> {
  $PiutangTableTable get piutangTable => attachedDatabase.piutangTable;
  $PaymentHistoryTableTable get paymentHistoryTable =>
      attachedDatabase.paymentHistoryTable;
  PiutangDaoManager get managers => PiutangDaoManager(this);
}

class PiutangDaoManager {
  final _$PiutangDaoMixin _db;
  PiutangDaoManager(this._db);
  $$PiutangTableTableTableManager get piutangTable =>
      $$PiutangTableTableTableManager(_db.attachedDatabase, _db.piutangTable);
  $$PaymentHistoryTableTableTableManager get paymentHistoryTable =>
      $$PaymentHistoryTableTableTableManager(
        _db.attachedDatabase,
        _db.paymentHistoryTable,
      );
}
