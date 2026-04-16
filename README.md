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

### Autentikasi & Sinkronisasi
- **Mode Tamu**: semua data tersimpan lokal (SQLite), tidak perlu akun
- **Login Google**: Firebase Auth + sinkronisasi Firestore
  - Ganti perangkat dan login lagi → data dipulihkan dari cloud
  - *Memerlukan konfigurasi Firebase — lihat §3 di bawah*

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

## §3 — Mengaktifkan Firebase (Opsional)

Firebase diperlukan untuk fitur **Login Google** dan **sinkronisasi cloud**.
Tanpa Firebase, aplikasi tetap berjalan penuh dalam mode lokal/tamu.

### Langkah-langkah Setup Firebase

```bash
# 1. Buat proyek Firebase di https://console.firebase.google.com
#    Aktifkan: Authentication (Google), Firestore Database

# 2. Pasang FlutterFire CLI
dart pub global activate flutterfire_cli

# 3. Konfigurasi proyek (ikuti instruksi interaktif)
flutterfire configure

#    Perintah ini akan:
#    - Menghasilkan lib/firebase_options.dart dengan kredensial nyata
#    - Menambahkan google-services.json ke android/app/
#    - Menambahkan GoogleService-Info.plist ke ios/Runner/

# 4. Aktifkan Firebase di kode
#    Buka lib/firebase_options.dart dan ubah:
#    const bool kFirebaseConfigured = false;
#    menjadi:
#    const bool kFirebaseConfigured = true;

# 5. Jalankan ulang
flutter run
```

### Konfigurasi Firestore Rules (di Firebase Console)

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

## Dokumentasi Lengkap

- [`docs/CODEBASE_HANDOVER.md`](docs/CODEBASE_HANDOVER.md) — arsitektur, alur kode, panduan handover
- [`docs/DEVELOPMENT_TO_DEPLOY.md`](docs/DEVELOPMENT_TO_DEPLOY.md) — panduan build, deploy, dan konfigurasi
