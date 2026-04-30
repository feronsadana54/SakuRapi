// test/widget/hutang_form_test.dart
//
// Widget tests untuk HutangFormScreen.
//
// Covers:
//   + Render judul "Tambah Hutang"
//   + Field namaKreditur, jumlahAwal, tanggalPinjam, catatan
//   + Tombol Simpan
//   + Tombol Close di AppBar
//   V Validasi: namaKreditur kosong → "Nama harus diisi"
//   V Validasi: jumlahAwal kosong → "Jumlah tidak boleh kosong"
//   V Validasi: jumlahAwal 0 → "Jumlah harus lebih dari 0"
//   + Mode edit: judul "Edit Hutang" dan field terisi data lama
//   + Preview format Rupiah di atas field jumlah
//   + Field tanggal jatuh tempo (opsional) tampil
//
// Run: flutter test test/widget/hutang_form_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/core/constants/app_strings.dart';
import 'package:finance_tracker/domain/entities/hutang_entity.dart';
import 'package:finance_tracker/presentation/features/hutang/hutang_form_screen.dart';
import 'package:finance_tracker/presentation/providers/database_provider.dart';
import 'package:finance_tracker/presentation/providers/hutang_provider.dart';
import 'package:finance_tracker/presentation/providers/transaction_provider.dart';

import '../helpers/test_helpers.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildForm({
  required SharedPreferences prefs,
  HutangEntity? editHutang,
}) {
  final fakeHutangRepo = FakeHutangRepository();
  final fakeTxRepo = FakeTransactionRepository();

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => HutangFormScreen(editHutang: editHutang),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      hutangRepositoryProvider.overrideWithValue(fakeHutangRepo),
      transactionRepositoryProvider.overrideWithValue(fakeTxRepo),
      allTransactionsProvider.overrideWith((ref) => Stream.value([])),
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Finder get _saveBtn => find.text(AppStrings.save);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  // ── Render ────────────────────────────────────────────────────────────────

  group('HutangFormScreen — render', () {
    testWidgets('menampilkan judul "Tambah Hutang"', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      expect(find.text(AppStrings.tambahHutang), findsOneWidget);
    });

    testWidgets('menampilkan label namaKreditur', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      expect(find.text(AppStrings.namaKreditur), findsOneWidget);
    });

    testWidgets('menampilkan label jumlahAwal', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      expect(find.text(AppStrings.jumlahAwal), findsOneWidget);
    });

    testWidgets('menampilkan label tanggalPinjam', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      expect(find.text(AppStrings.tanggalPinjam), findsOneWidget);
    });

    testWidgets('menampilkan label tanggalJatuhTempo (opsional)', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      expect(find.textContaining(AppStrings.tanggalJatuhTempo), findsWidgets);
    });

    testWidgets('menampilkan tombol Simpan', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      expect(_saveBtn, findsOneWidget);
    });

    testWidgets('menampilkan tombol Close di AppBar', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('preview jumlah menampilkan "Rp 0" saat field kosong',
        (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      // ValueListenableBuilder preview di atas field jumlah
      expect(find.textContaining('0'), findsWidgets);
    });
  });

  // ── Validasi ──────────────────────────────────────────────────────────────

  group('HutangFormScreen — validasi', () {
    testWidgets('save tanpa namaKreditur → "Nama harus diisi"', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      await tester.tap(_saveBtn);
      await tester.pump();
      expect(find.text('Nama harus diisi'), findsOneWidget);
    });

    testWidgets('save tanpa jumlah → "Jumlah tidak boleh kosong"',
        (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      // Isi nama agar melewati validasi nama
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan nama kreditur'), 'Bank X');
      await tester.tap(_saveBtn);
      await tester.pump();
      expect(find.text('Jumlah tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('save dengan jumlah 0 → "Jumlah harus lebih dari 0"',
        (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan nama kreditur'), 'Bank X');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan jumlah hutang'), '0');
      await tester.tap(_saveBtn);
      await tester.pump();
      expect(find.text('Jumlah harus lebih dari 0'), findsOneWidget);
    });

    testWidgets(
        'save dengan nama dan jumlah valid → tidak ada pesan validasi error',
        (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan nama kreditur'), 'Bank Y');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan jumlah hutang'),
          '500000');
      await tester.tap(_saveBtn);
      await tester.pump();
      expect(find.text('Nama harus diisi'), findsNothing);
      expect(find.text('Jumlah tidak boleh kosong'), findsNothing);
      expect(find.text('Jumlah harus lebih dari 0'), findsNothing);
    });
  });

  // ── Mode edit ─────────────────────────────────────────────────────────────

  group('HutangFormScreen — mode edit', () {
    testWidgets('judul berubah menjadi "Edit Hutang"', (tester) async {
      final hutang = makeHutangAktif(namaKreditur: 'BRI Test');
      await _load(tester, _buildForm(prefs: prefs, editHutang: hutang));
      expect(find.text(AppStrings.editHutang), findsOneWidget);
    });

    testWidgets('field namaKreditur diisi dengan data lama', (tester) async {
      final hutang = makeHutangAktif(namaKreditur: 'BNI Test');
      await _load(tester, _buildForm(prefs: prefs, editHutang: hutang));
      expect(find.text('BNI Test'), findsOneWidget);
    });

    testWidgets('field jumlah diisi dengan jumlahAwal', (tester) async {
      final hutang = makeHutangAktif(jumlahAwal: 750_000);
      await _load(tester, _buildForm(prefs: prefs, editHutang: hutang));
      expect(find.text('750000'), findsOneWidget);
    });
  });

  // ── Preview format ────────────────────────────────────────────────────────

  group('HutangFormScreen — format jumlah', () {
    testWidgets('input angka → preview format Rupiah tampil', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan jumlah hutang'),
          '1000000');
      await tester.pump();
      expect(find.textContaining('1.000.000'), findsWidgets);
    });
  });
}
