# SakuRapi — Aplikasi Pencatat Keuangan Pribadi

**SakuRapi** adalah aplikasi pencatat keuangan pribadi yang modern, lengkap, dan mendukung mode offline maupun cloud sync.
Dibuat dengan Flutter untuk Android dan iOS. Tagline: *Kelola Saku, Rapi Keuangan.*

---

## Fitur Utama

### Transaksi
- Catat pemasukan dan pengeluaran dengan kategori (termasuk kategori kustom)
- Laporan harian, bulanan, tahunan, rentang tanggal, dan siklus gajian
- Ekspor dan impor data via CSV

### Hutang & Piutang (Terintegrasi dengan Keuangan)
- **Hutang**: catat hutangmu kepada orang lain / bank
  - Bayar hutang lewat form Pengeluaran → saldo otomatis berkurang
  - Bayar hutang langsung dari detail hutang → saldo + riwayat terupdate
  - Status otomatis berubah ke *Lunas* saat sisa = 0
- **Piutang**: catat uang yang kamu pinjamkan
  - Membuat piutang baru → expense otomatis dibuat (uang keluar dari saldo)
  - Terima cicilan → income otomatis dibuat (uang kembali ke saldo)
  - Status otomatis berubah ke *Lunas* saat sisa = 0
- Semua pembayaran hutang/piutang muncul di laporan keuangan terpadu

### Laporan Modul
- Laporan transaksi (harian, bulanan, tahunan, rentang, siklus gaji)
- Laporan khusus Hutang (aktif vs lunas, jatuh tempo, riwayat)
- Laporan khusus Piutang (aktif vs lunas, jatuh tempo, riwayat)

### Autentikasi & Sinkronisasi Multi-Perangkat
- **Mode Tamu**: semua data tersimpan lokal (SQLite), tidak perlu akun
- **Login Google**: Firebase Auth + sinkronisasi Firestore realtime
- **Login Email Link**: Firebase passwordless — tidak perlu password, cukup klik link di email
- **Multi-device sync** (untuk akun Google dan Email Link):
  - Data yang berubah di perangkat A secara otomatis muncul di perangkat B via Firestore realtime listeners
  - Login di perangkat baru → cloud restore berjalan di background, UI langsung pakai data lokal
  - Offline tetap berfungsi penuh; sinkronisasi berjalan otomatis saat kembali online
  - Strategi merge: INSERT OR IGNORE (transaksi, kategori, riwayat bayar) + last-write-wins by updatedAt (hutang/piutang)
  - Settings (payday, notifikasi) tidak disinkronisasi — bersifat per-perangkat
  - *Google: perlu mendaftarkan SHA-1 di Firebase Console — lihat §3 di bawah*

### Notifikasi & Pengingat
- Pengingat harian transaksi (jam dan hari yang bisa dikonfigurasi)
- Default: 21:00 WIB, semua hari aktif

### UI & Pengalaman Pengguna
- Material 3 modern dengan tema premium
- Responsif untuk mobile dan tablet
- Semua teks dalam Bahasa Indonesia
- Input uang berformat Rupiah (Rp 5.000.000)

---

## Prasyarat

- Flutter 3.22.0+
- Dart 3.7.0+
- Android Studio / VS Code dengan ekstensi Flutter
- Xcode 15+ (untuk build iOS, hanya Mac)
- JDK 17+

---

## Setup & Jalankan

```bash
# 1. Clone repositori
git clone <url-repo>
cd project_ai_claude_apk_android_ios

# 2. Pasang dependensi
flutter pub get

# 3. Generate kode Drift (ORM database) — WAJIB
dart run build_runner build --delete-conflicting-outputs

# 4. Jalankan aplikasi
flutter run
```

Aplikasi langsung berjalan dalam mode lokal/tamu tanpa konfigurasi tambahan.

---

## §3 — Firebase & Google Login

Firebase sudah dikonfigurasi di proyek ini (proyek: `sakurapi-aa6ac`).
Tombol **Masuk dengan Google** langsung melakukan login nyata.

### Package Firebase yang Digunakan

| Package | Fungsi |
|---------|--------|
| `firebase_core` | Inisialisasi Firebase SDK |
| `firebase_auth` | Autentikasi Google — semua platform (signInWithPopup di web, signInWithCredential di native) |
| `google_sign_in` | Dialog pemilih akun Google — **Android dan iOS saja** (tidak digunakan di web) |
| `cloud_firestore` | Sinkronisasi data ke cloud |

### Mode Tamu vs Login Google

| Fitur | Mode Tamu | Login Google |
|---|---|---|
| Akses penuh fitur keuangan | ✅ | ✅ |
| Data tersimpan lokal (SQLite) | ✅ | ✅ |
| Sinkronisasi cloud (Firestore) | ❌ | ✅ |
| Backup kategori kustom | ❌ | ✅ |
| Backup riwayat pembayaran hutang/piutang | ❌ | ✅ |
| Restore otomatis saat login di perangkat baru | ❌ | ✅ |
| Migrasi data tamu ke Google | — | ✅ (via Settings) |

### Logout & Sesi

**Login Google** — Ketuk **Keluar** di Settings. Sesi Firebase & Google Sign-In
dibersihkan, data lokal dan cloud tetap aman. Login kembali memulihkan data cloud.

**Mode Tamu** — Tidak ada akun untuk di-logout. Settings menampilkan tombol
**Masuk dengan Google** (migrasi data lokal ke cloud) dan **Akhiri Sesi Tamu**
(kembali ke layar login tanpa menghapus data lokal).

### Migrasi Data Tamu ke Google

Jika pengguna sudah menggunakan mode tamu lalu ingin login Google:
1. Buka **Settings → Akun → Masuk dengan Google**
2. Login Google berhasil → semua data lokal (transaksi, hutang, piutang) otomatis diunggah ke Firestore
3. Data tetap tersedia secara lokal + sekarang ter-backup di cloud

Strategi merge dua langkah:
1. **Upload (local wins)** — data lokal di-upsert ke Firestore (overwrite cloud jika ID sama)
2. **Restore (cloud fills gaps)** — data cloud yang belum ada lokal ditarik masuk (INSERT OR IGNORE)

---

### Setup Android: Daftarkan SHA-1

Google Sign-In pada Android memerlukan SHA-1 fingerprint terdaftar di Firebase Console.

```
[1] Dapatkan SHA-1 debug key (perintah di bawah)
[2] Firebase Console → sakurapi-aa6ac → Project Settings
    → Android app (com.financetracker.finance_tracker) → Add fingerprint → paste SHA-1
[3] Download ulang google-services.json → android/app/google-services.json
[4] flutter run → test Login Google
```

Tanpa SHA-1: tombol Google Sign-In tetap muncul tapi menampilkan pesan error
"Login Google belum siap" — bukan dialog setup developer.

```bash
# macOS / Linux
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android

# Windows
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore ^
  -alias androiddebugkey -storepass android -keypass android
```

### Setup Web: Authorized JavaScript Origins

Login Google di web menggunakan `FirebaseAuth.signInWithPopup(GoogleAuthProvider())` —
**bukan** `google_sign_in`. Firebase SDK mengelola seluruh OAuth popup secara native di browser.

**Setup satu kali untuk development:**

1. Buka [console.cloud.google.com](https://console.cloud.google.com) → proyek `sakurapi-aa6ac`
2. **APIs & Services → Credentials → OAuth 2.0 Client IDs** → klik Web Client (auto-created by Firebase)
3. Di **Authorized JavaScript origins**, tambahkan:
   - `http://localhost` (atau `http://localhost:7357` jika ingin port eksplisit)
4. Di **Authorized redirect URIs**, pastikan ada:
   - `https://sakurapi-aa6ac.firebaseapp.com/__/auth/handler`
5. Inject Web Client ID ke `web/index.html` (lihat §Konfigurasi di bawah)
6. **Save** → jalankan:

```bash
flutter run -d chrome --web-hostname localhost --web-port 7357
```

Untuk production build: tambahkan URL produksi (mis. `https://sakurapi.web.app`) ke Authorized JavaScript origins.

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

Lihat [`docs/DEVELOPMENT_TO_DEPLOY.md §Firebase`](docs/DEVELOPMENT_TO_DEPLOY.md) untuk panduan lengkap.

---

## Build Release

```bash
# Android APK
flutter build apk --release --no-tree-shake-icons

# Android App Bundle (direkomendasikan untuk Play Store)
flutter build appbundle --release

# iOS (hanya Mac, perlu signing)
flutter build ios --release
```

---

## Menjalankan Tests

```bash
# Semua tests
flutter test

# Unit tests saja
flutter test test/unit/

# Widget tests saja
flutter test test/widget/

# Test spesifik
flutter test test/unit/usecases/hutang_payment_integration_test.dart
```

---

## Arsitektur

```
lib/
├── main.dart               — Entry point, Firebase init, ProviderScope
├── app.dart                — MaterialApp.router, tema, locale
├── firebase_options.dart   — Konfigurasi Firebase (generated)
├── router/                 — GoRouter: semua rute aplikasi
├── core/
│   ├── constants/          — AppStrings, AppColors, SystemCategories
│   ├── services/           — AuthService, NotificationService, SyncService
│   ├── utils/              — CurrencyFormatter, AppDateUtils
│   └── widgets/            — Widget reusable (LoadingIndicator, EmptyState)
├── domain/
│   ├── entities/           — Model data murni (Transaction, Hutang, Piutang)
│   ├── enums/              — TransactionType, CategoryType, AuthMode
│   └── repositories/       — Interface repository (abstraksi)
├── data/
│   ├── database/           — Drift: skema, tabel, DAO
│   └── repositories/       — Implementasi repository (SQLite)
└── presentation/
    ├── providers/          — Riverpod: state management seluruh app
    └── features/           — Layar UI per fitur
```

**Teknologi**: Flutter • Dart • Drift (SQLite) • Riverpod • GoRouter • Firebase • flutter_local_notifications

---

## Struktur Kategori Sistem

Kategori berikut dikelola oleh sistem (ID tetap, tidak bisa dihapus):

| Kategori | Tipe | Digunakan Saat |
|---|---|---|
| Pembayaran Hutang | Pengeluaran | Bayar hutang dari form transaksi atau detail hutang |
| Memberi Pinjaman | Pengeluaran | Buat piutang baru (otomatis) |
| Penerimaan Piutang | Pemasukan | Terima cicilan piutang (otomatis) |

---

---

## Konfigurasi & Keamanan

### File konfigurasi Firebase

Proyek ini menggunakan Firebase. File konfigurasi platform berikut ada di `.gitignore`
dan **tidak di-commit ke repository**:

| File | Platform | Cara Mendapatkan |
|------|----------|------------------|
| `android/app/google-services.json` | Android | Firebase Console → Project Settings → Android app → Download |
| `ios/Runner/GoogleService-Info.plist` | iOS | Firebase Console → Project Settings → iOS app → Download |

Template (tanpa nilai nyata) tersedia di:
- `android/app/google-services.example.json`
- `ios/Runner/GoogleService-Info.example.plist`

File `lib/firebase_options.dart` **sengaja di-commit** agar proyek bisa langsung
di-build setelah clone. Berisi public client config (bukan secret).

### Tentang Firebase API Keys & OAuth Client IDs

Firebase API keys dan OAuth Client IDs di proyek ini bukan secret server-side.
Nilai-nilai ini memang tertanam di dalam APK/IPA setelah build dan dirancang
untuk publik oleh Google. Keamanan data diatur via Firebase Security Rules,
bukan dengan menyembunyikan keys.

Meski bukan secret, untuk menjaga kebersihan source yang di-commit, Web Client ID
**tidak** di-hardcode langsung di source file yang di-commit. Gunakan pendekatan
di bawah untuk menyediakan nilai secara lokal.

Lihat [`docs/CONFIG_AND_SECRET_AUDIT.txt`](docs/CONFIG_AND_SECRET_AUDIT.txt) untuk
penjelasan lengkap, inventaris semua nilai yang ditemukan, dan panduan keamanan.

### Web Client ID — Konfigurasi Lokal

`web/index.html` berisi placeholder `YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com`
yang perlu diganti dengan nilai nyata sebelum menjalankan atau build web.

**⚠ Jujur soal keamanan:** OAuth Client ID adalah konfigurasi klien publik. Nilai ini
akan terlihat di source HTML yang dikirim ke browser setelah inject — tidak dapat
disembunyikan dari pengguna. Tujuan pendekatan ini adalah **kebersihan source yang
di-commit**, bukan menyembunyikan nilai.

**Langkah untuk development lokal (web):**

```bash
# 1. Dapatkan Web Client ID dari Firebase Console → sakurapi-aa6ac
#    → Project Settings → Web App → OAuth 2.0 client ID
#    ATAU: Google Cloud Console → APIs & Services → Credentials →
#    "Web client (auto created by Google Service)"

# 2. Inject nilai ke web/index.html
GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com bash scripts/inject_web_client_id.sh

# 3. Jalankan
flutter run -d chrome --web-hostname localhost --web-port 7357

# 4. Setelah selesai, kembalikan placeholder agar tidak ter-commit
git checkout web/index.html
```

**Untuk native (Android/iOS)**, gunakan `--dart-define`:

```bash
flutter run \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com

flutter build apk --release \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
```

Nilai `_webClientId` di `auth_service.dart` dibaca dari `--dart-define` atau
default ke placeholder jika tidak disediakan (native Google Sign-In akan gagal
jika placeholder digunakan tanpa penggantian).

---

## Dokumentasi Lengkap

- [`docs/CODEBASE_HANDOVER.md`](docs/CODEBASE_HANDOVER.md) — arsitektur, alur kode, panduan handover
- [`docs/DEVELOPMENT_TO_DEPLOY.md`](docs/DEVELOPMENT_TO_DEPLOY.md) — panduan build, deploy, dan konfigurasi
- [`docs/CONFIG_AND_SECRET_AUDIT.txt`](docs/CONFIG_AND_SECRET_AUDIT.txt) — audit konfigurasi & keamanan
