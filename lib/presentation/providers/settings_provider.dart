import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';

// ── Onboarding ────────────────────────────────────────────────────────────────

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.isOnboardingComplete();
});

// ── Settings state ────────────────────────────────────────────────────────────

class AppSettings {
  final int paydayDate;
  final bool notificationEnabled;
  final int reminderHour;
  final int reminderMinute;
  final List<int> reminderDays;

  const AppSettings({
    required this.paydayDate,
    required this.notificationEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.reminderDays,
  });

  AppSettings copyWith({
    int? paydayDate,
    bool? notificationEnabled,
    int? reminderHour,
    int? reminderMinute,
    List<int>? reminderDays,
  }) =>
      AppSettings(
        paydayDate: paydayDate ?? this.paydayDate,
        notificationEnabled: notificationEnabled ?? this.notificationEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        reminderDays: reminderDays ?? this.reminderDays,
      );
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    final payday = await repo.getPaydayDate();
    final notif = await repo.isNotificationEnabled();
    final hour = await repo.getReminderHour();
    final minute = await repo.getReminderMinute();
    final days = await repo.getReminderDays();
    return AppSettings(
      paydayDate: payday,
      notificationEnabled: notif,
      reminderHour: hour,
      reminderMinute: minute,
      reminderDays: days,
    );
  }

  Future<void> setPaydayDate(int day) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setPaydayDate(day);
    state = state.whenData((s) => s.copyWith(paydayDate: day));
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setNotificationEnabled(enabled);
    state = state.whenData((s) => s.copyWith(notificationEnabled: enabled));
  }

  Future<void> setReminderHour(int hour) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setReminderHour(hour);
    state = state.whenData((s) => s.copyWith(reminderHour: hour));
  }

  Future<void> setReminderMinute(int minute) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setReminderMinute(minute);
    state = state.whenData((s) => s.copyWith(reminderMinute: minute));
  }

  Future<void> setReminderDays(List<int> days) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setReminderDays(days);
    state = state.whenData((s) => s.copyWith(reminderDays: days));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
