import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../domain/entities/summary_result.dart';
import 'database_provider.dart';
import 'settings_provider.dart';

// ── Base fetch provider ───────────────────────────────────────────────────────

/// Provider laporan dasar yang mengambil dan mengagregasi transaksi untuk rentang tanggal apapun.
///
/// Menggunakan Dart 3 record `(DateTime start, DateTime end)` sebagai family key —
/// record memiliki kesetaraan struktural, sehingga dua provider dengan rentang yang sama
/// berbagi hasil cache yang sama tanpa class [Equatable] khusus.
///
/// Dipanggil oleh semua provider laporan turunan (harian, bulanan, tahunan, rentang,
/// siklus gaji). Tidak dipanggil langsung oleh layar UI.
final reportSummaryProvider =
    FutureProvider.family<SummaryResult, (DateTime, DateTime)>(
  (ref, range) async {
    final repo = ref.watch(transactionRepositoryProvider);
    final txs = await repo.getByDateRange(range.$1, range.$2);
    return SummaryResult.fromTransactions(txs);
  },
);

// ── Per-tab state providers ───────────────────────────────────────────────────

final selectedDayProvider = StateProvider<DateTime>(
  (ref) => AppDateUtils.dateOnly(DateTime.now()),
);

final selectedMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime(DateTime.now().year, DateTime.now().month, 1),
);

final selectedYearProvider = StateProvider<int>(
  (ref) => DateTime.now().year,
);

/// Null berarti pengguna belum memilih rentang tanggal di tab Rentang.
/// [rangeReportProvider] mengembalikan null saat ini null.
final selectedRangeProvider = StateProvider<DateTimeRange?>((_) => null);

// ── Derived report providers ──────────────────────────────────────────────────

final dailyReportProvider = Provider<AsyncValue<SummaryResult>>((ref) {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(
    reportSummaryProvider((
      AppDateUtils.startOfDay(day),
      AppDateUtils.endOfDay(day),
    )),
  );
});

final monthlyReportProvider = Provider<AsyncValue<SummaryResult>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(
    reportSummaryProvider((
      AppDateUtils.firstDayOfMonth(month),
      AppDateUtils.lastDayOfMonth(month),
    )),
  );
});

final yearlyReportProvider = Provider<AsyncValue<SummaryResult>>((ref) {
  final year = ref.watch(selectedYearProvider);
  final ref_ = DateTime(year, 1, 1);
  return ref.watch(
    reportSummaryProvider((
      AppDateUtils.firstDayOfYear(ref_),
      AppDateUtils.lastDayOfYear(ref_),
    )),
  );
});

final rangeReportProvider = Provider<AsyncValue<SummaryResult>?>((ref) {
  final range = ref.watch(selectedRangeProvider);
  if (range == null) return null;
  return ref.watch(
    reportSummaryProvider((
      AppDateUtils.startOfDay(range.start),
      AppDateUtils.endOfDay(range.end),
    )),
  );
});

/// Menghitung ringkasan siklus gajian beserta tanggal mulai/akhirnya.
///
/// Logika siklus gajian (ditangani oleh [AppDateUtils.getPaydayCycle]):
///   - Membaca paydayDate dari settings (default 25).
///   - "Siklus saat ini" = dari tanggal gajian terakhir yang sudah lewat
///     hingga (tidak termasuk) tanggal gajian berikutnya.
///   - Contoh dengan paydayDate=25 pada 2026-04-16:
///       mulai siklus = 2026-03-25, akhir siklus = 2026-04-24.
///
/// Mengembalikan `(SummaryResult, startDate, endDate)` agar UI dapat menampilkan
/// baik total maupun label rentang tanggal siklus.
final paydayCycleReportProvider =
    Provider<AsyncValue<(SummaryResult, DateTime, DateTime)>>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (settings) {
      final (start, end) = AppDateUtils.getPaydayCycle(
        paydayDate: settings.paydayDate,
      );
      final summaryAsync = ref.watch(reportSummaryProvider((start, end)));
      return summaryAsync.when(
        loading: () => const AsyncLoading(),
        error: (e, st) => AsyncError(e, st),
        data: (s) => AsyncData((s, start, end)),
      );
    },
  );
});
