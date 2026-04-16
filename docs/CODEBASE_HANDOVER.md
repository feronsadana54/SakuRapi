# DompetKu — Dokumen Serah Terima Kode

> Dokumen ini ditulis untuk developer yang baru bergabung dan belum mengenal proyek ini sama sekali.
> Dokumen ini menjelaskan setiap keputusan arsitektur, setiap folder, setiap file penting,
> serta cara kerja fitur-fitur utama dari awal hingga akhir.

---

## Daftar Isi

1. [Gambaran Umum Proyek](#1-gambaran-umum-proyek)
2. [Arsitektur](#2-arsitektur)
3. [Struktur Folder](#3-struktur-folder)
4. [Lapisan Data](#4-lapisan-data)
5. [Lapisan Domain](#5-lapisan-domain)
6. [Lapisan Presentasi](#6-lapisan-presentasi)
7. [Manajemen State](#7-manajemen-state)
8. [Routing](#8-routing)
9. [Sistem UI Responsif](#9-sistem-ui-responsif)
10. [Logika Kalkulasi Laporan](#10-logika-kalkulasi-laporan)
11. [Logika Siklus Gajian](#11-logika-siklus-gajian)
12. [Logika Notifikasi & Pengingat](#12-logika-notifikasi--pengingat)
13. [Logika Ekspor / Impor CSV](#13-logika-ekspor--impor-csv)
14. [Fitur Kutipan Keuangan](#14-fitur-kutipan-keuangan)
15. [Pengaturan & Persistensi](#15-pengaturan--persistensi)
16. [Startup & Logika Splash Screen](#16-startup--logika-splash-screen)
17. [Dukungan Platform Web](#17-dukungan-platform-web)
18. [Pengujian](#18-pengujian)
19. [Menambahkan Fitur Baru](#19-menambahkan-fitur-baru)
20. [Keterbatasan yang Diketahui & Rencana ke Depan](#20-keterbatasan-yang-diketahui--rencana-ke-depan)

---

## 1. Gambaran Umum Proyek

**DompetKu** adalah aplikasi pencatat keuangan pribadi yang sepenuhnya offline untuk Android, iOS, dan Web. Pengguna dapat mencatat transaksi pemasukan dan pengeluaran, melihat laporan dalam lima rentang waktu, mendapatkan pengingat harian yang dapat dikonfigurasi sesuai jam dan hari, serta mengekspor/mengimpor data dalam format CSV.

**Keputusan desain utama:**

| Keputusan | Alasan |
|----------|-----------|
| 100% offline | Tidak ada backend, tidak ada akun, tidak ada risiko privasi |
| Drift (SQLite) | Query bertipe aman, reactive stream, pembuatan kode otomatis |
| Riverpod (manual) | Tidak memerlukan pembuatan kode untuk state, model mental lebih sederhana |
| go_router | Routing deklaratif dengan `ShellRoute` untuk navigasi tab |
| flutter_svg | Semua ilustrasi dikirim sebagai SVG — vektor, tajam di semua DPI |
| Antarmuka Bahasa Indonesia | Target pengguna adalah masyarakat Indonesia |

**Nama paket:** `finance_tracker` (`pubspec.yaml`)  
**Nama tampilan aplikasi:** `DompetKu`  
**Flutter:** 3.41.6+ · **Dart:** 3.7.0+

---

## 2. Arsitektur

Proyek ini mengikuti **Clean Architecture** dengan tiga lapisan yang ketat. Dependensi hanya mengalir ke dalam — Presentation → Domain ← Data.

```
┌──────────────────────────────────────────────────┐
│  PRESENTATION                                    │
│  Screens · Widgets · Providers (Riverpod)        │
│                                                  │
│  Mengetahui: Entitas & use-case Domain           │
│  TIDAK mengimpor: Kelas lapisan Data secara langsung │
├──────────────────────────────────────────────────┤
│  DOMAIN  (Dart murni — tanpa Flutter, tanpa Drift) │
│  Entities · Repository interfaces · Enums        │
│                                                  │
│  Mengetahui: tidak ada yang di luar dirinya sendiri │
├──────────────────────────────────────────────────┤
│  DATA                                            │
│  Drift database · DAO classes · Repository impls │
│                                                  │
│  Mengetahui: Antarmuka Domain                    │
│  TIDAK: mengekspos tipe Drift ke Presentation    │
└──────────────────────────────────────────────────┘
```

Lapisan Presentation mengakses lapisan Data **hanya melalui provider Riverpod** yang didefinisikan di `lib/presentation/providers/database_provider.dart`. Provider tersebut mengekspos instance repository yang diketik sebagai antarmuka domain (`ITransactionRepository`, `ICategoryRepository`, `ISettingsRepository`).

---

## 3. Struktur Folder

```
lib/
├── main.dart                     # Entry point: inisialisasi SharedPrefs + timezone + notif (non-web)
├── app.dart                      # MaterialApp.router — tema + locale + router
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart       # Semua konstanta Color (jangan hardcode hex di tempat lain)
│   │   ├── app_icons.dart        # Definisi ikon
│   │   ├── app_strings.dart      # Semua string UI dalam Bahasa Indonesia
│   │   └── finance_quotes.dart   # 30 kutipan motivasi + getter todayIndex (rotasi hari-dalam-tahun)
│   ├── responsive/
│   │   ├── breakpoints.dart      # Enum ScreenClass + ekstensi BuildContext
│   │   ├── app_spacing.dart      # Helper padding/gap responsif
│   │   ├── app_type_scale.dart   # Helper ukuran font responsif
│   │   └── responsive_container.dart  # Pembungkus lebar maksimum untuk tablet
│   ├── services/
│   │   ├── notification_service.dart  # Wrapper flutter_local_notifications (dilindungi kIsWeb)
│   │   └── export_import_service.dart # Ekspor CSV via share_plus, impor via file_picker
│   ├── theme/
│   │   └── app_theme.dart        # ThemeData Material 3 lengkap (font Poppins)
│   ├── utils/
│   │   ├── date_utils.dart       # Helper tanggal murni + kalkulasi siklus gajian
│   │   └── currency_formatter.dart    # Format/parsing IDR (intl)
│   └── widgets/
│       ├── app_loading_indicator.dart
│       └── empty_state_widget.dart    # Menerima svgAsset opsional; fallback ke ikon-dalam-lingkaran
│
├── data/
│   ├── database/
│   │   ├── app_database.dart     # @DriftDatabase + seed + migrasi + _openDatabase() platform-aware
│   │   ├── app_database.g.dart   # DIBUAT OTOMATIS — jangan diedit
│   │   ├── daos/
│   │   │   ├── category_dao.dart    # @DriftAccessor untuk kategori
│   │   │   ├── category_dao.g.dart  # DIBUAT OTOMATIS
│   │   │   ├── transaction_dao.dart # @DriftAccessor untuk transaksi
│   │   │   └── transaction_dao.g.dart # DIBUAT OTOMATIS
│   │   └── tables/
│   │       ├── categories_table.dart   # Definisi tabel Drift
│   │       └── transactions_table.dart # Definisi tabel Drift
│   └── repositories/
│       ├── category_repository_impl.dart
│       ├── settings_repository_impl.dart   # Berbasis SharedPreferences
│       └── transaction_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── category_entity.dart     # Category (Equatable)
│   │   ├── transaction_entity.dart  # Transaction (Equatable)
│   │   └── summary_result.dart      # Output laporan teragregasi
│   ├── enums/
│   │   ├── category_type.dart       # income / expense / both
│   │   └── transaction_type.dart    # income / expense
│   └── repositories/
│       ├── i_category_repository.dart
│       ├── i_settings_repository.dart
│       └── i_transaction_repository.dart
│
├── presentation/
│   ├── features/
│   │   ├── home/home_screen.dart
│   │   ├── onboarding/onboarding_screen.dart
│   │   ├── reports/
│   │   │   ├── reports_screen.dart       # Shell TabController (5 tab)
│   │   │   └── tabs/
│   │   │       ├── daily_report_tab.dart
│   │   │       ├── monthly_report_tab.dart
│   │   │       ├── yearly_report_tab.dart
│   │   │       ├── range_report_tab.dart
│   │   │       └── payday_report_tab.dart
│   │   ├── settings/settings_screen.dart
│   │   ├── shell/app_shell.dart          # BottomNav + NavigationRail (tablet)
│   │   ├── splash/splash_screen.dart     # Timer 1600ms + pemeriksaan onboarding dengan timeout
│   │   └── transactions/
│   │       ├── transaction_form_screen.dart  # Form Tambah / Edit
│   │       └── transaction_list_screen.dart  # Daftar + filter + geser-hapus
│   ├── providers/
│   │   ├── database_provider.dart      # Provider DB + DAO + repository
│   │   ├── settings_provider.dart      # AsyncNotifier<AppSettings>
│   │   ├── transaction_provider.dart   # StreamProvider + HomeSummary
│   │   ├── category_provider.dart      # StreamProvider + family berdasarkan tipe
│   │   ├── report_provider.dart        # FutureProvider.family + 5 provider turunan
│   │   └── notification_provider.dart  # NotificationToggleNotifier
│   └── widgets/
│       ├── category_grid_picker.dart
│       ├── report_widgets.dart         # SummaryStatCards, CategoryBreakdown, PeriodBarChart
│       └── transaction_tile.dart       # Widget baris + DateGroupHeader
│
└── router/
    └── app_router.dart   # Konfigurasi GoRouter + konstanta AppRoutes
```

---

## 4. Lapisan Data

### Database (`AppDatabase`)

**File:** `lib/data/database/app_database.dart`

Menggunakan Drift 2.x. Database dibuka via metode statis `_openDatabase()` yang memilih implementasi berdasarkan platform:

- **Android/iOS**: `driftDatabase(name: 'finance_tracker')` → menyimpan ke `finance_tracker.db` di direktori dokumen aplikasi
- **Web**: `NativeDatabase.memory()` → in-memory, data tidak persisten saat reload

Versi skema: **1**. Tingkatkan dengan menaikkan `schemaVersion` dan menambahkan handler `onUpgrade`.

**Data seed** dijalankan pada `onCreate` saja (instalasi pertama). Menyemai 10 kategori pengeluaran + 5 kategori pemasukan menggunakan `int` codepoint ikon yang di-hardcode.

### Tabel

**`CategoriesTable`** — `@DataClassName('CategoryData')`

| Kolom | Tipe | Keterangan |
|--------|------|-------|
| `id` | TEXT | Primary key UUID |
| `name` | TEXT | Nama tampilan |
| `iconCode` | INTEGER | `IconData.codePoint` dari MaterialIcons |
| `colorValue` | INTEGER | Warna ARGB sebagai int (`Color.value`) |
| `type` | TEXT | `'income'` / `'expense'` / `'both'` |
| `isDefault` | BOOLEAN | Data seed tidak dapat dihapus (diberlakukan di UI) |

**`TransactionsTable`** — `@DataClassName('TransactionData')`

| Kolom | Tipe | Keterangan |
|--------|------|-------|
| `id` | TEXT | Primary key UUID |
| `type` | TEXT | `'income'` / `'expense'` |
| `amount` | REAL | Selalu positif |
| `categoryId` | TEXT | FK → `categories.id` |
| `note` | TEXT? | Boleh null |
| `date` | INTEGER | `DateTime.millisecondsSinceEpoch` (tengah malam, tanpa komponen waktu) |
| `createdAt` | INTEGER | Timestamp lengkap dalam epoch ms |

### DAO

**`CategoryDao`** — `getAll()`, `watchAll()`, `insert()`, `delete()`

**`TransactionDao`** — `watchAll()` (stream, urutan tanggal menurun), `getByDateRange(startMs, endMs)`, `getById()`, `insertTransaction()`, `updateTransaction()`, `deleteTransaction()`

Query rentang tanggal membandingkan epoch ms secara langsung:
```dart
where((t) => t.date.isBetweenValues(startEpochMs, endEpochMs))
```

### Implementasi Repository

Implementasi repository menerjemahkan antara kelas data Drift (`CategoryData`, `TransactionData`) dan entitas domain (`Category`, `Transaction`). Lapisan Presentation tidak pernah melihat tipe Drift.

`TransactionRepositoryImpl` melakukan join kategori pada saat query — ia memanggil `_catDao.getAll()` dan membangun peta `id → Category` untuk menghidrasi setiap baris transaksi.

**Pengaturan** disimpan di `SharedPreferences` (tidak ada tabel Drift). Semua kunci:

| Kunci | Default | Tipe |
|-----|---------|------|
| `onboarding_complete` | `false` | bool |
| `payday_date` | `25` | int |
| `notification_enabled` | `true` | bool |
| `reminder_hour` | `21` | int |
| `reminder_minute` | `0` | int |
| `reminder_days` | `'1,2,3,4,5,6,7'` | String (CSV) |

---

## 5. Lapisan Domain

Dart murni — tanpa Flutter, tanpa Drift, tanpa import platform.

### `Transaction`

```dart
class Transaction extends Equatable {
  final String id;         // UUID
  final TransactionType type;
  final double amount;     // selalu positif
  final Category category;
  final String? note;
  final DateTime date;     // hanya tengah malam (waktu dihilangkan)
  final DateTime createdAt;
  
  bool get isIncome  => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
}
```

### `Category`

```dart
class Category extends Equatable {
  final String id;
  final String name;
  final int iconCode;    // codepoint MaterialIcons
  final int colorValue;  // Color.value (ARGB)
  final CategoryType type;
  final bool isDefault;
}
```

### `SummaryResult`

Output universal dari semua kalkulasi laporan. Dibangun oleh `SummaryResult.fromTransactions(List<Transaction>)`:

```dart
class SummaryResult {
  final double totalIncome;
  final double totalExpense;
  final List<Transaction> transactions;
  final Map<Category, double> expenseByCategory;
  final Map<Category, double> incomeByCategory;
  
  double get balance => totalIncome - totalExpense;
  bool get isEmpty   => transactions.isEmpty;
  
  static const SummaryResult empty = ...;
}
```

`fromTransactions` melakukan iterasi sekali O(n) — tanpa pass terpisah untuk pemasukan/pengeluaran. Kesetaraan kategori menggunakan `Equatable` pada `id`.

---

## 6. Lapisan Presentasi

### Daftar Screen

| Screen | Route | Tujuan |
|--------|-------|---------|
| `SplashScreen` | `/splash` | Menentukan apakah akan ke onboarding atau home |
| `OnboardingScreen` | `/onboarding` | 3 halaman + pengaturan tanggal gajian awal |
| `HomeScreen` | `/home` | Kartu saldo, ringkasan hari ini, transaksi terbaru, kutipan |
| `TransactionListScreen` | `/transactions` | Semua transaksi, filter berdasarkan tipe, geser-untuk-hapus, long-press untuk multi-select + hapus massal |
| `TransactionFormScreen` | `/transactions/add`, `/transactions/edit` | Menambah atau mengedit transaksi |
| `ReportsScreen` | `/reports` | TabBar yang membungkus 5 tab laporan |
| `SettingsScreen` | `/settings` | Gajian, notifikasi, ekspor/impor, tentang |

### Shell

`AppShell` (`lib/presentation/features/shell/app_shell.dart`) membungkus 4 tab utama dalam sebuah `ShellRoute`. Di tablet (`≥ 720 dp`), merender `NavigationRail`; di ponsel menggunakan `BottomNavigationBar`. Screen form berada **di luar** shell sehingga tidak menampilkan navigation bar.

### Widget yang Dapat Digunakan Ulang

| Widget | Tujuan |
|--------|---------|
| `TransactionTile` | Baris dengan ikon kategori, nama, jumlah, tanggal |
| `DateGroupHeader` | Pemisah label tanggal di `TransactionListScreen` |
| `CategoryGridPicker` | Grid 3 kolom untuk pemilihan kategori di form |
| `SummaryStatCards` | Kartu pemasukan / pengeluaran / saldo (semua 5 tab laporan) |
| `CategoryBreakdownSection` | Daftar terurut dengan progress bar (semua 5 tab laporan) |
| `PeriodBarChart` | Grafik batang fl_chart — batang tunggal atau ganda |
| `EmptyStateWidget` | Ilustrasi SVG + judul + subjudul + tombol aksi opsional |
| `AppLoadingIndicator` | `CircularProgressIndicator` yang terpusat |

---

## 7. Manajemen State

Proyek menggunakan **Riverpod 2.x** dengan provider manual (tanpa `riverpod_annotation` atau pembuatan kode).

### Hierarki Provider

```
sharedPreferencesProvider   ← ditimpa di main() ProviderScope
    └─ settingsRepositoryProvider
           └─ settingsProvider (AsyncNotifierProvider)
           └─ onboardingCompleteProvider (FutureProvider)

appDatabaseProvider
    ├─ categoryDaoProvider
    │      └─ categoryRepositoryProvider
    │             ├─ categoriesProvider (StreamProvider)
    │             └─ categoriesForTypeProvider (Provider.family)
    └─ transactionDaoProvider
           └─ transactionRepositoryProvider
                  ├─ allTransactionsProvider (StreamProvider)
                  ├─ homeSummaryProvider (Provider<AsyncValue>)
                  └─ reportSummaryProvider (FutureProvider.family<SummaryResult, (DateTime,DateTime)>)
                         ├─ dailyReportProvider
                         ├─ monthlyReportProvider
                         ├─ yearlyReportProvider
                         ├─ rangeReportProvider
                         └─ paydayCycleReportProvider

notificationServiceProvider
    └─ notificationToggleProvider (AsyncNotifierProvider)
```

### Pola Utama

**`StreamProvider` untuk data reaktif:** `allTransactionsProvider` dan `categoriesProvider` mengamati stream Drift. Setiap penulisan ke DB secara otomatis memperbarui semua widget yang bergantung padanya.

**`FutureProvider.family` untuk laporan:** `reportSummaryProvider` menerima record `(DateTime, DateTime)`. Lima provider laporan turunan mengombinasikan ini dengan state rentang tanggal mereka masing-masing.

**`AsyncNotifier` untuk pengaturan:** `SettingsNotifier` memuat pengaturan sekali di `build()`, lalu mengekspos setter seperti `setPaydayDate()`, `setReminderHour()`, `setReminderDays()`.

**Pre-loading `SharedPreferences`:** `SharedPreferences.getInstance()` ditunggu di `main()` sebelum `runApp()`. Hasilnya diinjeksikan melalui `ProviderScope.overrides`.

---

## 8. Routing

**File:** `lib/router/app_router.dart`

Menggunakan `go_router` dengan pola `ShellRoute`.

```
/splash             → SplashScreen (memeriksa flag onboarding)
/onboarding         → OnboardingScreen
/transactions/add   → TransactionFormScreen (tanpa nav bar)
/transactions/edit  → TransactionFormScreen(editTransaction: extra) (tanpa nav bar)

ShellRoute (AppShell — menampilkan nav bar)
  /home             → HomeScreen
  /transactions     → TransactionListScreen
  /reports          → ReportsScreen
  /settings         → SettingsScreen
```

### Navigasi

```dart
// Push (back stack dipertahankan)
context.push(AppRoutes.transactionAdd);

// Push dengan data extra
context.push(AppRoutes.transactionEdit, extra: transaction);

// Replace (tanpa tombol kembali — digunakan di tab shell)
context.go(AppRoutes.home);
```

---

## 9. Sistem UI Responsif

**File:** `lib/core/responsive/`

### Breakpoint

| Kelas | Lebar layar | Contoh perangkat |
|-------|-------------|-----------------|
| `smallMobile` | < 360 dp | Ponsel Android yang sangat kecil |
| `normalMobile` | 360–599 dp | Kebanyakan ponsel (Pixel, Samsung) |
| `largeMobile` | 600–719 dp | Ponsel besar, tablet kecil |
| `tablet` | ≥ 720 dp | iPad, tablet Android |

Akses melalui ekstensi `BuildContext`:

```dart
context.screenClass  // enum ScreenClass
context.isTablet     // bool
context.isMobile     // bool
context.isSmall      // bool (hanya smallMobile)
```

### Spasi & Tipografi

```dart
AppSpacing.pagePadding(context)       // 12 / 16 / 20 / 28 dp
AppTypeScale.balanceDisplay(context)  // 26 / 30 / 34 / 40 sp
AppTypeScale.bodyText(context)        // 12 / 13 / 14 / 15 sp
```

Screen yang memiliki tampilan khusus tablet: `HomeScreen`, `TransactionListScreen`, `AppShell`.

---

## 10. Logika Kalkulasi Laporan

**Fungsi inti:** `SummaryResult.fromTransactions(List<Transaction>)`  
**File:** `lib/domain/entities/summary_result.dart`

Semua 5 tipe laporan memasukkan transaksi melalui fungsi tunggal ini. Pengambilan data ditangani oleh `reportSummaryProvider` yang memanggil `ITransactionRepository.getByDateRange(start, end)`.

### 5 Tipe Laporan

| Tab | Rentang tanggal |
|-----|-----------|
| Harian | `startOfDay(selectedDay)` → `endOfDay(selectedDay)` |
| Bulanan | `firstDayOfMonth` → `lastDayOfMonth` |
| Tahunan | 1 Januari → 31 Desember |
| Rentang Tanggal | Dipilih pengguna via date range picker |
| Siklus Gajian | Diturunkan dari `AppDateUtils.getPaydayCycle(paydayDate)` |

### Grafik

- **Tab Bulanan:** bucket pengeluaran per hari dalam bulan (bar chart harian)
- **Tab Tahunan:** pemasukan + pengeluaran per bulan dalam tahun (bar chart ganda per bulan)
- Grafik dirender dengan `fl_chart` melalui widget `PeriodBarChart`

---

## 11. Logika Siklus Gajian

**File:** `lib/core/utils/date_utils.dart`  
**Fungsi:** `AppDateUtils.getPaydayCycle({required int paydayDate, DateTime? reference})`  
**Return:** `(DateTime start, DateTime end)` (Dart record)

### Algoritma

Diberikan `paydayDate` (1–31) dan tanggal referensi:

1. Tentukan **bulan siklus** berdasarkan hari saat ini vs tanggal gajian
2. Jika hari ini **≥ tanggal gajian**: siklus dimulai bulan ini, berakhir bulan depan (sehari sebelum gajian)
3. Jika hari ini **< tanggal gajian**: siklus dimulai bulan lalu, berakhir bulan ini (sehari sebelum gajian)
4. Gunakan `clampToMonth(day, month, year)` untuk menangani bulan yang tidak memiliki hari tersebut (mis., 31 Februari → 28 atau 29 Feb)

### Contoh

Tanggal gajian = 25:
- Hari ini = 28 April → siklus: 25 Apr – 24 Mei
- Hari ini = 10 April → siklus: 25 Mar – 24 Apr

Tanggal gajian = 31:
- Bulan Februari: `clampToMonth(31, 2, year)` → 28 atau 29

---

## 12. Logika Notifikasi & Pengingat

**File:** `lib/core/services/notification_service.dart`  
**Provider:** `lib/presentation/providers/notification_provider.dart`

### Penjadwalan

Notifikasi dijadwalkan **per hari dalam seminggu**, menggunakan ID 1–7 (Senin–Minggu). Pengguna dapat memilih:
- **Jam dan menit** pengingat (default: 21:00 WIB)
- **Hari-hari aktif** (default: setiap hari, 1–7)

Setiap kali pengguna mengubah pengaturan:
1. Semua notifikasi yang ada (ID 1–7 + ID legacy 0) dibatalkan via `cancelAllReminders()`
2. Notifikasi baru dijadwalkan untuk setiap hari yang dipilih via `zonedSchedule` dengan `DateTimeComponents.dayOfWeekAndTime`

### Metode Utama

```dart
// Minta izin (Android 13+: POST_NOTIFICATIONS; Android 12+: SCHEDULE_EXACT_ALARM)
await service.requestPermission() → bool

// Jadwalkan ulang semua hari yang dipilih
await service.scheduleReminders(hour: 21, minute: 0, weekdays: [1,2,3,4,5,6,7])

// Batalkan semua
await service.cancelAllReminders()
```

### Perilaku di Web

Semua metode `NotificationService` mengembalikan nilai default (tanpa error) saat `kIsWeb == true`. Notifikasi dinonaktifkan di web karena `flutter_local_notifications` tidak mendukung platform browser.

### Inisialisasi di `main.dart`

Inisialisasi timezone dan notifikasi dilakukan **setelah frame pertama** menggunakan `addPostFrameCallback`. Setiap operasi dibungkus dengan timeout 3 detik. Jika inisialisasi gagal, aplikasi tetap berfungsi normal (hanya tanpa notifikasi). Di web, blok ini dilewati sepenuhnya.

Flag `_bgInitDone` memastikan inisialisasi hanya berjalan sekali per proses (tidak berulang saat hot-reload).

---

## 13. Logika Ekspor / Impor CSV

**File:** `lib/core/services/export_import_service.dart`

### Format CSV

```
Tanggal,Tipe,Jumlah,Kategori,Catatan
15 Apr 2026,expense,50000,Makan & Minum,Makan siang
14 Apr 2026,income,5000000,Gaji,
```

- **Tanggal:** format `d MMM yyyy` dalam nama bulan Indonesia (Jan/Feb/Mar/Apr/Mei/Jun/Jul/Agu/Sep/Okt/Nov/Des)
- **Tipe:** `income` atau `expense` (nilai bahasa Inggris, stabil untuk parsing)
- **Jumlah:** angka desimal tanpa pemisah ribuan
- **Kategori:** nama kategori persis sesuai database

### Ekspor

`exportAndShare(List<Transaction>)` → membangun string CSV di memori → berbagi via `share_plus`. Tidak menulis file ke disk.

### Impor

`pickAndParse()` → pengguna memilih file via `file_picker` → parsing dengan `CsvToListConverter` → mengembalikan daftar `CsvRow`. Baris dengan nama kategori yang tidak dikenali dilewati secara diam-diam. Jumlah baris yang berhasil diimpor ditampilkan ke pengguna.

### Perilaku Fallback

Jika parsing tanggal gagal (format tidak dikenal), baris tersebut menggunakan tanggal hari ini. Ini mencegah crash namun menghasilkan tanggal yang tidak akurat.

---

## 14. Fitur Kutipan Keuangan

**File:** `lib/core/constants/finance_quotes.dart`  
**Widget:** `_QuoteCarousel` di `lib/presentation/features/home/home_screen.dart`

30 kutipan motivasi tentang keuangan dalam Bahasa Indonesia.

### Indeks Awal Harian

Kutipan pertama yang ditampilkan saat membuka aplikasi ditentukan secara deterministik berdasarkan **hari dalam tahun** (bukan tanggal kalender):

```dart
static int get todayIndex {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year)).inDays;
  return dayOfYear % quotes.length; // 0–29
}
```

### Rotasi Otomatis Setiap 8 Detik

Widget `_QuoteCarousel` adalah `StatefulWidget` yang menjalankan `Timer.periodic(Duration(seconds: 8), ...)`. Setiap tick, indeks kutipan maju satu langkah dengan wrapping:

```dart
_index = (_index + 1) % FinanceQuotes.quotes.length;
```

Pergantian kutipan ditampilkan dengan efek fade + slide ke atas menggunakan `AnimatedSwitcher` (durasi transisi 450ms, kurva `Curves.easeOut`). Timer dibatalkan di `dispose()` — tidak ada kebocoran memori atau timer yang berjalan setelah widget dilepas.

### Properti Penting

| Properti | Nilai |
|----------|-------|
| Jumlah kutipan | 30 |
| Interval rotasi | 8 detik |
| Animasi transisi | Fade + slide (450ms, easeOut) |
| Sumber kutipan | Hardcoded lokal, tanpa jaringan |
| Indeks awal | `todayIndex` (deterministik per hari) |

Kutipan ditampilkan di **layar beranda** (`HomeScreen`). Tidak memerlukan jaringan — sepenuhnya offline.

---

## 14a. Pemilih Tanggal Transaksi — Tanpa Batas Atas

**File:** `lib/presentation/features/transactions/transaction_form_screen.dart`

Pemilih tanggal di form transaksi (`_pickDate()`) tidak memiliki batas atas tanggal. Pengguna bebas memilih tanggal masa lalu maupun masa depan:

```dart
final picked = await showDatePicker(
  context: context,
  initialDate: _selectedDate,
  firstDate: DateTime(2000),      // Batas bawah: tahun 2000
  lastDate: DateTime(2100),       // Batas atas: tahun 2100 (tidak ada batasan praktis)
  locale: const Locale('id', 'ID'),
  ...
);
```

**Alasan desain:** Pengguna mungkin perlu mencatat transaksi yang terlupa di masa lalu, atau merencanakan transaksi di masa depan (misalnya: pembayaran cicilan yang akan datang). Tidak ada alasan untuk membatasi pilihan tanggal.

Tanggal yang dipilih disimpan hanya sebagai "tanggal" (tanpa komponen waktu) menggunakan `AppDateUtils.dateOnly(_selectedDate)`.

---

## 14b. Hapus Massal Transaksi (Multi-Select Mode)

**File:** `lib/presentation/features/transactions/transaction_list_screen.dart`

### Alur UX

1. **Mode Normal:** Setiap item diwrap `GestureDetector` + `Dismissible`. Tap → buka form edit. Geser kiri → konfirmasi hapus satu item.
2. **Masuk Mode Pilih:** Long-press pada item mana saja → memanggil `_enterSelectMode(tx)` → item itu langsung terpilih.
3. **Mode Pilih Aktif:**
   - AppBar diganti dengan `_buildSelectionAppBar()` yang menampilkan jumlah item terpilih (`N dipilih`).
   - Filter bar (Semua / Pemasukan / Pengeluaran) disembunyikan.
   - FAB disembunyikan.
   - Setiap tile diganti dengan `_SelectableTile` (checkbox + tile) — tap untuk toggle.
   - Ikon hapus merah muncul di AppBar jika ada item terpilih.
4. **Hapus Massal:** Tap ikon hapus → dialog konfirmasi → konfirmasi → iterasi `repo.delete(id)` untuk setiap ID terpilih → keluar mode pilih → tampilkan snackbar.
5. **Keluar Mode Pilih:** Tap tombol tutup (×) di AppBar, atau tekan tombol back Android (ditangani `PopScope`), atau set terakhir dikosongkan saat toggle.

### State yang Dikelola

```dart
bool _isSelectMode = false;
final Set<String> _selectedIds = {};
```

State ini dikelola sepenuhnya di `_TransactionListScreenState`. Tidak ada provider atau state global.

### Catatan Tablet

Mode multi-select hanya tersedia di tampilan mobile. Di tablet, `_TabletLayout` menampilkan panel detail dua kolom (list kiri + detail kanan) tanpa mode multi-select, karena tablet memiliki ruang untuk menampilkan dan mengedit transaksi secara langsung.

---

## 15. Pengaturan & Persistensi

**File:** `lib/data/repositories/settings_repository_impl.dart`  
**Provider:** `lib/presentation/providers/settings_provider.dart`

### Kelas `AppSettings`

```dart
class AppSettings {
  final int paydayDate;           // 1–31, default 25
  final bool notificationEnabled; // default true
  final int reminderHour;         // 0–23, default 21
  final int reminderMinute;       // 0–59, default 0
  final List<int> reminderDays;   // 1=Sen … 7=Min, default [1..7]
}
```

### Layar Pengaturan

**Seksi Keuangan:**
- `_PaydayTile` — dialog input angka 1–31 untuk mengubah tanggal gajian

**Seksi Notifikasi:**
- Toggle switch untuk mengaktifkan/menonaktifkan pengingat
- Jika aktif: tampilkan `ListTile` pemilih waktu (tapping membuka `showTimePicker`)
- Jika aktif: tampilkan `_WeekdaySelector` — 7 chip berbentuk lingkaran (Sn/Sl/Rb/Km/Jm/Sb/Mg), minimal 1 hari harus dipilih

Setiap perubahan di layar Pengaturan memanggil `reschedule()` pada `NotificationToggleNotifier` untuk membatalkan semua notifikasi lama dan menjadwalkan ulang dengan pengaturan baru.

**Seksi Data:**
- Ekspor CSV — share sheet
- Impor CSV — file picker + dialog konfirmasi

---

## 16. Startup & Logika Splash Screen

**File:** `lib/presentation/features/splash/splash_screen.dart`

### Alur

1. `SplashScreen` diinisialisasi dengan `AnimationController` (700ms fade + scale in)
2. `Timer(_splashDelay = 1600ms, _navigate)` dibuat — selalu dibatalkan di `dispose()`
3. Setelah 1600ms, `_navigate()` dipanggil:
   - Memanggil `settingsRepository.isOnboardingComplete()` dengan timeout 3 detik
   - Jika error atau timeout → `isComplete = true` (fallback ke beranda, pengguna tidak pernah terjebak)
   - Navigasi ke `/home` atau `/onboarding` sesuai hasilnya

### Jaminan Stabilitas

- Timer selalu dibatalkan di `dispose()` → tidak ada navigasi setelah widget dibuang
- `if (!mounted) return` diperiksa sebelum dan sesudah operasi async
- Timeout 3 detik mencegah splash tergantung karena SharedPreferences lambat

---

## 17. Dukungan Platform Web

Proyek mendukung penuh kompilasi ke web (Chrome, Firefox, Safari). Folder `web/` berisi `index.html`, `manifest.json`, ikon PWA, dan dua file penting untuk database web.

### Arsitektur Database Web

Database web menggunakan **SQLite berbasis WebAssembly** melalui `drift_flutter` — bukan `dart:ffi` (yang tidak tersedia di browser). Ini memberikan SQL penuh yang kompatibel dengan versi native, dengan data yang persisten di browser.

#### File yang diperlukan di `web/`

| File | Ukuran | Fungsi |
|------|--------|--------|
| `sqlite3.wasm` | ~700 KB | SQLite dikompilasi ke WebAssembly |
| `drift_worker.js` | ~370 KB | Worker drift untuk sinkronisasi multi-tab |

File ini sudah ada di repo. Jangan hapus.

#### Cara kerja persistence

Drift mencoba backend berdasarkan kemampuan browser, dalam urutan prioritas:

1. **OPFS (Origin Private File System)** — paling efisien, Firefox dan Chrome modern
2. **IndexedDB** — fallback universal, semua browser modern
3. **In-memory** — hanya jika dua opsi di atas gagal (data tidak persisten)

Secara praktis, hampir semua pengguna Chrome/Firefox mendapatkan OPFS atau IndexedDB sehingga data persisten.

### Perbedaan Perilaku Web

| Komponen | Android/iOS | Web |
|----------|-------------|-----|
| `AppDatabase._openDatabase()` | `driftDatabase()` — SQLite file persisten | `driftDatabase()` dengan `DriftWebOptions` — WASM SQLite persisten |
| `NotificationService.*` | Penuh | Semua metode no-op (`kIsWeb` guard) |
| `main.dart _initBackground()` | Dipanggil post-frame | Dilewati (`if (!kIsWeb)`) |
| `ExportImportService.exportAndShare()` | Share sheet native via `share_plus` | Unduhan browser via `dart:js_interop` + `package:web` |
| `ExportImportService.pickAndParse()` | `file_picker` → path → `File.readAsString()` | `file_picker` → bytes → `utf8.decode()` |
| Pengaturan notifikasi di UI | Toggle aktif + pilih jam/hari | Toggle disabled + pesan "tidak tersedia" |

### Conditional Imports untuk File I/O

`export_import_service.dart` dulu mengimpor `dart:io` secara langsung — ini menyebabkan error kompilasi di web. Sekarang sudah direfaktor:

```
lib/core/services/platform/
├── csv_file_helper.dart   # Router dengan conditional export
├── csv_file_stub.dart     # Stub (fallback jika bukan native maupun web)
├── csv_file_native.dart   # Implementasi dart:io (Android/iOS/desktop)
└── csv_file_web.dart      # Implementasi dart:js_interop (web)
```

`csv_file_helper.dart` menggunakan conditional export:
```dart
export 'csv_file_stub.dart'
    if (dart.library.io) 'csv_file_native.dart'
    if (dart.library.js_interop) 'csv_file_web.dart';
```

Ini memastikan `dart:io` tidak pernah dikompilasi ke build web, dan web interop tidak pernah masuk ke build native.

### Cara Menjalankan di Web

```bash
flutter run -d chrome --no-tree-shake-icons
```

### Build Web

```bash
flutter build web --release --no-tree-shake-icons
```

Output ada di `build/web/`. File `sqlite3.wasm` dan `drift_worker.js` otomatis disertakan dalam output build.

### Batasan Web

- Notifikasi push tidak tersedia (toggle dinonaktifkan dengan pesan informatif)
- `permission_handler` tidak digunakan di web (tidak diimpor, tidak ada masalah)
- Untuk performa database multi-threaded terbaik, server perlu mengirim header COOP/COEP (lihat `DEVELOPMENT_TO_DEPLOY.md §8` untuk detail)

---

## 18. Pengujian

**Direktori:** `test/`

### Struktur

```
test/
├── unit/
│   ├── usecases/
│   │   ├── payday_cycle_test.dart         # 11 tes: batas, pergantian tahun, kabisat
│   │   └── summary_calculation_test.dart  # 9 tes: agregasi, kasus kosong, peta kategori
│   └── utils/
│       ├── date_utils_test.dart           # 14 tes: clampToMonth, helper rentang tanggal
│       └── currency_formatter_test.dart   # 9 tes: format/parsing IDR
├── widget/
│   ├── home_quote_test.dart               # Logika daftar kutipan, wrapping indeks, interval 8 detik
│   ├── transaction_date_test.dart         # Tanggal masa lalu/masa depan dapat disimpan; lastDate = 2100
│   ├── transaction_selection_test.dart    # Long-press → mode pilih; checkbox; hapus massal; batal
│   ├── settings_reminder_test.dart        # UI pengingat di Pengaturan
│   └── splash_navigation_test.dart        # Routing splash ke onboarding/home
└── widget_test.dart                       # Tes widget generik
```

**Total: 91 tes unit dan widget, 0 kegagalan.**

### Menjalankan pengujian

```bash
# Hanya unit test
flutter test test/unit/

# Semua test
flutter test

# Dengan cakupan kode
flutter test --coverage
```

### Catatan Pengujian

- Unit test murni tidak bergantung pada Flutter — dapat dijalankan cepat
- Widget test (`test/widget/`) menggunakan provider override Riverpod dengan fake repository (`_FakeTransactionRepo`) — tidak memerlukan mock library eksternal
- `transaction_selection_test.dart` mensimulasikan long-press untuk masuk mode multi-select, memverifikasi tampilan checkbox, snackbar, dan dialog hapus massal. Test mengatur ukuran viewport ke 600 dp (di bawah breakpoint tablet 720 dp) agar layout mobile dengan `Dismissible` yang dapat long-press dirender — bukan tablet two-column layout
- `transaction_date_test.dart` memverifikasi bahwa tanggal masa depan (contoh: 2028, 2030) dapat disimpan di entitas `Transaction` dan ditampilkan tanpa error di form
- `home_quote_test.dart` memverifikasi bahwa daftar kutipan tidak kosong, `todayIndex` dalam batas, dan logika rotasi 8 detik terdokumentasi
- File `*.g.dart` yang dibuat otomatis sudah di-commit sehingga tidak perlu `build_runner` sebelum menjalankan test

---

## 19. Menambahkan Fitur Baru

### Menambah kategori baru

1. Edit `_seedDefaultCategories()` di `app_database.dart`
2. Tambahkan icon codepoint dari `MaterialIcons` (buka `Icons.star.codePoint` di Flutter untuk mendapatkan nilainya)
3. Naikkan `schemaVersion` jika menambah kategori ke instalasi yang sudah ada (bukan hanya instalasi baru)

### Menambah tipe laporan baru

1. Tambahkan tab baru di `ReportsScreen` (tambah `Tab` di `TabBar` dan `TabBarView`)
2. Buat file `lib/presentation/features/reports/tabs/new_report_tab.dart`
3. Tambahkan provider baru di `lib/presentation/providers/report_provider.dart` yang memanggil `reportSummaryProvider` dengan rentang tanggal yang sesuai

### Menambah kolom ke tabel

1. Tambahkan kolom di file tabel (`categories_table.dart` atau `transactions_table.dart`)
2. Naikkan `schemaVersion` di `app_database.dart`
3. Tambahkan langkah migrasi di `MigrationStrategy.onUpgrade`
4. Jalankan `dart run build_runner build --delete-conflicting-outputs`
5. Perbarui entitas domain, implementasi repository, dan provider yang relevan

### Menambah string UI baru

Selalu tambahkan ke `lib/core/constants/app_strings.dart`. Jangan hardcode string di widget.

### Menambah warna baru

Selalu tambahkan ke `lib/core/constants/app_colors.dart`. Jangan hardcode nilai hex di widget.

---

## 20. Keterbatasan yang Diketahui & Rencana ke Depan

### Keterbatasan Saat Ini

| Keterbatasan | Detail |
|-------------|--------|
| Web: data tidak persisten | Database menggunakan in-memory. Perlu WASM/IndexedDB untuk persistensi penuh. |
| Web: notifikasi tidak ada | `flutter_local_notifications` tidak mendukung web. |
| iOS: perlu macOS | Build iOS tidak dapat dilakukan di Windows. |
| `--no-tree-shake-icons` | Diperlukan karena ikon dimuat dinamis dari database. |
| Notifikasi Android 12+ | `SCHEDULE_EXACT_ALARM` mungkin perlu izin manual. |
| Kategori tidak bisa diedit namanya | Hanya bisa ditambah/dihapus (kategori default tidak bisa dihapus). |

### Peningkatan yang Dapat Dilakukan Selanjutnya

- Persistensi database web via `sqlite3_wasm` atau `drift` web worker
- Mode gelap (tema saat ini hanya mode terang)
- Notifikasi web via Push Notifications API + service worker
- Kategori kustom (tambah/edit/hapus)
- Backup ke Google Drive / iCloud
- Grafik tren (line chart) di laporan
- Widget layar beranda Android
- Impor dari bank statement (format OFX/QIF)
