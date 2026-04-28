// test/widget/piutang_form_test.dart
//
// Widget tests untuk PiutangFormScreen.
//
// Covers:
//   + Render judul "Tambah Piutang"
//   + Field namaPeminjam, jumlahAwal, tanggalPinjam
//   + Tombol Simpan dan Close
//   V Validasi: namaPeminjam kosong → error
//   V Validasi: jumlahAwal kosong → error
//   V Validasi: jumlahAwal 0 → error
//   + Mode edit: judul "Edit Piutang" dan field terisi
//   + Preview format Rupiah
//
// Run: flutter test test/widget/piutang_form_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/core/constants/app_strings.dart';
import 'package:finance_tracker/domain/entities/piutang_entity.dart';
import 'package:finance_tracker/presentation/features/piutang/piutang_form_screen.dart';
import 'package:finance_tracker/presentation/providers/database_provider.dart';
import 'package:finance_tracker/presentation/providers/transaction_provider.dart';

import '../helpers/test_helpers.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildForm({
  required SharedPreferences prefs,
  PiutangEntity? editPiutang,
}) {
  final fakePiutangRepo = FakePiutangRepository();
  final fakeTxRepo = FakeTransactionRepository();

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (ctx, st) => PiutangFormScreen(editPiutang: editPiutang),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      piutangRepositoryProvider.overrideWithValue(fakePiutangRepo),
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

  group('PiutangFormScreen — render', () {
    testWidgets('menampilkan judul "Tambah Piutang"', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      expect(find.text(AppStrings.tambahPiutang), findsOneWidget);
    });

    testWidgets('menampilkan label namaPeminjam', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      expect(find.text(AppStrings.namaPeminjam), findsOneWidget);
    });

    testWidgets('menampilkan label jumlahAwal', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      expect(find.text(AppStrings.jumlahAwal), findsOneWidget);
    });

    testWidgets('menampilkan label tanggalPinjam', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      expect(find.text(AppStrings.tanggalPinjam), findsOneWidget);
    });

    testWidgets('menampilkan tombol Simpan', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      expect(_saveBtn, findsOneWidget);
    });

    testWidgets('menampilkan tombol Close di AppBar', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });

  // ── Validasi ──────────────────────────────────────────────────────────────

  group('PiutangFormScreen — validasi', () {
    testWidgets('save tanpa namaPeminjam → pesan error tampil', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      await tester.tap(_saveBtn);
      await tester.pump();
      // Validator: 'v == null || v.trim().isEmpty' → ada pesan error
      expect(find.byType(TextFormField), findsWidgets);
      // Setidaknya satu error validation muncul
      final errorWidgets = find
          .descendant(
            of: find.byType(TextFormField),
            matching: find.byType(Text),
          )
          .evaluate()
          .where((e) {
        final widget = e.widget as Text;
        final text = widget.data ?? '';
        return text.contains('diisi') ||
            text.contains('kosong') ||
            text.contains('wajib');
      });
      expect(errorWidgets.length, greaterThanOrEqualTo(1));
    });

    testWidgets('save tanpa jumlah (setelah isi nama) → error jumlah',
        (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan nama peminjam'),
          'Siti');
      await tester.tap(_saveBtn);
      await tester.pump();
      expect(find.text('Jumlah tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('save dengan jumlah 0 → "Jumlah harus lebih dari 0"',
        (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan nama peminjam'),
          'Budi');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan jumlah piutang'), '0');
      await tester.tap(_saveBtn);
      await tester.pump();
      expect(find.text('Jumlah harus lebih dari 0'), findsOneWidget);
    });

    testWidgets('save valid → tidak ada pesan error validasi', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan nama peminjam'),
          'Andi');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan jumlah piutang'),
          '200000');
      await tester.tap(_saveBtn);
      await tester.pump();
      expect(find.text('Jumlah tidak boleh kosong'), findsNothing);
      expect(find.text('Jumlah harus lebih dari 0'), findsNothing);
    });
  });

  // ── Mode edit ─────────────────────────────────────────────────────────────

  group('PiutangFormScreen — mode edit', () {
    testWidgets('judul berubah menjadi "Edit Piutang"', (tester) async {
      final piutang = makePiutangAktif(namaPeminjam: 'Citra Test');
      await _load(tester, _buildForm(prefs: prefs, editPiutang: piutang));
      expect(find.text(AppStrings.editPiutang), findsOneWidget);
    });

    testWidgets('field namaPeminjam diisi dengan data lama', (tester) async {
      final piutang = makePiutangAktif(namaPeminjam: 'Diana Test');
      await _load(tester, _buildForm(prefs: prefs, editPiutang: piutang));
      expect(find.text('Diana Test'), findsOneWidget);
    });

    testWidgets('field jumlah diisi dengan jumlahAwal', (tester) async {
      final piutang = makePiutangAktif(jumlahAwal: 300_000);
      await _load(tester, _buildForm(prefs: prefs, editPiutang: piutang));
      expect(find.text('300000'), findsOneWidget);
    });
  });

  // ── Format ────────────────────────────────────────────────────────────────

  group('PiutangFormScreen — format jumlah', () {
    testWidgets('input angka → preview format Rupiah tampil', (tester) async {
      await _load(tester, _buildForm(prefs: prefs));
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan jumlah piutang'),
          '500000');
      await tester.pump();
      expect(find.textContaining('500.000'), findsWidgets);
    });
  });
}
