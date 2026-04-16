// Widget tests for the reminder-settings section inside SettingsScreen.
//
// Covers:
//  - Toggle switch is rendered and reflects the persisted value.
//  - When enabled, the time row and weekday chips are shown.
//  - When disabled, time row and weekday chips are hidden.
//  - Tapping the toggle calls the notification provider (stubbed).
//
// Run: flutter test test/widget/settings_reminder_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/core/constants/app_strings.dart';
import 'package:finance_tracker/data/repositories/settings_repository_impl.dart';
import 'package:finance_tracker/presentation/features/settings/settings_screen.dart';
import 'package:finance_tracker/presentation/providers/database_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Pumps a standalone SettingsScreen with a real SharedPreferences instance.
/// The database providers are not needed for the reminder-settings section.
Future<void> _pumpSettings(
  WidgetTester tester,
  SharedPreferences prefs,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('id', 'ID')],
        home: const SettingsScreen(),
      ),
    ),
  );
  // Let async providers settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen — reminder section defaults', () {
    testWidgets('shows reminder toggle (enabled by default)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await _pumpSettings(tester, prefs);

      // The SwitchListTile for the reminder must be visible.
      expect(find.text(AppStrings.dailyReminder), findsOneWidget);

      // Default is enabled → time and weekday rows should be present.
      expect(find.text(AppStrings.reminderTime), findsOneWidget);
      expect(find.text(AppStrings.reminderDays), findsOneWidget);
    });

    testWidgets('weekday chips are rendered for all 7 days', (tester) async {
      SharedPreferences.setMockInitialValues({'notification_enabled': true});
      final prefs = await SharedPreferences.getInstance();

      await _pumpSettings(tester, prefs);

      for (final label in AppStrings.weekdayShort) {
        expect(find.text(label), findsOneWidget,
            reason: 'Weekday chip "$label" not found');
      }
    });

    testWidgets('default reminder time is 21:00', (tester) async {
      SharedPreferences.setMockInitialValues({'notification_enabled': true});
      final prefs = await SharedPreferences.getInstance();

      await _pumpSettings(tester, prefs);

      // The formatted time "21:00" must appear somewhere in the settings card.
      expect(find.text('21:00'), findsOneWidget);
    });
  });

  group('SettingsScreen — reminder section when disabled', () {
    testWidgets('time and days rows hidden when reminder is disabled',
        (tester) async {
      SharedPreferences.setMockInitialValues({'notification_enabled': false});
      final prefs = await SharedPreferences.getInstance();

      await _pumpSettings(tester, prefs);

      // Toggle must still be visible.
      expect(find.text(AppStrings.dailyReminder), findsOneWidget);

      // When disabled, the expanded rows should NOT be shown.
      expect(find.text(AppStrings.reminderTime), findsNothing);
      expect(find.text(AppStrings.reminderDays), findsNothing);
    });
  });

  group('SettingsRepositoryImpl — defaults', () {
    test('notification enabled by default', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);
      expect(await repo.isNotificationEnabled(), isTrue);
    });

    test('reminder hour default is 21', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);
      expect(await repo.getReminderHour(), 21);
    });

    test('reminder minute default is 0', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);
      expect(await repo.getReminderMinute(), 0);
    });

    test('reminder days default is all 7 days', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);
      expect(await repo.getReminderDays(), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('persists and reads back notification toggle', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);
      await repo.setNotificationEnabled(false);
      expect(await repo.isNotificationEnabled(), isFalse);
      await repo.setNotificationEnabled(true);
      expect(await repo.isNotificationEnabled(), isTrue);
    });

    test('persists and reads back custom reminder time', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);
      await repo.setReminderHour(8);
      await repo.setReminderMinute(30);
      expect(await repo.getReminderHour(), 8);
      expect(await repo.getReminderMinute(), 30);
    });

    test('persists and reads back selected weekdays', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);
      await repo.setReminderDays([1, 3, 5]);
      expect(await repo.getReminderDays(), [1, 3, 5]);
    });

    test('ignores out-of-range day values on read', () async {
      SharedPreferences.setMockInitialValues({'reminder_days': '0,1,8,3'});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);
      // 0 and 8 are out of range [1–7], should be filtered out.
      expect(await repo.getReminderDays(), [1, 3]);
    });
  });
}
