import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/system_categories.dart';
import 'daos/category_dao.dart';
import 'daos/hutang_dao.dart';
import 'daos/piutang_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables/categories_table.dart';
import 'tables/hutang_table.dart';
import 'tables/payment_history_table.dart';
import 'tables/piutang_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

/// Database utama aplikasi menggunakan Drift (SQLite).
///
/// Mendaftarkan semua tabel dan DAO. Saat menambah tabel baru:
///   1. Buat file tabel di lib/data/database/tables/
///   2. Buat DAO di lib/data/database/daos/
///   3. Tambahkan ke annotation @DriftDatabase di sini
///   4. Naikkan [schemaVersion] dan tambahkan case di [migration.onUpgrade]
///   5. Jalankan: dart run build_runner build --delete-conflicting-outputs
///
/// Untuk testing, gunakan: AppDatabase(NativeDatabase.memory())
@DriftDatabase(
  tables: [
    CategoriesTable,
    TransactionsTable,
    HutangTable,
    PiutangTable,
    PaymentHistoryTable,
  ],
  daos: [CategoryDao, TransactionDao, HutangDao, PiutangDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openDatabase());

  /// Membuka database SQLite persisten di Android/iOS, atau database SQLite
  /// berbasis WASM di web (didukung IndexedDB atau OPFS untuk persistensi).
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
  int get schemaVersion => 4;

  /// Strategi migrasi database.
  ///
  /// Riwayat versi skema:
  ///   v1 → Tabel categories + transactions
  ///   v2 → Tambah hutang_table, piutang_table, payment_history
  ///   v3 → Seed kategori sistem: Pembayaran Hutang & Penerimaan Piutang
  ///   v4 → Seed kategori sistem: Memberi Pinjaman (untuk piutang baru)
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultCategories();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Versi 1 → 2: tambah tabel hutang, piutang, payment_history
            await m.createTable(hutangTable);
            await m.createTable(piutangTable);
            await m.createTable(paymentHistoryTable);
          }
          if (from < 3) {
            // Versi 2 → 3: seed kategori sistem untuk integrasi hutang/piutang
            await _insertSystemCategoriesIfMissing();
          }
          if (from < 4) {
            // Versi 3 → 4: seed kategori Memberi Pinjaman untuk alur piutang baru
            await _insertSystemCategoriesIfMissing();
          }
        },
      );

  // ── Seed data ──────────────────────────────────────────────────────────

  /// Memasukkan kategori sistem menggunakan INSERT OR IGNORE sehingga aman dipanggil
  /// pada database yang sudah ada (duplikat diabaikan secara diam-diam).
  ///
  /// Kategori sistem memiliki ID tetap (sys-*) agar dapat direferensikan dari
  /// kode tanpa perlu query terlebih dahulu.
  /// Memasukkan SEMUA kategori sistem menggunakan INSERT OR IGNORE.
  /// Aman dipanggil pada database yang sudah ada — duplikat diabaikan.
  Future<void> _insertSystemCategoriesIfMissing() async {
    for (final cat in SystemCategories.all) {
      await into(categoriesTable).insert(
        CategoriesTableCompanion.insert(
          id: cat.id,
          name: cat.name,
          iconCode: cat.iconCode,
          colorValue: cat.colorValue,
          type: cat.type.value,
          isDefault: const Value(true),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

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

    // System integration categories (fixed IDs, always present)
    await _insertSystemCategoriesIfMissing();
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
