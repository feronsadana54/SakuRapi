// Integration tests — run on a connected device or emulator.
//
// Each test boots the full app via app.main() and verifies end-to-end flows.
//
// Run on a connected device:
//   flutter test integration_test/app_startup_test.dart -d <device_id>
//
// Run with flutter drive (generates JUnit XML for CI):
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_startup_test.dart \
//     -d <device_id>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/main.dart' as app;
import 'package:finance_tracker/core/constants/app_strings.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── 1. First launch (fresh install) ────────────────────────────────────────
  testWidgets('first launch: splash → onboarding (fresh install)',
      (tester) async {
    // Simulate a fresh install — no prefs written yet.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await tester.pump();

    // Splash branding is visible.
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.tagline), findsOneWidget);

    // Advance past the 1.6-second splash delay and let navigation settle.
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Must have navigated away from the splash.
    // Splash text is no longer on screen.
    expect(find.text(AppStrings.tagline), findsNothing,
        reason: 'App is still on splash — possible hang regression');
  });

  // ── 2. Subsequent launch (onboarding already complete) ────────────────────
  testWidgets('subsequent launch: splash → home without hanging',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('onboarding_complete', true);

    app.main();
    await tester.pump();

    // Splash is showing.
    expect(find.text(AppStrings.appName), findsOneWidget);

    // Advance past splash delay.
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Splash tagline must be gone — we have navigated to home.
    expect(find.text(AppStrings.tagline), findsNothing,
        reason: 'App is still on splash after navigation window elapsed');

    // Bottom navigation bar should be visible (contains "Beranda").
    expect(find.text(AppStrings.navHome), findsOneWidget);
  });

  // ── 3. Reminder settings persist ─────────────────────────────────────────
  testWidgets('reminder toggle persists to SharedPreferences', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setBool('notification_enabled', true);

    app.main();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Navigate to settings screen via bottom nav.
    await tester.tap(find.text(AppStrings.navSettings));
    await tester.pumpAndSettle();

    // Tap the first Switch (the reminder toggle).
    final toggle = find.byType(Switch).first;
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    // Verify the value was persisted.
    final updatedPrefs = await SharedPreferences.getInstance();
    expect(updatedPrefs.getBool('notification_enabled'), isFalse);
  });

  // Expose the binding so CI can get the test results.
  tearDownAll(() {
    binding.reportData ??= <String, dynamic>{};
  });
}
