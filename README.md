# DompetKu — Aplikasi Pencatat Keuangan Pribadi

Aplikasi pencatat keuangan pribadi yang modern, lengkap, dan sepenuhnya offline. Dibangun dengan Flutter untuk Android, iOS, dan Web.

---

## Fitur Utama

- Pencatatan pemasukan dan pengeluaran, tanggal bebas dipilih (masa lalu maupun masa depan)
- 15 kategori bawaan (10 pengeluaran + 5 pemasukan), dapat dikembangkan
- Hapus massal transaksi — long-press untuk masuk mode multi-select, centang beberapa item, hapus sekaligus
- Laporan dalam 5 rentang waktu: Harian · Bulanan · Tahunan · Rentang Tanggal · Siklus Gajian
- Ringkasan hari ini di layar beranda
- Pengingat harian yang dapat dikonfigurasi (jam + hari dalam seminggu)
- Kutipan keuangan motivasi berputar otomatis setiap 8 detik di beranda (30 kutipan, tanpa jaringan)
- Ekspor dan impor data dalam format CSV
- UI modern dan ramah pengguna dalam Bahasa Indonesia
- Sepenuhnya offline — tidak ada akun, tidak ada backend, tidak ada risiko privasi

---

## Screenshot

> *Tambahkan screenshot aplikasi di sini setelah ada perangkat fisik atau emulator yang siap.*

---

## Tech Stack

| Lapisan | Teknologi |
|---------|-----------|
| Framework | Flutter 3.41.6+ / Dart 3.7.0+ |
| State Management | flutter_riverpod 2.x (tanpa code generation) |
| Navigasi | go_router 14.x (ShellRoute untuk navigasi tab) |
| Database | Drift 2.x + SQLite (drift_flutter) |
| Persistensi Pengaturan | shared_preferences |
| Notifikasi | flutter_local_notifications 17.x + timezone |
| Grafik | fl_chart |
| UI | google_fonts (Poppins) + flutter_svg |
| Ekspor/Impor | csv + share_plus + file_picker |

---

## Arsitektur

Proyek mengikuti **Clean Architecture** dengan tiga lapisan. Dependensi hanya mengalir ke dalam:

```
Presentation  →  Domain  ←  Data
```

- **Domain** (`lib/domain/`): Entitas, enum, dan antarmuka repository murni Dart tanpa dependensi Flutter.
- **Data** (`lib/data/`): Implementasi repository menggunakan Drift (SQLite) dan SharedPreferences.
- **Presentation** (`lib/presentation/`): Widget Flutter, provider Riverpod, dan layar UI.

---

## Struktur Proyek

```
lib/
├── main.dart                    # Entry point: inisialisasi SharedPrefs, notifikasi, orientasi
├── app.dart                     # MaterialApp.router (tema, locale, router)
├── core/
│   ├── constants/               # Warna, string, kutipan keuangan
│   ├── responsive/              # Breakpoints, spacing, typography responsif
│   ├── services/                # NotificationService, ExportImportService
│   ├── theme/                   # AppTheme (Material 3, Poppins)
│   ├── utils/                   # DateUtils, CurrencyFormatter
│   └── widgets/                 # Widget umum (loading, empty state)
├── data/
│   ├── database/                # AppDatabase (Drift), tabel, DAO
│   └── repositories/            # Implementasi repository
├── domain/
│   ├── entities/                # Category, Transaction, SummaryResult
│   ├── enums/                   # CategoryType, TransactionType
│   └── repositories/            # Antarmuka repository (I*Repository)
├── presentation/
│   ├── features/                # Layar: home, splash, onboarding, reports, settings, transactions
│   ├── providers/               # Provider Riverpod
│   └── widgets/                 # Widget yang dapat digunakan ulang
└── router/
    └── app_router.dart          # GoRouter + konstanta AppRoutes
```

---

## Prasyarat

| Alat | Versi Minimum | Catatan |
|------|---------------|---------|
| Flutter SDK | 3.41.6 (stable) | `flutter upgrade` untuk memperbarui |
| Dart SDK | 3.7.0+ | Termasuk dalam Flutter |
| Android Studio | 2024.x | Untuk emulator dan build Android |
| JDK | 17 | Diperlukan oleh Gradle |
| Git | Versi apapun | Untuk clone repo |
| Xcode 16+ | **Hanya macOS** | Diperlukan untuk build iOS |

Verifikasi lingkungan:

```bash
flutter doctor -v
```

---

## Clone dan Mulai

### 1. Clone repositori

```bash
git clone <url-repo>
cd project_ai_claude_apk_android_ios
```

### 2. Instal dependensi

```bash
flutter pub get
```

### 3. Generate file Drift (jika diperlukan)

File `*.g.dart` sudah di-commit ke repo. Jalankan ulang hanya jika Anda mengubah skema database atau DAO:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Jalankan analyzer

```bash
dart analyze lib/
```

### 5. Jalankan pengujian

```bash
# Semua unit test
flutter test test/unit/

# Dengan cakupan kode
flutter test --coverage
```

---

## Menjalankan Aplikasi

### Di Android (emulator atau perangkat)

```bash
flutter devices          # Lihat perangkat yang tersedia
flutter run -d <id>      # Jalankan di perangkat tertentu
```

### Di Web (Chrome)

```bash
flutter run -d chrome --no-tree-shake-icons
```

> **Catatan:** Flag `--no-tree-shake-icons` diperlukan karena ikon kategori dimuat secara dinamis dari database.  
> Lihat bagian [Keterbatasan Fitur di Web](#keterbatasan-fitur-di-web) untuk detail.

---

## Build Android

### Release APK (instalasi langsung / pengujian)

```bash
flutter build apk --release --no-tree-shake-icons
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Release APK dipisah per ABI (ukuran lebih kecil)

```bash
flutter build apk --split-per-abi --release --no-tree-shake-icons
```

Output:
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### Release AAB (untuk Google Play Store)

```bash
flutter build appbundle --release --no-tree-shake-icons
```

Output: `build/app/outputs/bundle/release/app-release.aab`

> **Penandatanganan:** Konfigurasi `android/key.properties` diperlukan sebelum upload ke Play Store.  
> Saat ini dikonfigurasi dengan debug keystore. Lihat `docs/DEVELOPMENT_TO_DEPLOY.md §6` untuk instruksi lengkap.

---

## Build iOS

> **PENTING: Build iOS lokal hanya dapat dilakukan di macOS dengan Xcode 16+ terpasang.**  
> Build iOS **tidak dapat** dilakukan di Windows.

Perintah yang dijalankan **di mesin macOS**:

```bash
# Setup CocoaPods
cd ios && pod install && cd ..

# Build tanpa codesign (untuk CI)
flutter build ios --release --no-codesign --no-tree-shake-icons

# Build IPA untuk App Store
flutter build ipa --release --no-tree-shake-icons
```

Output IPA: `build/ios/ipa/DompetKu.ipa`

Untuk detail lengkap termasuk konfigurasi Xcode, Bundle ID, dan upload App Store, lihat `docs/DEVELOPMENT_TO_DEPLOY.md §7`.

---

## Web Build

```bash
flutter build web --release --no-tree-shake-icons
```

Output: `build/web/`

Untuk deploy: upload seluruh isi folder `build/web/` ke hosting statis (Firebase Hosting, Netlify, GitHub Pages, dsb.).

### Keterbatasan Fitur di Web

| Fitur | Android/iOS | Web |
|-------|-------------|-----|
| Database | Persisten (SQLite file lokal) | Persisten via WASM SQLite + IndexedDB/OPFS |
| Notifikasi pengingat | Didukung penuh | Tidak tersedia (toggle dinonaktifkan otomatis) |
| Izin sistem | Didukung | Tidak tersedia |
| Ekspor CSV | Share sheet native | Unduhan file browser |
| Impor CSV | File picker native | File picker browser |
| Semua fitur UI | Penuh | Penuh |

> **Catatan database web:** Data disimpan secara persisten di browser menggunakan SQLite yang dikompilasi ke WebAssembly. Data tetap ada saat halaman di-refresh. File konfigurasi yang diperlukan (`sqlite3.wasm` dan `drift_worker.js`) sudah disertakan di folder `web/`.

---

## Dokumentasi Lengkap

| Dokumen | Isi |
|---------|-----|
| `docs/DEVELOPMENT_TO_DEPLOY.md` | Panduan lengkap dari setup hingga rilis ke Play Store / App Store |
| `docs/CODEBASE_HANDOVER.md` | Penjelasan arsitektur, semua lapisan, logika bisnis, cara menambah fitur |

---

## Catatan untuk Kontributor

- Semua string UI ada di `lib/core/constants/app_strings.dart` — jangan hardcode string di widget.
- Semua warna ada di `lib/core/constants/app_colors.dart` — jangan hardcode hex di widget.
- File `*.g.dart` dibuat otomatis oleh `build_runner` — jangan edit manual.
- **Jangan pernah commit** `android/key.properties`, file `*.jks`, atau keystore apapun.
- **Jangan pernah commit** sertifikat iOS (`.p12`, `.mobileprovision`).
- Skema database ada di versi **1**. Tambahkan migrasi sebelum menaikkan `schemaVersion`.
- Untuk menambahkan fitur baru, ikuti panduan di `docs/CODEBASE_HANDOVER.md §17`.

---

## Keterbatasan yang Diketahui

- **Web — Notifikasi**: Push notification tidak tersedia di web. Toggle notifikasi dinonaktifkan otomatis di browser.
- **Web — COOP/COEP**: Untuk performa database terbaik di web (mode SharedArrayBuffer), server harus mengirim header `Cross-Origin-Opener-Policy: same-origin` dan `Cross-Origin-Embedder-Policy: require-corp`. Tanpa header ini, drift menggunakan mode WASM single-threaded yang tetap berfungsi normal.
- **iOS build**: Membutuhkan macOS + Xcode 16+. Tidak bisa di-build di Windows.
- **`--no-tree-shake-icons`**: Diperlukan karena `IconData` diambil secara dinamis dari database.
- **Notifikasi Android 12+**: Izin `SCHEDULE_EXACT_ALARM` mungkin perlu diaktifkan manual di pengaturan sistem.
- **Impor CSV**: File yang diedit dengan Excel bisa memiliki masalah encoding. Simpan ulang sebagai UTF-8 tanpa BOM.
