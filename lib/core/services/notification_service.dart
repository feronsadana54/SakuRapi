import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_strings.dart';

/// Hasil dari [NotificationService.scheduleReminders] agar UI dapat memberi
/// umpan balik yang akurat ke pengguna.
class ScheduleResult {
  final int scheduledCount;
  final bool exactAlarmDenied;
  final bool permissionDenied;

  const ScheduleResult({
    required this.scheduledCount,
    required this.exactAlarmDenied,
    required this.permissionDenied,
  });

  bool get success => scheduledCount > 0 && !permissionDenied;

  /// True jika dijadwalkan tetapi memakai mode "inexact" (Android 12+ tanpa
  /// izin SCHEDULE_EXACT_ALARM). Pengingat masih akan muncul, hanya saja
  /// jamnya bisa meleset beberapa menit.
  bool get usingInexactFallback =>
      scheduledCount > 0 && exactAlarmDenied;
}

/// Mengelola notifikasi pengingat keuangan harian.
///
/// **Tujuan**: notifikasi yang andal — muncul tepat waktu dengan suara,
/// bahkan setelah perangkat reboot atau aplikasi diperbarui.
///
/// **Strategi:**
///   - ID 1–7 dipakai untuk Senin–Minggu, masing-masing dijadwalkan ulang
///     setiap minggu via `matchDateTimeComponents: dayOfWeekAndTime`.
///   - Coba `AndroidScheduleMode.exactAllowWhileIdle` terlebih dahulu.
///     Bila `SCHEDULE_EXACT_ALARM` ditolak (Android 12+ user setting),
///     fallback ke `inexactAllowWhileIdle` — pengingat tetap muncul,
///     hanya saja waktunya bisa meleset beberapa menit.
///   - `AndroidNotificationChannel` dibuat dengan suara default sistem +
///     getaran. Channel hanya dapat dibuat sekali; setelah itu pengaturan
///     suara hanya bisa diubah pengguna lewat Settings perangkat.
///
/// **Reboot-safe**: `flutter_local_notifications` mendaftarkan
/// `ScheduledNotificationBootReceiver` di AndroidManifest, sehingga semua
/// pengingat otomatis dijadwalkan ulang setelah BOOT_COMPLETED atau
/// MY_PACKAGE_REPLACED (update aplikasi).
///
/// **Batasan jujur:**
///   - **Force stop / swipe-away dari recent apps**: di Android, AlarmManager
///     dapat tetap memicu notifikasi karena dikelola sistem, bukan oleh
///     proses aplikasi. Namun beberapa OEM (Xiaomi, Huawei, Oppo)
///     mematikan alarm saat aplikasi di-force-stop sampai pengguna
///     membuka aplikasi lagi. Ini di luar kendali aplikasi — solusi:
///     dokumentasi panduan "izinkan autostart".
///   - **Doze mode**: `exactAllowWhileIdle` tetap melewati doze, tapi hanya
///     diizinkan setelah `SCHEDULE_EXACT_ALARM` atau `USE_EXACT_ALARM`
///     diizinkan oleh pengguna (Android 12+).
///   - **Web**: tidak didukung sama sekali. Semua method no-op.
class NotificationService {
  static const _notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      AppStrings.notifChannelId,
      AppStrings.notifChannelName,
      channelDescription: AppStrings.notifChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      // Tanpa parameter `sound` — pakai suara notifikasi default sistem.
      // Ini lebih reliable daripada custom RawResource, dan menghormati
      // preferensi audio pengguna.
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static const _tag = 'NotificationService';

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

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final notifGranted = await androidImpl?.requestNotificationsPermission();

    // Coba minta izin SCHEDULE_EXACT_ALARM (Android 12+). Jika ditolak,
    // [scheduleReminders] akan otomatis fallback ke inexact mode.
    try {
      await androidImpl?.requestExactAlarmsPermission();
    } catch (e) {
      dev.log('requestExactAlarmsPermission tidak didukung: $e', name: _tag);
    }

    return (iosGranted ?? true) && (notifGranted ?? true);
  }

  /// True jika izin notifikasi sudah diberikan (Android 13+/iOS).
  /// Pada Android < 13 atau platform tanpa permission flow, mengembalikan true.
  Future<bool> isPermissionGranted() async {
    if (kIsWeb) return false;
    await _ensureInitialized();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.areNotificationsEnabled();
    return granted ?? true;
  }

  /// True jika perangkat mengizinkan SCHEDULE_EXACT_ALARM (Android 12+).
  /// Bernilai true otomatis pada Android < 12 atau platform lain.
  Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb) return false;
    await _ensureInitialized();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    try {
      final allowed = await androidImpl?.canScheduleExactNotifications();
      return allowed ?? true;
    } catch (_) {
      // Method tidak ada di versi plugin tertentu — anggap true (Android < 12).
      return true;
    }
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  /// Membatalkan semua pengingat yang ada, lalu menjadwalkan satu notifikasi per
  /// hari yang dipilih (1=Senin … 7=Minggu) pada [hour]:[minute] WIB yang diberikan.
  ///
  /// Jika [weekdays] kosong, semua 7 hari digunakan (pengulangan harian).
  /// Tidak melakukan apa-apa di web (tidak didukung).
  ///
  /// **Strategi exact vs inexact**: mencoba `exactAllowWhileIdle` dulu.
  /// Jika SCHEDULE_EXACT_ALARM ditolak (Android 12+), fallback ke
  /// `inexactAllowWhileIdle` agar pengingat tetap muncul, hanya saja
  /// waktunya bisa meleset 1–15 menit.
  ///
  /// Mengembalikan [ScheduleResult] dengan info mode aktif untuk UI.
  Future<ScheduleResult> scheduleReminders({
    int hour = 21,
    int minute = 0,
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
  }) async {
    if (kIsWeb) {
      return const ScheduleResult(
        scheduledCount: 0,
        exactAlarmDenied: false,
        permissionDenied: false,
      );
    }
    await _ensureInitialized();

    final permissionGranted = await isPermissionGranted();
    if (!permissionGranted) {
      dev.log('Permission notifikasi belum diberikan — schedule dilewati',
          name: _tag);
      return const ScheduleResult(
        scheduledCount: 0,
        exactAlarmDenied: false,
        permissionDenied: true,
      );
    }

    await cancelAllReminders();

    final exactAllowed = await canScheduleExactAlarms();
    final scheduleMode = exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final jakarta = tz.getLocation('Asia/Jakarta');
    final now = tz.TZDateTime.now(jakarta);
    final days = weekdays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : weekdays;

    var scheduled = 0;
    for (final day in days) {
      final next = _nextOccurrence(now, day, hour, minute, jakarta);
      try {
        await _plugin.zonedSchedule(
          day, // ID 1–7 maps directly to Mon–Sun
          AppStrings.notifTitle,
          AppStrings.notifBody,
          next,
          _notifDetails,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        scheduled++;
      } catch (e) {
        dev.log('Gagal menjadwalkan ID $day: $e', name: _tag, level: 900);
      }
    }

    dev.log(
      'Pengingat dijadwalkan: $scheduled/${days.length} hari, '
      'mode=${exactAllowed ? "exact" : "inexact"}',
      name: _tag,
    );

    return ScheduleResult(
      scheduledCount: scheduled,
      exactAlarmDenied: !exactAllowed,
      permissionDenied: false,
    );
  }

  /// Memastikan pengingat aktif: jika tidak ada notifikasi pending tetapi
  /// pengaturan menyatakan aktif, jadwalkan ulang. Aman dipanggil setiap
  /// startup — idempoten dan murah jika pengingat sudah terjadwal.
  ///
  /// Berguna mengatasi kasus di mana sistem membersihkan jadwal akibat
  /// pengaturan baterai OEM, namun preferensi pengguna masih "aktif".
  Future<void> ensureScheduled({
    required int hour,
    required int minute,
    required List<int> weekdays,
  }) async {
    if (kIsWeb) return;
    await _ensureInitialized();
    final pending = await _plugin.pendingNotificationRequests();
    final activeIds = pending.map((p) => p.id).where((id) => id >= 1 && id <= 7);
    if (activeIds.length == weekdays.length) {
      dev.log(
        'Pengingat sudah lengkap (${activeIds.length}/${weekdays.length}) — skip',
        name: _tag,
      );
      return;
    }
    dev.log(
      'Hanya ${activeIds.length}/${weekdays.length} pengingat aktif — '
      'menjadwalkan ulang',
      name: _tag,
    );
    await scheduleReminders(hour: hour, minute: minute, weekdays: weekdays);
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
