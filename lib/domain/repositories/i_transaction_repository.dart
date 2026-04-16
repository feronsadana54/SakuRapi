import '../entities/transaction_entity.dart';

abstract interface class ITransactionRepository {
  /// Reactive stream of all transactions, sorted by date descending.
  Stream<List<Transaction>> watchAll();

  /// Returns all transactions within [startDate]–[endDate] inclusive.
  Future<List<Transaction>> getByDateRange(DateTime startDate, DateTime endDate);

  Future<Transaction?> getById(String id);

  Future<void> insert(Transaction transaction);

  Future<void> update(Transaction transaction);

  Future<void> delete(String id);
}
