import '../entities/hutang_entity.dart';

abstract interface class IHutangRepository {
  Future<List<HutangEntity>> getAll();
  Future<HutangEntity?> getById(String id);
  Future<void> insert(HutangEntity hutang);
  Future<void> update(HutangEntity hutang);
  Future<void> delete(String id);
  Future<void> addPayment(String hutangId, PaymentRecord payment);
  Stream<List<HutangEntity>> watchAll();
}
