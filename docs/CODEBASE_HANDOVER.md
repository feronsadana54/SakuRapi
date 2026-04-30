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
24. [Firebase & Google Sign-In](#mengaktifkan-firebase)

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
- Mode Tamu (data lokal saja) + Login Google + Login Email Link (Firebase Auth + sinkronisasi Firestore realtime)
- **Multi-device sync**: data berubah di perangkat A → otomatis muncul di perangkat B via Firestore realtime listeners
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
| Auth cloud | firebase_auth + google_sign_in + app_links | 5.x / 6.x |
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
├── firebase_options.dart        ← Konfigurasi Firebase (gitignored — salin dari firebase_options.example.dart)
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
│   │   ├── auth_service.dart           ← Login tamu/Google/EmailLink, baca/tulis sesi ke SharedPrefs
│   │   ├── sync_service.dart           ← Write-to-Firestore (aktif untuk Google & EmailLink)
│   │   ├── cloud_restore_service.dart  ← Restore data dari Firestore ke SQLite saat login
│   │   ├── realtime_sync_service.dart  ← Firestore realtime listeners untuk sinkronisasi multi-perangkat
│   │   ├── notification_service.dart   ← Jadwal/batalkan notifikasi harian
│   │   └── export_import_service.dart  ← Ekspor/impor CSV
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
│   │   └── auth_mode.dart           ← guest | google | emailLink
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

1. **`lib/main.dart`** — Titik masuk, inisialisasi Firebase, kapan notifikasi dijadwalkan
2. **`lib/firebase_options.dart`** — Konfigurasi Firebase (gitignored; buat dari `firebase_options.example.dart` atau `flutterfire configure`)
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
  ├─ Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
  │       .timeout(Duration(seconds: 10))
  │       └─ catch: abaikan, app tetap berjalan dalam mode lokal/tamu
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

### Firebase Initialization

Firebase selalu diinisialisasi saat startup via `Firebase.initializeApp()`.
Jika inisialisasi gagal (offline, dll.), app tetap berjalan dalam mode lokal/tamu.
Google Sign-In akan gagal dengan pesan error yang jelas jika Firebase tidak tersedia.

Konfigurasi Firebase ada di `lib/firebase_options.dart` (gitignored — setiap developer menyiapkan sendiri).
Lihat [Firebase & Google Sign-In](#mengaktifkan-firebase) untuk detail setup.

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

Seluruh autentikasi dikelola oleh `AuthService` (business logic) dan `AuthNotifier`
(state management Riverpod). UI tidak mengakses Firebase/Google SDK secara langsung.

---

### Alur Startup & Pengecekan Auth State

```
App startup → main.dart
  ├─ Firebase.initializeApp()   ← selalu dijalankan, kegagalan ditangani (app tetap berjalan)
  ├─ SharedPreferences.getInstance()
  └─ runApp(ProviderScope) → SplashScreen

SplashScreen._navigate()
  ├─ settingsRepository.isOnboardingComplete()  → false → /onboarding
  └─ authService.getCurrentUser()               → dari SharedPreferences
      ├─ null → /login
      └─ UserEntity(mode=guest|google) → /home
```

`getCurrentUser()` membaca SharedPreferences — cepat, tidak butuh jaringan.
Sesi tetap aktif setelah restart karena tersimpan di SharedPreferences.

---

### Path A — Mode Tamu

```
/login → LoginScreen → Tombol "Masuk sebagai Tamu"
  └─ AuthNotifier.signInAsGuest()
      └─ AuthService.signInAsGuest()
          ├─ Cek apakah saku_auth_id sudah ada (UUID sebelumnya)
          ├─ Jika belum: buat UUID baru via Uuid().v4()
          ├─ Simpan ke SharedPreferences:
          │     saku_auth_id   = UUID
          │     saku_auth_name = 'Tamu'
          │     saku_auth_mode = 'guest'
          └─ Return UserEntity(id=UUID, displayName='Tamu', AuthMode.guest)
  └─ state = AsyncData(user) → GoRouter redirect ke /home

Karakteristik Mode Tamu:
  - Data tersimpan HANYA di SQLite lokal
  - SyncService.isAvailable = false (tidak ada sync ke Firestore)
  - UUID bertahan selama app tidak di-uninstall
  - Bisa upgrade ke Google kapan saja tanpa kehilangan data
```

---

### Path B — Login Google (dari Layar Login)

Alur berbeda per platform. `AuthService.signInWithGoogle()` mendispatch ke
`_signInWithGoogleWeb()` atau `_signInWithGoogleNative()` berdasarkan `kIsWeb`.

**Optimasi UX**: setelah Firebase auth selesai, navigasi ke home terjadi *segera*.
Cloud restore berjalan di background — tidak memblokir navigasi.

```
/login → LoginScreen → Tombol "Masuk dengan Google"
  └─ AuthNotifier.signInWithGoogle()
      └─ AuthService.signInWithGoogle()  ← BLOCKING (menunggu user pilih akun)
          │
          ├─ [kIsWeb = true] → _signInWithGoogleWeb()
          │     └─ FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())
          │         ← popup browser native, OAuth dikelola penuh oleh Firebase SDK
          │         ← [popup ditutup pengguna] → return false (login dibatalkan)
          │         ← [popup diblokir browser] → UI: "Browser memblokir popup..."
          │     └─ UserCredential.user → _persistAndBuildUser()
          │
          └─ [kIsWeb = false] → _signInWithGoogleNative()
                └─ GoogleSignIn.signOut()  ← paksa pilih akun baru
                └─ GoogleSignIn.signIn()   ← dialog pemilih akun [BLOCKING ~1-5s user time]
                └─ googleAccount.authentication → idToken [BLOCKING ~200-500ms]
                └─ FirebaseAuth.signInWithCredential(credential) [BLOCKING ~200-800ms]
                └─ _persistAndBuildUser():
                     Simpan mode='google', id=uid ke SharedPreferences

      ── AUTH SELESAI — NAVIGASI KE HOME SEKARANG ──

      state = AsyncData(user) → GoRouter redirect ke /home
      isBackgroundSyncingProvider = true  ← banner muncul di HomeScreen

      [background] _restoreFromCloudBackground()
          └─ CloudRestoreService.restoreFromCloud()
              ├─ Future.wait([5 Firestore fetches])  ← paralel, bukan sequential
              ├─ insertOrIgnore ke categories, transactions, payment_history
              └─ last-write-wins ke hutang/piutang
          └─ Kegagalan: non-fatal, data lokal tetap aman
          └─ isBackgroundSyncingProvider = false  ← banner hilang

HomeScreen:
  - Drift reactive streams langsung memperbarui UI saat data baru masuk ke SQLite
  - Banner "Sedang memulihkan data dari cloud..." terlihat selama restore berlangsung

Catatan Platform:
  Web     : signInWithPopup(GoogleAuthProvider()) — tidak perlu google_sign_in
            Syarat: Authorized JavaScript Origins di Google Cloud Console
  Android : GoogleSignIn(serverClientId: _webClientId) → signInWithCredential
            Syarat: SHA-1 debug/release terdaftar di Firebase Console
  iOS     : GoogleSignIn(serverClientId: _webClientId) → signInWithCredential
            Syarat: GoogleService-Info.plist valid
```

---

### Path C — Upgrade Tamu ke Google (dari Settings)

**Optimasi UX**: Firebase auth selesai → state diperbarui segera.
Upload data lokal (migrasi) + restore dari cloud keduanya berjalan di background.

```
SettingsScreen → AccountCard (mode tamu) → Tombol "Masuk dengan Google"
  └─ AuthNotifier.upgradeGuestToGoogle()
      ├─ AuthService.signInWithGoogle()     ← BLOCKING, sama dengan Path B
      │   └─ SharedPreferences diperbarui: mode='google', id=Firebase UID
      │   └─ SyncService.isAvailable = true (lazy, auto-aktif)
      │
      ── AUTH SELESAI — UPDATE STATE SEKARANG ──

      state = AsyncData(googleUser)
      isBackgroundSyncingProvider = true
      SnackBar: "Login Google berhasil! Data kamu sedang disinkronkan..."

      [background] _runUpgradeBackground()
          ├─ _migrateLocalDataToCloud()   ← unggah data lokal ke Firestore
          │   ├─ Baca SQLite: tx, hutang, piutang, kategori
          │   └─ SyncService.migrateGuestData()  ← BATCH writes (maks 500/batch)
          │       Semua record dikumpulkan → commit dalam satu/beberapa WriteBatch
          │       Jauh lebih cepat dari sequential individual writes
          │
          └─ CloudRestoreService.restoreFromCloud()
              (INSERT OR IGNORE — tidak overwrite data lokal yang sudah ada)

      isBackgroundSyncingProvider = false  ← banner hilang

Strategi Merge:
  Upload (local wins): semua record ditulis ke Firestore via batch.
    Record yang sama di cloud di-overwrite oleh versi lokal.
  Restore (cloud fills gaps): INSERT OR IGNORE untuk kategori, transaksi, payment history.
    Untuk hutang/piutang: cloud menang jika updatedAt cloud > updatedAt lokal.

Yang TIDAK dimigrasikan:
  - Settings (payday, notifikasi) — device-specific, tidak perlu sync
```

---

### Path D — Logout (Google User)

```
SettingsScreen → AccountCard (mode Google) → Tombol "Keluar"
  └─ _confirmLogout() → dialog konfirmasi
      └─ AuthNotifier.signOut()
          └─ AuthService.signOut()
              ├─ mode == 'google':
              │   ├─ _googleSignIn.signOut()           ← sign out dari Google SDK
              │   └─ FirebaseAuth.instance.signOut()   ← hapus Firebase session
              └─ Hapus dari SharedPreferences:
                    saku_auth_id, saku_auth_name, saku_auth_email, saku_auth_mode
  
  state = AsyncData(null)
  GoRouter redirect ke /login

  Data lokal SQLite: TETAP ADA
  Data cloud Firestore: TETAP ADA
  Login ulang dengan akun yang sama: sesi Firebase baru, data cloud tetap ada
```

---

### Path E — Akhiri Sesi Tamu (Guest User)

```
SettingsScreen → AccountCard (mode tamu) → Tombol "Akhiri Sesi Tamu"
  └─ _confirmEndGuestSession() → dialog konfirmasi
      └─ AuthNotifier.signOut()
          └─ AuthService.signOut()
              ├─ mode == 'guest': tidak ada Google/Firebase sign out
              └─ Hapus dari SharedPreferences:
                    saku_auth_id, saku_auth_name, saku_auth_mode

  state = AsyncData(null)
  GoRouter redirect ke /login

  Data lokal SQLite: TETAP ADA (UUID tamu juga tetap tersimpan)
  
  Saat login sebagai tamu lagi:
    UUID yang sama digunakan kembali → data lokal masih tersedia
```

---

### Path F — Sync Cloud (Setiap Operasi Tulis)

```
Setiap insert/update/delete di repository (setelah login Google atau Email Link):
  └─ SyncService.isAvailable?
      ├─ false (mode tamu): return — tidak ada yang dikirim ke Firestore
      └─ true (mode Google ATAU EmailLink):
          └─ FirebaseFirestore
               .collection('users').doc(userId)
               .collection('transactions'|'hutang'|'piutang').doc(entityId)
               .set({...fields, 'updatedAt': FieldValue.serverTimestamp()})
               
  Kegagalan sync: try/catch → diabaikan, data lokal tetap aman
  SyncService.isAvailable dibaca lazy setiap panggilan (tidak di-cache)
```

---

### Kapan Sesi Aktif

`SplashScreen` membaca `AuthService.getCurrentUser()` dari SharedPreferences.
Jika ada sesi tersimpan, navigasi langsung ke `/home` tanpa login ulang.
Sesi Google juga di-re-validate oleh Firebase SDK secara internal (token refresh).

---

## Alur Sinkronisasi Cloud (Firebase)

Sinkronisasi aktif untuk pengguna **Google** dan **Email Link** (`authMode == 'google' || 'emailLink'`).
Pengguna tamu tidak pernah sync.

### Arsitektur Sync — 3 Lapisan

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  LAPISAN 1 — WRITE TO CLOUD (fire-and-forget)                                  │
│  SyncService.upsertXxx() / deleteXxx()                                          │
│  Dipanggil via unawaited() dari setiap Repository.insert/update/delete          │
│  Tidak memblokir UI. Kegagalan ditangani diam-diam (try/catch).                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│  LAPISAN 2 — RESTORE ON LOGIN (one-time, background)                            │
│  CloudRestoreService.restoreFromCloud()                                          │
│  Dipanggil satu kali setelah login berhasil                                     │
│  Fetch 5 koleksi paralel → tulis ke SQLite dengan strategi merge                │
├─────────────────────────────────────────────────────────────────────────────────┤
│  LAPISAN 3 — REALTIME MULTI-DEVICE SYNC (persistent listeners)                  │
│  RealtimeSyncService — 5 Firestore snapshots() listeners                        │
│  Aktif selama pengguna terautentikasi                                            │
│  Perubahan dari perangkat lain → langsung tulis ke SQLite → UI auto-refresh     │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Lapisan 1 — Write to Cloud

```
SyncService
  │
  ├─ isAvailable: _userId != null && (authMode == 'google' || authMode == 'emailLink')
  │   (dibaca lazy setiap panggilan — otomatis aktif setelah login)
  │
  └─ Setiap kali data berubah di lokal:
      └─ Repository.insert/update/delete → SyncService.upsertXxx/deleteXxx()
          └─ Firestore: users/{userId}/transactions|hutang|piutang|categories|payment_history/{id}
          └─ fire-and-forget via unawaited() — tidak memblokir UI
          └─ Kegagalan: try/catch → diabaikan, data lokal tetap aman
```

### Lapisan 2 — Restore on Login

```
CloudRestoreService.restoreFromCloud()
  ├─ Dipanggil saat: login Google, login Email Link, atau upgrade dari tamu
  ├─ Future.wait([5 Firestore fetches]) ← paralel — hemat 4 round-trip jaringan
  │
  ├─ Strategi merge:
  │   ├─ categories    : INSERT OR IGNORE (lokal menang jika sudah ada)
  │   ├─ transactions  : INSERT OR IGNORE (immutable setelah dibuat)
  │   ├─ hutang        : last-write-wins by updatedAt (cloud menang jika lebih baru)
  │   ├─ piutang       : last-write-wins by updatedAt (cloud menang jika lebih baru)
  │   └─ payment_history: INSERT OR IGNORE (immutable setelah dicatat)
  │
  └─ isBackgroundSyncingProvider = false setelah selesai → banner hilang
```

### Lapisan 3 — Realtime Multi-Device Sync

```
RealtimeSyncService (5 Firestore CollectionReference.snapshots() listeners)
  │
  ├─ Diaktifkan oleh: _RealtimeSyncHandler di app.dart
  │   └─ startListening(userId) dipanggil saat auth state → authenticated
  │   └─ stopListening() dipanggil saat auth state → null/tamu
  │
  ├─ includeMetadataChanges: true + filter hasPendingWrites == true
  │   └─ Echo tulisan lokal yang belum dikonfirmasi server dilewati
  │   └─ Hanya perubahan yang dikonfirmasi server yang diproses
  │
  ├─ DocumentChangeType.added    → INSERT OR IGNORE (baru dari cloud)
  ├─ DocumentChangeType.modified → INSERT OR REPLACE / last-write-wins (update)
  └─ DocumentChangeType.removed  → DELETE dari SQLite lokal
  │
  ├─ Bypass repository: menulis langsung ke DAO
  │   Alasan: repository menggunakan unawaited(sync.upsert*()) — akan membuat loop
  │   upload jika kita lewat repository saat menulis data yang datang dari cloud
  │
  └─ Kegagalan: try/catch per event — satu error tidak menghentikan listener lain
```

### Perilaku Offline

```
Saat device offline:
  ├─ SQLite lokal tetap berfungsi penuh (baca dan tulis)
  ├─ SyncService.upsertXxx() gagal → diabaikan (data lokal aman)
  ├─ RealtimeSyncService listener pause otomatis (Firestore SDK handle)
  └─ UI tetap responsif

Saat kembali online:
  ├─ Firestore SDK reconnect otomatis
  ├─ Listener menerima delta perubahan yang terlewat
  └─ Data disinkronkan tanpa perlu manual refresh
```

**Struktur Firestore:**
```
users/{userId}/transactions/{id}     ← id, type, amount, categoryId, note, date, createdAt, updatedAt
users/{userId}/hutang/{id}           ← id, namaKreditur, jumlahAwal, sisaHutang, tanggalPinjam, dll.
users/{userId}/piutang/{id}          ← id, namaPeminjam, jumlahAwal, sisaPiutang, tanggalPinjam, dll.
users/{userId}/categories/{id}       ← kategori KUSTOM saja (isDefault=false)
users/{userId}/payment_history/{id}  ← id, referenceId, referenceType, amount, paidAt, catatan
```

**Rekomendasi Firestore Security Rules:**
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
Rules ini memastikan setiap pengguna hanya bisa baca/tulis data miliknya sendiri.

---

## Inventaris Data Firebase — Apa yang Ada dan Tidak Ada di Firestore

Tabel ini adalah sumber kebenaran untuk pertanyaan "data apa yang tersimpan di Firebase?"

| Data | Lokal (SQLite/SharedPrefs) | Di Firestore | Tulis ke Cloud | Restore saat Login | Realtime Listener |
|---|---|---|---|---|---|
| **Transaksi** | ✅ SQLite `transactions` | ✅ Ya | ✅ WriteBatch: transaksi + kategorinya sekaligus | ✅ INSERT OR IGNORE + fallback categoryName | ✅ added→insertOrIgnore; modified→insertOrReplace; removed→delete |
| **Hutang — summary** | ✅ SQLite `hutang` | ✅ Ya | ✅ insert / update / delete | ✅ last-write-wins by updatedAt | ✅ last-write-wins by updatedAt |
| **Hutang — riwayat pembayaran** | ✅ SQLite `payment_history` | ✅ Ya | ✅ upsertPaymentRecord | ✅ INSERT OR IGNORE | ✅ insertOrIgnore; removed→delete |
| **Piutang — summary** | ✅ SQLite `piutang` | ✅ Ya | ✅ insert / update / delete | ✅ last-write-wins by updatedAt | ✅ last-write-wins by updatedAt |
| **Piutang — riwayat pembayaran** | ✅ SQLite `payment_history` | ✅ Ya | ✅ upsertPaymentRecord | ✅ INSERT OR IGNORE | ✅ insertOrIgnore; removed→delete |
| **Kategori kustom** (isDefault=false) | ✅ SQLite `categories` | ✅ Ya | ✅ via upsertTransaction batch + upsertCategory / deleteCategory | ✅ INSERT OR IGNORE |
| **Kategori default** (isDefault=true) | ✅ SQLite `categories` (ID stabil sejak v5) | ✅ Ya | ✅ via upsertTransaction batch + syncAllLocalCategories saat login | ✅ INSERT OR IGNORE (stable ID = sudah ada, diabaikan) |
| **Settings** (payday, notifikasi) | ✅ SharedPreferences | ❌ **Tidak disimpan** | ❌ Tidak di-sync | ❌ Device-specific |
| **Auth session** | ✅ SharedPreferences | ✅ Firebase Auth | — | — |

### Catatan Implementasi

**Kategori default dan kustom** — Sejak perbaikan ini, SEMUA kategori (termasuk `isDefault=true`)
ditulis ke Firestore melalui dua mekanisme:
1. `SyncService.upsertTransaction()` menggunakan **WriteBatch** yang sekaligus menulis
   kategori dan transaksi secara atomik — sehingga koleksi `categories` selalu terisi
   setiap kali transaksi dibuat atau diperbarui.
2. `AuthNotifier._restoreBackground()` memanggil `syncAllLocalCategories()` setelah login
   untuk memastikan semua 18+ kategori lokal (default + kustom) ada di Firestore.

**Riwayat pembayaran** — `HutangRepositoryImpl.addPayment()` dan
`PiutangRepositoryImpl.addPayment()` masing-masing memanggil
`unawaited(_sync.upsertPaymentRecord(...))` setelah insert ke SQLite.

**Cross-device restore** — `CloudRestoreService.restoreFromCloud()` dipanggil di
`AuthNotifier.signInWithGoogle()` dan `upgradeGuestToGoogle()`. Restore bypass repository
(langsung ke DAO) untuk menghindari re-upload ke Firestore saat restore.

**Urutan restore:** Kategori → Transaksi → Hutang → Piutang → Riwayat Bayar.
Kategori selalu diproses pertama agar foreign key `transactions.categoryId` dapat diselesaikan.

**Fallback categoryName untuk transaksi** — Saat restore, jika `categoryId` dari Firestore
tidak ditemukan di SQLite lokal (data lama sebelum migrasi v5 dengan UUID acak), layanan
mencari kategori lokal berdasarkan `(categoryName|type)`. Ini menangani data lama yang sudah
ada di Firestore dengan UUID acak sebelum migrasi v5. Jika nama juga tidak cocok, transaksi
dilewati dan dicatat via `dev.log()` level 900.

**Strategi merge per tabel:**
- Kategori (semua) : INSERT OR IGNORE — lokal menang jika ID sudah ada; ID stabil (def-*/sys-*) dari seed selalu terpelihara
- Transaksi         : INSERT OR IGNORE dengan fallback categoryName — immutable setelah dibuat
- Riwayat bayar    : INSERT OR IGNORE — immutable setelah dicatat
- Hutang/Piutang   : last-write-wins by `updatedAt` — cloud menang jika lebih baru

**Settings** — `SettingsRepositoryImpl` hanya baca/tulis `SharedPreferences`. Tidak ada
Firebase dependency. Setiap perangkat memiliki konfigurasi gajian dan notifikasi sendiri.

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

## Kategori Default — ID Stabil (sejak v5)

Selain kategori sistem, terdapat 15 kategori default (10 pengeluaran + 5 pemasukan).
Sejak skema v5, semua kategori default menggunakan **ID tetap** dari `DefaultCategoryIds`
di `lib/data/database/app_database.dart`, bukan UUID acak.

**Mengapa penting:** Sebelum v5, setiap install menghasilkan UUID berbeda untuk kategori yang
sama. Transaksi di Firestore mereferensikan UUID perangkat A, sehingga restore ke perangkat B
gagal karena UUID tidak cocok. Setelah v5, semua perangkat memiliki ID yang sama.

**ID stabil:** Pola `def-{type}-{name}-v1` — contoh: `def-income-gaji-v1`, `def-expense-makan-v1`.

**Migrasi v5:** Saat upgrade dari v4, `_migrateCategoryIdsToStable()`:
1. Mencari semua kategori default dengan ID non-stabil (bukan `def-*` / `sys-*`)
2. Mencocokkan ke stableId berdasarkan `(name|type)`
3. Mengupdate referensi di tabel `transactions` terlebih dahulu
4. Mengupdate primary key di tabel `categories`
5. Seed kategori yang belum ada

**JANGAN ubah** nilai di `DefaultCategoryIds` — transaksi di SQLite dan Firestore
mereferensikan ID ini.

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
| 4 | 5 | Ganti UUID acak kategori default dengan ID stabil (`def-*`); update referensi di transactions |

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

realtimeSyncServiceProvider  (listener Firestore → tulis ke DAO)
  ├─ categoryDaoProvider
  ├─ transactionDaoProvider
  ├─ hutangDaoProvider
  └─ piutangDaoProvider
  [diaktifkan oleh _RealtimeSyncHandler di app.dart; listen ke currentUserProvider]

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

## Firebase & Google Sign-In

> **Konfigurasi Firebase harus disesuaikan dengan project Firebase milik Anda sendiri.**
> Semua file konfigurasi Firebase ada di `.gitignore` — tidak disertakan di repository.

Google Services plugin sudah aktif di Gradle. Developer baru wajib menyiapkan
konfigurasi Firebase sebelum fitur login dan cloud sync dapat digunakan.

### File Konfigurasi yang Diperlukan (Gitignored)

| File | Template Tersedia Di |
|---|---|
| `lib/firebase_options.dart` | `lib/firebase_options.example.dart` |
| `android/app/google-services.json` | `android/app/google-services.example.json` |
| `ios/Runner/GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.example.plist` |

Cara tercepat: jalankan `flutterfire configure` dengan project Firebase Anda.

### Setup yang Diperlukan per Platform

| Platform | Yang Perlu Dikonfigurasi |
|---|---|
| Semua | `lib/firebase_options.dart` (via `flutterfire configure` atau salin dari `.example.dart`) |
| Android | Download `google-services.json` dari Firebase Console + daftarkan SHA-1 |
| iOS | Download `GoogleService-Info.plist` dari Firebase Console |
| Web | Tambahkan `http://localhost` ke Authorized JavaScript Origins di Google Cloud Console |

Panduan lengkap per platform ada di `docs/DEVELOPMENT_TO_DEPLOY.md §Firebase`.
Lihat `docs/CONFIG_AND_SECRET_AUDIT.txt` untuk detail keamanan konfigurasi.

### Komponen yang Terlibat dalam Auth

| File | Peran |
|---|---|
| `lib/core/services/auth_service.dart` | Business logic: guest sign-in, Google sign-in, sign-out, sesi |
| `lib/presentation/providers/auth_provider.dart` | `AuthNotifier` — state auth + migrasi guest ke Google |
| `lib/core/services/sync_service.dart` | Upload data ke Firestore (aktif hanya mode Google) |
| `lib/firebase_options.dart` | Konfigurasi Firebase per platform (gitignored — buat dari `.example.dart`) |
| `web/index.html` | Tag meta `google-signin-client_id` untuk GIS — berisi placeholder; inject nilai nyata via `scripts/inject_web_client_id.sh` sebelum run/build web |

### Mengapa SyncService Menggunakan Lazy Reading

`SyncService` membaca `userId` dan `authMode` langsung dari `SharedPreferences`
setiap kali `isAvailable` diperiksa — bukan saat konstruksi. Ini penting karena:

- Provider `syncServiceProvider` dibuat sekali dan di-cache Riverpod
- Setelah Google Sign-In, SharedPreferences diupdate dengan userId baru
- `SyncService.isAvailable` langsung `true` tanpa perlu recreate provider
- Semua operasi tulis berikutnya otomatis ter-sync ke Firestore

### Apa yang Terjadi Saat Firebase.initializeApp() Gagal

Firebase diinisialisasi dengan timeout 10 detik. Jika gagal (jaringan putus, dll.):
- App tetap berjalan penuh dalam mode lokal/tamu
- Tombol Google Sign-In tetap muncul tapi akan gagal saat ditekan
- Pesan error Bahasa Indonesia ditampilkan ke pengguna (bukan crash)

### Keterbatasan Sinkronisasi (v1.0)

- **Upload only**: data lokal dikirim ke Firestore setiap ada perubahan
- **Cross-device restore**: belum diimplementasikan (planned v2.0)
- **Sementara**: gunakan Ekspor/Impor CSV untuk pindah perangkat

### Firestore Security Rules (wajib untuk produksi)

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

---

---

## Peta Panggilan: Provider → Service → Repository → Database

Bagian ini menjawab pertanyaan: **"File mana memanggil siapa?"**

### Inisialisasi (main.dart → app.dart)

```
main.dart
  └─ SharedPreferences.getInstance()              ← await sebelum runApp
  └─ Firebase.initializeApp()                     ← selalu, catch jika gagal
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
      └─ SyncService.isAvailable?   ← _userId != null && authMode == 'google'
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

*Dokumen ini terakhir diperbarui: 26 April 2026 — Web Client ID: placeholder di web/index.html (inject via scripts/inject_web_client_id.sh), --dart-define untuk native*
