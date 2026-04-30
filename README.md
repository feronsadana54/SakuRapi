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

Aplikasi langsung berjalan dalam **mode lokal/tamu** tanpa konfigurasi tambahan.

Untuk fitur **Google Sign-In, Email Link, dan cloud sync**, konfigurasi Firebase
dengan project milik Anda sendiri diperlukan — lihat [§Konfigurasi Firebase](#konfigurasi-firebase).

---

## §3 — Firebase & Google Login

> **⚠ Konfigurasi diperlukan**: Fitur ini memerlukan project Firebase **milik Anda sendiri**.
> Lihat [§Konfigurasi Firebase](#konfigurasi-firebase) di bawah untuk panduan setup lengkap.

Firebase Auth digunakan untuk Google Sign-In, Email Link sign-in, dan cloud sync via Firestore.

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
[2] Firebase Console → [Project Anda] → Project Settings
    → Android app → Add fingerprint → paste SHA-1
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

1. Buka [console.cloud.google.com](https://console.cloud.google.com) → project Firebase Anda
2. **APIs & Services → Credentials → OAuth 2.0 Client IDs** → klik Web Client (auto-created by Firebase)
3. Di **Authorized JavaScript origins**, tambahkan:
   - `http://localhost` (atau `http://localhost:7357` jika ingin port eksplisit)
4. Di **Authorized redirect URIs**, pastikan ada:
   - `https://[PROJECT-ID].firebaseapp.com/__/auth/handler`
5. Inject Web Client ID ke `web/index.html` (lihat §Web Client ID di bawah)
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
├── firebase_options.dart   — Konfigurasi Firebase (gitignored — salin dari firebase_options.example.dart)
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

## Konfigurasi Firebase

> **Konfigurasi Firebase harus disesuaikan dengan akun/project Firebase milik Anda sendiri.**
> Jangan commit nilai asli ke repository publik.
> Gunakan file contoh/placeholder yang tersedia.

Proyek ini memerlukan project Firebase **milik Anda sendiri**. Semua file konfigurasi
Firebase ada di `.gitignore` dan **tidak disertakan di repository** — setiap developer
wajib menyiapkan konfigurasi mereka sendiri.

### File yang diperlukan (gitignored, tidak ada di repository)

| File | Platform | Template tersedia di |
|------|----------|---------------------|
| `lib/firebase_options.dart` | Semua platform | `lib/firebase_options.example.dart` |
| `android/app/google-services.json` | Android | `android/app/google-services.example.json` |
| `ios/Runner/GoogleService-Info.plist` | iOS | `ios/Runner/GoogleService-Info.example.plist` |

### Langkah Setup Firebase (satu kali)

**Opsi A — FlutterFire CLI (direkomendasikan):**

```bash
# 1. Buat project di https://console.firebase.google.com
#    Tambahkan app Android, iOS, dan/atau Web ke project Anda

# 2. Install FlutterFire CLI dan login
dart pub global activate flutterfire_cli
firebase login

# 3. Generate lib/firebase_options.dart secara otomatis
flutterfire configure
```

**Opsi B — Manual dari Firebase Console:**

```bash
# 1. Salin template ke file yang sebenarnya
cp lib/firebase_options.example.dart lib/firebase_options.dart

# 2. Buka Firebase Console → [Project Anda] → Project Settings → General
#    Isi setiap nilai YOUR_... di lib/firebase_options.dart
#    dengan nilai nyata dari Firebase Console

# 3. Download dan letakkan file config platform:
#    google-services.json  → android/app/
#    GoogleService-Info.plist → ios/Runner/
```

**Langkah Firebase Console (wajib):**
1. Aktifkan Authentication → Sign-in methods: **Google** dan **Email/Link** (passwordless)
2. Buat **Firestore Database** (production mode)
3. Terapkan Firestore Security Rules (lihat di bawah)
4. Daftarkan SHA-1 fingerprint untuk Google Sign-In Android (lihat §Setup Android)

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

### Web Client ID — Konfigurasi Lokal

`web/index.html` berisi placeholder `YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com`
yang perlu diganti dengan nilai nyata sebelum menjalankan atau build web.

> OAuth Client ID adalah konfigurasi klien publik yang akan terlihat di source HTML
> yang dikirim ke browser. Tujuan placeholder ini hanya menjaga kebersihan source
> yang di-commit, bukan menyembunyikan nilai.

```bash
# Inject Web Client ID ke web/index.html sebelum run/build
GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com bash scripts/inject_web_client_id.sh

# Jalankan web
flutter run -d chrome --web-hostname localhost --web-port 7357

# Kembalikan placeholder setelah selesai agar tidak ter-commit
git checkout web/index.html
```

Untuk native Android/iOS, gunakan `--dart-define`:

```bash
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
flutter build apk --release --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
```

Dapatkan Web Client ID dari: Firebase Console → [Project Anda] → Project Settings
→ Web App → OAuth 2.0 client ID, **ATAU** Google Cloud Console → APIs & Services
→ Credentials → "Web client (auto created by Google Service)".

### Tentang Firebase API Keys

Firebase client config (apiKey, appId, dll.) bukan secret server-side — nilai ini
memang tertanam di APK/IPA setelah build dan dirancang untuk publik oleh Google.
Keamanan diatur via Firebase Security Rules, bukan dengan menyembunyikan keys.

Meski bukan secret, semua konfigurasi Firebase dijaga di luar git agar setiap
developer menggunakan project Firebase mereka sendiri dan repository aman dipublikasikan.

Lihat [`docs/CONFIG_AND_SECRET_AUDIT.txt`](docs/CONFIG_AND_SECRET_AUDIT.txt) untuk
penjelasan teknis lengkap dan panduan keamanan.

---

## Dokumentasi Lengkap

- [`docs/CODEBASE_HANDOVER.md`](docs/CODEBASE_HANDOVER.md) — arsitektur, alur kode, panduan handover
- [`docs/DEVELOPMENT_TO_DEPLOY.md`](docs/DEVELOPMENT_TO_DEPLOY.md) — panduan build, deploy, dan konfigurasi
- [`docs/CONFIG_AND_SECRET_AUDIT.txt`](docs/CONFIG_AND_SECRET_AUDIT.txt) — audit konfigurasi & keamanan
