import 'dart:async';

import 'package:app_links/app_links.dart';
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
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/database_provider.dart';

bool _bgInitDone = false;

/// Titik masuk utama aplikasi SakuRapi.
///
/// Urutan eksekusi:
///   1. Inisialisasi binding Flutter
///   2. Firebase.initializeApp()
///   3. Muat SharedPreferences
///   4. Tangkap deep link awal (cold start) via app_links
///   5. Buat ProviderContainer (bukan ProviderScope) agar bisa mengakses
///      provider dari luar widget tree — diperlukan untuk mendaftarkan
///      URI email sign-in yang masuk setelah aplikasi hidup
///   6. Jalankan runApp dengan UncontrolledProviderScope
///   7. Daftarkan listener app_links untuk URI yang masuk di foreground
///   8. Inisialisasi timezone + notifikasi setelah frame pertama
Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]));

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } catch (_) {
    // Firebase gagal init — aplikasi tetap berjalan dalam mode lokal/tamu.
  }

  final prefs = await SharedPreferences.getInstance();

  // Tangkap URI yang membuka aplikasi dari cold start (email sign-in link).
  // Hanya pada native — web menangani sendiri via Firebase Auth redirect.
  String? initialLink;
  if (!kIsWeb) {
    try {
      final uri = await AppLinks()
          .getInitialLink()
          .timeout(const Duration(seconds: 2));
      initialLink = uri?.toString();
    } catch (_) {}
  }

  // Gunakan ProviderContainer langsung agar main() dapat mengakses provider
  // dari luar widget tree (untuk mendaftarkan URI deep link).
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Daftarkan URI awal jika ada (cold start via email link).
  if (initialLink != null) {
    container.read(pendingEmailLinkProvider.notifier).state = initialLink;
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );

  // Dengarkan URI baru saat aplikasi sudah berjalan (foreground / background).
  // Stream ini hidup selama proses aplikasi berjalan — tidak perlu di-cancel.
  if (!kIsWeb) {
    AppLinks().uriLinkStream.listen((uri) {
      container.read(pendingEmailLinkProvider.notifier).state =
          uri.toString();
    });
  }

  // Tunda inisialisasi berat ke setelah frame pertama.
  if (!kIsWeb) {
    binding.addPostFrameCallback((_) => _initBackground(prefs));
  }
}

/// Inisialisasi timezone + notifikasi setelah frame pertama.
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
  } catch (_) {}
}
