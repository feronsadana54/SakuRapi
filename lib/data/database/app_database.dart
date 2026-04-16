import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import 'daos/category_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables/categories_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [CategoriesTable, TransactionsTable],
  daos: [CategoryDao, TransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openDatabase());

  /// Opens a persistent SQLite database on Android/iOS, or a WASM-based
  /// SQLite database on web (backed by IndexedDB or OPFS for persistence).
  ///
  /// On web the [DriftWebOptions] must point to the two static files placed
  /// in the `web/` folder:
  ///   • `web/sqlite3.wasm`  — compiled SQLite WebAssembly module
  ///   • `web/drift_worker.js` — shared-worker used by drift for multi-tab sync
  static QueryExecutor _openDatabase() {
    return driftDatabase(
      name: 'finance_tracker',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultCategories();
        },
      );

  // ── Seed data ──────────────────────────────────────────────────────────

  Future<void> _seedDefaultCategories() async {
    const uuid = Uuid();

    // Icon codepoints from MaterialIcons font (stable across Flutter versions).
    // Expense categories
    final expenseCategories = [
      _cat(uuid.v4(), 'Makan & Minum',    0xe56c, 0xFFEF5350, 'expense'), // restaurant
      _cat(uuid.v4(), 'Transportasi',      0xe1b1, 0xFF42A5F5, 'expense'), // directions_car
      _cat(uuid.v4(), 'Belanja',           0xef6f, 0xFFAB47BC, 'expense'), // shopping_bag
      _cat(uuid.v4(), 'Tagihan & Utilitas',0xe56b, 0xFFFF7043, 'expense'), // receipt
      _cat(uuid.v4(), 'Kesehatan',         0xe548, 0xFF26A69A, 'expense'), // local_hospital
      _cat(uuid.v4(), 'Hiburan',           0xe415, 0xFFFFA726, 'expense'), // movie
      _cat(uuid.v4(), 'Pendidikan',        0xe80c, 0xFF5C6BC0, 'expense'), // school
      _cat(uuid.v4(), 'Rumah Tangga',      0xe318, 0xFF66BB6A, 'expense'), // home
      _cat(uuid.v4(), 'Pakaian',           0xe3c4, 0xFFEC407A, 'expense'), // style
      _cat(uuid.v4(), 'Lainnya',           0xe5d3, 0xFF78909C, 'expense'), // more_horiz
    ];

    // Income categories
    final incomeCategories = [
      _cat(uuid.v4(), 'Gaji',             0xe850, 0xFF2E7D32, 'income'), // account_balance_wallet
      _cat(uuid.v4(), 'Bonus',            0xe8f6, 0xFF1565C0, 'income'), // card_giftcard
      _cat(uuid.v4(), 'Freelance',        0xe8f9, 0xFF6A1B9A, 'income'), // work
      _cat(uuid.v4(), 'Investasi',        0xe8e5, 0xFF00838F, 'income'), // trending_up
      _cat(uuid.v4(), 'Lainnya',          0xe5d3, 0xFF546E7A, 'income'), // more_horiz
    ];

    for (final cat in [...expenseCategories, ...incomeCategories]) {
      await into(categoriesTable).insert(cat);
    }
  }

  CategoriesTableCompanion _cat(
    String id,
    String name,
    int iconCode,
    int colorValue,
    String type,
  ) =>
      CategoriesTableCompanion.insert(
        id: id,
        name: name,
        iconCode: iconCode,
        colorValue: colorValue,
        type: type,
        isDefault: const Value(true),
      );
}
