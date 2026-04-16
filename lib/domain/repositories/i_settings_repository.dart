abstract interface class ISettingsRepository {
  Future<bool> isOnboardingComplete();
  Future<void> setOnboardingComplete(bool value);

  Future<int> getPaydayDate();
  Future<void> setPaydayDate(int day);

  Future<bool> isNotificationEnabled();
  Future<void> setNotificationEnabled(bool enabled);

  Future<int> getReminderHour();
  Future<void> setReminderHour(int hour);

  Future<int> getReminderMinute();
  Future<void> setReminderMinute(int minute);

  /// Returns list of weekday ints: Monday=1 … Sunday=7.
  /// Default is all 7 days.
  Future<List<int>> getReminderDays();
  Future<void> setReminderDays(List<int> days);
}
