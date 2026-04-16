import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../domain/entities/transaction_entity.dart';
import 'database_provider.dart';

// ── Reactive stream of all transactions ───────────────────────────────────────

/// Mengekspos seluruh riwayat transaksi sebagai [Stream] reaktif.
///
/// Didukung oleh [TransactionRepositoryImpl.watchAll], yang mendelegasikan ke
/// [TransactionDao.watchAll] — query SELECT Drift yang otomatis memancarkan ulang
/// setiap kali tabel `transactions` berubah.
///
/// Diawasi oleh:
/// - [homeSummaryProvider] — untuk kartu saldo dan ringkasan hari ini.
/// - [TransactionListScreen] — untuk daftar transaksi yang dapat di-scroll.
/// - [reportSummaryProvider] — melalui query rentang tanggal (tidak stream ini langsung).
final allTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

// ── Home screen aggregated summary ───────────────────────────────────────────

/// Ringkasan data keuangan yang sudah dihitung sebelumnya untuk [HomeScreen].
///
/// Diturunkan secara sinkron dari [allTransactionsProvider] sehingga layar home
/// tidak perlu berlangganan ke banyak provider secara terpisah.
class HomeSummary {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final double todayIncome;
  final double todayExpense;
  final List<Transaction> recentTransactions;

  const HomeSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.todayIncome,
    required this.todayExpense,
    required this.recentTransactions,
  });

  static const empty = HomeSummary(
    totalBalance: 0,
    totalIncome: 0,
    totalExpense: 0,
    todayIncome: 0,
    todayExpense: 0,
    recentTransactions: [],
  );
}

/// Menghitung semua transaksi menjadi satu [HomeSummary] dalam satu iterasi.
///
/// Dihitung ulang setiap kali [allTransactionsProvider] memancarkan data baru —
/// yang terjadi setelah setiap insert, update, atau delete via stream reaktif Drift.
///
/// Digunakan secara eksklusif oleh [HomeScreen]. Layar laporan menggunakan
/// [reportSummaryProvider] dengan parameter rentang tanggal eksplisit.
final homeSummaryProvider = Provider<AsyncValue<HomeSummary>>((ref) {
  return ref.watch(allTransactionsProvider).whenData((txs) {
    final today = AppDateUtils.dateOnly(DateTime.now());

    double allIncome = 0;
    double allExpense = 0;
    double todayIncome = 0;
    double todayExpense = 0;

    for (final tx in txs) {
      if (tx.isIncome) {
        allIncome += tx.amount;
        if (AppDateUtils.dateOnly(tx.date) == today) todayIncome += tx.amount;
      } else {
        allExpense += tx.amount;
        if (AppDateUtils.dateOnly(tx.date) == today) todayExpense += tx.amount;
      }
    }

    return HomeSummary(
      totalBalance: allIncome - allExpense,
      totalIncome: allIncome,
      totalExpense: allExpense,
      todayIncome: todayIncome,
      todayExpense: todayExpense,
      recentTransactions: txs.take(7).toList(),
    );
  });
});
