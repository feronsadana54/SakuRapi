import 'dart:async';

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
import 'presentation/providers/database_provider.dart';

// Prevents the background initialisation from running more than once per
// process lifetime (can fire again on hot-reload / hot-restart in dev).
bool _bgInitDone = false;

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Orientation: fire-and-forget, non-critical.
  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]));

  // Transparent status bar with dark icons (overridden by Flutter after first frame).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // SharedPreferences must be ready before runApp so the provider override works.
  // This is a fast disk read; it is safe to await here.
  final prefs = await SharedPreferences.getInstance();

  // Launch the app immediately — do NOT block for timezone or notifications.
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );

  // Defer all heavy work until after the first frame.  This guarantees
  // the UI is responsive before any potentially slow platform calls run.
  // Notifications are not supported on web — skip entirely.
  if (!kIsWeb) {
    binding.addPostFrameCallback((_) => _initBackground(prefs));
  }
}

/// Timezone + notification scheduling — runs entirely after the first frame.
///
/// Every operation is wrapped in a timeout so a misbehaving platform plugin
/// cannot freeze the app.  All failures are silently ignored; the app works
/// fully without notifications.
Future<void> _initBackground(SharedPreferences prefs) async {
  if (_bgInitDone) return; // Guard: only run once per process.
  _bgInitDone = true;

  // Timezone init — synchronous CPU work, kept short with a Future wrapper
  // so it yields between microtasks and does not block the event loop.
  try {
    await Future<void>.microtask(() {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    });
  } catch (_) {
    return; // Cannot schedule without a valid timezone.
  }

  try {
    final settingsRepo = SettingsRepositoryImpl(prefs);
    final notifEnabled = await settingsRepo.isNotificationEnabled();
    if (!notifEnabled) return;

    final notificationService = NotificationService();

    // 3-second timeout per platform call — well inside the 5-second ANR limit.
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
    // Non-fatal: notifications unavailable this launch.
  }
}
