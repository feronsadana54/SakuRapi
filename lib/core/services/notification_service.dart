import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_strings.dart';

/// Mengelola notifikasi pengingat keuangan harian.
///
/// Mendukung penjadwalan pada hari-hari tertentu dalam seminggu pada waktu kustom.
/// Menggunakan ID 1–7 (Senin–Minggu) untuk notifikasi per-hari.
/// Panggil [initialize] sekali sebelum menjadwalkan, atau biarkan lazy-initialize.
///
/// Dipanggil dari [main._initBackground] saat aplikasi dibuka,
/// dan dari [NotificationProvider] saat pengguna mengubah pengaturan pengingat.
class NotificationService {
  static const _notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      AppStrings.notifChannelId,
      AppStrings.notifChannelName,
      channelDescription: AppStrings.notifChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Initialization ────────────────────────────────────────────────────────

  /// Menginisialisasi plugin notifikasi dan membuat channel Android.
  /// Idempotent — aman dipanggil berkali-kali.
  /// Tidak melakukan apa-apa di web (notifikasi tidak didukung).
  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;
    _initialized = true; // Set first to prevent concurrent re-entry.

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            AppStrings.notifChannelId,
            AppStrings.notifChannelName,
            description: AppStrings.notifChannelDesc,
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  // ── Permission ────────────────────────────────────────────────────────────

  /// Meminta izin notifikasi di iOS dan Android 13+.
  /// Mengembalikan true jika izin diberikan (atau tidak diperlukan di platform ini).
  /// Selalu mengembalikan false di web (tidak didukung).
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await _ensureInitialized();

    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return (iosGranted ?? true) && (androidGranted ?? true);
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  /// Membatalkan semua pengingat yang ada, lalu menjadwalkan satu notifikasi per
  /// hari yang dipilih (1=Senin … 7=Minggu) pada [hour]:[minute] WIB yang diberikan.
  ///
  /// Jika [weekdays] kosong, semua 7 hari digunakan (pengulangan harian).
  /// Tidak melakukan apa-apa di web (tidak didukung).
  ///
  /// Dipanggil dari [main._initBackground] saat startup dan dari
  /// [NotificationProvider] saat pengguna menyimpan pengaturan pengingat baru.
  Future<void> scheduleReminders({
    int hour = 21,
    int minute = 0,
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
  }) async {
    if (kIsWeb) return;
    await _ensureInitialized();
    await cancelAllReminders();

    final jakarta = tz.getLocation('Asia/Jakarta');
    final now = tz.TZDateTime.now(jakarta);
    final days = weekdays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : weekdays;

    for (final day in days) {
      final scheduled = _nextOccurrence(now, day, hour, minute, jakarta);
      await _plugin.zonedSchedule(
        day, // ID 1–7 maps directly to Mon–Sun
        AppStrings.notifTitle,
        AppStrings.notifBody,
        scheduled,
        _notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  /// Membatalkan semua notifikasi pengingat (ID 1–7 ditambah ID legacy 0).
  /// Tidak melakukan apa-apa di web (tidak didukung).
  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    await _ensureInitialized();
    for (int id = 0; id <= 7; id++) {
      await _plugin.cancel(id);
    }
  }

  // ── Query ─────────────────────────────────────────────────────────────────

  /// Apakah setidaknya satu notifikasi pengingat sedang dijadwalkan.
  /// Selalu mengembalikan false di web (tidak didukung).
  Future<bool> isAnyReminderScheduled() async {
    if (kIsWeb) return false;
    await _ensureInitialized();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((n) => n.id >= 1 && n.id <= 7);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Mengembalikan [tz.TZDateTime] berikutnya yang jatuh pada [targetWeekday]
  /// (1=Sen … 7=Min) pada [hour]:[minute] di [location], setelah [now].
  ///
  /// Algoritma: mulai dari hari ini pada waktu yang diminta, maju satu hari
  /// pada satu waktu hingga mendarat pada hari target DAN waktu sudah lewat.
  tz.TZDateTime _nextOccurrence(tz.TZDateTime now, int targetWeekday,
      int hour, int minute, tz.Location location) {
    // Mulai dari tanggal hari ini dengan waktu yang diminta.
    var candidate =
        tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);

    // Maju satu hari pada satu waktu hingga mendarat pada hari target
    // DAN waktu sudah benar-benar di masa depan.
    while (candidate.weekday != targetWeekday ||
        !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
