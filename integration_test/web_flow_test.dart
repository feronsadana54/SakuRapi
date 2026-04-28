// integration_test/web_flow_test.dart
//
// Integration tests untuk web flow SakuRapi.
//
// Test ini menjalankan aplikasi penuh (app.main()) dan memverifikasi
// alur navigasi end-to-end yang relevan untuk web.
//
// PENTING — Web limitations yang diketahui:
//   - Firebase Auth tidak terinisialisasi dengan benar karena tidak ada
//     konfigurasi CORS / Firebase Hosting dalam test environment.
//     App sudah handle ini dengan timeout 10 detik (fail-safe ke /home).
//   - Google Sign-In tidak bisa diuji karena memerlukan OAuth flow asli.
//   - flutter_local_notifications dinonaktifkan di web (app sudah guard ini).
//   - SQLite/Drift menggunakan WASM di web; test membutuhkan server wasm
//     yang tersedia saat flutter test -d chrome dijalankan.
//
// Jalankan di Chrome:
//   flutter test integration_test/web_flow_test.dart -d chrome

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/core/constants/app_strings.dart';
import 'package:finance_tracker/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── 1. Fresh install → onboarding ─────────────────────────────────────────

  testWidgets('fresh install: splash → onboarding', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await tester.pump();

    // Splash masih tampil
    expect(find.text(AppStrings.appName), findsOneWidget);

    // Lewati splash delay
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Harus berpindah dari splash
    expect(find.text(AppStrings.tagline), findsNothing,
        reason: 'App masih di splash — kemungkinan hang');
  });

  // ── 2. Onboarding selesai → login ─────────────────────────────────────────

  testWidgets('onboarding selesai tapi belum login → layar login',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('onboarding_complete', true);
    // Tidak ada auth key → getCurrentUser() return null → /login

    app.main();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text(AppStrings.loginTitle), findsOneWidget);
    expect(find.text(AppStrings.loginAsGuest), findsOneWidget);
    expect(find.text(AppStrings.loginWithGoogle), findsOneWidget);
  });

  // ── 3. Login tamu → home ───────────────────────────────────────────────────

  testWidgets('guest login: ketuk Masuk sebagai Tamu → layar home',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('onboarding_complete', true);

    app.main();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Harus ada di login screen
    expect(find.text(AppStrings.loginAsGuest), findsOneWidget);

    await tester.tap(find.text(AppStrings.loginAsGuest));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Home screen: AppBar berisi nama app
    expect(find.text(AppStrings.appName), findsWidgets);
    // Navigasi bar bawah tampil
    expect(find.text(AppStrings.navHome), findsOneWidget);
  });

  // ── 4. Home screen: bottom nav ─────────────────────────────────────────────

  testWidgets('home: bottom navigation bar menampilkan semua item nav',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('saku_auth_id', 'test-guest-id');
    await prefs.setString('saku_auth_name', 'Tamu');
    await prefs.setString('saku_auth_mode', 'guest');

    app.main();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text(AppStrings.navHome), findsOneWidget);
    expect(find.text(AppStrings.navTransactions), findsOneWidget);
    expect(find.text(AppStrings.navReports), findsOneWidget);
    expect(find.text(AppStrings.navSettings), findsOneWidget);
  });

  // ── 5. Navigasi ke Transaksi ────────────────────────────────────────────────

  testWidgets('navigasi ke layar Transaksi dari bottom nav', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('saku_auth_id', 'test-guest-id');
    await prefs.setString('saku_auth_name', 'Tamu');
    await prefs.setString('saku_auth_mode', 'guest');

    app.main();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text(AppStrings.navTransactions));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.navTransactions), findsWidgets);
  });

  // ── 6. Navigasi ke Laporan ─────────────────────────────────────────────────

  testWidgets('navigasi ke layar Laporan dari bottom nav', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('saku_auth_id', 'test-guest-id');
    await prefs.setString('saku_auth_name', 'Tamu');
    await prefs.setString('saku_auth_mode', 'guest');

    app.main();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text(AppStrings.navReports));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reports), findsOneWidget);
    // Tab Harian harus ada
    expect(find.text(AppStrings.daily), findsWidgets);
  });

  // ── 7. Navigasi ke Pengaturan ──────────────────────────────────────────────

  testWidgets('navigasi ke layar Pengaturan dari bottom nav', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('saku_auth_id', 'test-guest-id');
    await prefs.setString('saku_auth_name', 'Tamu');
    await prefs.setString('saku_auth_mode', 'guest');

    app.main();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text(AppStrings.navSettings));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.settings), findsOneWidget);
  });

  // ── 8. Form transaksi terbuka dari FAB ─────────────────────────────────────

  testWidgets('ketuk FAB di home → form tambah transaksi terbuka',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('saku_auth_id', 'test-guest-id');
    await prefs.setString('saku_auth_name', 'Tamu');
    await prefs.setString('saku_auth_mode', 'guest');

    app.main();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Pastikan di home
    expect(find.text(AppStrings.navHome), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Form transaksi terbuka
    expect(find.text(AppStrings.addTransaction), findsOneWidget);
  });

  // Expose binding untuk CI.
  tearDownAll(() {
    binding.reportData ??= <String, dynamic>{};
  });
}
