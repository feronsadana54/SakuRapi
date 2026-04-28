// test/widget/home_screen_test.dart
//
// Widget tests untuk HomeScreen.
//
// Covers:
//   + Render AppBar dengan nama app
//   + FAB untuk tambah transaksi
//   + Empty state saat tidak ada transaksi
//   + Render label ringkasan (Pemasukan, Pengeluaran, Saldo)
//   + Render daftar transaksi terbaru saat data tersedia
//   + Render kartu saldo dengan nilai yang benar
//   - Error state saat provider gagal
//   + Navigasi FAB ke form transaksi
//
// Run: flutter test test/widget/home_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/core/constants/app_strings.dart';
import 'package:finance_tracker/domain/entities/transaction_entity.dart';
import 'package:finance_tracker/presentation/features/home/home_screen.dart';
import 'package:finance_tracker/presentation/providers/database_provider.dart';
import 'package:finance_tracker/presentation/providers/transaction_provider.dart';
import 'package:finance_tracker/router/app_router.dart';

import '../helpers/test_helpers.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildApp({
  required SharedPreferences prefs,
  required List<Transaction> txList,
  bool providerError = false,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (ctx, st) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.transactionAdd,
        builder: (ctx, st) => const Scaffold(body: Text('Form Transaksi')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      allTransactionsProvider.overrideWith(
        (ref) => providerError
            ? Stream.error(Exception('db error'))
            : Stream.value(txList),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID')],
    ),
  );
}

Future<void> _load(WidgetTester tester, Widget app) async {
  setPhoneViewport(tester);
  await tester.pumpWidget(app);
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
      'onboarding_complete': true,
      'saku_auth_id': 'test-guest-id',
      'saku_auth_name': 'Tamu',
      'saku_auth_mode': 'guest',
    });
    prefs = await SharedPreferences.getInstance();
  });

  // ── Render ────────────────────────────────────────────────────────────────

  group('HomeScreen — render dasar', () {
    testWidgets('menampilkan nama aplikasi di AppBar', (tester) async {
      await _load(tester, _buildApp(prefs: prefs, txList: []));
      expect(find.text(AppStrings.appName), findsWidgets);
    });

    testWidgets('FAB untuk tambah transaksi tampil', (tester) async {
      await _load(tester, _buildApp(prefs: prefs, txList: []));
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('tooltip FAB adalah addTransaction', (tester) async {
      await _load(tester, _buildApp(prefs: prefs, txList: []));
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.tooltip, AppStrings.addTransaction);
    });
  });

  // ── Empty state ───────────────────────────────────────────────────────────

  group('HomeScreen — empty state', () {
    testWidgets('menampilkan "Belum Ada Transaksi" saat data kosong',
        (tester) async {
      await _load(tester, _buildApp(prefs: prefs, txList: []));
      expect(find.text(AppStrings.noTransactions), findsOneWidget);
    });

    testWidgets('menampilkan deskripsi empty state', (tester) async {
      await _load(tester, _buildApp(prefs: prefs, txList: []));
      expect(find.text(AppStrings.noTransactionsDesc), findsOneWidget);
    });
  });

  // ── Data state ────────────────────────────────────────────────────────────

  group('HomeScreen — dengan data', () {
    testWidgets('menampilkan ringkasan keuangan saat ada transaksi',
        (tester) async {
      final txs = [
        makeIncomeTx('tx-1'),
        makeExpenseTx('tx-2'),
      ];
      await _load(tester, _buildApp(prefs: prefs, txList: txs));

      // Label ringkasan keuangan harus tampil
      expect(find.text(AppStrings.income), findsWidgets);
      expect(find.text(AppStrings.expense), findsWidgets);
    });

    testWidgets(
        'daftar transaksi terbaru tampil saat ada data (kategori terbaru terlihat)',
        (tester) async {
      final txs = [makeIncomeTx('tx-1')];
      await _load(tester, _buildApp(prefs: prefs, txList: txs));
      // Nama kategori income harus tampil di tile transaksi
      expect(find.text(kIncomeCategory.name), findsWidgets);
    });

    testWidgets(
        'header "Transaksi Terbaru" tampil saat ada data',
        (tester) async {
      final txs = [makeExpenseTx('tx-1')];
      await _load(tester, _buildApp(prefs: prefs, txList: txs));
      expect(find.text(AppStrings.recentTransactions), findsOneWidget);
    });

    testWidgets(
        'label "Saldo" atau "Pemasukan" muncul dengan nominal yang benar',
        (tester) async {
      final txs = [makeIncomeTx('tx-1')]; // 5.000.000
      await _load(tester, _buildApp(prefs: prefs, txList: txs));

      // CurrencyFormatter.full(5_000_000) → 'Rp 5.000.000'
      expect(find.textContaining('5.000.000'), findsWidgets);
    });
  });

  // ── Error state ───────────────────────────────────────────────────────────

  group('HomeScreen — error state', () {
    testWidgets('menampilkan pesan error saat provider gagal',
        (tester) async {
      await _load(
          tester, _buildApp(prefs: prefs, txList: [], providerError: true));
      expect(find.text(AppStrings.errorLoad), findsOneWidget);
    });
  });

  // ── Navigasi ──────────────────────────────────────────────────────────────

  group('HomeScreen — navigasi', () {
    testWidgets('ketuk FAB → pindah ke form tambah transaksi', (tester) async {
      await _load(tester, _buildApp(prefs: prefs, txList: []));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Form Transaksi'), findsOneWidget);
    });
  });
}
