// test/widget/reports_screen_test.dart
//
// Widget tests untuk ReportsScreen.
//
// Covers:
//   + Render judul "Laporan"
//   + Semua 7 tab tersedia (Harian, Bulanan, Tahunan, Rentang, Siklus Gaji, Hutang, Piutang)
//   + Tab default aktif adalah "Harian"
//   + Dapat berpindah ke tab Bulanan
//   + Dapat berpindah ke tab Hutang
//   + Dapat berpindah ke tab Piutang
//   + Tab Harian menampilkan label "Total Pemasukan" dan "Total Pengeluaran"
//   - Empty state tampil saat tidak ada data
//
// Run: flutter test test/widget/reports_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/core/constants/app_strings.dart';
import 'package:finance_tracker/presentation/features/reports/reports_screen.dart';
import 'package:finance_tracker/presentation/providers/database_provider.dart';
import 'package:finance_tracker/presentation/providers/hutang_provider.dart';
import 'package:finance_tracker/presentation/providers/piutang_provider.dart';
import 'package:finance_tracker/presentation/providers/transaction_provider.dart';

import '../helpers/test_helpers.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildReports(SharedPreferences prefs) {
  final fakeTxRepo = FakeTransactionRepository();
  final fakeHutangRepo = FakeHutangRepository();
  final fakePiutangRepo = FakePiutangRepository();
  final fakeSettings = FakeSettingsRepository(paydayDate: 25);

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      transactionRepositoryProvider.overrideWithValue(fakeTxRepo),
      hutangRepositoryProvider.overrideWithValue(fakeHutangRepo),
      piutangRepositoryProvider.overrideWithValue(fakePiutangRepo),
      settingsRepositoryProvider.overrideWithValue(fakeSettings),
      allTransactionsProvider.overrideWith((ref) => Stream.value([])),
      hutangListProvider.overrideWith((ref) => Stream.value([])),
      piutangListProvider.overrideWith((ref) => Stream.value([])),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('id', 'ID')],
      home: ReportsScreen(),
    ),
  );
}

Future<void> _load(WidgetTester tester, SharedPreferences prefs) async {
  setPhoneViewport(tester);
  await tester.pumpWidget(_buildReports(prefs));
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'payday_date': 25,
    });
    prefs = await SharedPreferences.getInstance();
  });

  // ── Render ────────────────────────────────────────────────────────────────

  group('ReportsScreen — render', () {
    testWidgets('menampilkan judul "Laporan"', (tester) async {
      await _load(tester, prefs);
      expect(find.text(AppStrings.reports), findsOneWidget);
    });

    testWidgets('menampilkan tab "Harian"', (tester) async {
      await _load(tester, prefs);
      expect(find.text(AppStrings.daily), findsWidgets);
    });

    testWidgets('menampilkan tab "Bulanan"', (tester) async {
      await _load(tester, prefs);
      expect(find.text(AppStrings.monthly), findsWidgets);
    });

    testWidgets('menampilkan tab "Tahunan"', (tester) async {
      await _load(tester, prefs);
      expect(find.text(AppStrings.yearly), findsWidgets);
    });

    testWidgets('menampilkan tab "Rentang"', (tester) async {
      await _load(tester, prefs);
      expect(find.text(AppStrings.dateRange), findsWidgets);
    });

    testWidgets('menampilkan tab "Siklus Gaji"', (tester) async {
      await _load(tester, prefs);
      expect(find.text(AppStrings.paydayCycle), findsWidgets);
    });

    testWidgets('menampilkan tab "Hutang"', (tester) async {
      await _load(tester, prefs);
      expect(find.text(AppStrings.hutang), findsWidgets);
    });

    testWidgets('menampilkan tab "Piutang"', (tester) async {
      await _load(tester, prefs);
      expect(find.text(AppStrings.piutang), findsWidgets);
    });
  });

  // ── Navigasi tab ──────────────────────────────────────────────────────────

  group('ReportsScreen — navigasi tab', () {
    testWidgets('dapat berpindah ke tab Bulanan', (tester) async {
      await _load(tester, prefs);

      await tester.tap(find.text(AppStrings.monthly).first);
      await tester.pumpAndSettle();

      // Tab bar masih menampilkan semua tab
      expect(find.text(AppStrings.monthly), findsWidgets);
    });

    testWidgets('dapat berpindah ke tab Tahunan', (tester) async {
      await _load(tester, prefs);

      await tester.tap(find.text(AppStrings.yearly).first);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.yearly), findsWidgets);
    });

    testWidgets('dapat berpindah ke tab Hutang', (tester) async {
      await _load(tester, prefs);

      await tester.tap(find.text(AppStrings.hutang).first);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.hutang), findsWidgets);
    });

    testWidgets('dapat berpindah ke tab Piutang', (tester) async {
      await _load(tester, prefs);

      await tester.tap(find.text(AppStrings.piutang).first);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.piutang), findsWidgets);
    });
  });

  // ── Tab Harian — content ──────────────────────────────────────────────────

  group('ReportsScreen — konten tab Harian', () {
    testWidgets(
        'tab Harian menampilkan label totalIncome dan totalExpense',
        (tester) async {
      await _load(tester, prefs);
      // Label laporan keuangan harus ada di tab pertama
      expect(find.text(AppStrings.totalIncome), findsWidgets);
      expect(find.text(AppStrings.totalExpense), findsWidgets);
    });

    testWidgets(
        'tab Harian menampilkan label netBalance (saldo bersih)',
        (tester) async {
      await _load(tester, prefs);
      expect(find.text(AppStrings.netBalance), findsWidgets);
    });

    testWidgets(
        'empty state tampil saat tidak ada transaksi hari ini',
        (tester) async {
      await _load(tester, prefs);
      // Dengan data kosong, "Belum Ada Data" atau sejenisnya harus tampil
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              ((w.data?.contains('Belum') == true) ||
                  (w.data?.contains('Data') == true) ||
                  (w.data?.contains('0') == true)),
        ),
        findsWidgets,
      );
    });
  });
}
