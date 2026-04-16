import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/i_settings_repository.dart';

class SettingsRepositoryImpl implements ISettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepositoryImpl(this._prefs);

  static const _keyOnboarding = 'onboarding_complete';
  static const _keyPayday = 'payday_date';
  static const _keyNotification = 'notification_enabled';
  static const _keyReminderHour = 'reminder_hour';
  static const _keyReminderMinute = 'reminder_minute';
  static const _keyReminderDays = 'reminder_days';

  @override
  Future<bool> isOnboardingComplete() async =>
      _prefs.getBool(_keyOnboarding) ?? false;

  @override
  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(_keyOnboarding, value);

  @override
  Future<int> getPaydayDate() async => _prefs.getInt(_keyPayday) ?? 25;

  @override
  Future<void> setPaydayDate(int day) => _prefs.setInt(_keyPayday, day);

  @override
  Future<bool> isNotificationEnabled() async =>
      _prefs.getBool(_keyNotification) ?? true;

  @override
  Future<void> setNotificationEnabled(bool enabled) =>
      _prefs.setBool(_keyNotification, enabled);

  @override
  Future<int> getReminderHour() async =>
      _prefs.getInt(_keyReminderHour) ?? 21;

  @override
  Future<void> setReminderHour(int hour) =>
      _prefs.setInt(_keyReminderHour, hour);

  @override
  Future<int> getReminderMinute() async =>
      _prefs.getInt(_keyReminderMinute) ?? 0;

  @override
  Future<void> setReminderMinute(int minute) =>
      _prefs.setInt(_keyReminderMinute, minute);

  @override
  Future<List<int>> getReminderDays() async {
    final raw = _prefs.getString(_keyReminderDays);
    if (raw == null || raw.isEmpty) return [1, 2, 3, 4, 5, 6, 7];
    return raw
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toList();
  }

  @override
  Future<void> setReminderDays(List<int> days) =>
      _prefs.setString(_keyReminderDays, days.join(','));
}
