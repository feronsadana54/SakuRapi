import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_service.dart';
import 'settings_provider.dart';

// ── Service singleton ─────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ── Toggle + reschedule handler ───────────────────────────────────────────────

/// Hasil toggle/reschedule untuk konsumsi UI.
class ReminderActionResult {
  final bool success;
  final bool permissionDenied;
  final bool usingInexactFallback;

  const ReminderActionResult({
    required this.success,
    required this.permissionDenied,
    required this.usingInexactFallback,
  });

  static const disabled = ReminderActionResult(
    success: true,
    permissionDenied: false,
    usingInexactFallback: false,
  );
}

/// Mengelola enable/disable reminder harian dan reschedule saat waktu
/// atau hari berubah. Mengembalikan status agar UI dapat menampilkan
/// snackbar yang akurat (granted, denied, fallback inexact).
class NotificationToggleNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Enables or disables the reminder.
  Future<ReminderActionResult> toggle(bool enable) async {
    final service = ref.read(notificationServiceProvider);

    if (enable) {
      final granted = await service.requestPermission();
      if (!granted) {
        return const ReminderActionResult(
          success: false,
          permissionDenied: true,
          usingInexactFallback: false,
        );
      }

      final settings = ref.read(settingsProvider).valueOrNull;
      final result = await service.scheduleReminders(
        hour: settings?.reminderHour ?? 21,
        minute: settings?.reminderMinute ?? 0,
        weekdays: settings?.reminderDays ?? [1, 2, 3, 4, 5, 6, 7],
      );

      await ref
          .read(settingsProvider.notifier)
          .setNotificationEnabled(true);

      return ReminderActionResult(
        success: result.success,
        permissionDenied: result.permissionDenied,
        usingInexactFallback: result.usingInexactFallback,
      );
    } else {
      await service.cancelAllReminders();
      await ref
          .read(settingsProvider.notifier)
          .setNotificationEnabled(false);
      return ReminderActionResult.disabled;
    }
  }

  /// Re-schedules reminders using the current saved settings.
  /// No-op if notifications are disabled.
  Future<ReminderActionResult> reschedule() async {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null || !settings.notificationEnabled) {
      return ReminderActionResult.disabled;
    }

    final service = ref.read(notificationServiceProvider);
    final result = await service.scheduleReminders(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
      weekdays: settings.reminderDays,
    );
    return ReminderActionResult(
      success: result.success,
      permissionDenied: result.permissionDenied,
      usingInexactFallback: result.usingInexactFallback,
    );
  }
}

final notificationToggleProvider =
    AsyncNotifierProvider<NotificationToggleNotifier, void>(
  NotificationToggleNotifier.new,
);
