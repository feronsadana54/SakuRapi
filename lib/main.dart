import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app.dart';
import 'core/services/notification_service.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'firebase_options.dart';
import 'presentation/providers/database_provider.dart';

/// Guard agar inisialisasi background hanya berjalan sekali per lifetime proses.
bool _bgInitDone = false;

/// Titik masuk utama aplikasi SakuRapi.
///
/// Urutan eksekusi:
///   1. Inisialisasi binding Flutter
///   2. Firebase.initializeApp() — hanya jika [kFirebaseConfigured] == true
///   3. Muat SharedPreferences (diperlukan sebelum runApp)
///   4. Jalankan aplikasi dalam ProviderScope (Riverpod)
///   5. Setelah frame pertama: inisialisasi timezone + jadwalkan notifikasi
///
/// Semua pekerjaan berat (Firebase, timezone, notifikasi) ditangani secara
/// aman dengan timeout dan try/catch agar UI tetap responsif.
Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Orientasi: fire-and-forget, tidak kritis.
  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]));

  // Status bar transparan dengan ikon gelap.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Inisialisasi Firebase — hanya jika sudah dikonfigurasi via flutterfire CLI.
  // Jika kFirebaseConfigured masih false, lewati dan jalankan dalam mode lokal.
  // Lihat lib/firebase_options.dart dan docs/DEVELOPMENT_TO_DEPLOY.md §3.
  if (kFirebaseConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Firebase gagal init — aplikasi tetap berjalan dalam mode lokal/tamu.
    }
  }

  // SharedPreferences harus siap sebelum runApp agar override provider berjalan.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );

  // Tunda inisialisasi berat ke setelah frame pertama.
  // Notifikasi tidak didukung di web.
  if (!kIsWeb) {
    binding.addPostFrameCallback((_) => _initBackground(prefs));
  }
}

/// Inisialisasi timezone + penjadwalan notifikasi setelah frame pertama.
///
/// Setiap operasi dibungkus timeout agar plugin platform yang bermasalah
/// tidak membekukan aplikasi. Semua kegagalan diabaikan; aplikasi berjalan
/// penuh tanpa notifikasi jika inisialisasi ini gagal.
Future<void> _initBackground(SharedPreferences prefs) async {
  if (_bgInitDone) return;
  _bgInitDone = true;

  try {
    await Future<void>.microtask(() {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    });
  } catch (_) {
    return;
  }

  try {
    final settingsRepo = SettingsRepositoryImpl(prefs);
    final notifEnabled = await settingsRepo.isNotificationEnabled();
    if (!notifEnabled) return;

    final notificationService = NotificationService();

    await notificationService
        .initialize()
        .timeout(const Duration(seconds: 3));

    final hour = await settingsRepo.getReminderHour();
    final minute = await settingsRepo.getReminderMinute();
    final days = await settingsRepo.getReminderDays();

    await notificationService
        .scheduleReminders(hour: hour, minute: minute, weekdays: days)
        .timeout(const Duration(seconds: 3));
  } catch (_) {
    // Non-fatal: notifikasi tidak tersedia saat peluncuran ini.
  }
}
