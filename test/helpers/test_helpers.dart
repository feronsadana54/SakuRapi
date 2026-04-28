// test/helpers/test_helpers.dart
//
// Shared test infrastructure for all SakuRapi widget tests.
//
// Berisi:
//   - Fake implementations semua repository interface (tanpa database nyata).
//   - Data fixture siap pakai (Category, Transaction, HutangEntity, PiutangEntity).
//   - buildTestApp() — membungkus screen dalam ProviderScope + GoRouter.
//   - pumpAndLoad() — pump hingga async provider selesai emit.
//   - setPhoneViewport() — set viewport 600×900 @ 1x DPR untuk mobile layout.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/domain/entities/category_entity.dart';
import 'package:finance_tracker/domain/entities/hutang_entity.dart';
import 'package:finance_tracker/domain/entities/piutang_entity.dart';
import 'package:finance_tracker/domain/entities/transaction_entity.dart';
import 'package:finance_tracker/domain/enums/category_type.dart';
import 'package:finance_tracker/domain/enums/transaction_type.dart';
import 'package:finance_tracker/domain/repositories/i_category_repository.dart';
import 'package:finance_tracker/domain/repositories/i_hutang_repository.dart';
import 'package:finance_tracker/domain/repositories/i_piutang_repository.dart';
import 'package:finance_tracker/domain/repositories/i_settings_repository.dart';
import 'package:finance_tracker/domain/repositories/i_transaction_repository.dart';
import 'package:finance_tracker/presentation/providers/database_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FIXTURES
// ══════════════════════════════════════════════════════════════════════════════

const kExpenseCategory = Category(
  id: 'cat-expense-001',
  name: 'Makan & Minum',
  iconCode: 0xe56c,
  colorValue: 0xFFEF5350,
  type: CategoryType.expense,
  isDefault: true,
);

const kIncomeCategory = Category(
  id: 'cat-income-001',
  name: 'Gaji',
  iconCode: 0xe227,
  colorValue: 0xFF4CAF50,
  type: CategoryType.income,
  isDefault: true,
);

final kRef = DateTime(2026, 4, 16);

Transaction makeExpenseTx(String id) => Transaction(
      id: id,
      type: TransactionType.expense,
      amount: 50_000,
      category: kExpenseCategory,
      note: null,
      date: kRef,
      createdAt: kRef,
    );

Transaction makeIncomeTx(String id) => Transaction(
      id: id,
      type: TransactionType.income,
      amount: 5_000_000,
      category: kIncomeCategory,
      note: null,
      date: kRef,
      createdAt: kRef,
    );

HutangEntity makeHutangAktif({
  String id = 'hutang-001',
  String namaKreditur = 'Bank Test',
  double jumlahAwal = 1_000_000,
  double sisaHutang = 800_000,
}) =>
    HutangEntity(
      id: id,
      namaKreditur: namaKreditur,
      jumlahAwal: jumlahAwal,
      sisaHutang: sisaHutang,
      tanggalPinjam: kRef,
      status: 'aktif',
      riwayatPembayaran: const [],
      createdAt: kRef,
      updatedAt: kRef,
    );

HutangEntity makeHutangLunas() => HutangEntity(
      id: 'hutang-lunas-001',
      namaKreditur: 'Lunas Co',
      jumlahAwal: 500_000,
      sisaHutang: 0,
      tanggalPinjam: kRef,
      status: 'lunas',
      riwayatPembayaran: const [],
      createdAt: kRef,
      updatedAt: kRef,
    );

PiutangEntity makePiutangAktif({
  String id = 'piutang-001',
  String namaPeminjam = 'Teman B',
  double jumlahAwal = 500_000,
  double sisaPiutang = 500_000,
}) =>
    PiutangEntity(
      id: id,
      namaPeminjam: namaPeminjam,
      jumlahAwal: jumlahAwal,
      sisaPiutang: sisaPiutang,
      tanggalPinjam: kRef,
      status: 'aktif',
      riwayatPembayaran: const [],
      createdAt: kRef,
      updatedAt: kRef,
    );

PiutangEntity makePiutangLunas() => PiutangEntity(
      id: 'piutang-lunas-001',
      namaPeminjam: 'Lunas D',
      jumlahAwal: 200_000,
      sisaPiutang: 0,
      tanggalPinjam: kRef,
      status: 'lunas',
      riwayatPembayaran: const [],
      createdAt: kRef,
      updatedAt: kRef,
    );

// ══════════════════════════════════════════════════════════════════════════════
// FAKE TRANSACTION REPOSITORY
// ══════════════════════════════════════════════════════════════════════════════

class FakeTransactionRepository implements ITransactionRepository {
  final List<Transaction> _data;
  final _ctrl = StreamController<List<Transaction>>.broadcast();

  FakeTransactionRepository([List<Transaction>? initial])
      : _data = List.of(initial ?? []) {
    Future.microtask(_emit);
  }

  void _emit() {
    if (!_ctrl.isClosed) _ctrl.add(List.unmodifiable(_data));
  }

  @override
  Stream<List<Transaction>> watchAll() => _ctrl.stream;

  @override
  Future<List<Transaction>> getByDateRange(DateTime s, DateTime e) async =>
      _data.where((t) => !t.date.isBefore(s) && !t.date.isAfter(e)).toList();

  @override
  Future<Transaction?> getById(String id) async =>
      _data.cast<Transaction?>().firstWhere((t) => t?.id == id,
          orElse: () => null);

  @override
  Future<void> insert(Transaction tx) async {
    _data.add(tx);
    _emit();
  }

  @override
  Future<void> update(Transaction tx) async {
    final i = _data.indexWhere((t) => t.id == tx.id);
    if (i >= 0) {
      _data[i] = tx;
      _emit();
    }
  }

  @override
  Future<void> delete(String id) async {
    _data.removeWhere((t) => t.id == id);
    _emit();
  }

  void dispose() => _ctrl.close();
}

// ══════════════════════════════════════════════════════════════════════════════
// FAKE CATEGORY REPOSITORY
// ══════════════════════════════════════════════════════════════════════════════

class FakeCategoryRepository implements ICategoryRepository {
  final List<Category> _data;
  final _ctrl = StreamController<List<Category>>.broadcast();

  FakeCategoryRepository([List<Category>? initial])
      : _data = List.of(initial ?? const [kExpenseCategory, kIncomeCategory]) {
    Future.microtask(_emit);
  }

  void _emit() {
    if (!_ctrl.isClosed) _ctrl.add(List.unmodifiable(_data));
  }

  @override
  Stream<List<Category>> watchAll() => _ctrl.stream;

  @override
  Future<List<Category>> getAll() async => List.unmodifiable(_data);

  @override
  Future<void> insert(Category cat) async {
    _data.add(cat);
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _data.removeWhere((c) => c.id == id);
    _emit();
  }

  void dispose() => _ctrl.close();
}

// ══════════════════════════════════════════════════════════════════════════════
// FAKE HUTANG REPOSITORY
// ══════════════════════════════════════════════════════════════════════════════

class FakeHutangRepository implements IHutangRepository {
  final List<HutangEntity> _data;
  final _ctrl = StreamController<List<HutangEntity>>.broadcast();

  FakeHutangRepository([List<HutangEntity>? initial])
      : _data = List.of(initial ?? []) {
    Future.microtask(_emit);
  }

  void _emit() {
    if (!_ctrl.isClosed) _ctrl.add(List.unmodifiable(_data));
  }

  @override
  Stream<List<HutangEntity>> watchAll() => _ctrl.stream;

  @override
  Future<List<HutangEntity>> getAll() async => List.unmodifiable(_data);

  @override
  Future<HutangEntity?> getById(String id) async =>
      _data.cast<HutangEntity?>().firstWhere((h) => h?.id == id,
          orElse: () => null);

  @override
  Future<void> insert(HutangEntity h) async {
    _data.add(h);
    _emit();
  }

  @override
  Future<void> update(HutangEntity h) async {
    final i = _data.indexWhere((x) => x.id == h.id);
    if (i >= 0) {
      _data[i] = h;
      _emit();
    }
  }

  @override
  Future<void> delete(String id) async {
    _data.removeWhere((h) => h.id == id);
    _emit();
  }

  @override
  Future<void> addPayment(String hutangId, PaymentRecord payment) async {
    final i = _data.indexWhere((h) => h.id == hutangId);
    if (i < 0) return;
    final e = _data[i];
    final newSisa =
        (e.sisaHutang - payment.amount).clamp(0.0, double.infinity);
    _data[i] = HutangEntity(
      id: e.id,
      namaKreditur: e.namaKreditur,
      jumlahAwal: e.jumlahAwal,
      sisaHutang: newSisa,
      tanggalPinjam: e.tanggalPinjam,
      status: newSisa <= 0 ? 'lunas' : 'aktif',
      riwayatPembayaran: [...e.riwayatPembayaran, payment],
      createdAt: e.createdAt,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  void dispose() => _ctrl.close();
}

// ══════════════════════════════════════════════════════════════════════════════
// FAKE PIUTANG REPOSITORY
// ══════════════════════════════════════════════════════════════════════════════

class FakePiutangRepository implements IPiutangRepository {
  final List<PiutangEntity> _data;
  final _ctrl = StreamController<List<PiutangEntity>>.broadcast();

  FakePiutangRepository([List<PiutangEntity>? initial])
      : _data = List.of(initial ?? []) {
    Future.microtask(_emit);
  }

  void _emit() {
    if (!_ctrl.isClosed) _ctrl.add(List.unmodifiable(_data));
  }

  @override
  Stream<List<PiutangEntity>> watchAll() => _ctrl.stream;

  @override
  Future<List<PiutangEntity>> getAll() async => List.unmodifiable(_data);

  @override
  Future<PiutangEntity?> getById(String id) async =>
      _data.cast<PiutangEntity?>().firstWhere((p) => p?.id == id,
          orElse: () => null);

  @override
  Future<void> insert(PiutangEntity p) async {
    _data.add(p);
    _emit();
  }

  @override
  Future<void> update(PiutangEntity p) async {
    final i = _data.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      _data[i] = p;
      _emit();
    }
  }

  @override
  Future<void> delete(String id) async {
    _data.removeWhere((p) => p.id == id);
    _emit();
  }

  @override
  Future<void> addPayment(String piutangId, PaymentRecord payment) async {
    final i = _data.indexWhere((p) => p.id == piutangId);
    if (i < 0) return;
    final e = _data[i];
    final newSisa =
        (e.sisaPiutang - payment.amount).clamp(0.0, double.infinity);
    _data[i] = PiutangEntity(
      id: e.id,
      namaPeminjam: e.namaPeminjam,
      jumlahAwal: e.jumlahAwal,
      sisaPiutang: newSisa,
      tanggalPinjam: e.tanggalPinjam,
      status: newSisa <= 0 ? 'lunas' : 'aktif',
      riwayatPembayaran: [...e.riwayatPembayaran, payment],
      createdAt: e.createdAt,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  void dispose() => _ctrl.close();
}

// ══════════════════════════════════════════════════════════════════════════════
// FAKE SETTINGS REPOSITORY
// ══════════════════════════════════════════════════════════════════════════════

class FakeSettingsRepository implements ISettingsRepository {
  bool _onboardingComplete;
  int _paydayDate;
  bool _notifEnabled;
  int _reminderHour;
  int _reminderMinute;
  List<int> _reminderDays;

  FakeSettingsRepository({
    bool onboardingComplete = true,
    int paydayDate = 25,
    bool notifEnabled = false,
    int reminderHour = 21,
    int reminderMinute = 0,
    List<int>? reminderDays,
  })  : _onboardingComplete = onboardingComplete,
        _paydayDate = paydayDate,
        _notifEnabled = notifEnabled,
        _reminderHour = reminderHour,
        _reminderMinute = reminderMinute,
        _reminderDays = reminderDays ?? [1, 2, 3, 4, 5, 6, 7];

  @override
  Future<bool> isOnboardingComplete() async => _onboardingComplete;
  @override
  Future<void> setOnboardingComplete(bool v) async => _onboardingComplete = v;
  @override
  Future<int> getPaydayDate() async => _paydayDate;
  @override
  Future<void> setPaydayDate(int d) async => _paydayDate = d;
  @override
  Future<bool> isNotificationEnabled() async => _notifEnabled;
  @override
  Future<void> setNotificationEnabled(bool v) async => _notifEnabled = v;
  @override
  Future<int> getReminderHour() async => _reminderHour;
  @override
  Future<void> setReminderHour(int h) async => _reminderHour = h;
  @override
  Future<int> getReminderMinute() async => _reminderMinute;
  @override
  Future<void> setReminderMinute(int m) async => _reminderMinute = m;
  @override
  Future<List<int>> getReminderDays() async => List.of(_reminderDays);
  @override
  Future<void> setReminderDays(List<int> days) async =>
      _reminderDays = List.of(days);
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET BUILDER
// ══════════════════════════════════════════════════════════════════════════════

/// Membungkus [home] dalam ProviderScope + GoRouter sehingga screen yang
/// memanggil context.go() / context.pop() tidak crash.
///
/// [extraRoutes] — peta path → WidgetBuilder untuk rute yang mungkin
/// dinavigasi dari screen yang diuji (misal '/home', '/transactions/add').
Widget buildTestApp({
  required Widget home,
  required SharedPreferences prefs,
  List<Override> overrides = const [],
  Map<String, WidgetBuilder> extraRoutes = const {},
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (ctx, st) => home),
      ...extraRoutes.entries.map(
        (e) => GoRoute(path: e.key, builder: (ctx, st) => e.value(ctx)),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...overrides,
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

/// Pump + tunggu hingga async provider emit nilai pertama.
Future<void> pumpAndLoad(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// Set viewport ke ukuran phone (600×900 @ 1x DPR).
void setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(600, 900);
  tester.view.devicePixelRatio = 1.0;
}
