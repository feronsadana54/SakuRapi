/// All user-visible Indonesian strings in one place.
/// Do NOT put strings directly in widgets — always reference this class.
abstract final class AppStrings {
  // ── App ───────────────────────────────────────────────────────────────
  static const String appName = 'DompetKu';
  static const String tagline = 'Catat. Pantau. Hemat.';
  static const String locale = 'id_ID';

  // ── Navigation ────────────────────────────────────────────────────────
  static const String navHome = 'Beranda';
  static const String navTransactions = 'Transaksi';
  static const String navReports = 'Laporan';
  static const String navSettings = 'Pengaturan';

  // ── Onboarding ────────────────────────────────────────────────────────
  static const String onboardingTitle1 = 'Selamat Datang di DompetKu';
  static const String onboardingDesc1 =
      'Kelola keuangan harianmu dengan mudah dan cerdas, kapan saja dan di mana saja.';
  static const String onboardingTitle2 = 'Catat Semua Transaksi';
  static const String onboardingDesc2 =
      'Lacak pemasukan dan pengeluaran secara real-time dengan kategori yang lengkap.';
  static const String onboardingTitle3 = 'Laporan & Siklus Gajian';
  static const String onboardingDesc3 =
      'Lihat laporan harian, bulanan, tahunan, dan siklus gajianmu dalam sekejap.';
  static const String setPaydayTitle = 'Atur Tanggal Gajian';
  static const String setPaydayDesc =
      'Tanggal berapa kamu biasanya gajian? Ini digunakan untuk laporan siklus gajian.';
  static const String paydayHint = 'Contoh: 25';

  // ── Common actions ────────────────────────────────────────────────────
  static const String save = 'Simpan';
  static const String cancel = 'Batal';
  static const String delete = 'Hapus';
  static const String edit = 'Edit';
  static const String add = 'Tambah';
  static const String next = 'Lanjut';
  static const String done = 'Selesai';
  static const String skip = 'Lewati';
  static const String start = 'Mulai';
  static const String retry = 'Coba Lagi';
  static const String close = 'Tutup';
  static const String confirm = 'Konfirmasi';
  static const String yes = 'Ya';
  static const String no = 'Tidak';

  // ── Semantic labels ───────────────────────────────────────────────────
  static const String income = 'Pemasukan';
  static const String expense = 'Pengeluaran';
  static const String balance = 'Saldo';
  static const String total = 'Total';
  static const String today = 'Hari Ini';

  // ── Transaction form ──────────────────────────────────────────────────
  static const String addTransaction = 'Tambah Transaksi';
  static const String editTransaction = 'Edit Transaksi';
  static const String amount = 'Jumlah';
  static const String category = 'Kategori';
  static const String note = 'Catatan';
  static const String date = 'Tanggal';
  static const String selectCategory = 'Pilih Kategori';
  static const String enterAmount = 'Masukkan jumlah';
  static const String optionalNote = 'Catatan (opsional)';
  static const String deleteTransactionTitle = 'Hapus Transaksi?';
  static const String deleteTransactionBody =
      'Transaksi ini akan dihapus secara permanen.';

  // ── Reports ───────────────────────────────────────────────────────────
  static const String reports = 'Laporan';
  static const String daily = 'Harian';
  static const String monthly = 'Bulanan';
  static const String yearly = 'Tahunan';
  static const String dateRange = 'Rentang';
  static const String paydayCycle = 'Siklus Gaji';
  static const String totalIncome = 'Total Pemasukan';
  static const String totalExpense = 'Total Pengeluaran';
  static const String netBalance = 'Saldo Bersih';
  static const String selectDateRange = 'Pilih Rentang Tanggal';
  static const String currentCycle = 'Siklus Aktif';

  // ── Home ──────────────────────────────────────────────────────────────
  static const String goodMorning = 'Selamat Pagi';
  static const String goodAfternoon = 'Selamat Siang';
  static const String goodEvening = 'Selamat Malam';
  static const String recentTransactions = 'Transaksi Terbaru';
  static const String seeAll = 'Lihat Semua';
  static const String todaySummary = 'Ringkasan Hari Ini';
  static const String quoteOfDay = 'Kutipan Hari Ini';

  // ── Settings ──────────────────────────────────────────────────────────
  static const String settings = 'Pengaturan';
  static const String paydayDate = 'Tanggal Gajian';
  static const String paydayDateDesc = 'Digunakan untuk laporan siklus gajian';
  static const String dailyReminder = 'Pengingat Keuangan';
  static const String dailyReminderDesc = 'Aktifkan pengingat untuk mencatat keuangan';
  static const String aboutApp = 'Tentang Aplikasi';
  static const String version = 'Versi';
  static const String notifPermissionRequired =
      'Izin notifikasi diperlukan. Aktifkan di Pengaturan perangkat.';

  // ── Reminder settings ─────────────────────────────────────────────────
  static const String reminderTime = 'Waktu Pengingat';
  static const String reminderDays = 'Hari Aktif';
  static const String reminderDaysDesc =
      'Pilih hari-hari di mana pengingat akan berbunyi';
  static const String reminderRescheduled = 'Jadwal pengingat diperbarui';
  static const List<String> weekdayShort = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min',
  ];

  // ── Empty states ──────────────────────────────────────────────────────
  static const String noTransactions = 'Belum Ada Transaksi';
  static const String noTransactionsDesc =
      'Ketuk tombol + untuk menambahkan transaksi pertamamu.';
  static const String noData = 'Belum Ada Data';
  static const String noDataDesc =
      'Data akan muncul setelah kamu menambahkan transaksi.';

  // ── Validation errors ─────────────────────────────────────────────────
  static const String amountRequired = 'Jumlah tidak boleh kosong';
  static const String amountInvalid = 'Jumlah harus lebih dari 0';
  static const String categoryRequired = 'Pilih kategori terlebih dahulu';
  static const String paydayInvalid = 'Masukkan angka antara 1 dan 31';

  // ── General errors ────────────────────────────────────────────────────
  static const String errorGeneral = 'Terjadi kesalahan. Silakan coba lagi.';
  static const String errorLoad = 'Gagal memuat data.';

  // ── Notification content ──────────────────────────────────────────────
  static const String notifTitle = 'Waktunya Catat Keuangan';
  static const String notifBody =
      'Sudah catat pengeluaran hari ini? Yuk, catat sekarang!';
  static const String notifChannelId = 'keuangan_harian';
  static const String notifChannelName = 'Pengingat Keuangan Harian';
  static const String notifChannelDesc =
      'Notifikasi pengingat untuk mencatat keuangan harian';

  // ── Export / Import ───────────────────────────────────────────────────────
  static const String exportCsv = 'Ekspor CSV';
  static const String exportCsvDesc = 'Bagikan semua transaksi sebagai file CSV';
  static const String importCsv = 'Impor CSV';
  static const String importCsvDesc = 'Muat transaksi dari file CSV DompetKu';
  static const String exportSuccess = 'Ekspor berhasil';
  static const String importSuccess = 'Impor berhasil';
  static const String importConfirmTitle = 'Konfirmasi Impor';
  static const String importConfirmBody =
      'transaksi akan ditambahkan ke data kamu. Lanjutkan?';
  static const String noTransactionsToExport =
      'Belum ada transaksi untuk diekspor.';
  static const String importInvalidFormat =
      'Format file tidak valid. Gunakan file CSV yang diekspor dari DompetKu.';
  static const String importing = 'Mengimpor data...';

  // ── Bulk delete ───────────────────────────────────────────────────────────
  static const String bulkDeleteTitle = 'Hapus Transaksi Terpilih?';
  static const String bulkDeleteBody =
      'transaksi yang dipilih akan dihapus secara permanen.';

  // ── About ─────────────────────────────────────────────────────────────────
  static const String appDescription =
      'Aplikasi pencatat keuangan pribadi offline yang modern, aman, dan mudah digunakan.';
  static const String notifPermissionDenied =
      'Izin notifikasi ditolak. Aktifkan di Pengaturan perangkat.';
  static const String notifScheduled =
      'Pengingat berhasil dijadwalkan';
  static const String notifDisabled =
      'Pengingat dinonaktifkan';
  static const String notifNotSupportedOnWeb =
      'Notifikasi tidak didukung di browser. Gunakan aplikasi Android/iOS.';
}
