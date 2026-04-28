import 'dart:developer' as dev;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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

/// ID tetap untuk semua kategori default.
///
/// Sebelum v5, kategori default menggunakan uuid.v4() sehingga setiap
/// install menghasilkan ID berbeda. Ini menyebabkan restore dari cloud
/// gagal di perangkat lain karena categoryId tidak cocok.
///
/// ID-ID ini harus TIDAK PERNAH diubah setelah rilis — transaksi di
/// Firestore dan SQLite mereferensikan ID ini.
abstract final class DefaultCategoryIds {
  // ── Pengeluaran ────────────────────────────────────────────────────────
  static const String makanMinum     = 'def-expense-makan-v1';
  static const String transportasi   = 'def-expense-transportasi-v1';
  static const String belanja        = 'def-expense-belanja-v1';
  static const String tagihan        = 'def-expense-tagihan-v1';
  static const String kesehatan      = 'def-expense-kesehatan-v1';
  static const String hiburan        = 'def-expense-hiburan-v1';
  static const String pendidikan     = 'def-expense-pendidikan-v1';
  static const String rumahTangga    = 'def-expense-rumahtangga-v1';
  static const String pakaian        = 'def-expense-pakaian-v1';
  static const String lainnyaExpense = 'def-expense-lainnya-v1';

  // ── Pemasukan ──────────────────────────────────────────────────────────
  static const String gaji           = 'def-income-gaji-v1';
  static const String bonus          = 'def-income-bonus-v1';
  static const String freelance      = 'def-income-freelance-v1';
  static const String investasi      = 'def-income-investasi-v1';
  static const String lainnyaIncome  = 'def-income-lainnya-v1';

  /// Lookup (name|type) → stableId — dipakai oleh migrasi v5 dan restore.
  static const Map<String, String> byNameAndType = {
    'Makan & Minum|expense':      makanMinum,
    'Transportasi|expense':       transportasi,
    'Belanja|expense':            belanja,
    'Tagihan & Utilitas|expense': tagihan,
    'Kesehatan|expense':          kesehatan,
    'Hiburan|expense':            hiburan,
    'Pendidikan|expense':         pendidikan,
    'Rumah Tangga|expense':       rumahTangga,
    'Pakaian|expense':            pakaian,
    'Lainnya|expense':            lainnyaExpense,
    'Gaji|income':                gaji,
    'Bonus|income':               bonus,
    'Freelance|income':           freelance,
    'Investasi|income':           investasi,
    'Lainnya|income':             lainnyaIncome,
  };
}

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
  int get schemaVersion => 5;

  /// Strategi migrasi database.
  ///
  /// Riwayat versi skema:
  ///   v1 → Tabel categories + transactions
  ///   v2 → Tambah hutang_table, piutang_table, payment_history
  ///   v3 → Seed kategori sistem: Pembayaran Hutang & Penerimaan Piutang
  ///   v4 → Seed kategori sistem: Memberi Pinjaman (untuk piutang baru)
  ///   v5 → Perbaiki ID kategori default dari UUID acak ke ID stabil lintas perangkat
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultCategories();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(hutangTable);
            await m.createTable(piutangTable);
            await m.createTable(paymentHistoryTable);
          }
          if (from < 3) {
            await _insertSystemCategoriesIfMissing();
          }
          if (from < 4) {
            await _insertSystemCategoriesIfMissing();
          }
          if (from < 5) {
            // v5: ganti UUID acak kategori default dengan ID stabil.
            // Ini memperbaiki restore cloud yang gagal di perangkat baru.
            await _migrateCategoryIdsToStable();
          }
        },
      );

  // ── Seed data ──────────────────────────────────────────────────────────

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

  /// Seed kategori default menggunakan ID stabil (bukan uuid.v4()).
  ///
  /// Menggunakan insertOrIgnore agar aman dipanggil berkali-kali
  /// (misalnya dari onCreate dan dari _migrateCategoryIdsToStable).
  Future<void> _seedDefaultCategories() async {
    final expenseCategories = [
      _cat(DefaultCategoryIds.makanMinum,     'Makan & Minum',      0xe56c, 0xFFEF5350, 'expense'),
      _cat(DefaultCategoryIds.transportasi,   'Transportasi',        0xe1b1, 0xFF42A5F5, 'expense'),
      _cat(DefaultCategoryIds.belanja,        'Belanja',             0xef6f, 0xFFAB47BC, 'expense'),
      _cat(DefaultCategoryIds.tagihan,        'Tagihan & Utilitas',  0xe56b, 0xFFFF7043, 'expense'),
      _cat(DefaultCategoryIds.kesehatan,      'Kesehatan',           0xe548, 0xFF26A69A, 'expense'),
      _cat(DefaultCategoryIds.hiburan,        'Hiburan',             0xe415, 0xFFFFA726, 'expense'),
      _cat(DefaultCategoryIds.pendidikan,     'Pendidikan',          0xe80c, 0xFF5C6BC0, 'expense'),
      _cat(DefaultCategoryIds.rumahTangga,    'Rumah Tangga',        0xe318, 0xFF66BB6A, 'expense'),
      _cat(DefaultCategoryIds.pakaian,        'Pakaian',             0xe3c4, 0xFFEC407A, 'expense'),
      _cat(DefaultCategoryIds.lainnyaExpense, 'Lainnya',             0xe5d3, 0xFF78909C, 'expense'),
    ];

    final incomeCategories = [
      _cat(DefaultCategoryIds.gaji,           'Gaji',      0xe850, 0xFF2E7D32, 'income'),
      _cat(DefaultCategoryIds.bonus,          'Bonus',     0xe8f6, 0xFF1565C0, 'income'),
      _cat(DefaultCategoryIds.freelance,      'Freelance', 0xe8f9, 0xFF6A1B9A, 'income'),
      _cat(DefaultCategoryIds.investasi,      'Investasi', 0xe8e5, 0xFF00838F, 'income'),
      _cat(DefaultCategoryIds.lainnyaIncome,  'Lainnya',   0xe5d3, 0xFF546E7A, 'income'),
    ];

    for (final cat in [...expenseCategories, ...incomeCategories]) {
      await into(categoriesTable).insert(cat, mode: InsertMode.insertOrIgnore);
    }

    await _insertSystemCategoriesIfMissing();
  }

  /// Migrasi v4→v5: update ID kategori default dari UUID acak ke ID stabil.
  ///
  /// Algoritma:
  ///   1. Cari semua kategori default yang ID-nya belum stabil (bukan def-* / sys-*)
  ///   2. Cocokkan ke stableId berdasarkan (name|type)
  ///   3. Update semua transaksi yang mereferensikan oldId → stableId
  ///   4. Update primaryKey kategori oldId → stableId
  ///   5. Seed kategori stabil yang mungkin masih kurang
  Future<void> _migrateCategoryIdsToStable() async {
    const tag = 'AppDatabase.v5';
    dev.log('Memulai migrasi ID kategori ke ID stabil...', name: tag);

    var updated = 0;
    var skipped = 0;

    final allCats = await (select(categoriesTable)
          ..where((c) => c.isDefault.equals(true)))
        .get();

    for (final cat in allCats) {
      // Lewati jika sudah memiliki ID stabil
      if (cat.id.startsWith('sys-') || cat.id.startsWith('def-')) {
        skipped++;
        continue;
      }

      final key      = '${cat.name}|${cat.type}';
      final stableId = DefaultCategoryIds.byNameAndType[key];
      if (stableId == null) {
        dev.log('Kategori tidak dikenal: "${cat.name}" (${cat.type}) — dilewati', name: tag);
        skipped++;
        continue;
      }

      // Periksa apakah ID stabil sudah ada (bisa terjadi pada install ulang parsial)
      final alreadyExists = await (select(categoriesTable)
            ..where((c) => c.id.equals(stableId)))
          .getSingleOrNull();

      if (alreadyExists != null) {
        // ID stabil sudah ada → arahkan referensi lama ke stableId lalu hapus duplikat
        await customStatement(
          'UPDATE transactions SET categoryId = ? WHERE categoryId = ?',
          [stableId, cat.id],
        );
        await (delete(categoriesTable)..where((c) => c.id.equals(cat.id))).go();
        dev.log('Duplikat "${cat.name}" (${cat.id}) digabung ke $stableId', name: tag);
      } else {
        // Update referensi transaksi terlebih dahulu, lalu ubah PK kategori
        await customStatement(
          'UPDATE transactions SET categoryId = ? WHERE categoryId = ?',
          [stableId, cat.id],
        );
        await customStatement(
          'UPDATE categories SET id = ? WHERE id = ?',
          [stableId, cat.id],
        );
        dev.log('"${cat.name}": ${cat.id} → $stableId', name: tag);
      }
      updated++;
    }

    // Seed kategori stabil yang mungkin belum ada sama sekali
    await _seedDefaultCategories();

    dev.log(
      'Migrasi v5 selesai: $updated diperbarui, $skipped dilewati',
      name: tag,
    );
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
