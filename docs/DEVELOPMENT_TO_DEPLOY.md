# DompetKu — Panduan Development hingga Deploy

> Flutter 3.41.6+ · Dart 3.7.0+ · Android · iOS · Web · Offline-first

---

## Daftar Isi

1. [Prasyarat](#1-prasyarat)
2. [Pengaturan Proyek](#2-pengaturan-proyek)
3. [Menjalankan Aplikasi](#3-menjalankan-aplikasi)
4. [Pembuatan Kode (Drift)](#4-pembuatan-kode-drift)
5. [Menjalankan Pengujian](#5-menjalankan-pengujian)
6. [Build & Rilis Android](#6-build--rilis-android)
7. [Build & Rilis iOS](#7-build--rilis-ios)
8. [Build & Deploy Web](#8-build--deploy-web)
9. [Daftar Periksa Lingkungan Sebelum Rilis](#9-daftar-periksa-lingkungan-sebelum-rilis)
10. [Pemecahan Masalah](#10-pemecahan-masalah)

---

## 1. Prasyarat

| Alat | Versi Minimum | Keterangan |
|------|----------------|-------|
| Flutter SDK | 3.41.6 (stable) | `flutter upgrade` untuk memperbarui |
| Dart SDK | 3.7.0+ | Sudah termasuk dalam Flutter |
| Android Studio | 2024.x | Untuk emulator Android dan penandatanganan |
| JDK | 17 | Diperlukan oleh Gradle |
| Git | Versi apapun | Untuk kontrol versi |
| Xcode | 16.x | **Hanya macOS** — untuk build iOS |
| CocoaPods | Terbaru | **Hanya macOS** — `sudo gem install cocoapods` |

Periksa lingkungan:

```bash
flutter doctor -v
```

Semua tanda centang harus berwarna hijau. Hambatan yang paling umum adalah lisensi Android yang belum diterima.

Terima lisensi Android jika belum dilakukan:

```bash
flutter doctor --android-licenses
```

---

## 2. Pengaturan Proyek

### Clone dan instal dependensi

```bash
git clone <url-repo>
cd project_ai_claude_apk_android_ios
flutter pub get
```

### Struktur direktori

```
project_ai_claude_apk_android_ios/
├── android/                    # Kode platform Android
│   └── app/
│       ├── build.gradle.kts    # Konfigurasi Gradle (applicationId, SDK version, signing)
│       └── src/main/
│           └── AndroidManifest.xml
├── ios/                        # Kode platform iOS
│   └── Runner/
│       ├── AppDelegate.swift
│       └── Info.plist
├── web/                        # Kode platform Web
│   ├── index.html              # HTML entry point
│   └── manifest.json           # PWA manifest
├── lib/                        # Semua kode sumber Dart
├── test/                       # Unit test dan widget test
├── docs/                       # Folder ini
├── assets/
│   └── images/                 # SVG dan PNG aset aplikasi
├── pubspec.yaml
└── pubspec.lock
```

### Aset

Direktori `assets/images/` terdaftar di `pubspec.yaml`. File yang disertakan:

| File | Digunakan di |
|------|---------|
| `logo.svg` | Layar splash (logo dalam container putih) |
| `app_icon.png` | Ikon launcher aplikasi (1024×1024 PNG) |
| `onboarding_wallet.svg` | Halaman onboarding 1 |
| `onboarding_chart.svg` | Halaman onboarding 2 |
| `onboarding_calendar.svg` | Halaman onboarding 3 |
| `empty_transactions.svg` | Status kosong di daftar transaksi dan beranda |
| `empty_reports.svg` | Status kosong di semua 5 tab laporan |

SVG dirender dengan `flutter_svg ^2.0.10+1`. Mereka dapat diskalakan ke kepadatan layar mana pun tanpa kehilangan kualitas.

### Ikon aplikasi

Ikon launcher kustom sudah dikonfigurasi di `pubspec.yaml` via `flutter_launcher_icons`. Untuk menghasilkan ulang ikon (misalnya setelah mengganti `app_icon.png`):

```bash
dart run flutter_launcher_icons
```

Perintah ini menimpa folder `android/app/src/main/res/mipmap-*` dan `ios/Runner/Assets.xcassets/AppIcon.appiconset` secara otomatis.

Konfigurasi saat ini (`pubspec.yaml`):
- Sumber: `assets/images/app_icon.png` (1024×1024)
- Warna latar adaptif Android: `#1565C0` (sesuai `AppColors.primary`)
- Target: Android SDK 21+ dan iOS

---

## 3. Menjalankan Aplikasi

### Hot reload (pengembangan)

```bash
# Daftar perangkat yang terhubung
flutter devices

# Jalankan di perangkat tertentu
flutter run -d <device-id>

# Jalankan di Chrome (web)
flutter run -d chrome --no-tree-shake-icons
```

### Mode debug/release/profile

```bash
# Debug (default — hot reload, DevTools)
flutter run

# Release (tanpa hot reload, dioptimalkan)
flutter run --release --no-tree-shake-icons

# Profile (performa release + pelacakan DevTools)
flutter run --profile --no-tree-shake-icons
```

> **`--no-tree-shake-icons`**: Flag ini diperlukan karena `IconData` untuk ikon kategori diambil secara dinamis dari database sebagai nilai integer. Flutter tidak bisa menentukan ikon mana yang digunakan saat compile time, sehingga tree-shaking perlu dinonaktifkan agar ikon Material tidak dihilangkan dari binary.

### Flutter DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 4. Pembuatan Kode (Drift)

Lapisan database menggunakan [Drift](https://drift.simonbinder.eu/) dengan pembuatan kode. File yang dibuat otomatis (`*.g.dart`) di-commit ke repo — Anda biasanya tidak perlu membuatnya ulang kecuali jika mengubah skema.

### Kapan perlu dijalankan ulang

- Menambahkan kolom baru ke `CategoriesTable` atau `TransactionsTable`
- Menambahkan metode DAO baru dengan anotasi `@Query`
- Menambahkan tabel baru ke `AppDatabase`

### Cara menjalankan

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Mode watch (selama pengembangan aktif)

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### File yang dibuat otomatis

| Sumber | Hasil Pembuatan |
|--------|-----------|
| `lib/data/database/app_database.dart` | `app_database.g.dart` |
| `lib/data/database/daos/category_dao.dart` | `category_dao.g.dart` |
| `lib/data/database/daos/transaction_dao.dart` | `transaction_dao.g.dart` |

> **Penting:** Jangan pernah mengedit file `*.g.dart` secara manual. File tersebut akan ditimpa setiap kali `build_runner` dijalankan.

### Migrasi skema

Versi skema saat ini adalah **1** (`AppDatabase.schemaVersion`). Ketika Anda mengubah skema:

1. Naikkan `schemaVersion` di `app_database.dart`
2. Tambahkan langkah migrasi di `MigrationStrategy.onUpgrade`
3. Jalankan ulang `build_runner`

Contoh migrasi:

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
    await _seedDefaultCategories();
  },
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(transactionsTable, transactionsTable.someNewColumn);
    }
  },
);
```

---

## 5. Menjalankan Pengujian

### Semua unit test

```bash
flutter test test/unit/
```

### File pengujian tunggal

```bash
flutter test test/unit/usecases/payday_cycle_test.dart
```

### Dengan cakupan kode

```bash
flutter test --coverage
# Lihat laporan HTML (memerlukan lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### File pengujian

| File | Yang Diuji |
|------|--------------|
| `test/unit/usecases/payday_cycle_test.dart` | `AppDateUtils.getPaydayCycle` — 11 kasus batas termasuk pergantian tahun, pemotongan Februari, dan tahun kabisat |
| `test/unit/usecases/summary_calculation_test.dart` | `SummaryResult.fromTransactions` — agregasi pemasukan/pengeluaran, peta kategori |
| `test/unit/utils/date_utils_test.dart` | `clampToMonth`, konstruktor rentang tanggal |
| `test/unit/utils/currency_formatter_test.dart` | Format dan parsing IDR |
| `test/widget/transaction_date_test.dart` | Form transaksi menerima tanggal masa lalu dan masa depan; `lastDate` picker adalah tahun 2100 |
| `test/widget/transaction_selection_test.dart` | Long-press masuk mode multi-select; checkbox; jumlah item terpilih; dialog hapus massal; batal pilih |
| `test/widget/home_quote_test.dart` | Daftar kutipan tidak kosong; `todayIndex` dalam batas; wrapping indeks; interval rotasi 8 detik |
| `test/widget/settings_reminder_test.dart` | UI pengingat — toggle dan konfigurasi waktu |
| `test/widget/splash_navigation_test.dart` | Routing splash → onboarding / home |

**Jumlah pengujian: 91 pengujian, 0 kegagalan.**

---

## 6. Build & Rilis Android

### Langkah 1 — Buat keystore (hanya pertama kali)

```bash
keytool -genkey -v \
  -keystore ~/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Simpan `upload-keystore.jks` dan kata sandinya di tempat yang aman.  
**Jangan pernah meng-commit keystore ke Git.** File ini sudah ada di `.gitignore`.

### Langkah 2 — Konfigurasi penandatanganan

Buat `android/key.properties` (file ini di-`.gitignore`):

```properties
storePassword=<kata-sandi-store-Anda>
keyPassword=<kata-sandi-kunci-Anda>
keyAlias=upload
storeFile=<jalur-absolut-ke>/upload-keystore.jks
```

Ubah `android/app/build.gradle.kts` untuk membaca `key.properties`. Tambahkan di bagian atas file (sebelum blok `android {}`):

```kotlin
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
```

Kemudian ubah blok `buildTypes` untuk menggunakan signing config release:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String?
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

### Langkah 3 — Build

```bash
# APK untuk instalasi langsung / pengujian
flutter build apk --release --no-tree-shake-icons

# APK dipisah per ABI (ukuran lebih kecil)
flutter build apk --split-per-abi --release --no-tree-shake-icons

# AAB untuk Google Play Store (direkomendasikan)
flutter build appbundle --release --no-tree-shake-icons
```

### Lokasi output

| Tipe Build | Lokasi Output |
|------------|---------------|
| APK universal | `build/app/outputs/flutter-apk/app-release.apk` |
| APK arm64 | `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` |
| APK armeabi | `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` |
| AAB | `build/app/outputs/bundle/release/app-release.aab` |

### Langkah 4 — Upload ke Play Store

1. Buat aplikasi di [Google Play Console](https://play.google.com/console)
2. Isi daftar toko (nama, deskripsi, screenshot)
3. Buka **Production → Create new release**
4. Upload file `.aab`
5. Kirim untuk ditinjau

### Persyaratan SDK

| Pengaturan | Nilai |
|---------|-------|
| `minSdkVersion` | 21 (Android 5.0 Lollipop) |
| `targetSdkVersion` | 34 |
| `compileSdkVersion` | 35 |
| `applicationId` | `com.financetracker.finance_tracker` |

> Ganti `applicationId` dengan ID aplikasi Anda sendiri sebelum publish ke Play Store.

### Catatan notifikasi Android

Aplikasi mendukung pengingat yang dijadwalkan pada hari dan jam tertentu menggunakan `zonedSchedule` dengan `DateTimeComponents.dayOfWeekAndTime`. Pada **Android 12+**, pengguna mungkin perlu memberikan izin `SCHEDULE_EXACT_ALARM`. Aplikasi meminta `POST_NOTIFICATIONS` saat runtime pada Android 13+. Keduanya ditangani secara otomatis oleh `NotificationService.requestPermission()`.

---

## 7. Build & Rilis iOS

> **PENTING: Build iOS hanya dapat dilakukan di macOS dengan Xcode 16+ terpasang.**  
> Tidak ada cara yang sah untuk build iOS dari Windows. Semua perintah di bagian ini  
> harus dijalankan di mesin macOS.

### Langkah 1 — Setup proyek Xcode (di macOS)

```bash
cd ios
pod install
open Runner.xcworkspace
```

Di Xcode:
- Tetapkan **Bundle Identifier** ke ID aplikasi Anda (mis., `com.yourname.dompetku`)
- Tetapkan **Development Team** (memerlukan akun Apple Developer)
- Tetapkan **Deployment Target** ke minimum iOS 13.0

### Langkah 2 — Capabilities (di Xcode)

Di Xcode → Runner → Signing & Capabilities, tambahkan:
- **Push Notifications** (diperlukan untuk `flutter_local_notifications`)
- **Background Modes** → centang **Background fetch** dan **Remote notifications**

### Langkah 3 — Entri Info.plist yang diperlukan

Tambahkan ke `ios/Runner/Info.plist` jika belum ada:

```xml
<!-- Untuk file_picker di iOS 11+ -->
<key>UISupportsDocumentBrowser</key>
<true/>

<!-- Untuk share_plus -->
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

### Langkah 4 — Build (di macOS)

```bash
# Build tanpa codesign — untuk CI atau testing
flutter build ios --release --no-codesign --no-tree-shake-icons

# Build IPA — untuk App Store (memerlukan akun Apple Developer)
flutter build ipa --release --no-tree-shake-icons
```

### Lokasi output

| Tipe Build | Lokasi Output |
|------------|---------------|
| IPA | `build/ios/ipa/DompetKu.ipa` |
| Framework | `build/ios/iphoneos/Runner.app` |

### Langkah 5 — Upload ke App Store

1. Buka **Xcode → Product → Archive**
2. Atau gunakan `xcrun altool` atau [Transporter](https://apps.apple.com/app/transporter/id1450874784)
3. Kirim melalui [App Store Connect](https://appstoreconnect.apple.com)

### Catatan untuk CI/CD

Jika Anda ingin build iOS otomatis tanpa mesin macOS fisik, gunakan layanan seperti:
- [Codemagic](https://codemagic.io) — mendukung Flutter, gratis untuk tier terbatas
- [Bitrise](https://bitrise.io) — mendukung Flutter iOS
- GitHub Actions dengan `macos-latest` runner

---

## 8. Build & Deploy Web

### Arsitektur Web

Proyek ini mendukung penuh kompilasi ke web dengan:

- **Database**: SQLite dikompilasi ke WebAssembly (`sqlite3.wasm`) + drift worker (`drift_worker.js`) untuk akses database multi-tab. Data disimpan secara persisten di browser menggunakan OPFS (Origin Private File System) atau IndexedDB sebagai fallback — data tidak hilang saat halaman di-refresh.
- **Ekspor CSV**: Menggunakan `dart:js_interop` + `package:web` untuk memicu unduhan file di browser.
- **Impor CSV**: `file_picker` mendukung web — membuka dialog file browser dan mengembalikan bytes.
- **Notifikasi**: Tidak tersedia di web. Toggle notifikasi dinonaktifkan otomatis dengan pesan yang sesuai.

### File web yang diperlukan

Dua file statik harus ada di folder `web/` sebelum build:

| File | Deskripsi |
|------|-----------|
| `web/sqlite3.wasm` | SQLite dikompilasi ke WebAssembly |
| `web/drift_worker.js` | Drift shared-worker untuk sinkronisasi multi-tab |

File-file ini sudah disertakan di repo. Jika perlu diperbarui (setelah upgrade drift/sqlite3):

```bash
# Salin sqlite3.wasm dari build devtools drift
cp "$HOME/.pub-cache/hosted/pub.dev/drift-X.Y.Z/extension/devtools/build/sqlite3.wasm" web/

# Kompilasi ulang drift_worker.js
# Buat file worker.dart sementara:
echo "import 'package:drift/wasm.dart'; void main() { WasmDatabase.workerMainForOpen(); }" > /tmp/worker.dart
dart compile js /tmp/worker.dart -o web/drift_worker.js -O2
```

### Jalankan di browser

```bash
flutter run -d chrome --no-tree-shake-icons
```

### Build untuk produksi

```bash
flutter build web --release --no-tree-shake-icons
```

Output: seluruh isi folder `build/web/`

> **Tip WASM**: Tambahkan flag `--wasm` untuk mengkompilasi aplikasi itu sendiri ke WebAssembly (bukan hanya database). Ini menghasilkan performa lebih tinggi tapi memerlukan browser yang mendukung WasmGC (Chrome 119+, Firefox 120+).

### Deploy ke hosting statis

Upload seluruh isi folder `build/web/` ke layanan hosting statis pilihan Anda:

```bash
# Contoh: Firebase Hosting
firebase deploy --only hosting

# Contoh: Netlify
netlify deploy --prod --dir=build/web

# Contoh: GitHub Pages
# Upload isi build/web/ ke branch gh-pages
```

### Header COOP/COEP (opsional, untuk performa terbaik)

Untuk mengaktifkan mode SharedArrayBuffer (WASM multi-threaded), server harus mengirim:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Tanpa header ini, drift secara otomatis fallback ke mode WASM single-threaded yang tetap berfungsi normal (hanya sedikit lebih lambat untuk query besar).

**Firebase Hosting** — tambahkan ke `firebase.json`:

```json
{
  "hosting": {
    "headers": [{
      "source": "**",
      "headers": [
        { "key": "Cross-Origin-Opener-Policy", "value": "same-origin" },
        { "key": "Cross-Origin-Embedder-Policy", "value": "require-corp" }
      ]
    }]
  }
}
```

### Keterbatasan web yang diketahui

| Fitur | Android/iOS | Web |
|-------|-------------|-----|
| Database | SQLite persisten (file lokal) | WASM SQLite persisten (IndexedDB/OPFS) |
| Notifikasi pengingat | Didukung penuh | **Tidak tersedia** — toggle dinonaktifkan |
| Izin sistem | Didukung | **Tidak tersedia** |
| Ekspor CSV | Share sheet native | Unduhan file browser |
| Impor CSV | File picker native | File picker browser |
| Semua fitur UI | Penuh | **Penuh** |

---

## 9. Daftar Periksa Lingkungan Sebelum Rilis

Jalankan daftar ini sebelum setiap rilis produksi:

- [ ] Semua unit test lulus: `flutter test test/unit/`
- [ ] Tidak ada masalah analyzer: `dart analyze lib/`
- [ ] Versi sudah dinaikkan di `pubspec.yaml` (`version: X.Y.Z+buildNumber`)
- [ ] Catatan rilis atau `CHANGELOG.md` sudah disiapkan
- [ ] Nama aplikasi adalah `DompetKu` (bukan `finance_tracker`) — verifikasi di `AndroidManifest.xml` dan Xcode
- [ ] `applicationId` sudah diubah dari `com.financetracker.finance_tracker` ke ID Anda sendiri (sebelum publish)
- [ ] Keystore / sertifikat penandatanganan tersedia dan kata sandi sudah dikonfirmasi
- [ ] `flutter clean && flutter pub get` untuk memastikan build yang bersih
- [ ] Diuji di perangkat nyata (bukan hanya emulator) — Android minimum, iOS jika tersedia
- [ ] Alur notifikasi: aktifkan pengingat, pilih jam dan hari, verifikasi muncul di waktu yang ditentukan
- [ ] Alur ekspor/impor CSV berfungsi dengan benar
- [ ] Onboarding pertama kali berjalan dengan benar (uninstall/reinstall untuk menguji)
- [ ] Tidak ada banner debug atau `debugPrint` yang tersisa di kode release

### Perintah kenaikan versi

```bash
# Edit pubspec.yaml: version: 1.1.0+2
# Kemudian:
flutter build appbundle --release --no-tree-shake-icons
```

---

## 10. Pemecahan Masalah

### `MissingPluginException` pada notifikasi

```bash
flutter clean && flutter pub get && flutter run
```

Ini biasanya terjadi setelah menambahkan plugin tanpa rebuild penuh.

### `InvalidDataException` Drift saat startup

Skema database berubah tetapi `schemaVersion` tidak dinaikkan. Naikkan versinya (dengan migrasi) atau hapus data aplikasi di perangkat untuk memicu `onCreate`.

### Konflik `build_runner`

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Build Gradle gagal dengan "License not accepted"

```bash
flutter doctor --android-licenses
```

### `CocoaPods` tidak ditemukan (iOS, macOS saja)

```bash
sudo gem install cocoapods
cd ios && pod install
```

### Notifikasi tidak muncul di Android 12+

Perangkat mungkin telah mencabut izin alarm eksak. Arahkan pengguna ke:  
**Pengaturan → Aplikasi → DompetKu → Alarm & Pengingat → Izinkan**

Sebagai alternatif, ubah ke `AndroidScheduleMode.inexactAllowWhileIdle` di `NotificationService` jika ketepatan waktu tidak kritis.

### Notifikasi tidak muncul di Android 13+

Pastikan izin `POST_NOTIFICATIONS` diberikan. Ini diminta secara otomatis saat pengguna mengaktifkan pengingat di layar Pengaturan.

### Impor CSV gagal secara diam-diam

Impor mengharapkan header persis: `Tanggal,Tipe,Jumlah,Kategori,Catatan`. Jika file diedit di Excel, karakter BOM atau akhir baris CRLF dapat merusak parsing. Simpan ulang dalam format UTF-8 tanpa BOM menggunakan teks editor.

### Ikon kategori tidak muncul di release build

Tambahkan flag `--no-tree-shake-icons` ke perintah build. Ikon diambil secara dinamis dari database sebagai nilai integer, sehingga Flutter's tree-shaking tidak dapat mendeteksinya.

### Web: app crash atau tidak bisa buka

Pastikan menggunakan flag `--no-tree-shake-icons`:

```bash
flutter run -d chrome --no-tree-shake-icons
```

### Web: data hilang setelah refresh halaman

Ini adalah perilaku yang diharapkan. Database web menggunakan in-memory SQLite tanpa persistensi. Untuk persistensi di web, diperlukan implementasi WASM/IndexedDB yang belum ada di proyek ini.
