// Konfigurasi Firebase untuk proyek SakuRapi.
// Dihasilkan oleh FlutterFire CLI dan telah dikonfigurasi untuk proyek:
//   sakurapi-aa6ac
//
// Untuk memperbarui konfigurasi ini (misal menambah platform baru), jalankan:
//   dart pub global activate flutterfire_cli
//   flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Konfigurasi Firebase untuk proyek sakurapi-aa6ac.
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBOxxXkXwXudzaD1baFJc8pv6ZhvVD0wTw',
    appId: '1:130977240505:android:c838ce1099939a92cb5268',
    messagingSenderId: '130977240505',
    projectId: 'sakurapi-aa6ac',
    storageBucket: 'sakurapi-aa6ac.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDBf3qVGA_BvqWnlxIuId6au6Gn7aQR8iw',
    appId: '1:130977240505:ios:816155cd58197d6bcb5268',
    messagingSenderId: '130977240505',
    projectId: 'sakurapi-aa6ac',
    storageBucket: 'sakurapi-aa6ac.firebasestorage.app',
    iosBundleId: 'com.financetracker.financeTracker',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA7_O0N8n7CIQoMPo6-u8Tybfko400SvKA',
    appId: '1:130977240505:web:e85631d49beebd83cb5268',
    messagingSenderId: '130977240505',
    projectId: 'sakurapi-aa6ac',
    authDomain: 'sakurapi-aa6ac.firebaseapp.com',
    storageBucket: 'sakurapi-aa6ac.firebasestorage.app',
    measurementId: 'G-EDK91DNMBK',
  );

}