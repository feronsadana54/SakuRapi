# SakuRapi — Dokumen Serah Terima Kode

> Dokumen ini ditulis untuk developer yang baru bergabung dan belum mengenal proyek ini.
> Tujuannya adalah agar kamu bisa langsung memahami **dari mana eksekusi dimulai**, **ke mana alurnya berlanjut**, dan **siapa yang bertanggung jawab atas apa** — tanpa harus menebak-nebak dari kode.

---

## Daftar Isi

1. [Gambaran Umum](#gambaran-umum)
2. [Arsitektur & Teknologi](#arsitektur--teknologi)
3. [Struktur Folder](#struktur-folder)
4. [Urutan Membaca Kode untuk Developer Baru](#urutan-membaca-kode-untuk-developer-baru)
5. [Alur Startup Aplikasi](#alur-startup-aplikasi)
6. [Alur Onboarding](#alur-onboarding)
7. [Alur Login / Autentikasi](#alur-login--autentikasi)
8. [Alur Sinkronisasi Cloud (Firebase)](#alur-sinkronisasi-cloud-firebase)
9. [Alur Home Screen](#alur-home-screen)
10. [Alur Tambah Transaksi](#alur-tambah-transaksi)
11. [Alur Edit & Hapus Transaksi](#alur-edit--hapus-transaksi)
12. [Alur Kategori Kustom](#alur-kategori-kustom)
13. [Alur Hutang — Tambah, Bayar, Lunas](#alur-hutang)
14. [Alur Piutang — Tambah, Terima Cicilan, Lunas](#alur-piutang)
15. [Kategori Sistem (System Categories)](#kategori-sistem)
16. [Alur Laporan Keuangan](#alur-laporan-keuangan)
17. [Alur Siklus Gajian](#alur-siklus-gajian)
18. [Alur Notifikasi & Pengingat](#alur-notifikasi--pengingat)
19. [Alur Ekspor & Impor CSV](#alur-ekspor--impor-csv)
20. [Skema Database Lengkap](#skema-database-lengkap)
21. [Graf Ketergantungan Provider Riverpod](#graf-ketergantungan-provider-riverpod)
22. [Navigasi GoRouter](#navigasi-gorouter)
23. [Cara Menambah Fitur Baru](#cara-menambah-fitur-baru)
24. [Mengaktifkan Firebase (Google Sign-In)](#mengaktifkan-firebase)

---

## Gambaran Umum

**SakuRapi** adalah aplikasi pencatat keuangan pribadi untuk Android dan iOS.
Dibuat dengan Flutter, bekerja sepenuhnya **offline-first** menggunakan SQLite lokal via Drift ORM.

**Hutang dan Piutang sepenuhnya terintegrasi dengan keuangan** — setiap aksi hutang/piutang
secara otomatis membuat transaksi pemasukan atau pengeluaran, sehingga saldo dan laporan
selalu mencerminkan kondisi keuangan nyata.

Fitur utama:
- Catat pemasukan dan pengeluaran dengan kategori kustom
- **Hutang**: kamu meminjam uang dari orang/bank — setiap pembayaran otomatis kurangi saldo
- **Piutang**: kamu meminjamkan uang ke orang lain — membuat piutang otomatis kurangi saldo; menerima cicilan otomatis tambah saldo
- Laporan harian, bulanan, tahunan, rentang tanggal, dan siklus gajian (termasuk efek hutang/piutang)
- Mode Tamu (data lokal saja) + Login Google (Firebase Auth + sinkronisasi Firestore)
- Pengingat harian via notifikasi (jam dan hari yang bisa dikonfigurasi)
- Ekspor/impor data CSV
- UI modern Material 3 dalam Bahasa Indonesia

---

## Arsitektur & Teknologi

### Clean Architecture — 3 Layer

```
Presentation Layer  →  Widget, Screen, Provider (Riverpod), Router (GoRouter)
Domain Layer        →  Entity, Repository Interface, Enum
Data Layer          →  Repository Implementation, DAO, Database (Drift/SQLite)
```

Aturan ketergantungan: Presentation bergantung ke Domain, Data mengimplementasikan Domain.
**Domain tidak bergantung ke Presentation maupun Data.**

### Stack Teknologi

| Komponen | Library | Versi |
|---|---|---|
| UI Framework | Flutter | 3.22.0+ |
| State Management | flutter_riverpod | 2.x |
| Navigasi | go_router | 14.x |
| Database lokal | drift (SQLite) | 2.x |
| Auth lokal | shared_preferences | 2.x |
| Auth cloud | firebase_auth + google_sign_in | 5.x / 6.x |
| Cloud sync | cloud_firestore | 5.x |
| Notifikasi | flutter_local_notifications | 17.x |
| Ekspor/impor | csv + file_picker | — |

### State Management: Riverpod

| Tipe Provider | Kegunaan |
|---|---|
| `StreamProvider` | Data reaktif dari DB (transaksi, hutang, piutang) |
| `FutureProvider` | Data yang dimuat sekali (laporan per rentang tanggal) |
| `StateNotifierProvider` | Aksi dengan state (auth, hutang CRUD, piutang CRUD) |
| `StateProvider` | State UI sederhana (tanggal terpilih, tab aktif) |
| `Provider` | Services, repositories, agregasi data |

---

## Struktur Folder

```
lib/
├── main.dart                    ← TITIK MASUK aplikasi
├── app.dart                     ← Widget root, MaterialApp.router
├── firebase_options.dart        ← Konfigurasi Firebase (kFirebaseConfigured flag)
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart      ← Semua warna (jangan hardcode warna di widget)
│   │   ├── app_strings.dart     ← Semua teks UI Bahasa Indonesia
│   │   ├── app_icons.dart       ← Konstanta ikon
│   │   ├── finance_quotes.dart  ← Daftar kutipan motivasi keuangan
│   │   └── system_categories.dart ← Kategori sistem dengan ID tetap
│   ├── responsive/
│   │   ├── breakpoints.dart     ← Breakpoint mobile (<720dp) vs tablet
│   │   ├── app_spacing.dart     ← Padding/gap responsif
│   │   ├── app_type_scale.dart  ← Ukuran font responsif
│   │   └── responsive_container.dart
│   ├── services/
│   │   ├── auth_service.dart    ← Login tamu/Google, baca/tulis sesi ke SharedPrefs
│   │   ├── sync_service.dart    ← Sinkronisasi Firestore (hanya aktif jika Firebase dikonfigurasi)
│   │   ├── notification_service.dart ← Jadwal/batalkan notifikasi harian
│   │   └── export_import_service.dart ← Ekspor/impor CSV
│   ├── theme/
│   │   └── app_theme.dart       ← Konfigurasi tema Material 3
│   ├── utils/
│   │   ├── currency_formatter.dart ← Format Rupiah (Rp 1.500.000)
│   │   └── date_utils.dart      ← Format tanggal, hitung siklus gajian
│   └── widgets/                 ← Widget umum yang dipakai di banyak layar
│
├── data/
│   ├── database/
│   │   ├── app_database.dart    ← Kelas database Drift (daftar tabel + DAO)
│   │   ├── app_database.g.dart  ← GENERATED — jangan edit manual
│   │   ├── tables/              ← Definisi tabel Drift
│   │   │   ├── transaction_table.dart
│   │   │   ├── category_table.dart
│   │   │   ├── hutang_table.dart
│   │   │   ├── piutang_table.dart
│   │   │   └── payment_history_table.dart
│   │   └── daos/                ← Data Access Objects (query SQL via Drift)
│   │       ├── transaction_dao.dart
│   │       ├── category_dao.dart
│   │       ├── hutang_dao.dart
│   │       └── piutang_dao.dart
│   └── repositories/            ← Implementasi konkret repository interface
│       ├── transaction_repository_impl.dart
│       ├── category_repository_impl.dart
│       ├── hutang_repository_impl.dart
│       └── piutang_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── transaction_entity.dart  ← Transaction, Category
│   │   ├── hutang_entity.dart       ← HutangEntity, PaymentRecord
│   │   ├── piutang_entity.dart      ← PiutangEntity
│   │   └── user_entity.dart         ← UserEntity
│   ├── enums/
│   │   ├── transaction_type.dart    ← income | expense
│   │   ├── category_type.dart       ← income | expense | both
│   │   └── auth_mode.dart           ← guest | google
│   └── repositories/               ← Interface/kontrak repository
│       ├── i_transaction_repository.dart
│       ├── i_category_repository.dart
│       ├── i_hutang_repository.dart
│       └── i_piutang_repository.dart
│
├── presentation/
│   ├── features/
│   │   ├── auth/                ← LoginScreen
│   │   ├── home/                ← HomeScreen
│   │   ├── hutang/              ← HutangListScreen, HutangFormScreen, HutangDetailScreen
│   │   ├── onboarding/          ← OnboardingScreen (4 halaman)
│   │   ├── piutang/             ← PiutangListScreen, PiutangFormScreen, PiutangDetailScreen
│   │   ├── reports/             ← ReportsScreen + tab laporan
│   │   ├── settings/            ← SettingsScreen
│   │   ├── shell/               ← AppShell (bottom nav / navigation rail)
│   │   ├── splash/              ← SplashScreen (navigasi awal)
│   │   └── transactions/        ← TransactionListScreen, TransactionFormScreen
│   ├── providers/               ← Semua Riverpod provider
│   │   ├── database_provider.dart    ← Root provider: DB, repos, services
│   │   ├── auth_provider.dart        ← AuthNotifier (currentUserProvider)
│   │   ├── transaction_provider.dart ← TransactionNotifier, streams
│   │   ├── category_provider.dart    ← CategoryNotifier, streams
│   │   ├── hutang_provider.dart      ← HutangNotifier, streams
│   │   ├── piutang_provider.dart     ← PiutangNotifier, streams
│   │   ├── report_provider.dart      ← Kalkulasi laporan keuangan
│   │   └── settings_provider.dart   ← Pengaturan: payday, notifikasi
│   └── widgets/                 ← Widget yang dipakai di banyak fitur
│
└── router/
    └── app_router.dart          ← Semua rute GoRouter
```

---

## Urutan Membaca Kode untuk Developer Baru

Mulai dari sini, baca berurutan:

1. **`lib/main.dart`** — Titik masuk, cara inisialisasi Firebase, kapan notifikasi dijadwalkan
2. **`lib/firebase_options.dart`** — Pahami flag `kFirebaseConfigured` yang mengontrol Firebase
3. **`lib/app.dart`** — Widget root, bagaimana MaterialApp dirakit
4. **`lib/router/app_router.dart`** — Semua rute, mana yang pakai shell, mana yang standalone
5. **`lib/presentation/features/splash/splash_screen.dart`** — Logika keputusan navigasi awal
6. **`lib/presentation/providers/database_provider.dart`** — Graf ketergantungan semua provider
7. **`lib/data/database/app_database.dart`** — Struktur database, migrasi, seed data
8. **`lib/presentation/providers/transaction_provider.dart`** — Cara data transaksi mengalir ke UI
9. **`lib/presentation/features/home/home_screen.dart`** — Layar pertama setelah login
10. **`lib/presentation/features/transactions/transaction_form_screen.dart`** — Alur form → save → DB (termasuk integrasi Pembayaran Hutang)
11. **`lib/presentation/providers/hutang_provider.dart`** — Alur dengan integrasi dua domain (hutang + transaksi)
12. **`lib/presentation/providers/piutang_provider.dart`** — Alur piutang + auto-create transaksi

---

## Alur Startup Aplikasi

**File pertama yang dieksekusi: `lib/main.dart`**

```
Dart runtime memanggil main()
  │
  ├─ WidgetsFlutterBinding.ensureInitialized()
  │
  ├─ SharedPreferences.getInstance()   ← AWAIT (diperlukan sebelum runApp)
  │
  ├─ if (kFirebaseConfigured)           ← CEK FLAG di firebase_options.dart
  │   └─ Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
  │       .timeout(Duration(seconds: 10))
  │       └─ catch: abaikan, app tetap berjalan dalam mode lokal
  │
  ├─ runApp(ProviderScope(overrides: [sharedPreferencesProvider], child: App()))
  │   └─ App()  →  MaterialApp.router  →  GoRouter (initialLocation: /splash)
  │               └─ SplashScreen ditampilkan
  │
  └─ addPostFrameCallback(_initBackground)
      └─ Setelah frame pertama:
          ├─ initializeTimeZones() + setLocalLocation('Asia/Jakarta')
          ├─ Cek apakah notifikasi diaktifkan di settings
          └─ scheduleReminders(hour, minute, weekdays)
```

### Flag `kFirebaseConfigured`

File `lib/firebase_options.dart` berisi:
```dart
const bool kFirebaseConfigured = false;
```

Jika `false`: Firebase **tidak pernah diinisialisasi** — aplikasi berjalan penuh dalam mode lokal.
Jika `true`: Firebase diinisialisasi; Google Sign-In aktif; sinkronisasi Firestore aktif.

Untuk mengaktifkan Firebase, jalankan `flutterfire configure` dan set flag ke `true`.
Lihat [Mengaktifkan Firebase](#mengaktifkan-firebase) untuk detail.

---

## Alur Onboarding

**Masuk ke alur ini dari:** `SplashScreen._navigate()` ketika `isOnboardingComplete == false`

```
/onboarding → OnboardingScreen
  │
  ├─ Halaman 1: Selamat datang (informasi saja)
  ├─ Halaman 2: Fitur transaksi + hutang/piutang
  ├─ Halaman 3: Laporan + permintaan izin notifikasi
  │   └─ permission_handler.Permission.notification.request()
  │
  └─ Halaman 4: Input tanggal gajian + tombol "Mulai"
      └─ _finish()
          ├─ Validasi input (1–31)
          ├─ settingsRepository.setPaydayDate(parsed)
          ├─ settingsRepository.setOnboardingComplete(true)
          └─ context.go('/login')
```

---

## Alur Login / Autentikasi

**Masuk ke alur ini dari:** `SplashScreen._navigate()` ketika onboarding selesai tapi `getCurrentUser() == null`

```
/login → LoginScreen
  │
  ├─ Tombol "Masuk sebagai Tamu"
  │   └─ AuthNotifier.signInAsGuest()
  │       └─ AuthService.signInAsGuest()
  │           ├─ Buat UUID baru (atau pakai yang sudah ada)
  │           ├─ Simpan ke SharedPreferences: saku_auth_id, saku_auth_name, saku_auth_mode='guest'
  │           └─ Return UserEntity(id, 'Tamu', AuthMode.guest)
  │       └─ context.go('/home')
  │
  └─ Tombol "Masuk dengan Google"
      ├─ Jika !kFirebaseConfigured → SnackBar informatif, tidak ada perubahan state
      └─ Jika kFirebaseConfigured:
          └─ AuthNotifier.signInWithGoogle()
              └─ AuthService.signInWithGoogle()
                  ├─ GoogleSignIn().signIn()          ← Google OAuth popup
                  ├─ GoogleSignInAccount → GoogleSignInAuthentication
                  ├─ GoogleAuthProvider.credential(idToken, accessToken)
                  ├─ FirebaseAuth.instance.signInWithCredential(credential)
                  ├─ Simpan ke SharedPreferences: userId=uid, name=displayName, mode='google'
                  └─ Return UserEntity(uid, displayName, AuthMode.google)
              └─ SyncService.fetchAll() — unduh data dari Firestore ke lokal
              └─ context.go('/home')
```

### Kapan Sesi Aktif

`SplashScreen` membaca `AuthService.getCurrentUser()` dari SharedPreferences.
Jika ada sesi tersimpan, navigasi langsung ke `/home` tanpa harus login ulang.

---

## Alur Sinkronisasi Cloud (Firebase)

Sinkronisasi **hanya aktif** jika `kFirebaseConfigured == true` DAN user login dengan Google.

```
SyncService
  │
  ├─ isAvailable: kFirebaseConfigured && _userId != null
  │
  ├─ Setiap kali data berubah di lokal:
  │   └─ Repository calls → SyncService.upsertXxx(entity)
  │       └─ Firestore: users/{userId}/transactions|hutang|piutang/{id}
  │
  ├─ Saat login Google berhasil:
  │   └─ SyncService.fetchAll()
  │       ├─ fetchAllTransactions() → upsert ke DB lokal
  │       ├─ fetchAllHutang() → upsert ke DB lokal
  │       └─ fetchAllPiutang() → upsert ke DB lokal
  │
  └─ Semua operasi dibungkus try/catch
      └─ Sync gagal → tidak crash app, hanya log error
```

**Aturan Firestore:**
```
users/{userId}/transactions/{id}
users/{userId}/hutang/{id}
users/{userId}/piutang/{id}
```

---

## Alur Home Screen

```
HomeScreen
  │
  └─ ref.watch(homeSummaryProvider)
      └─ homeSummaryProvider
          └─ ref.watch(allTransactionsProvider)  (StreamProvider)
              └─ TransactionDao.watchAll() → Drift SELECT reaktif
                  └─ Stream<List<Transaction>>
                      (memancar ulang setiap tabel 'transactions' berubah)
          └─ whenData → hitung HomeSummary:
              totalIncome, totalExpense, totalBalance
              todayIncome, todayExpense
              recentTransactions (7 terakhir)
  │
  ├─ _BalanceCard      ← totalBalance, totalIncome, totalExpense
  ├─ _TodaySummaryRow  ← todayIncome, todayExpense
  ├─ _QuoteCarousel    ← kutipan hari ini dari FinanceQuotes, rotasi 8 detik
  └─ _RecentList       ← 7 transaksi terbaru
      └─ tap tile → context.push('/transactions/edit', extra: tx)
```

---

## Alur Tambah Transaksi

**Titik masuk:** FAB di HomeScreen atau tombol + di TransactionListScreen

```
context.push('/transactions/add')
  └─ TransactionFormScreen(editTransaction: null)
      │
      ├─ initState: type=expense, date=hari ini, category=null
      │
      ├─ ref.watch(categoriesForTypeProvider(type))
      │   └─ CategoryDao.watchAll() → filter by type → tampilkan CategoryGridPicker
      │
      ├─ Jika user pilih kategori "Pembayaran Hutang" (sys-pembayaran-hutang-v1):
      │   └─ _isPembayaranHutang = true
      │       └─ _HutangPicker ditampilkan di bawah CategoryGridPicker
      │           └─ ref.watch(activeHutangProvider)  ← hutang yang belum lunas
      │           └─ user pilih hutang dari dropdown → _selectedHutang di-set
      │           └─ validator amount: amount <= _selectedHutang.sisaHutang
      │
      └─ Ketuk "Simpan" → _save()
          ├─ Validasi form (amount > 0, kategori dipilih)
          ├─ Jika _isPembayaranHutang && _selectedHutang != null:
          │   ├─ Validasi _validateHutangSelection() (amount <= sisaHutang)
          │   ├─ transactionNotifier.add(Transaction(expense, amount, ...))
          │   │   └─ TransactionDao.insert() ← tulis ke DB lokal
          │   │   └─ SyncService.upsertTransaction() ← jika Firebase aktif
          │   └─ hutangNotifier.updateAfterPayment(hutangId, amount)
          │       └─ HutangDao.update() — kurangi sisaHutang, tambah riwayat
          │       └─ SyncService.upsertHutang() ← jika Firebase aktif
          │       └─ TIDAK membuat transaksi baru (sudah dibuat di atas)
          │
          └─ Jika kategori normal:
              └─ transactionNotifier.add(tx)
              └─ context.pop()
```

**PENTING — Mencegah Duplikasi Transaksi Hutang:**
Ada dua cara membayar hutang:
1. Dari `HutangDetailScreen.addPayment()` → membuat transaksi expense + update hutang
2. Dari `TransactionFormScreen._save()` → membuat transaksi expense (form), lalu `updateAfterPayment()` yang **hanya update hutang tanpa buat transaksi baru**

---

## Alur Edit & Hapus Transaksi

```
context.push('/transactions/edit', extra: tx)
  └─ TransactionFormScreen(editTransaction: tx)
      │
      ├─ initState: prefill semua field dari tx
      │
      ├─ Ketuk "Simpan" → _save()
      │   └─ transactionNotifier.update(tx.copyWith(...))
      │       └─ TransactionDao.update() ← UPDATE di DB
      │
      └─ Ketuk "Hapus" → _confirmDelete() → _delete()
          └─ transactionNotifier.delete(tx.id)
              └─ TransactionDao.deleteById() ← DELETE di DB
              └─ SyncService.deleteTransaction(tx.id) ← jika Firebase aktif
```

---

## Alur Kategori Kustom

```
SettingsScreen → "Kategori" tile → context.push('/settings/categories')
  └─ CategoryListScreen
      │
      ├─ ref.watch(categoriesProvider) → watchAll() → tampilkan semua kategori
      │
      ├─ Tap "+" → CategoryFormScreen (mode tambah)
      │   ├─ Input: nama, pilih ikon, pilih warna, tipe (income/expense/both)
      │   └─ Simpan → categoryNotifier.add(category)
      │               └─ CategoryDao.insert()
      │
      ├─ Tap kategori → CategoryFormScreen (mode edit)
      │   ├─ Prefill dari kategori yang dipilih
      │   └─ Simpan → categoryNotifier.update(category)
      │
      └─ Swipe/hapus → Cek isSystemCategory()
          ├─ Jika iya: tampilkan dialog "Kategori sistem tidak bisa dihapus"
          └─ Jika tidak: categoryNotifier.delete(category.id)
                         └─ CategoryDao.deleteById()
```

---

## Alur Hutang

### Cara 1: Bayar langsung dari HutangDetailScreen

```
HutangDetailScreen → "Bayar Hutang" → _showPaymentBottomSheet()
  └─ Input: jumlah, catatan, tanggal
  └─ Validasi: amount > 0 && amount <= sisaHutang
  └─ hutangNotifier.addPayment(hutangId, amount, catatan)
      └─ HutangRepositoryImpl.addPayment()
          ├─ Buat PaymentRecord baru
          ├─ Hitung newSisa = sisaHutang - amount (clamp ke 0)
          ├─ Hitung newStatus = newSisa <= 0 ? 'lunas' : 'aktif'
          ├─ HutangDao.update() ← update DB
          ├─ Buat Transaction(expense, amount, kategori=PembayaranHutang, catatan)
          │   └─ TransactionDao.insert() ← tulis expense ke DB
          └─ SyncService.upsertHutang() + SyncService.upsertTransaction()
```

### Cara 2: Bayar lewat Form Transaksi

```
TransactionFormScreen → pilih kategori "Pembayaran Hutang"
  └─ _HutangPicker muncul → pilih hutang aktif dari dropdown
  └─ Isi jumlah (divalidasi ≤ sisaHutang)
  └─ Ketuk Simpan → _save()
      ├─ transactionNotifier.add(Transaction(expense, ...))  ← buat expense dulu
      └─ hutangNotifier.updateAfterPayment(hutangId, amount)
          └─ Update sisaHutang + status + riwayat di DB
          └─ TIDAK membuat transaksi (sudah dibuat di atas)
```

### Tambah Hutang Baru

```
HutangListScreen → "+" → HutangFormScreen
  └─ Input: nama kreditur, jumlah, tanggal pinjam, jatuh tempo, catatan
  └─ hutangNotifier.add(hutang)
      └─ HutangDao.insert()
      └─ SyncService.upsertHutang()
```

Hutang baru **tidak** membuat transaksi otomatis — hutang hanya dicatat sebagai kewajiban.
Saldo hanya berkurang saat pembayaran dilakukan.

---

## Alur Piutang

### Tambah Piutang Baru

```
PiutangListScreen → "+" → PiutangFormScreen
  └─ Input: nama peminjam, jumlah, tanggal pinjam, jatuh tempo, catatan
  └─ piutangNotifier.addPiutang(piutang)
      ├─ PiutangDao.insert()
      ├─ Buat Transaction(expense, jumlahAwal, kategori=MemberiPinjaman, note='Memberi pinjaman ke: {nama}')
      │   └─ TransactionDao.insert() ← saldo BERKURANG (uang keluar)
      └─ SyncService.upsertPiutang() + SyncService.upsertTransaction()
```

### Terima Cicilan Piutang

```
PiutangDetailScreen → "Terima Cicilan" → _showRepaymentBottomSheet()
  └─ Input: jumlah cicilan, catatan, tanggal
  └─ piutangNotifier.addPayment(piutangId, amount, catatan)
      ├─ Buat PaymentRecord baru
      ├─ Hitung newSisa = sisaPiutang - amount (clamp ke 0)
      ├─ Hitung newStatus = newSisa <= 0 ? 'lunas' : 'aktif'
      ├─ PiutangDao.update()
      ├─ Buat Transaction(income, amount, kategori=PenerimaanPiutang, note='Cicilan piutang dari: {nama}')
      │   └─ TransactionDao.insert() ← saldo BERTAMBAH (uang kembali)
      └─ SyncService.upsertPiutang() + SyncService.upsertTransaction()
```

---

## Kategori Sistem

Tiga kategori sistem dengan ID tetap — tidak bisa dihapus user.

| ID | Nama | Tipe | Dibuat Saat |
|---|---|---|---|
| `sys-pembayaran-hutang-v1` | Pembayaran Hutang | expense | Bayar hutang (TransactionForm atau HutangDetail) |
| `sys-penerimaan-piutang-v1` | Penerimaan Piutang | income | Terima cicilan piutang |
| `sys-memberi-pinjaman-v1` | Memberi Pinjaman | expense | Buat piutang baru |

**Definisi:** `lib/core/constants/system_categories.dart`

```dart
abstract final class SystemCategories {
  static const pembayaranHutang = Category(id: 'sys-pembayaran-hutang-v1', ...);
  static const penerimaanPiutang = Category(id: 'sys-penerimaan-piutang-v1', ...);
  static const memberiPinjaman = Category(id: 'sys-memberi-pinjaman-v1', ...);
  static const List<Category> all = [pembayaranHutang, penerimaanPiutang, memberiPinjaman];

  static bool isSystemCategory(String id) => all.any((c) => c.id == id);
}
```

**Seeding:** `AppDatabase.migration` menjalankan `_insertSystemCategoriesIfMissing()` saat upgrade ke versi 4. Menggunakan `INSERT OR IGNORE` — aman untuk instalasi lama.

---

## Alur Laporan Keuangan

```
ReportsScreen
  │
  ├─ Tab 1: Harian
  │   └─ ref.watch(dailyReportProvider(selectedDate))
  │       └─ filter transaksi where date == selectedDate
  │
  ├─ Tab 2: Bulanan
  │   └─ ref.watch(monthlyReportProvider(selectedMonth))
  │       └─ filter transaksi where month == selectedMonth
  │
  ├─ Tab 3: Tahunan
  │   └─ ref.watch(yearlyReportProvider(selectedYear))
  │
  ├─ Tab 4: Rentang Tanggal
  │   └─ ref.watch(dateRangeReportProvider(startDate, endDate))
  │
  ├─ Tab 5: Siklus Gajian
  │   └─ ref.watch(paydayCycleReportProvider)
  │       └─ AppDateUtils.getPaydayCycle(paydayDate, DateTime.now())
  │           → (cycleStart, cycleEnd)
  │       └─ filter transaksi dalam rentang cycleStart..cycleEnd
  │
  ├─ Tab 6: Laporan Hutang
  │   └─ ref.watch(hutangReportProvider)
  │       └─ hutangListProvider → group by status (aktif/lunas)
  │       └─ tampilkan: total hutang aktif, mendekati jatuh tempo, riwayat
  │
  └─ Tab 7: Laporan Piutang
      └─ ref.watch(piutangReportProvider)
          └─ piutangListProvider → group by status (aktif/lunas)
```

**Penting:** Semua laporan transaksi mencakup transaksi dari kategori sistem (Pembayaran Hutang, Memberi Pinjaman, Penerimaan Piutang) — sehingga laporan benar-benar mencerminkan aliran kas nyata.

---

## Alur Siklus Gajian

Siklus gajian dihitung oleh `AppDateUtils.getPaydayCycle(paydayDate, now)`.

**Logika:**
- Jika `paydayDate = 25` dan hari ini tanggal 20 Maret:
  - Siklus aktif = 25 Feb → 24 Mar
- Jika hari ini tanggal 27 Maret:
  - Siklus aktif = 25 Mar → 24 Apr

**Kasus tepi (akhir bulan):**
- Jika `paydayDate = 31` dan bulan ini hanya 28 hari → pakai hari terakhir bulan tersebut

---

## Alur Notifikasi & Pengingat

```
main.dart (addPostFrameCallback)
  └─ SettingsRepository.getNotificationSettings()
      └─ notifEnabled, hour, minute, weekdays
  └─ Jika notifEnabled:
      └─ NotificationService.scheduleReminders(hour, minute, weekdays)
          └─ flutter_local_notifications
              └─ Untuk setiap hari yang aktif:
                  ├─ AndroidNotificationDetails(channelId, channelName)
                  └─ zonedSchedule(id, title, body, scheduledDate, details)
                      └─ scheduledDate = TZDateTime untuk hari berikutnya yang cocok + jam yang diset
```

**Mengubah Jadwal:**
`SettingsScreen` → ubah jam/hari → `NotificationService.cancelAll()` → `NotificationService.scheduleReminders(newHour, newMinute, newWeekdays)`

**Izin Notifikasi:**
- Android 13+: `POST_NOTIFICATIONS` diminta di halaman 3 Onboarding
- iOS: izin juga diminta di OnboardingScreen via `flutter_local_notifications.requestPermissions()`

---

## Alur Ekspor & Impor CSV

### Ekspor

```
SettingsScreen → "Ekspor Data CSV"
  └─ ExportImportService.exportToCSV()
      ├─ Ambil semua transaksi dari DB
      ├─ Konversi ke List<List<dynamic>> (header + rows)
      ├─ Tulis ke file temp: getTemporaryDirectory()/sakurapi_export_{timestamp}.csv
      └─ Share.shareXFiles([XFile(path)])  ← share sheet Android/iOS
```

### Impor

```
SettingsScreen → "Impor Data CSV"
  └─ ExportImportService.importFromCSV()
      ├─ FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'])
      ├─ Parse CSV: CsvToListConverter().convert(content)
      ├─ Validasi header (kolom sesuai format ekspor)
      ├─ Untuk setiap baris:
      │   ├─ Parse jumlah, tipe, kategori, tanggal, catatan
      │   └─ TransactionDao.insert(tx)
      └─ Tampilkan SnackBar: "Berhasil impor X transaksi"
```

---

## Skema Database Lengkap

**File:** `lib/data/database/app_database.dart`
**Schema Version:** 4

### Tabel `transactions`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | TEXT PK | UUID |
| type | TEXT | 'income' \| 'expense' |
| amount | REAL | Dalam Rupiah |
| category_id | TEXT | FK ke categories.id |
| note | TEXT nullable | Catatan opsional |
| date | INTEGER | Unix timestamp (hari saja, no time) |
| created_at | INTEGER | Unix timestamp |

### Tabel `categories`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | TEXT PK | UUID atau 'sys-*' untuk kategori sistem |
| name | TEXT | Nama kategori |
| icon_code | INTEGER | Material Icons codepoint |
| color_value | INTEGER | ARGB int |
| type | TEXT | 'income' \| 'expense' \| 'both' |
| is_default | INTEGER | 0/1 |

### Tabel `hutang`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | TEXT PK | UUID |
| nama_kreditur | TEXT | Nama pemberi pinjaman |
| jumlah_awal | REAL | Jumlah hutang awal |
| sisa_hutang | REAL | Sisa yang belum dibayar |
| tanggal_pinjam | INTEGER | Unix timestamp |
| jatuh_tempo | INTEGER nullable | Unix timestamp |
| status | TEXT | 'aktif' \| 'lunas' |
| catatan | TEXT nullable | |
| created_at | INTEGER | |
| updated_at | INTEGER | |

### Tabel `piutang`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | TEXT PK | UUID |
| nama_peminjam | TEXT | Nama penerima pinjaman |
| jumlah_awal | REAL | Jumlah piutang awal |
| sisa_piutang | REAL | Sisa yang belum diterima |
| tanggal_pinjam | INTEGER | Unix timestamp |
| jatuh_tempo | INTEGER nullable | Unix timestamp |
| status | TEXT | 'aktif' \| 'lunas' |
| catatan | TEXT nullable | |
| created_at | INTEGER | |
| updated_at | INTEGER | |

### Tabel `payment_history`

Digunakan oleh hutang dan piutang untuk menyimpan riwayat pembayaran.

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | TEXT PK | UUID |
| parent_id | TEXT | FK ke hutang.id atau piutang.id |
| parent_type | TEXT | 'hutang' \| 'piutang' |
| amount | REAL | Jumlah pembayaran |
| paid_at | INTEGER | Unix timestamp |
| catatan | TEXT nullable | |

### Riwayat Migrasi

| Dari Versi | Ke Versi | Perubahan |
|---|---|---|
| (baru) | 1 | Buat tabel transactions, categories, seed kategori default |
| 1 | 2 | Buat tabel hutang + payment_history |
| 2 | 3 | Buat tabel piutang |
| 3 | 4 | INSERT OR IGNORE kategori sistem (pembayaran hutang, penerimaan piutang, memberi pinjaman) |

---

## Graf Ketergantungan Provider Riverpod

```
sharedPreferencesProvider  (diberikan via ProviderScope override)
  │
  ├─ settingsRepositoryProvider
  │   ├─ paydayDateProvider
  │   ├─ notificationSettingsProvider
  │   └─ isOnboardingCompleteProvider
  │
  ├─ authServiceProvider
  │   └─ currentUserProvider (StateNotifierProvider<AuthNotifier>)
  │
  └─ syncServiceProvider
      └─ dipakai oleh hutangNotifierProvider, piutangNotifierProvider, transactionNotifierProvider

appDatabaseProvider  (singleton AppDatabase)
  │
  ├─ transactionDaoProvider → transactionRepositoryProvider
  │   ├─ allTransactionsProvider (StreamProvider)
  │   ├─ transactionNotifierProvider (StateNotifierProvider)
  │   └─ homeSummaryProvider, dailyReportProvider, monthlyReportProvider, ...
  │
  ├─ categoryDaoProvider → categoryRepositoryProvider
  │   ├─ categoriesProvider (StreamProvider)
  │   ├─ categoriesForTypeProvider (family StreamProvider)
  │   └─ categoryNotifierProvider (StateNotifierProvider)
  │
  ├─ hutangDaoProvider → hutangRepositoryProvider
  │   ├─ hutangListProvider (StreamProvider)
  │   ├─ activeHutangProvider (Provider — filter dari hutangListProvider)
  │   └─ hutangNotifierProvider (StateNotifierProvider)
  │
  └─ piutangDaoProvider → piutangRepositoryProvider
      ├─ piutangListProvider (StreamProvider)
      └─ piutangNotifierProvider (StateNotifierProvider)
```

---

## Navigasi GoRouter

**File:** `lib/router/app_router.dart`

### Rute Di Luar Shell (layar penuh)

| Path | Widget | Keterangan |
|---|---|---|
| `/splash` | SplashScreen | Navigasi awal — baca state → redirect |
| `/onboarding` | OnboardingScreen | Hanya ditampilkan sekali |
| `/login` | LoginScreen | Mode tamu atau Google |

### Rute Di Dalam Shell (punya bottom nav)

```
ShellRoute → AppShell (bottom nav: Home, Transaksi, Hutang, Piutang, Laporan)
  ├─ /home → HomeScreen
  ├─ /transactions → TransactionListScreen
  ├─ /hutang → HutangListScreen
  ├─ /piutang → PiutangListScreen
  └─ /reports → ReportsScreen
```

### Rute Modal / Detail (push ke atas shell)

| Path | Widget | Extra |
|---|---|---|
| `/transactions/add` | TransactionFormScreen | — |
| `/transactions/edit` | TransactionFormScreen | Transaction |
| `/hutang/add` | HutangFormScreen | — |
| `/hutang/edit` | HutangFormScreen | HutangEntity |
| `/hutang/detail` | HutangDetailScreen | HutangEntity |
| `/piutang/add` | PiutangFormScreen | — |
| `/piutang/edit` | PiutangFormScreen | PiutangEntity |
| `/piutang/detail` | PiutangDetailScreen | PiutangEntity |
| `/settings` | SettingsScreen | — |
| `/settings/categories` | CategoryListScreen | — |
| `/settings/categories/add` | CategoryFormScreen | — |
| `/settings/categories/edit` | CategoryFormScreen | Category |

---

## Cara Menambah Fitur Baru

### Menambah Tipe Laporan Baru

1. Tambah provider baru di `lib/presentation/providers/report_provider.dart`
2. Tambah tab baru di `lib/presentation/features/reports/reports_screen.dart`
3. Tambah string label di `lib/core/constants/app_strings.dart`

### Menambah Tabel Database Baru

1. Buat file tabel di `lib/data/database/tables/`
2. Daftarkan di `AppDatabase.tables` di `app_database.dart`
3. Naikkan `schemaVersion` dan tambah migrasi
4. Jalankan `dart run build_runner build --delete-conflicting-outputs`
5. Buat DAO di `lib/data/database/daos/`
6. Buat interface di `lib/domain/repositories/`
7. Buat implementasi di `lib/data/repositories/`
8. Daftarkan provider di `lib/presentation/providers/database_provider.dart`

### Menambah Layar Baru

1. Buat file screen di `lib/presentation/features/{fitur}/`
2. Tambah rute di `lib/router/app_router.dart`
3. Jika membutuhkan navigasi dari layar lain, tambah `AppRoutes.{namaRute}` di konstanta rute
4. Jika masuk dalam shell (bottom nav), tambah `NavigationDestination` di `AppShell`

### Menambah Kategori Sistem Baru

1. Tambah konstanta di `lib/core/constants/system_categories.dart`
2. Tambah ke list `SystemCategories.all`
3. Naikkan `schemaVersion` di `app_database.dart` dan tambah migrasi yang memanggil `_insertSystemCategoriesIfMissing()`

---

## Mengaktifkan Firebase

Firebase diperlukan untuk **Login Google** dan **sinkronisasi cloud**.
Tanpa Firebase, aplikasi berjalan penuh dalam mode lokal.

### Langkah Aktivasi

```bash
# 1. Buat proyek di https://console.firebase.google.com
#    Aktifkan: Authentication (provider: Google), Firestore Database

# 2. Pasang FlutterFire CLI
dart pub global activate flutterfire_cli

# 3. Konfigurasi (ikuti instruksi interaktif)
flutterfire configure
# Menghasilkan: lib/firebase_options.dart, android/app/google-services.json,
#               ios/Runner/GoogleService-Info.plist

# 4. Aktifkan flag di lib/firebase_options.dart:
#    const bool kFirebaseConfigured = false;
#    →
#    const bool kFirebaseConfigured = true;

# 5. Jalankan ulang
flutter run
```

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Apa yang Berubah Saat Firebase Aktif

- `main.dart`: `Firebase.initializeApp()` dipanggil saat startup
- `LoginScreen`: tombol Google Sign-In aktif (tidak disabled)
- `AuthService.signInWithGoogle()`: melakukan OAuth nyata
- `SyncService.isAvailable`: returns `true` untuk user Google
- Setiap insert/update/delete di repository memanggil SyncService
- Saat login Google → `SyncService.fetchAll()` mengunduh data dari Firestore

---

---

## Peta Panggilan: Provider → Service → Repository → Database

Bagian ini menjawab pertanyaan: **"File mana memanggil siapa?"**

### Inisialisasi (main.dart → app.dart)

```
main.dart
  └─ SharedPreferences.getInstance()              ← await sebelum runApp
  └─ Firebase.initializeApp()                     ← jika kFirebaseConfigured
  └─ runApp(ProviderScope(overrides: [sharedPreferencesProvider]))
      └─ App() → MaterialApp.router → routerProvider → GoRouter
          └─ /splash → SplashScreen
              └─ ref.read(settingsRepositoryProvider)   ← database_provider.dart
              └─ ref.read(authServiceProvider)           ← auth_provider.dart
```

### Alur Baca Data Transaksi (HomeScreen)

```
HomeScreen
  └─ ref.watch(homeSummaryProvider)               ← transaction_provider.dart
      └─ ref.watch(allTransactionsProvider)        ← StreamProvider
          └─ ref.watch(transactionRepositoryProvider)  ← database_provider.dart
              └─ TransactionRepositoryImpl         ← transaction_repository_impl.dart
                  └─ TransactionDao.watchAll()     ← transaction_dao.dart (Drift)
                      └─ AppDatabase (SQLite)      ← app_database.dart
```

### Alur Tulis Transaksi (TransactionFormScreen._save)

```
TransactionFormScreen._save()
  └─ ref.read(transactionRepositoryProvider)
      └─ ITransactionRepository.insert(tx)        ← domain interface
          └─ TransactionRepositoryImpl.insert(tx) ← data layer
              └─ TransactionDao.insert(tx)         ← Drift DAO
                  └─ AppDatabase INSERT INTO transactions
  └─ [jika Pembayaran Hutang]
      └─ ref.read(hutangNotifierProvider.notifier).updateAfterPayment()
          └─ IHutangRepository.getById() + update()
              └─ HutangDao.getById() + update()
```

### Alur Baca/Tulis Hutang (HutangNotifier.addPayment)

```
HutangDetailScreen → "Bayar Hutang"
  └─ ref.read(hutangNotifierProvider.notifier).addPayment()
      └─ IHutangRepository.addPayment()           ← i_hutang_repository.dart
          └─ HutangRepositoryImpl.addPayment()    ← hutang_repository_impl.dart
              └─ HutangDao.addPayment()           ← hutang_dao.dart
                  └─ INSERT INTO payment_history
                  └─ UPDATE hutang SET sisa_hutang=...
      └─ ITransactionRepository.insert(Transaction expense)
          └─ TransactionDao.insert()
              └─ INSERT INTO transactions
```

### Alur Baca/Tulis Piutang (PiutangNotifier.addPiutang)

```
PiutangFormScreen → Simpan
  └─ ref.read(piutangNotifierProvider.notifier).addPiutang()
      └─ IPiutangRepository.insert(piutang)
          └─ PiutangRepositoryImpl.insert()
              └─ PiutangDao.insert()
                  └─ INSERT INTO piutang
      └─ ITransactionRepository.insert(Transaction expense "Memberi Pinjaman")
          └─ TransactionDao.insert()
              └─ INSERT INTO transactions
```

### Alur Sinkronisasi Cloud (SyncService)

```
Setiap operasi tulis repository (contoh: TransactionRepositoryImpl.insert)
  └─ ref.read(syncServiceProvider).upsertTransaction(tx)
      └─ SyncService.isAvailable?   ← kFirebaseConfigured && _userId != null
          ├─ false → return (no-op, mode tamu atau Firebase belum aktif)
          └─ true → FirebaseFirestore
                    .collection('users').doc(_userId)
                    .collection('transactions').doc(tx.id)
                    .set({...data, 'updatedAt': FieldValue.serverTimestamp()})
```

### Alur Laporan (ReportsScreen → reportSummaryProvider)

```
ReportsScreen (Tab Bulanan)
  └─ ref.watch(monthlyReportProvider)             ← report_provider.dart
      └─ ref.watch(reportSummaryProvider((start, end)))  ← FutureProvider.family
          └─ ref.watch(transactionRepositoryProvider)
              └─ ITransactionRepository.getByDateRange(start, end)
                  └─ TransactionDao.getByDateRange()
                      └─ SELECT * FROM transactions WHERE date BETWEEN start AND end
          └─ SummaryResult.fromTransactions(txs)  ← hitung income/expense/balance
```

### Alur Notifikasi (NotificationService)

```
main._initBackground()  (dipanggil setelah frame pertama)
  └─ SettingsRepositoryImpl(prefs).getReminderHour/Minute/Days()
      └─ SharedPreferences.getInt/getStringList()
  └─ NotificationService.scheduleReminders(hour, minute, weekdays)
      └─ FlutterLocalNotificationsPlugin.initialize()
      └─ Untuk setiap hari aktif (1-7):
          └─ _plugin.zonedSchedule(
               id: dayOfWeek,
               title: 'SakuRapi',
               body: 'Jangan lupa catat keuanganmu hari ini!',
               scheduledDate: TZDateTime(...)  ← hari berikutnya + jam yang diset
             )

Saat user ubah pengaturan di SettingsScreen:
  └─ ref.read(notificationServiceProvider).cancelAll()
  └─ ref.read(notificationServiceProvider).scheduleReminders(newHour, ...)
```

---

## Kapan State Berubah

Tabel ini menjelaskan kapan setiap tipe provider memancar ulang / memperbarui state.

### StreamProvider (reaktif otomatis)

| Provider | Berubah Saat | Efek ke UI |
|---|---|---|
| `allTransactionsProvider` | Setiap INSERT/UPDATE/DELETE di tabel `transactions` | HomeScreen rebuild, TransactionListScreen rebuild |
| `hutangListProvider` | Setiap INSERT/UPDATE/DELETE di tabel `hutang` | HutangListScreen rebuild, HutangDetailScreen rebuild |
| `piutangListProvider` | Setiap INSERT/UPDATE/DELETE di tabel `piutang` | PiutangListScreen rebuild, PiutangDetailScreen rebuild |

Stream Drift otomatis mendeteksi perubahan menggunakan SQLite UPDATE hooks — tidak perlu `invalidate()` manual.

### FutureProvider (refresh saat parameter berubah)

| Provider | Berubah Saat | Efek ke UI |
|---|---|---|
| `reportSummaryProvider((start, end))` | `start` atau `end` berubah (tab ganti, tanggal dipilih) | ReportsScreen rebuild |
| `dailyReportProvider` | `selectedDayProvider` berubah | Tab Harian rebuild |
| `monthlyReportProvider` | `selectedMonthProvider` berubah | Tab Bulanan rebuild |

FutureProvider.family cache hasil per key. Saat key berubah, query baru dijalankan.
**Catatan:** FutureProvider laporan TIDAK reaktif terhadap perubahan transaksi — user perlu keluar-masuk tab atau navigasi ulang untuk melihat data terbaru.

### StateNotifierProvider (state eksplisit)

| Provider | State | Berubah Saat |
|---|---|---|
| `transactionNotifierProvider` | `AsyncValue<void>` | Saat `add/update/delete` dipanggil — `loading` → `data` atau `error` |
| `hutangNotifierProvider` | `AsyncValue<void>` | Saat `addHutang/updateHutang/addPayment/updateAfterPayment` dipanggil |
| `piutangNotifierProvider` | `AsyncValue<void>` | Saat `addPiutang/addPayment/markAsLunas` dipanggil |
| `currentUserProvider` | `UserEntity?` | Saat `signInAsGuest/signInWithGoogle/signOut` dipanggil |

### StateProvider (state UI)

| Provider | Berubah Saat | Efek |
|---|---|---|
| `selectedDayProvider` | User tap tanggal di tab Harian | `dailyReportProvider` recompute |
| `selectedMonthProvider` | User tap bulan di tab Bulanan | `monthlyReportProvider` recompute |
| `selectedYearProvider` | User tap tahun di tab Tahunan | `yearlyReportProvider` recompute |
| `selectedRangeProvider` | User pilih rentang tanggal | `rangeReportProvider` recompute |

---

## Kapan Data Dibaca dan Disimpan

### Data Dibaca (READ)

| Kapan | Siapa Membaca | Dari Mana |
|---|---|---|
| App buka (SplashScreen) | `settingsRepositoryProvider` → `isOnboardingComplete()` | SharedPreferences |
| App buka (SplashScreen) | `authServiceProvider` → `getCurrentUser()` | SharedPreferences |
| HomeScreen mount | `allTransactionsProvider` watch | SQLite stream (Drift) |
| TransactionFormScreen mount (edit) | Data dari `extra` di GoRouter state | Memory (dari list screen) |
| TransactionFormScreen (pembayaran hutang) | `activeHutangProvider` watch | SQLite stream (Drift) |
| ReportsScreen tab aktif | `reportSummaryProvider(range)` | SQLite query satu kali |
| HutangDetailScreen mount | Data dari `extra` di GoRouter state | Memory (dari list screen) |
| SettingsScreen mount | `settingsRepositoryProvider` → getPaydayDate, getReminderHour, dll. | SharedPreferences |

### Data Disimpan (WRITE)

| Kapan | Siapa Menulis | Ke Mana |
|---|---|---|
| TransactionFormScreen._save() | `ITransactionRepository.insert/update` | SQLite tabel `transactions` |
| TransactionFormScreen._save() (edit) | `ITransactionRepository.update` | SQLite tabel `transactions` |
| TransactionFormScreen._delete() | `ITransactionRepository.delete` | SQLite tabel `transactions` |
| HutangFormScreen simpan | `IHutangRepository.insert/update` | SQLite tabel `hutang` |
| HutangDetailScreen bayar | `IHutangRepository.addPayment` + `ITransactionRepository.insert` | SQLite tabel `hutang` + `payment_history` + `transactions` |
| PiutangFormScreen simpan | `IPiutangRepository.insert` + `ITransactionRepository.insert` | SQLite tabel `piutang` + `transactions` |
| PiutangDetailScreen terima cicilan | `IPiutangRepository.addPayment` + `ITransactionRepository.insert` | SQLite tabel `piutang` + `payment_history` + `transactions` |
| OnboardingScreen halaman 4 | `settingsRepositoryProvider.setPaydayDate/setOnboardingComplete` | SharedPreferences |
| LoginScreen (tamu) | `AuthService.signInAsGuest()` | SharedPreferences (`saku_auth_*`) |
| LoginScreen (Google) | `AuthService.signInWithGoogle()` | SharedPreferences + Firebase Auth |
| Setiap tulis ke SQLite (jika Firebase aktif) | `SyncService.upsertXxx/deleteXxx` | Firestore Cloud |
| SettingsScreen ubah pengingat | `settingsRepositoryProvider.setReminderHour/Minute/Days` | SharedPreferences |
| SettingsScreen ekspor CSV | `ExportImportService.exportToCSV()` | File temp perangkat |
| SettingsScreen impor CSV | `ExportImportService.importFromCSV()` | SQLite tabel `transactions` |

---

## Bagaimana Provider Terhubung ke Layar (Ringkasan Visual)

```
SharedPreferences (override di ProviderScope)
  │
  ├─ settingsRepositoryProvider ──► SplashScreen, OnboardingScreen, SettingsScreen
  ├─ authServiceProvider ──────────► SplashScreen, LoginScreen
  └─ syncServiceProvider ──────────► (dipakai repository impl, bukan UI)

AppDatabase (singleton Drift)
  │
  ├─ transactionDaoProvider
  │   └─ transactionRepositoryProvider
  │       ├─ allTransactionsProvider ──────────► HomeScreen, TransactionListScreen
  │       ├─ transactionNotifierProvider ──────► TransactionFormScreen
  │       └─ reportSummaryProvider ────────────► ReportsScreen
  │
  ├─ categoryDaoProvider
  │   └─ categoryRepositoryProvider
  │       ├─ categoriesProvider ───────────────► CategoryListScreen
  │       ├─ categoriesForTypeProvider ────────► TransactionFormScreen
  │       └─ categoryNotifierProvider ─────────► CategoryFormScreen
  │
  ├─ hutangDaoProvider
  │   └─ hutangRepositoryProvider
  │       ├─ hutangListProvider ───────────────► HutangListScreen
  │       ├─ hutangSummaryProvider ────────────► HutangListScreen (ringkasan atas)
  │       ├─ activeHutangProvider ─────────────► TransactionFormScreen (dropdown hutang)
  │       └─ hutangNotifierProvider ───────────► HutangFormScreen, HutangDetailScreen
  │
  └─ piutangDaoProvider
      └─ piutangRepositoryProvider
          ├─ piutangListProvider ──────────────► PiutangListScreen
          ├─ piutangSummaryProvider ───────────► PiutangListScreen (ringkasan atas)
          └─ piutangNotifierProvider ──────────► PiutangFormScreen, PiutangDetailScreen
```

---

*Dokumen ini terakhir diperbarui: 17 April 2026*
