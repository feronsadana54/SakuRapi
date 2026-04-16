// File ini dihasilkan oleh FlutterFire CLI.
// Untuk mengaktifkan Firebase, jalankan:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Perintah di atas akan mengganti isi file ini dengan konfigurasi nyata
// dari proyek Firebase kamu, dan mengubah isConfigured menjadi true.
//
// Lihat docs/DEVELOPMENT_TO_DEPLOY.md §3 untuk panduan lengkap.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Menandai apakah Firebase sudah dikonfigurasi dengan kredensial nyata.
///
/// Ubah menjadi [true] setelah menjalankan `flutterfire configure`.
/// Selama false, seluruh fitur Firebase (Google Sign-In, Firestore sync)
/// dinonaktifkan dan aplikasi berjalan dalam mode lokal/tamu sepenuhnya.
const bool kFirebaseConfigured = false;

/// Konfigurasi Firebase yang dihasilkan oleh FlutterFire CLI.
///
/// JANGAN gunakan nilai-nilai ini secara langsung. Selalu akses melalui
/// [DefaultFirebaseOptions.currentPlatform] setelah memeriksa [kFirebaseConfigured].
class DefaultFirebaseOptions {
  /// Mengembalikan [FirebaseOptions] yang sesuai dengan platform saat ini.
  ///
  /// Melempar [UnsupportedError] jika [kFirebaseConfigured] masih false —
  /// artinya `flutterfire configure` belum dijalankan.
  static FirebaseOptions get currentPlatform {
    if (!kFirebaseConfigured) {
      throw UnsupportedError(
        'Firebase belum dikonfigurasi.\n'
        'Jalankan: flutterfire configure\n'
        'Lihat docs/DEVELOPMENT_TO_DEPLOY.md §3 untuk panduan.',
      );
    }
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

  // ── Placeholder values ──────────────────────────────────────────────────────
  // Nilai-nilai di bawah ini adalah PLACEHOLDER.
  // Setelah menjalankan `flutterfire configure`, file ini akan diganti
  // dengan konfigurasi nyata dari proyek Firebase kamu.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PLACEHOLDER_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'sakurapi-placeholder',
    storageBucket: 'sakurapi-placeholder.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PLACEHOLDER_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'sakurapi-placeholder',
    storageBucket: 'sakurapi-placeholder.firebasestorage.app',
    iosBundleId: 'com.financetracker.financeTracker',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PLACEHOLDER_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'sakurapi-placeholder',
    authDomain: 'sakurapi-placeholder.firebaseapp.com',
    storageBucket: 'sakurapi-placeholder.firebasestorage.app',
  );
}
