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
8. [Mengaktifkan Firebase (Opsional)](#mengaktifkan-firebase-opsional)
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
cd project_ai_claude_apk_android_ios
```

### 2. Pasang Dependensi Flutter

```bash
flutter pub get
```

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

## Mengaktifkan Firebase (Opsional)

Firebase diperlukan untuk fitur **Login Google** dan **sinkronisasi cloud**.
Tanpa Firebase, aplikasi tetap berjalan penuh dalam mode lokal/tamu.

### Langkah-langkah Aktivasi Firebase

```bash
# 1. Buat proyek Firebase di https://console.firebase.google.com
#    Aktifkan: Authentication (provider: Google), Firestore Database

# 2. Pasang FlutterFire CLI
dart pub global activate flutterfire_cli

# 3. Konfigurasi proyek (ikuti instruksi interaktif)
flutterfire configure
#    Perintah ini akan:
#    - Menghasilkan lib/firebase_options.dart dengan kredensial nyata
#    - Menambahkan google-services.json ke android/app/
#    - Menambahkan GoogleService-Info.plist ke ios/Runner/

# 4. Aktifkan flag Firebase di lib/firebase_options.dart:
#    Ubah:  const bool kFirebaseConfigured = false;
#    Menjadi: const bool kFirebaseConfigured = true;

# 5. Jalankan ulang
flutter run
```

### Konfigurasi Firestore Security Rules

Di Firebase Console → Firestore → Rules, terapkan rules berikut:

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

### Firebase (jika diaktifkan)

- [ ] `kFirebaseConfigured = true` di `lib/firebase_options.dart`
- [ ] `google-services.json` ada di `android/app/`
- [ ] `GoogleService-Info.plist` ada di `ios/Runner/`
- [ ] Login Google berhasil
- [ ] Data tersinkronisasi ke Firestore (cek di Firebase Console)
- [ ] Login ulang di device berbeda → data dipulihkan dari cloud
- [ ] Logout → data lokal tetap ada, sesi Firebase dibersihkan

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

- Pastikan `kFirebaseConfigured = true` di `lib/firebase_options.dart`
- Pastikan `google-services.json` ada di `android/app/`
- Jalankan `flutter clean && flutter pub get` lalu build ulang

### Google Sign-In gagal "PlatformException: sign_in_failed"

- Pastikan SHA-1 fingerprint sudah ditambahkan di Firebase Console → Project Settings → Android App
- Untuk debug: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
- Salin SHA-1 dan tambahkan di Firebase Console

---

*Dokumen ini terakhir diperbarui: 17 April 2026*
