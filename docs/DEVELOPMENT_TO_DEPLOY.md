# SakuRapi — Panduan Development hingga Deploy

> Dokumen ini menjelaskan cara setup lingkungan pengembangan, menjalankan aplikasi,
> membangun APK/IPA, menjalankan test, dan checklist sebelum deploy ke Play Store / App Store.

---

## Daftar Isi

1. [Prasyarat](#prasyarat)
2. [Setup Awal](#setup-awal)
3. [Menjalankan Aplikasi](#menjalankan-aplikasi)
4. [Struktur Build & Kode Generate Drift](#struktur-build--kode-generate-drift)
5. [Menjalankan Test](#menjalankan-test)
6. [Build untuk Android](#build-untuk-android)
7. [Build untuk iOS](#build-untuk-ios)
8. [Firebase & Google Login](#firebase--google-login)
9. [Strategi Testing](#strategi-testing)
10. [Checklist Sebelum Deploy](#checklist-sebelum-deploy)
11. [Troubleshooting Umum](#troubleshooting-umum)

---

## Prasyarat

Pastikan semua tools berikut sudah terpasang:

| Tool | Versi Minimum | Cara Cek |
|------|---------------|----------|
| Flutter | 3.22.0+ | `flutter --version` |
| Dart | 3.7.0+ | `dart --version` |
| Android Studio | Ladybug+ | — |
| Xcode (Mac only) | 15+ | `xcode-select --version` |
| CocoaPods (Mac only) | 1.14+ | `pod --version` |
| Java JDK | 17+ | `java -version` |

Pastikan `flutter doctor` menunjukkan semua hijau (atau hanya warning yang tidak relevan).

---

## Setup Awal

### 1. Clone Repositori

```bash
git clone <url-repo>
cd <nama-folder-repo>
```

### 2. Pasang Dependensi Flutter

```bash
flutter pub get
```

### 2b. Setup File Konfigurasi Firebase (wajib untuk fitur Google Sign-In)

> **⚠ Wajib menggunakan project Firebase Anda sendiri.**
> Semua file konfigurasi Firebase ada di `.gitignore` — tidak disertakan di repository.

File-file berikut perlu disiapkan sendiri oleh setiap developer:

| File | Cara mendapatkan |
|------|-----------------|
| `lib/firebase_options.dart` | Salin `lib/firebase_options.example.dart` → isi nilai, atau `flutterfire configure` |
| `android/app/google-services.json` | Firebase Console → [Project Anda] → Project Settings → Android app → Download |
| `ios/Runner/GoogleService-Info.plist` | Firebase Console → [Project Anda] → Project Settings → iOS app → Download |

Template placeholder tersedia di:
- `lib/firebase_options.example.dart`
- `android/app/google-services.example.json`
- `ios/Runner/GoogleService-Info.example.plist`

Cara tercepat — gunakan FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure   # generate lib/firebase_options.dart otomatis
```

> **Tanpa google-services.json:** Build Android akan gagal. Mode tamu tetap bisa
> ditest di iOS Simulator tanpa GoogleService-Info.plist, tapi Google Sign-In tidak akan jalan.

### 3. Generate Kode Drift (wajib dilakukan setelah clone atau setelah mengubah skema DB)

```bash
dart run build_runner build --delete-conflicting-outputs
```

Perintah ini menghasilkan file `.g.dart` untuk semua tabel dan DAO Drift.
File-file generated tidak di-commit ke git (ada di `.gitignore`).

### 4. (Opsional) Jalankan watcher untuk development aktif

```bash
dart run build_runner watch --delete-conflicting-outputs
```

Watcher otomatis men-generate ulang kode setiap ada perubahan pada tabel/DAO.

---

## Menjalankan Aplikasi

Aplikasi langsung berjalan dalam mode lokal/tamu tanpa konfigurasi Firebase tambahan.

### Android / iOS (emulator atau device fisik)

```bash
# Jalankan di device yang terhubung
flutter run

# Jalankan dengan mode release untuk test performa
flutter run --release

# Jalankan di emulator spesifik
flutter run -d emulator-5554
```

### Web (Chrome)

```bash
# Direkomendasikan — port tetap agar origin dev konsisten
flutter run -d chrome --web-hostname localhost --web-port 7357
```

> **Catatan Web:** Mode tamu berjalan penuh di web tanpa Firebase. Login Google
> menggunakan `FirebaseAuth.signInWithPopup` (bukan `google_sign_in`) dan memerlukan
> konfigurasi Authorized JavaScript Origins — lihat §Firebase → Web di bawah.

### Melihat semua device yang tersedia

```bash
flutter devices
```

---

## Struktur Build & Kode Generate Drift

Drift menggunakan code generation. File-file berikut adalah generated dan **jangan diedit manual**:

- `lib/data/database/app_database.g.dart`
- `lib/data/database/daos/transaction_dao.g.dart`
- `lib/data/database/daos/category_dao.g.dart`
- `lib/data/database/daos/hutang_dao.g.dart`
- `lib/data/database/daos/piutang_dao.g.dart`

Jika ada error "type X is undefined" setelah pull kode baru, jalankan ulang:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Menjalankan Test

### Semua Test

```bash
flutter test
```

### Test Spesifik

```bash
# Unit test — domain logic
flutter test test/unit/usecases/hutang_payment_integration_test.dart
flutter test test/unit/usecases/piutang_repayment_integration_test.dart
flutter test test/unit/usecases/hutang_calculation_test.dart
flutter test test/unit/usecases/piutang_calculation_test.dart
flutter test test/unit/usecases/payday_cycle_test.dart
flutter test test/unit/usecases/summary_calculation_test.dart
flutter test test/unit/auth/auth_mode_test.dart
flutter test test/unit/utils/date_utils_test.dart
flutter test test/unit/utils/currency_formatter_test.dart

# Widget test — navigasi dan form
flutter test test/widget/splash_navigation_test.dart
flutter test test/widget/transaction_date_test.dart
flutter test test/widget/transaction_selection_test.dart
flutter test test/widget/home_quote_test.dart
flutter test test/widget/settings_reminder_test.dart

# Test dengan coverage
flutter test --coverage
```

### Struktur Test

```
test/
├── unit/
│   ├── auth/
│   │   └── auth_mode_test.dart                   # UserEntity, AuthMode enum
│   ├── usecases/
│   │   ├── hutang_payment_integration_test.dart  # Integrasi pembayaran hutang (domain logic)
│   │   ├── piutang_repayment_integration_test.dart # Integrasi cicilan piutang (domain logic)
│   │   ├── hutang_calculation_test.dart          # HutangEntity: progressPersen, isLunas
│   │   ├── piutang_calculation_test.dart         # PiutangEntity: progressPersen, isLunas
│   │   ├── payday_cycle_test.dart                # AppDateUtils.getPaydayCycle (boundary cases)
│   │   └── summary_calculation_test.dart         # Kalkulasi total income/expense/balance
│   └── utils/
│       ├── date_utils_test.dart                  # AppDateUtils (format tanggal, helpers)
│       └── currency_formatter_test.dart          # Format Rupiah (Rp 1.000.000)
└── widget/
    ├── splash_navigation_test.dart               # SplashScreen: navigasi ke /home, /login, /onboarding
    ├── transaction_date_test.dart                # TransactionFormScreen: validasi tanggal
    ├── transaction_selection_test.dart           # TransactionFormScreen: pilih tipe & kategori
    ├── home_quote_test.dart                      # HomeScreen: kutipan keuangan
    └── settings_reminder_test.dart              # SettingsScreen: toggle pengingat
```

---

## Build untuk Android

### Debug APK (untuk testing)

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK (untuk distribusi langsung)

```bash
flutter build apk --release --no-tree-shake-icons
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### App Bundle (untuk Play Store — direkomendasikan)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Signing untuk Release

1. Buat keystore:
   ```bash
   keytool -genkey -v -keystore ~/sakurapi-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias sakurapi
   ```

2. Buat file `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=sakurapi
   storeFile=<path>/sakurapi-key.jks
   ```

3. Update `android/app/build.gradle` untuk membaca `key.properties` (lihat dokumentasi Flutter signing).

4. Build:
   ```bash
   flutter build appbundle --release
   ```

---

## Build untuk iOS

Membutuhkan Mac dengan Xcode dan Apple Developer Account.

### Build IPA

```bash
# Pasang pods
cd ios && pod install && cd ..

# Build untuk device
flutter build ios --release

# Archive dan export lewat Xcode
open ios/Runner.xcworkspace
```

Di Xcode:
1. Pilih menu **Product → Archive**
2. Setelah archive selesai, pilih **Distribute App**
3. Pilih **App Store Connect** atau **Ad Hoc**

### Pastikan sebelum build iOS

- `CFBundleIdentifier` di `ios/Runner/Info.plist` sudah sesuai dengan Bundle ID di Apple Developer
- Provisioning Profile dan Certificate sudah terpasang di Xcode
- `CFBundleDisplayName` sudah diset ke "SakuRapi"
- `pod install` telah dijalankan setelah `flutter pub get`

---

## Firebase & Google Login

Firebase digunakan untuk fitur **Login Google**, **Login Email Link (passwordless)**, dan **sinkronisasi cloud Firestore realtime**.

> **Konfigurasi Firebase harus disesuaikan dengan project Firebase milik Anda sendiri.**
> Tanpa melengkapi setup di bawah, pengguna dapat menggunakan mode tamu dengan data lokal penuh.

### Package yang Digunakan

| Package | Fungsi |
|---------|--------|
| `firebase_core` | Inisialisasi Firebase SDK |
| `firebase_auth` | Autentikasi pengguna via Google (semua platform) |
| `google_sign_in` | Dialog pemilih akun Google (Android dan iOS saja) |
| `cloud_firestore` | Sinkronisasi data ke cloud |

### Cara Kerja Login Google — Per Platform

Login Google menggunakan alur yang **berbeda per platform** untuk menghindari masalah
idToken kosong yang sering terjadi jika `google_sign_in` digunakan di browser.

#### Web

```
Pengguna ketuk "Masuk dengan Google"
  └─ AuthService._signInWithGoogleWeb()
      └─ FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())
          ← popup browser native, OAuth dikelola penuh oleh Firebase SDK
          ← tidak menggunakan google_sign_in sama sekali
          ← tidak perlu idToken manual
      └─ UserCredential.user → _persistAndBuildUser()
      └─ SharedPreferences diperbarui (mode = 'google')
```

**Syarat:** Authorized JavaScript Origins di Google Cloud Console harus mencakup
URL yang digunakan (localhost:port untuk dev, domain produksi untuk prod).

#### Android / iOS

```
Pengguna ketuk "Masuk dengan Google"
  └─ AuthService._signInWithGoogleNative()
      └─ GoogleSignIn(serverClientId: _webClientId).signIn()
          ← dialog pemilih akun native Android/iOS
      └─ googleAccount.authentication → idToken (wajib)
      └─ GoogleAuthProvider.credential(idToken: ...) → FirebaseAuth.signInWithCredential()
      └─ UserCredential.user → _persistAndBuildUser()
      └─ SharedPreferences diperbarui (mode = 'google')
```

**Syarat:** SHA-1 fingerprint debug/release harus terdaftar di Firebase Console (Android).

### Cara Kerja Logout

**Google user:**
- Web    → `FirebaseAuth.instance.signOut()` saja (google_sign_in tidak digunakan di web)
- Native → `FirebaseAuth.instance.signOut()` + `GoogleSignIn.signOut()`
- SharedPreferences dibersihkan (id, name, email, mode)
- Data lokal SQLite tetap ada

**Guest user:**
- Tidak ada akun — Settings menampilkan "Akhiri Sesi Tamu" bukan "Keluar"
- Hanya SharedPreferences yang dibersihkan
- Data lokal SQLite tetap ada

### Migrasi Data Tamu ke Google

Pengguna tamu bisa upgrade ke Google tanpa kehilangan data:
1. Settings → Akun → **Masuk dengan Google**
2. `AuthNotifier.upgradeGuestToGoogle()` dipanggil:
   a. Login Google → SharedPreferences diperbarui (mode = 'google')
   b. State diperbarui ke `AsyncData(user)` **segera** → user tidak menunggu
   c. Background: `_migrateLocalDataToCloud()` + `restoreFromCloud()` berjalan di belakang
   d. `SyncService.migrateGuestData()` menggunakan **Firestore WriteBatch** (maks 500/batch)
      — jauh lebih cepat dari N sequential individual writes sebelumnya
3. Banner "Sedang memulihkan data..." muncul di HomeScreen selama proses berjalan

**Strategi merge (local wins):** Semua record di-batch-upsert ke Firestore berdasarkan ID.
Jika akun Google sudah punya data sebelumnya, record dengan ID sama di-overwrite; record
berbeda ditambahkan. Kegagalan migrasi bersifat non-fatal — data lokal tetap aman.

---

### Setup Android: SHA-1 (Langkah Wajib)

Google Sign-In pada Android **memerlukan SHA-1 fingerprint** terdaftar di Firebase Console.

#### Langkah 1 — Dapatkan SHA-1 Debug

**Windows:**
```cmd
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**macOS / Linux:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Salin nilai **SHA1** dari output (format: `XX:XX:XX:...:XX`).

#### Langkah 2 — Tambahkan SHA-1 di Firebase Console

1. Buka [console.firebase.google.com](https://console.firebase.google.com) → project Firebase Anda
2. **Project Settings** → tab **Your apps** → Android app
3. Klik **Add fingerprint** → paste nilai SHA-1 → **Save**

#### Langkah 3 — Download Ulang google-services.json

Setelah SHA-1 ditambahkan:
1. Di halaman yang sama klik **Download google-services.json**
2. Letakkan file baru di `android/app/google-services.json` (timpa yang lama)

#### Langkah 4 — Jalankan dan Test

```bash
flutter run
```

1. Ketuk **Masuk dengan Google** → dialog pemilih akun muncul
2. Pilih akun → masuk ke HomeScreen
3. Cek Firebase Console → Authentication → Users

> **Tanpa SHA-1**: tombol "Masuk dengan Google" menampilkan pesan error Bahasa Indonesia
> "Login Google belum siap. Periksa konfigurasi SHA-1..." — bukan dialog setup developer.

---

### Setup Web: Authorized JavaScript Origins & Web Client ID (Langkah Wajib)

Login Google di web menggunakan `FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())` —
**bukan** `google_sign_in`. Firebase SDK menangani OAuth popup secara penuh di browser.

#### Langkah 1 — Daftarkan Authorized Origins di Google Cloud Console

1. Buka [console.cloud.google.com](https://console.cloud.google.com) → pilih project Firebase Anda
2. **APIs & Services → Credentials → OAuth 2.0 Client IDs**
3. Klik Web Client yang auto-dibuat oleh Firebase (nama biasanya "Web client (auto created by Google Service)")
4. Di **Authorized JavaScript origins**, tambahkan:
   - `http://localhost` (mencakup semua port, atau gunakan `http://localhost:7357` jika ingin eksplisit)
   - `https://[domain-produksi-Anda]` ← (URL produksi jika ada)
5. Di **Authorized redirect URIs**, tambahkan:
   - `https://[PROJECT-ID].firebaseapp.com/__/auth/handler`
     (biasanya sudah ada — ini digunakan oleh signInWithPopup)
6. **Save** → tunggu 1–2 menit agar perubahan propagasi

#### Langkah 2 — Inject Web Client ID ke web/index.html

`web/index.html` berisi placeholder `YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com`
yang perlu diganti dengan nilai nyata sebelum menjalankan di browser.

> **Mengapa placeholder?** Web Client ID adalah public client config — bukan secret.
> Nilai ini tetap terlihat di source HTML yang dikirim ke browser setelah diisi.
> Placeholder digunakan hanya untuk menjaga kebersihan source yang di-commit.
> Gunakan `--dart-define` untuk native (Android/iOS); untuk web, gunakan skrip inject.

```bash
# Dapatkan Web Client ID dari Firebase Console → [Project Anda] →
# Project Settings → Web App → OAuth 2.0 client ID
# ATAU: Google Cloud Console → APIs & Services → Credentials → Web client

# Inject ke web/index.html
GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com bash scripts/inject_web_client_id.sh

# Jalankan — port tetap agar origin konsisten
flutter run -d chrome --web-hostname localhost --web-port 7357

# Kembalikan placeholder setelah selesai (agar tidak ter-commit)
git checkout web/index.html
```

Untuk CI/CD atau production build, jalankan inject script sebelum `flutter build web`:

```bash
GOOGLE_WEB_CLIENT_ID=$SECRET_FROM_CI bash scripts/inject_web_client_id.sh
flutter build web --release
```

> **Error `popup-blocked`:** Jika browser memblokir popup, pengguna akan melihat pesan
> Bahasa Indonesia yang meminta mereka mengizinkan popup untuk situs ini.

> **Error `popup-closed-by-user`:** Jika pengguna menutup popup sebelum selesai login,
> aplikasi menampilkan "Login dibatalkan." — bukan error teknis.

#### Konfigurasi Native (Android/iOS) — dart-define

Untuk native, `_webClientId` di `auth_service.dart` dibaca dari `--dart-define`:

```bash
# Development
flutter run \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com

# Build release
flutter build apk --release \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com

flutter build appbundle --release \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
```

Jika `--dart-define` tidak diberikan, `auth_service.dart` menggunakan placeholder default
dan native Google Sign-In akan gagal dengan error idToken null.

---

### Setup Firebase Console dari Awal

Setiap developer menggunakan project Firebase mereka sendiri. Jalankan:

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

Ini akan membuat `lib/firebase_options.dart` dengan konfigurasi project Firebase Anda.
Pastikan juga:
- **Authentication** → **Sign-in method** → aktifkan **Google**
- **Authentication** → **Sign-in method** → aktifkan **Email/Password** lalu sub-opsi **Email link (passwordless sign-in)**
- **Firestore Database** → buat database → region `asia-southeast2` (Jakarta)

---

### Konfigurasi Firestore Security Rules

Di **Firebase Console → Firestore → Rules**, terapkan rules berikut untuk produksi:

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

### Cara Kerja Sinkronisasi Firestore — Arsitektur 3 Lapisan

Sinkronisasi aktif untuk mode `google` dan `emailLink`. Mode tamu tidak sync.

#### Lapisan 1 — Upload Otomatis (fire-and-forget)

Setiap operasi tulis (insert/update/delete) di-sync ke Firestore via `unawaited()` — tidak memblokir UI:

```
Pengguna tambah transaksi
  └─ TransactionRepositoryImpl.insert()
      ├─ TransactionDao.insert() — tulis ke SQLite lokal (AWAIT)
      └─ SyncService.upsertTransaction() — kirim ke Firestore (fire & forget)

Pengguna bayar hutang
  └─ HutangRepositoryImpl.addPayment()
      ├─ HutangDao.insertPayment() — tulis ke payment_history lokal (AWAIT)
      └─ SyncService.upsertPaymentRecord() — kirim ke Firestore (fire & forget)

Pengguna buat kategori kustom
  └─ CategoryRepositoryImpl.insert()
      ├─ CategoryDao.insertCategory() — tulis ke categories lokal (AWAIT)
      └─ SyncService.upsertCategory() — kirim ke Firestore (fire & forget)
```

#### Lapisan 2 — Restore saat Login (background, one-time)

`CloudRestoreService.restoreFromCloud()` berjalan di background setelah login berhasil.
User sudah masuk ke home screen sebelum restore selesai.

**Urutan eksekusi penting** — jangan dibalik:

```
Login Google / Email Link berhasil
  └─ AuthNotifier.signInWithGoogle() / handleEmailLink()
      ├─ state = AsyncData(user)           ← NAVIGASI KE HOME SEGERA
      └─ [background] _restoreBackground()
          │
          ├─ LANGKAH 1: SyncService.syncAllLocalCategories()
          │     Upload semua kategori lokal → Firestore (termasuk default)
          │     WAJIB sebelum restore agar Firestore punya kategori lengkap
          │
          ├─ LANGKAH 2: CloudRestoreService.restoreFromCloud()  [pass 1]
          │     ├─ Future.wait([5 fetches]) ← PARALEL (hemat round-trip)
          │     ├─ categories    → INSERT OR IGNORE (kustom saja)
          │     ├─ transactions  → INSERT OR IGNORE + fallback categoryName
          │     │     Jika categoryId cloud tidak ada lokal → cari by (name|type)
          │     │     Jika masih tidak ada → catat di transactionsSkipped (bukan failures)
          │     ├─ hutang        → insert baru atau update jika cloud lebih baru
          │     ├─ piutang       → insert baru atau update jika cloud lebih baru
          │     └─ payment_history → INSERT OR IGNORE
          │
          └─ LANGKAH 3 (kondisional): retry jika result.transactionsSkipped > 0
                CloudRestoreService.restoreFromCloud()  [pass 2]
                Diperlukan saat "first login after bootstrap": pass 1 berjalan
                sebelum kategori terisi → transaksi terlewati. Pass 2 memastikan
                transaksi yang tertinggal dipulihkan tanpa perlu logout ulang.
```

**Perbedaan `transactionsSkipped` vs `failures`:**
- `transactionsSkipped` — kategori tidak ditemukan lokal (soft skip, dapat di-retry)
- `failures` — exception teknis saat menulis ke SQLite (hard error, tidak bisa di-retry)

**Semua error dicatat via `dev.log()` dengan `level: 900`** — tidak ada lagi `catch (_) {}`
yang menelan error secara diam-diam. Setiap kegagalan individual dicatat bersama ID dokumen
yang bermasalah, dan counter `failures` / `transactionsSkipped` dilaporkan di log akhir.

#### Lapisan 3 — Realtime Multi-Device Sync (persistent Firestore listeners)

`RealtimeSyncService` berlangganan ke 5 koleksi Firestore menggunakan `snapshots()`.
Perubahan dari perangkat lain → tulis langsung ke SQLite lokal → Drift stream → UI refresh otomatis.

```
Device B mengubah hutang
  └─ HutangRepositoryImpl.update() → SyncService.upsertHutang()
      └─ Firestore confirms write
          └─ Device A's listener fires (hasPendingWrites: false)
              └─ RealtimeSyncService._onHutangSnapshot()
                  └─ _upsertHutangFromCloud(): last-write-wins by updatedAt
                      └─ HutangDao.updateHutang() → SQLite updated
                          └─ Drift watchAll() emits → HutangListScreen refreshes

Pencegahan write-back loop:
  - includeMetadataChanges: true
  - hasPendingWrites == true → SKIP (echo dari tulisan lokal yg belum dikonfirmasi)
  - hasPendingWrites == false → PROSES (data dari server / perangkat lain)
```

**Strategi merge per koleksi (berlaku untuk Lapisan 2 dan 3):**

| Koleksi | added | modified | removed |
|---------|-------|----------|---------|
| `transactions` | INSERT OR IGNORE | INSERT OR REPLACE | DELETE |
| `categories` | INSERT OR IGNORE | INSERT OR REPLACE | DELETE |
| `hutang` | insert jika baru | last-write-wins by updatedAt | DELETE |
| `piutang` | insert jika baru | last-write-wins by updatedAt | DELETE |
| `payment_history` | INSERT OR IGNORE | INSERT OR IGNORE | DELETE |

**Timing log tersedia di dev console:**
- `[login] Auth selesai Xms — navigasi ke home segera`
- `[bg] Sinkronisasi N kategori lokal ke Firestore...`
- `[restore] Fetch selesai dalam Xms — N kategori, N tx, ...`
- `[bg] Restore pass 1 selesai — N kategori, N tx dipulihkan, N tx dilewati`
- `[bg] N tx dilewati — memulai retry pass 2...` ← hanya jika ada yang dilewati
- `[bg] Retry pass 2 selesai — N tx dipulihkan tambahan`
- `[RealtimeSyncService] Listener aktif untuk uid=xxx (5 koleksi)`

**Struktur data Firestore:**
```
users/{userId}/transactions/{txId}
users/{userId}/hutang/{hutangId}
users/{userId}/piutang/{piutangId}
users/{userId}/categories/{categoryId}     ← kustom saja (isDefault=false)
users/{userId}/payment_history/{paymentId} ← semua cicilan hutang dan piutang
```

**Yang TIDAK disinkronisasi:**
- Settings (payday date, pengaturan notifikasi) — device-specific, tidak perlu sync
- Kategori default (isDefault=true) — selalu ada via database seed
- Display name — dikelola Firebase Auth; otomatis tersedia saat login di perangkat baru

**Perilaku offline:**
- SQLite lokal tetap berfungsi penuh saat tidak ada internet
- SyncService.upsert*() gagal → diabaikan (data lokal aman)
- RealtimeSyncService listeners pause otomatis saat offline (Firestore SDK)
- Saat kembali online: Firestore SDK reconnect, listener menerima delta perubahan

---

### Panduan Testing Google Sign-In

#### Testing di Android

```bash
# 1. Pastikan SHA-1 sudah terdaftar (lihat setup di atas)
# 2. Jalankan di emulator atau device fisik
flutter run

# 3. Alur test:
#    a. Ketuk "Masuk sebagai Tamu" → masuk HomeScreen → tambah beberapa transaksi
#    b. Buka Settings → ketuk "Masuk dengan Google" → pilih akun
#    c. Verifikasi: data tamu masih ada + kini ter-sync ke cloud
#    d. Cek Firebase Console → Authentication → Users (akun baru muncul)
#    e. Cek Firebase Console → Firestore → users/{uid}/transactions (data tamu diunggah)
#    f. Ketuk "Keluar" → kembali ke login screen
#    g. Login Google lagi → data harus tetap ada
```

#### Testing di Web

```bash
# 1. Pastikan http://localhost:7357 sudah ada di Authorized JavaScript Origins
# 2. Jalankan web dev server dengan port tetap (WAJIB)
flutter run -d chrome --web-hostname localhost --web-port 7357

# 3. Alur test:
#    a. Mode Tamu: tambah transaksi → berfungsi normal
#    b. Login Google: klik "Masuk dengan Google" → popup GIS muncul → pilih akun
#    c. Verifikasi: login berhasil, data lokal ter-migrasi ke Firestore
#    d. Logout: Settings → Keluar → kembali ke login screen
```

#### Testing Migrasi Tamu ke Google

```bash
# 1. Login sebagai tamu → tambah beberapa transaksi, hutang, piutang
# 2. Buka Settings → Akun → "Masuk dengan Google"
# 3. Pilih akun Google di popup
# 4. Verifikasi:
#    - SnackBar: "Login Google berhasil! Data kamu sudah disinkronkan ke cloud."
#    - Settings → Akun sekarang menampilkan nama Google + status "Data dicadangkan ke cloud"
#    - Firebase Console → Firestore → users/{uid}: data tamu sudah ada
# 5. Keluar → login sebagai tamu lagi dengan UUID baru → data Google tidak hilang
```

---

## Strategi Testing

### Level Test yang Ada

| Tipe | Coverage | Fokus |
|------|----------|-------|
| Unit | Domain entities, kalkulasi bisnis | Prioritas tinggi |
| Widget | Form validasi, empty state, navigasi | Prioritas menengah |
| Integration | Alur lengkap end-to-end | Manual testing |

### Prinsip Testing

1. **Unit test murni** — test entity dan domain logic tanpa database (tidak ada Drift, tidak ada SharedPreferences)
2. **Widget test dengan fake repository** — Screen menggunakan implementasi in-memory dari interface domain:
   - Fake repository didefinisikan langsung di file test sebagai private class (e.g. `_FakeCategoryRepo`)
   - Provider di-override lewat `ProviderScope(overrides: [categoryRepositoryProvider.overrideWithValue(...)])`
   - **Tidak ada instance Drift yang dibuat** → tidak ada warning "AppDatabase dibuat lebih dari sekali"
3. **Manual test** untuk notifikasi (sulit di-automate karena bergantung pada scheduler OS)
4. **Manual test** untuk Google Sign-In (bergantung pada Firebase dan akun Google nyata)

### Test yang Perlu Ditambah ke Depan

- Widget test untuk `HutangFormScreen` (validasi jumlah dan nama kreditur)
- Widget test untuk `PiutangFormScreen`
- Widget test untuk `TransactionFormScreen` dengan kategori "Pembayaran Hutang" (dropdown hutang aktif)
- Integration test alur lengkap: tambah hutang → bayar sebagian → tandai lunas → cek laporan

---

## Checklist Sebelum Deploy

### Umum

- [ ] `flutter analyze` tidak ada error
- [ ] `flutter test` semua pass
- [ ] `dart run build_runner build` berhasil tanpa error
- [ ] Tidak ada string hardcode di widget (semua dari `app_strings.dart`)
- [ ] Tidak ada warna hardcode di widget (semua dari `app_colors.dart`)
- [ ] `pubspec.yaml`: version sudah diupdate (format: `1.0.0+1`)

### Android

- [ ] `android/app/build.gradle`: `versionCode` dan `versionName` sudah diupdate
- [ ] `android/app/src/main/AndroidManifest.xml`: `android:label="SakuRapi"`
- [ ] Keystore sudah dibuat dan `key.properties` sudah dikonfigurasi
- [ ] Build dengan `flutter build appbundle --release` berhasil
- [ ] Test di minimal 2 device berbeda (small screen + normal)
- [ ] Test di Android 10, 12, dan 14

### iOS

- [ ] `ios/Runner/Info.plist`: `CFBundleDisplayName` dan `CFBundleName` = "SakuRapi"
- [ ] Bundle ID sudah dikonfigurasi di Xcode dan sesuai dengan Apple Developer
- [ ] Provisioning profile valid
- [ ] `pod install` berhasil
- [ ] Build di Xcode berhasil tanpa warning penting
- [ ] Test di minimal iPhone SE dan iPhone 15

### Fungsional (Manual Test)

- [ ] Onboarding 4 halaman berjalan normal, izin notifikasi diminta
- [ ] Login sebagai tamu berhasil, langsung masuk HomeScreen
- [ ] Tambah/edit/hapus transaksi (pemasukan dan pengeluaran)
- [ ] Laporan harian, bulanan, tahunan menampilkan data yang benar
- [ ] Siklus gajian: ganti tanggal gaji, cek laporan berubah
- [ ] Tambah hutang → bayar sebagian → saldo berkurang → cek laporan → tandai lunas
- [ ] Bayar hutang via TransactionFormScreen (pilih kategori "Pembayaran Hutang") → dropdown hutang aktif muncul
- [ ] Tambah piutang → saldo berkurang otomatis → cek laporan
- [ ] Terima cicilan piutang → saldo bertambah → tandai lunas saat sisa = 0
- [ ] Laporan Hutang dan Laporan Piutang menampilkan data yang benar
- [ ] Ekspor CSV: file terbuka dan dapat dibaca
- [ ] Impor CSV: data masuk dengan benar
- [ ] Notifikasi: aktifkan, tunggu waktu yang ditentukan (atau ubah ke 1 menit dari sekarang untuk test)
- [ ] Settings: simpan payday date, berubah di laporan siklus gajian
- [ ] Logout: kembali ke login screen, sesi bersih

### Firebase — Android

- [ ] SHA-1 debug fingerprint ditambahkan di Firebase Console → Android app
- [ ] `google-services.json` (terbaru) ada di `android/app/`
- [x] `android/settings.gradle.kts` — Google Services plugin aktif
- [x] `android/app/build.gradle.kts` — Google Services plugin aktif
- [ ] `lib/firebase_options.dart` — buat dari `lib/firebase_options.example.dart` atau `flutterfire configure`
- [ ] Login Google berhasil di Android — akun muncul di Firebase Console → Authentication
- [ ] Data tersinkronisasi ke Firestore setelah login Google

### Firebase — iOS

- [ ] `GoogleService-Info.plist` ada di `ios/Runner/`
- [ ] Bundle ID di `Info.plist` cocok dengan yang terdaftar di Firebase Console
- [ ] Login Google berhasil di iOS

### Firebase — Web

- [ ] `http://localhost:7357` sudah ada di Authorized JavaScript Origins (Google Cloud Console)
- [ ] URL produksi sudah ada di Authorized JavaScript Origins
- [ ] Login Google berhasil di Chrome (`flutter run -d chrome --web-hostname localhost --web-port 7357`)
- [ ] GIS popup muncul, bukan error "origin not allowed"
- [ ] `idToken` tidak kosong — cek DevTools Console untuk log `AuthService.signInWithGoogle`

### Firebase — Umum

- [ ] Authentication → Google provider diaktifkan di Firebase Console
- [ ] Firestore Database dibuat dengan mode production
- [ ] Firestore Security Rules diterapkan (hanya user sendiri bisa baca/tulis)
- [ ] Logout Google → data lokal tetap ada, sesi Firebase dibersihkan
- [ ] Logout tamu → kembali ke login, data lokal tetap ada
- [ ] Migrasi tamu ke Google → data lokal muncul di Firestore setelah upgrade

---

## Troubleshooting Umum

### Error: "Could not find the generated part"

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Error: "Gradle build failed"

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### Error: "CocoaPods not found" (iOS)

```bash
sudo gem install cocoapods
cd ios && pod install
```

### Notifikasi tidak muncul di Android 13+

- Pastikan izin `POST_NOTIFICATIONS` sudah diminta di onboarding
- Cek `AndroidManifest.xml` sudah ada:
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  ```

### Database error setelah update skema

```bash
# Uninstall app dari device/emulator (data lama terhapus)
# Kemudian install ulang:
flutter run
```

Atau tambahkan migrasi yang benar di `app_database.dart` tanpa uninstall.
**Schema version saat ini: 4** (lihat tabel migrasi di `CODEBASE_HANDOVER.md`).

### App tidak muncul di lock screen notification (iOS)

- Pastikan izin notifikasi sudah diizinkan user di Settings perangkat
- Cek `Info.plist` punya entry `UIBackgroundModes` dengan `remote-notification`

### Error "Firebase not initialized"

- Pastikan `google-services.json` sinkron (download ulang dari Firebase Console setelah menambahkan SHA-1)
- Pastikan `google-services.json` ada di `android/app/`
- Jalankan `flutter clean && flutter pub get` lalu build ulang

### Google Sign-In gagal "PlatformException: sign_in_failed" atau "ApiException: 10" (Android)

Ini adalah error paling umum di Android. Penyebab dan solusinya:

1. **SHA-1 belum terdaftar** — penyebab paling sering:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   Salin SHA-1 → Firebase Console → Project Settings → Android app → Add fingerprint.

2. **`google-services.json` tidak sinkron** — download ulang dari Firebase Console
   setelah menambahkan SHA-1, lalu replace `android/app/google-services.json`.

3. **Plugin Google Services belum diaktifkan** — pastikan baris di
   `android/settings.gradle.kts` dan `android/app/build.gradle.kts` sudah di-uncomment.

4. **OAuth consent screen belum dikonfigurasi** — di Google Cloud Console
   pastikan consent screen sudah disetup dan test user ditambahkan jika masih dalam
   mode "Testing".

### Google Sign-In gagal di Web — `idToken` kosong atau popup tertutup

1. **Port tidak tetap** — penyebab paling sering `idToken` kosong:
   - GIS mencocokkan origin secara eksplisit; port acak tidak cocok.
   - Selalu jalankan: `flutter run -d chrome --web-hostname localhost --web-port 7357`
   - Pastikan `http://localhost:7357` (bukan `http://localhost`) ada di Authorized JavaScript Origins.

2. **Authorized JavaScript origins belum dikonfigurasi atau salah**:
   - Buka Google Cloud Console → APIs & Services → Credentials → Web Client
   - Tambahkan `http://localhost:7357` → Simpan → tunggu 1–2 menit → coba lagi

3. **Error assertion "appClientId != null"** — Web Client ID tidak terbaca oleh plugin:
   - `web/index.html` berisi placeholder, bukan nilai nyata. Inject terlebih dahulu:
     ```bash
     GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com bash scripts/inject_web_client_id.sh
     ```
   - Dapatkan nilai nyata dari Firebase Console → [Project Anda] → Project Settings → Web App → Web Client ID
   - Setelah inject, jalankan: `flutter clean && flutter run -d chrome --web-hostname localhost --web-port 7357`

4. **`accessToken` null di web adalah normal** — jangan treat ini sebagai error.
   GIS hanya menjamin `idToken`. Kode sudah menghandle ini dengan benar.

### Google Sign-In error "sign_in_cancelled"

Pengguna menutup dialog pemilih akun. Ini bukan error — aplikasi akan kembali ke
layar login dengan pesan "Login dibatalkan".

---

*Dokumen ini terakhir diperbarui: 26 April 2026 — refactor Web Client ID: placeholder di web/index.html, inject via scripts/inject_web_client_id.sh, --dart-define untuk native*
