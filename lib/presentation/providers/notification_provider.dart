import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_service.dart';
import 'settings_provider.dart';

// ── Service singleton ─────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ── Toggle + reschedule handler ───────────────────────────────────────────────

/// Handles enabling/disabling the daily reminder and rescheduling
/// when the time or selected days change.
class NotificationToggleNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Enables or disables the reminder.
  /// Returns [true] if the operation succeeded (or permission was granted).
  Future<bool> toggle(bool enable) async {
    final service = ref.read(notificationServiceProvider);

    if (enable) {
      final granted = await service.requestPermission();
      if (!granted) return false;

      final settings = ref.read(settingsProvider).valueOrNull;
      await service.scheduleReminders(
        hour: settings?.reminderHour ?? 21,
        minute: settings?.reminderMinute ?? 0,
        weekdays: settings?.reminderDays ?? [1, 2, 3, 4, 5, 6, 7],
      );
    } else {
      await service.cancelAllReminders();
    }

    await ref
        .read(settingsProvider.notifier)
        .setNotificationEnabled(enable);

    return true;
  }

  /// Re-schedules reminders using the current saved settings.
  /// No-op if notifications are disabled.
  Future<void> reschedule() async {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null || !settings.notificationEnabled) return;

    final service = ref.read(notificationServiceProvider);
    await service.scheduleReminders(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
      weekdays: settings.reminderDays,
    );
  }
}

final notificationToggleProvider =
    AsyncNotifierProvider<NotificationToggleNotifier, void>(
  NotificationToggleNotifier.new,
);
