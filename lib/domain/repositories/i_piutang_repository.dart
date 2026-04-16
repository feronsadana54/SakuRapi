import '../entities/hutang_entity.dart';
import '../entities/piutang_entity.dart';

abstract interface class IPiutangRepository {
  Future<List<PiutangEntity>> getAll();
  Future<PiutangEntity?> getById(String id);
  Future<void> insert(PiutangEntity piutang);
  Future<void> update(PiutangEntity piutang);
  Future<void> delete(String id);
  Future<void> addPayment(String piutangId, PaymentRecord payment);
  Stream<List<PiutangEntity>> watchAll();
}
