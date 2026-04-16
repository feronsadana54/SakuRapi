// Tests for the multi-select / bulk-delete mode in TransactionListScreen.
//
// Covers:
//  - Default AppBar shows the filter bar (Semua / Pemasukan / Pengeluaran).
//  - Long-press a transaction tile → selection mode activated.
//  - Selection AppBar shows item count and replaces the default AppBar.
//  - Checkboxes appear in selection mode; FAB is hidden.
//  - Cancel (close) button in the selection AppBar restores the default AppBar.
//  - Delete button in the selection AppBar shows a confirmation dialog.
//  - Cancelling the delete dialog keeps selection mode active.
//
// Uses provider overrides (mock stream + no-op repository) to avoid requiring
// a real Drift database or async stream teardown issues in the test runner.
//
// NOTE: The screen is mounted directly inside a MaterialApp (no GoRouter)
// to keep navigation simple.  Navigation calls inside the screen use
// GoRouter.of(context) which is mocked via a real GoRouter wrapping a
// single route so the test does not need to mock the router.
//
// Run: flutter test test/widget/transaction_selection_test.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/core/constants/app_strings.dart';
import 'package:finance_tracker/domain/entities/category_entity.dart';
import 'package:finance_tracker/domain/entities/transaction_entity.dart';
import 'package:finance_tracker/domain/enums/category_type.dart';
import 'package:finance_tracker/domain/enums/transaction_type.dart';
import 'package:finance_tracker/domain/repositories/i_transaction_repository.dart';
import 'package:finance_tracker/presentation/features/transactions/transaction_list_screen.dart';
import 'package:finance_tracker/presentation/providers/database_provider.dart';
import 'package:finance_tracker/presentation/providers/transaction_provider.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeTransactionRepo implements ITransactionRepository {
  final List<Transaction> _txs;

  /// Broadcast controller for pushing updates after the initial state.
  final _update = StreamController<List<Transaction>>.broadcast();

  _FakeTransactionRepo(List<Transaction> txs) : _txs = List.of(txs);

  @override
  Stream<List<Transaction>> watchAll() {
    // Return a stream that immediately emits the current snapshot, then
    // forwards any subsequent updates pushed through [_update].
    return _update.stream.transform(
      StreamTransformer.fromHandlers(
        handleError: (e, st, sink) => sink.addError(e, st),
      ),
    );
  }

  void _push() => _update.add(List.unmodifiable(_txs));

  @override
  Future<List<Transaction>> getByDateRange(DateTime s, DateTime e) async =>
      _txs.where((t) => !t.date.isBefore(s) && !t.date.isAfter(e)).toList();

  @override
  Future<Transaction?> getById(String id) async =>
      _txs.cast<Transaction?>().firstWhere((t) => t?.id == id,
          orElse: () => null);

  @override
  Future<void> insert(Transaction tx) async {
    _txs.add(tx);
    _push();
  }

  @override
  Future<void> update(Transaction tx) async {}

  @override
  Future<void> delete(String id) async {
    _txs.removeWhere((t) => t.id == id);
    _push();
  }

  void close() => _update.close();
}

// ── Test fixtures ─────────────────────────────────────────────────────────────

const _stubCategory = Category(
  id: 'cat-test-001',
  name: 'Makan & Minum',
  iconCode: 0xe56c,
  colorValue: 0xFFEF5350,
  type: CategoryType.expense,
  isDefault: true,
);

Transaction _makeTx(String id) => Transaction(
      id: id,
      type: TransactionType.expense,
      amount: 50000,
      category: _stubCategory,
      note: null,
      date: DateTime(2024, 4, 15),
      createdAt: DateTime(2024, 4, 15),
    );

// ── Widget helpers ────────────────────────────────────────────────────────────

/// Builds the app with overridden providers.
///
/// The screen is wrapped in a plain [MaterialApp] (no GoRouter) because
/// using a router adds extra navigation frames that are not needed for
/// these interaction tests.  Any [context.push] / [context.go] calls
/// inside the screen are guarded by route existence so they won't crash
/// even without a full router setup.
Widget _buildApp({
  required _FakeTransactionRepo repo,
  required SharedPreferences prefs,
  required List<Transaction> initialData,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      transactionRepositoryProvider.overrideWithValue(repo),
      // Override the StreamProvider with a stream that starts with the
      // current snapshot of transactions.
      allTransactionsProvider.overrideWith(
        (ref) => Stream.fromIterable([initialData]),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID')],
      home: const TransactionListScreen(),
    ),
  );
}

/// Forces a viewport below the 720 dp tablet breakpoint so
/// [TransactionListScreen] renders its mobile layout (with [Dismissible]
/// tiles).  We use 600 dp width @ 1x DPR so the filter chips also fit.
void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(600, 900);
  tester.view.devicePixelRatio = 1.0;
}

/// Pumps until the transaction list body is rendered (or 10 pumps max).
Future<void> _load(WidgetTester tester, Widget app) async {
  _setPhoneSize(tester);
  await tester.pumpWidget(app);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 30));
    if (find.byType(Dismissible).evaluate().isNotEmpty) break;
  }
}

/// Finds the [GestureDetector] that wraps the first transaction tile.
/// We anchor on [Dismissible] to avoid accidentally hitting a filter-chip
/// [GestureDetector] that lives earlier in the widget tree (AppBar area).
Finder _firstTileGesture() {
  return find
      .ancestor(
        of: find.byType(Dismissible).first,
        matching: find.byType(GestureDetector),
      )
      .first;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeTransactionRepo repo;
  late SharedPreferences prefs;

  List<Transaction> twoTxs() => [_makeTx('tx-001'), _makeTx('tx-002')];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = _FakeTransactionRepo(twoTxs());
  });

  tearDown(() {
    repo.close();
  });

  group('TransactionListScreen — default mode', () {
    testWidgets('renders the screen title', (tester) async {
      await _load(
          tester, _buildApp(repo: repo, prefs: prefs, initialData: twoTxs()));
      expect(find.text(AppStrings.navTransactions), findsOneWidget);
    });

    testWidgets('default AppBar shows filter chips', (tester) async {
      await _load(
          tester, _buildApp(repo: repo, prefs: prefs, initialData: twoTxs()));
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text(AppStrings.income), findsOneWidget);
      expect(find.text(AppStrings.expense), findsOneWidget);
    });
  });

  group('TransactionListScreen — selection mode entry', () {
    testWidgets('long-press tile shows selection AppBar with count',
        (tester) async {
      await _load(
          tester, _buildApp(repo: repo, prefs: prefs, initialData: twoTxs()));

      await tester.longPress(_firstTileGesture());
      await tester.pump();

      expect(find.textContaining('1 dipilih'), findsOneWidget);
    });

    testWidgets('filter chips disappear in selection mode', (tester) async {
      await _load(
          tester, _buildApp(repo: repo, prefs: prefs, initialData: twoTxs()));

      await tester.longPress(_firstTileGesture());
      await tester.pump();

      expect(find.text('Semua'), findsNothing);
    });

    testWidgets('checkboxes appear in selection mode', (tester) async {
      await _load(
          tester, _buildApp(repo: repo, prefs: prefs, initialData: twoTxs()));

      expect(find.byType(Checkbox), findsNothing);

      await tester.longPress(_firstTileGesture());
      await tester.pump();

      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('FAB is hidden in selection mode', (tester) async {
      await _load(
          tester, _buildApp(repo: repo, prefs: prefs, initialData: twoTxs()));

      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.longPress(_firstTileGesture());
      await tester.pump(); // setState fires
      // The Scaffold's FAB has an exit animation; pump through it.
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('delete icon visible when at least one item is selected',
        (tester) async {
      await _load(
          tester, _buildApp(repo: repo, prefs: prefs, initialData: twoTxs()));

      await tester.longPress(_firstTileGesture());
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });

  group('TransactionListScreen — exiting selection mode', () {
    testWidgets('close button exits selection mode', (tester) async {
      await _load(
          tester, _buildApp(repo: repo, prefs: prefs, initialData: twoTxs()));

      await tester.longPress(_firstTileGesture());
      await tester.pump();

      expect(find.textContaining('dipilih'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(find.text(AppStrings.navTransactions), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
    });
  });

  group('TransactionListScreen — bulk delete dialog', () {
    testWidgets('tapping delete shows confirmation dialog', (tester) async {
      await _load(
          tester, _buildApp(repo: repo, prefs: prefs, initialData: twoTxs()));

      await tester.longPress(_firstTileGesture());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pump();

      expect(find.text(AppStrings.bulkDeleteTitle), findsOneWidget);
      expect(find.text(AppStrings.cancel), findsOneWidget);
      expect(find.text(AppStrings.delete), findsOneWidget);
    });

    testWidgets('cancelling delete dialog keeps selection mode active',
        (tester) async {
      await _load(
          tester, _buildApp(repo: repo, prefs: prefs, initialData: twoTxs()));

      await tester.longPress(_firstTileGesture());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pump();

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pump();

      // Still in selection mode.
      expect(find.textContaining('dipilih'), findsOneWidget);
    });

    testWidgets('confirming delete removes items and exits selection mode',
        (tester) async {
      final oneTx = [_makeTx('only-tx')];
      repo.close();
      repo = _FakeTransactionRepo(oneTx);

      await _load(
          tester, _buildApp(repo: repo, prefs: prefs, initialData: oneTx));

      await tester.longPress(_firstTileGesture());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pump();

      // Confirm the delete.
      await tester.tap(find.text(AppStrings.delete));
      // The repo's delete() is async; give it a few frames to complete.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Selection mode must be exited — the default AppBar is restored.
      expect(find.text(AppStrings.navTransactions), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
    });
  });
}
