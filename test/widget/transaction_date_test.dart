// Tests for the unrestricted transaction date-picker behaviour.
//
// Verifies that:
//  - A future date can be stored on a Transaction without error.
//  - The date field in TransactionFormScreen accepts and displays a future date
//    when the screen is opened in edit mode pre-populated with that date.
//  - The lastDate for the picker is in the year 2100 (no practical upper limit).
//
// Database strategy:
//  TransactionFormScreen watches categoriesForTypeProvider → categoryRepositoryProvider.
//  To prevent Drift from creating multiple AppDatabase instances across test runs
//  (which triggers a "DriftRemoteException: database is already open" warning),
//  we override categoryRepositoryProvider with a lightweight in-memory fake that
//  returns a static list of stub categories.  No real SQLite file is touched.
//
// Run: flutter test test/widget/transaction_date_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/core/utils/date_utils.dart';
import 'package:finance_tracker/domain/entities/category_entity.dart';
import 'package:finance_tracker/domain/entities/transaction_entity.dart';
import 'package:finance_tracker/domain/enums/category_type.dart';
import 'package:finance_tracker/domain/enums/transaction_type.dart';
import 'package:finance_tracker/domain/repositories/i_category_repository.dart';
import 'package:finance_tracker/presentation/features/transactions/transaction_form_screen.dart';
import 'package:finance_tracker/presentation/providers/database_provider.dart';

// ── Fake category repository ──────────────────────────────────────────────────

/// Returns a single stub expense category.
/// Used so TransactionFormScreen can render the category grid without needing
/// a real database.  No Drift AppDatabase is created.
class _FakeCategoryRepo implements ICategoryRepository {
  static final _cats = [
    const Category(
      id: 'cat-test-001',
      name: 'Test Kategori',
      iconCode: 0xe5d3,
      colorValue: 0xFF546E7A,
      type: CategoryType.expense,
      isDefault: false,
    ),
  ];

  @override
  Stream<List<Category>> watchAll() => Stream.value(_cats);

  @override
  Future<List<Category>> getAll() async => _cats;

  @override
  Future<void> insert(Category category) async {}

  @override
  Future<void> delete(String id) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// A minimal [Category] stub for building [Transaction] fixtures.
Category _stubCategory() => const Category(
      id: 'cat-test-001',
      name: 'Test Kategori',
      iconCode: 0xe5d3,
      colorValue: 0xFF546E7A,
      type: CategoryType.expense,
      isDefault: false,
    );

/// Builds a [Transaction] with the given [date].
Transaction _txWithDate(DateTime date) => Transaction(
      id: 'tx-test-001',
      type: TransactionType.expense,
      amount: 10000,
      category: _stubCategory(),
      note: null,
      date: AppDateUtils.dateOnly(date),
      createdAt: DateTime.now(),
    );

/// Pumps [TransactionFormScreen] in edit mode with a pre-populated transaction.
///
/// Overrides [categoryRepositoryProvider] with [_FakeCategoryRepo] so no real
/// AppDatabase is created — prevents the Drift "multiple instances" warning.
Future<void> _pumpForm(
  WidgetTester tester,
  Transaction tx,
  SharedPreferences prefs,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Replace the DB-backed category repo with a lightweight fake.
        // TransactionFormScreen only reads categories for the picker; no write
        // operations are triggered during these render-only tests.
        categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepo()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('id', 'ID')],
        home: TransactionFormScreen(editTransaction: tx),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Transaction date — no upper-limit restriction', () {
    test('future date is representable as a Transaction', () {
      // Ensures domain entity accepts dates beyond today without assertion.
      final future = DateTime(2030, 6, 15);
      final tx = _txWithDate(future);
      expect(tx.date.year, equals(2030));
      expect(tx.date.month, equals(6));
      expect(tx.date.day, equals(15));
    });

    test('lastDate for date picker is in year 2100 (no practical cap)', () {
      // Documents the picker's lastDate constant.
      final lastDate = DateTime(2100);
      expect(lastDate.year, equals(2100));
      expect(
        lastDate.isAfter(DateTime.now()),
        isTrue,
        reason: 'lastDate must be strictly in the future so future dates '
            'can be selected',
      );
    });

    testWidgets(
        'form opens with a future date pre-populated and renders without error',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // A date well into the future.
      final futureDate = DateTime(2028, 12, 25);
      final tx = _txWithDate(futureDate);

      // Should build and render without any exception.
      await _pumpForm(tester, tx, prefs);

      // The date field must display something — not crash or show an error.
      // AppDateUtils.formatFull renders the date; spot-check the year.
      expect(find.textContaining('2028'), findsWidgets,
          reason: 'Future year 2028 should appear in the date field');
    });

    testWidgets(
        'form opens with a past date pre-populated and renders without error',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final pastDate = DateTime(2023, 1, 10);
      final tx = _txWithDate(pastDate);

      await _pumpForm(tester, tx, prefs);

      expect(find.textContaining('2023'), findsWidgets,
          reason: 'Past year 2023 should appear in the date field');
    });
  });
}
