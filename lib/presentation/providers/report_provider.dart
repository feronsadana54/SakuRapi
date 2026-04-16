import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../domain/entities/summary_result.dart';
import 'database_provider.dart';
import 'settings_provider.dart';

// ── Base fetch provider ───────────────────────────────────────────────────────

/// Fetches and aggregates transactions for a date range.
/// Family parameter is a Dart 3 record — structural equality by default.
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

/// Null means no range selected yet.
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
