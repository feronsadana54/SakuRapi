import '../../domain/entities/category_entity.dart';
import '../../domain/enums/category_type.dart';

/// Kategori sistem dengan ID tetap yang digunakan untuk transaksi yang dibuat
/// secara otomatis saat pembayaran hutang (pengeluaran), penerimaan cicilan
/// piutang (pemasukan), dan pemberian pinjaman baru (pengeluaran).
///
/// ID ini di-seed ke database saat install pertama dan saat migrasi.
/// JANGAN ubah ID-nya — ID ini direferensikan dari kode provider dan DB seed.
///
/// Alur integrasi:
///   [pembayaranHutang]  → dipakai HutangNotifier & TransactionFormScreen
///                          saat merekam pembayaran hutang sebagai pengeluaran.
///   [penerimaanPiutang] → dipakai PiutangNotifier saat merekam penerimaan
///                          cicilan piutang sebagai pemasukan.
///   [memberiPinjaman]   → dipakai PiutangNotifier saat piutang baru dibuat;
///                          uang yang dipinjamkan dicatat sebagai pengeluaran.
abstract final class SystemCategories {
  // ── ID Tetap ──────────────────────────────────────────────────────────────

  static const String pembayaranHutangId = 'sys-pembayaran-hutang-v1';
  static const String penerimaanPiutangId = 'sys-penerimaan-piutang-v1';
  static const String memberiPinjamanId = 'sys-memberi-pinjaman-v1';

  // ── Objek Kategori ────────────────────────────────────────────────────────

  /// Kategori pengeluaran: dipakai saat user merekam pembayaran hutang,
  /// baik dari HutangDetailScreen maupun dari TransactionFormScreen.
  static const Category pembayaranHutang = Category(
    id: pembayaranHutangId,
    name: 'Pembayaran Hutang',
    iconCode: 0xe56b, // receipt icon
    colorValue: 0xFFE65100, // oranye hutang
    type: CategoryType.expense,
    isDefault: true,
  );

  /// Kategori pemasukan: dipakai saat user merekam penerimaan cicilan piutang
  /// dari PiutangDetailScreen.
  static const Category penerimaanPiutang = Category(
    id: penerimaanPiutangId,
    name: 'Penerimaan Piutang',
    iconCode: 0xe8e5, // trending_up icon
    colorValue: 0xFF1565C0, // biru primary
    type: CategoryType.income,
    isDefault: true,
  );

  /// Kategori pengeluaran: dipakai saat user mencatat piutang baru.
  /// Uang yang dipinjamkan keluar dari saldo — dicatat sebagai pengeluaran.
  static const Category memberiPinjaman = Category(
    id: memberiPinjamanId,
    name: 'Memberi Pinjaman',
    iconCode: 0xe56c, // payments icon
    colorValue: 0xFF0277BD, // biru terang piutang
    type: CategoryType.expense,
    isDefault: true,
  );

  /// Semua kategori sistem sebagai daftar, berguna untuk seeding dan validasi.
  static const List<Category> all = [
    pembayaranHutang,
    penerimaanPiutang,
    memberiPinjaman,
  ];

  /// Mengembalikan true jika ID kategori yang diberikan adalah kategori sistem.
  static bool isSystemCategory(String categoryId) {
    return all.any((c) => c.id == categoryId);
  }
}
