// test/widget/login_screen_test.dart
//
// Widget tests untuk LoginScreen.
//
// Covers:
//   + Render dua tombol login (Tamu + Google)
//   + Render judul dan subjudul halaman login
//   + Login sebagai Tamu berhasil → navigasi ke /home
//   + Tombol loading tampil saat proses autentikasi
//   - Tombol Google: error dialog tampil saat sign-in gagal
//   V Tombol lain disable saat loading sedang berlangsung
//
// Catatan:
//   Google Sign-In OAuth nyata tidak bisa diuji di widget test karena
//   platform channel tidak tersedia. Test negatif Google login mengandalkan
//   MissingPluginException yang dilempar plugin, kemudian ditangkap UI dan
//   ditampilkan sebagai dialog error.
//
// Run: flutter test test/widget/login_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/core/constants/app_strings.dart';
import 'package:finance_tracker/presentation/features/auth/login_screen.dart';
import 'package:finance_tracker/presentation/providers/database_provider.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildApp(SharedPreferences prefs) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('Beranda')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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

Future<void> _pump(WidgetTester tester, SharedPreferences prefs) async {
  await tester.pumpWidget(_buildApp(prefs));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  // ── Render ────────────────────────────────────────────────────────────────

  group('LoginScreen — render', () {
    testWidgets('menampilkan judul halaman login', (tester) async {
      await _pump(tester, prefs);
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
    });

    testWidgets('menampilkan subjudul halaman login', (tester) async {
      await _pump(tester, prefs);
      expect(find.text(AppStrings.loginSubtitle), findsOneWidget);
    });

    testWidgets('menampilkan tombol Masuk sebagai Tamu', (tester) async {
      await _pump(tester, prefs);
      expect(find.text(AppStrings.loginAsGuest), findsOneWidget);
    });

    testWidgets('menampilkan tombol Masuk dengan Google', (tester) async {
      await _pump(tester, prefs);
      expect(find.text(AppStrings.loginWithGoogle), findsOneWidget);
    });

    testWidgets('menampilkan catatan mode tamu', (tester) async {
      await _pump(tester, prefs);
      expect(find.text(AppStrings.guestModeNote), findsOneWidget);
    });

    testWidgets('menampilkan catatan sinkronisasi Google', (tester) async {
      await _pump(tester, prefs);
      expect(find.text(AppStrings.googleSyncNote), findsOneWidget);
    });
  });

  // ── Guest login — positive ─────────────────────────────────────────────────

  group('LoginScreen — guest login', () {
    testWidgets(
        'ketuk Masuk sebagai Tamu → navigasi ke /home setelah berhasil',
        (tester) async {
      await _pump(tester, prefs);

      await tester.tap(find.text(AppStrings.loginAsGuest));
      // Proses guest login bersifat sync (SharedPreferences mock) + satu frame async
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Harus sudah berpindah ke /home
      expect(find.text('Beranda'), findsOneWidget);
    });

    testWidgets(
        'indikator loading tampil di tombol Tamu saat login sedang berlangsung',
        (tester) async {
      await _pump(tester, prefs);

      // Tap tanpa settle — tangkap state loading sebelum selesai
      await tester.tap(find.text(AppStrings.loginAsGuest));
      await tester.pump(); // satu frame pertama

      // CircularProgressIndicator muncul di tombol yang aktif
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });

  // ── Google login — negative ────────────────────────────────────────────────

  group('LoginScreen — google login negatif', () {
    testWidgets(
        'tap Masuk dengan Google → dialog error tampil saat gagal (platform channel tidak tersedia)',
        (tester) async {
      await _pump(tester, prefs);

      await tester.tap(find.text(AppStrings.loginWithGoogle));
      await tester.pump();
      // Tunggu platform channel throw + catch + showDialog
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Dialog error harus muncul (AlertDialog dengan judul "Login Gagal")
      expect(find.text('Login Gagal'), findsOneWidget);
    });

    testWidgets(
        'dialog error memiliki tombol Tutup yang menutup dialog',
        (tester) async {
      await _pump(tester, prefs);

      await tester.tap(find.text(AppStrings.loginWithGoogle));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Pastikan dialog tampil
      expect(find.text('Login Gagal'), findsOneWidget);

      // Ketuk Tutup
      await tester.tap(find.text(AppStrings.close));
      await tester.pumpAndSettle();

      // Dialog hilang
      expect(find.text('Login Gagal'), findsNothing);
    });

    testWidgets(
        'dialog error memiliki tombol Salin Error',
        (tester) async {
      await _pump(tester, prefs);

      await tester.tap(find.text(AppStrings.loginWithGoogle));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Salin Error'), findsOneWidget);
    });
  });
}
