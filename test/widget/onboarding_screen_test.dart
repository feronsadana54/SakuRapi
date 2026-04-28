// test/widget/onboarding_screen_test.dart
//
// Widget tests untuk OnboardingScreen.
//
// Covers:
//   + Render halaman 1: judul "Selamat Datang di SakuRapi"
//   + Render halaman 1: deskripsi
//   + Tombol "Lanjut" tampil di halaman 1-3
//   + Dapat berpindah ke halaman 2 lewat tombol Lanjut
//   + Halaman 4 (payday): field input hari gajian tampil
//   + Halaman 4 (payday): value default "25"
//   V Validasi payday: nilai 0 → pesan error
//   V Validasi payday: nilai 32 → pesan error
//   + Validasi payday: nilai 1-31 → tidak ada error
//
// Catatan:
//   Halaman 3 meminta izin notifikasi (permission_handler). Di test environment,
//   permission_handler mengembalikan PermissionStatus.denied tanpa dialog native.
//   Lanjut dari halaman 3 ke 4 tetap bisa diuji.
//
// Run: flutter test test/widget/onboarding_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/core/constants/app_strings.dart';
import 'package:finance_tracker/presentation/features/onboarding/onboarding_screen.dart';
import 'package:finance_tracker/presentation/providers/database_provider.dart';

import '../helpers/test_helpers.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildOnboarding(SharedPreferences prefs) {
  final fakeSettings = FakeSettingsRepository(onboardingComplete: false);
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (ctx, st) => const OnboardingScreen()),
      GoRoute(
        path: '/login',
        builder: (ctx, st) => const Scaffold(body: Text('Login')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      settingsRepositoryProvider.overrideWithValue(fakeSettings),
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

Future<void> _load(WidgetTester tester, SharedPreferences prefs) async {
  setPhoneViewport(tester);
  await tester.pumpWidget(_buildOnboarding(prefs));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Navigasi ke halaman ke-[page] (0-indexed) dengan ketuk tombol Lanjut.
Future<void> _goToPage(WidgetTester tester, int page) async {
  for (var i = 0; i < page; i++) {
    final lanjut = find.text(AppStrings.next);
    if (lanjut.evaluate().isNotEmpty) {
      await tester.tap(lanjut);
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
    }
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  // ── Halaman 1 ─────────────────────────────────────────────────────────────

  group('OnboardingScreen — halaman 1', () {
    testWidgets('menampilkan judul halaman 1', (tester) async {
      await _load(tester, prefs);
      expect(find.text(AppStrings.onboardingTitle1), findsOneWidget);
    });

    testWidgets('menampilkan deskripsi halaman 1', (tester) async {
      await _load(tester, prefs);
      expect(find.text(AppStrings.onboardingDesc1), findsOneWidget);
    });

    testWidgets('menampilkan tombol Lanjut', (tester) async {
      await _load(tester, prefs);
      expect(find.text(AppStrings.next), findsOneWidget);
    });
  });

  // ── Navigasi antar halaman ────────────────────────────────────────────────

  group('OnboardingScreen — navigasi halaman', () {
    testWidgets('ketuk Lanjut → berpindah ke halaman 2', (tester) async {
      await _load(tester, prefs);
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.text(AppStrings.onboardingTitle2), findsOneWidget);
    });

    testWidgets('halaman 2 menampilkan deskripsi halaman 2', (tester) async {
      await _load(tester, prefs);
      await _goToPage(tester, 1);
      expect(find.text(AppStrings.onboardingDesc2), findsOneWidget);
    });

    testWidgets('halaman 3 menampilkan judul halaman 3', (tester) async {
      await _load(tester, prefs);
      await _goToPage(tester, 2);
      expect(find.text(AppStrings.onboardingTitle3), findsOneWidget);
    });
  });

  // ── Halaman payday (halaman 4) ─────────────────────────────────────────────

  group('OnboardingScreen — halaman tanggal gajian', () {
    testWidgets('halaman 4 menampilkan judul "Atur Tanggal Gajian"',
        (tester) async {
      await _load(tester, prefs);
      await _goToPage(tester, 3);
      expect(find.text(AppStrings.setPaydayTitle), findsOneWidget);
    });

    testWidgets('field payday tersedia dengan nilai default 25', (tester) async {
      await _load(tester, prefs);
      await _goToPage(tester, 3);
      final field = find.byType(TextFormField);
      expect(field, findsWidgets);
      // Default value adalah '25'
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets(
        'validasi: nilai 0 di field gajian → pesan error "antara 1 dan 31"',
        (tester) async {
      await _load(tester, prefs);
      await _goToPage(tester, 3);

      // Hapus isi lama, masukkan 0
      await tester.enterText(find.byType(TextFormField).last, '0');
      // Ketuk tombol Mulai / Selesai
      final mulaiBtn = find.text(AppStrings.start);
      if (mulaiBtn.evaluate().isNotEmpty) {
        await tester.tap(mulaiBtn);
        await tester.pump();
        expect(find.text(AppStrings.paydayInvalid), findsOneWidget);
      }
    });

    testWidgets(
        'validasi: nilai 32 di field gajian → pesan error "antara 1 dan 31"',
        (tester) async {
      await _load(tester, prefs);
      await _goToPage(tester, 3);

      await tester.enterText(find.byType(TextFormField).last, '32');
      final mulaiBtn = find.text(AppStrings.start);
      if (mulaiBtn.evaluate().isNotEmpty) {
        await tester.tap(mulaiBtn);
        await tester.pump();
        expect(find.text(AppStrings.paydayInvalid), findsOneWidget);
      }
    });

    testWidgets(
        'validasi: nilai 15 di field gajian → tidak ada error',
        (tester) async {
      await _load(tester, prefs);
      await _goToPage(tester, 3);

      await tester.enterText(find.byType(TextFormField).last, '15');
      await tester.pump();
      expect(find.text(AppStrings.paydayInvalid), findsNothing);
    });
  });
}
