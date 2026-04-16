import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_strings.dart';

/// Manages daily reminder notifications.
///
/// Supports scheduling on selected weekdays at a custom time.
/// Uses IDs 1–7 (Monday–Sunday) for per-weekday notifications.
/// Call [initialize] once before scheduling, or let it lazy-initialize.
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

  /// Initializes the notification plugin and creates the Android channel.
  /// Idempotent — safe to call multiple times.
  /// No-op on web (notifications not supported).
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

  /// Requests notification permission on iOS and Android 13+.
  /// Returns true if permission is granted (or not required on this platform).
  /// Always returns false on web (not supported).
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

  /// Cancels all existing reminders, then schedules one notification per
  /// selected weekday (1=Monday … 7=Sunday) at the given [hour]:[minute] WIB.
  ///
  /// If [weekdays] is empty, all 7 days are used (daily repeat).
  /// No-op on web (not supported).
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

  /// Cancels all reminder notifications (IDs 1–7 plus legacy ID 0).
  /// No-op on web (not supported).
  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    await _ensureInitialized();
    for (int id = 0; id <= 7; id++) {
      await _plugin.cancel(id);
    }
  }

  // ── Query ─────────────────────────────────────────────────────────────────

  /// Whether at least one reminder notification is currently scheduled.
  /// Always returns false on web (not supported).
  Future<bool> isAnyReminderScheduled() async {
    if (kIsWeb) return false;
    await _ensureInitialized();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((n) => n.id >= 1 && n.id <= 7);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the next [tz.TZDateTime] that falls on [targetWeekday]
  /// (1=Mon … 7=Sun) at [hour]:[minute] in [location], after [now].
  tz.TZDateTime _nextOccurrence(tz.TZDateTime now, int targetWeekday,
      int hour, int minute, tz.Location location) {
    // Start at today's date with the requested time.
    var candidate =
        tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);

    // Advance one day at a time until we land on the target weekday
    // AND the time is strictly in the future.
    while (candidate.weekday != targetWeekday ||
        !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
