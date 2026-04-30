// =============================================================================
// lib/firebase_options.example.dart — TEMPLATE KONFIGURASI FIREBASE
// =============================================================================
//
// PENTING — BACA SEBELUM MENGGUNAKAN:
//
// File ini adalah TEMPLATE/CONTOH dengan nilai PLACEHOLDER yang tidak valid.
// Jangan gunakan langsung tanpa mengisi nilai yang benar!
//
// Proyek ini TIDAK menyediakan akses ke Firebase project manapun.
// Anda wajib menggunakan project Firebase MILIK ANDA SENDIRI.
//
// ─────────────────────────────────────────────────────────────────────────────
// CARA SETUP — pilih salah satu:
//
// Opsi A (DIREKOMENDASIKAN) — FlutterFire CLI:
//   1. Buat project Firebase di https://console.firebase.google.com
//   2. Tambahkan app Android, iOS, dan/atau Web ke project Anda
//   3. Install FlutterFire CLI:
//        dart pub global activate flutterfire_cli
//   4. Login ke Firebase:
//        firebase login
//   5. Generate konfigurasi (akan membuat lib/firebase_options.dart):
//        flutterfire configure
//
// Opsi B — Isi manual dari Firebase Console:
//   1. Salin file ini ke lib/firebase_options.dart
//   2. Buka Firebase Console → [Project Anda] → Project Settings → General
//   3. Ganti setiap nilai YOUR_... dengan nilai nyata dari Firebase Console
//   4. JANGAN commit lib/firebase_options.dart — file ini sudah ada di .gitignore
//
// ─────────────────────────────────────────────────────────────────────────────
// CATATAN KEAMANAN:
//
// lib/firebase_options.dart ada di .gitignore dan TIDAK boleh di-commit.
// File ini berisi konfigurasi klien Firebase yang spesifik untuk project Anda.
//
// Meskipun Firebase client config (apiKey, appId, dll.) tidak dianggap
// "secret sejati" oleh Google (lihat docs/CONFIG_AND_SECRET_AUDIT.txt),
// menjaganya di luar git memastikan:
//   - Setiap developer menggunakan project Firebase mereka sendiri
//   - Tidak ada satu project Firebase yang digunakan bersama tanpa izin
//   - Repository dapat dipublikasikan dengan aman di GitHub
//   - Developer baru tidak secara tidak sengaja menggunakan Firebase
//     project orang lain
//
// ─────────────────────────────────────────────────────────────────────────────
// CARA MENDAPATKAN NILAI:
//
// Firebase Console → [Project Anda] → Project Settings → General tab
//   → "Your apps" → pilih platform → lihat config snippet atau download file
//
// Untuk flutterfire configure, semua nilai diisi otomatis.
// =============================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Konfigurasi Firebase untuk platform saat ini.
///
/// TEMPLATE — salin ke lib/firebase_options.dart dan isi nilai nyata.
/// Atau jalankan `flutterfire configure` untuk mengisi otomatis.
class DefaultFirebaseOptions {
  /// Mengembalikan [FirebaseOptions] yang sesuai dengan platform saat ini.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions hanya mendukung Android, iOS, dan Web.',
        );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Android — dapatkan nilai dari:
  // Firebase Console → Project Settings → Android app → google-services.json
  // atau bagian "SDK setup and configuration" → pilih "Config object"
  // ───────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',              // format: 1:SENDER_ID:android:HASH
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.firebasestorage.app',
  );

  // ───────────────────────────────────────────────────────────────────────────
  // iOS — dapatkan nilai dari:
  // Firebase Console → Project Settings → iOS app → GoogleService-Info.plist
  // atau bagian "SDK setup and configuration" → pilih "Config object"
  // ───────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',                  // format: 1:SENDER_ID:ios:HASH
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.firebasestorage.app',
    iosBundleId: 'YOUR_IOS_BUNDLE_ID',         // contoh: com.contoh.namaAplikasi
  );

  // ───────────────────────────────────────────────────────────────────────────
  // Web — dapatkan nilai dari:
  // Firebase Console → Project Settings → Web app → "SDK setup and configuration"
  // → pilih "Config" → salin objek firebaseConfig
  // ───────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',                  // format: 1:SENDER_ID:web:HASH
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    authDomain: 'YOUR_FIREBASE_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.firebasestorage.app',
    measurementId: 'YOUR_MEASUREMENT_ID',      // format: G-XXXXXXXXXX (Google Analytics)
  );
}
