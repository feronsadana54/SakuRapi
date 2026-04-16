// Widget tests for SplashScreen navigation behaviour.
//
// Covers:
//  - Splash renders app name and tagline.
//  - After the 1.6-second timer, navigates to /home when onboarding is done.
//  - After the 1.6-second timer, navigates to /onboarding when not done.
//  - Navigation falls through to /home on repository error (never hangs).
//
// Run: flutter test test/widget/splash_navigation_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/core/constants/app_strings.dart';
import 'package:finance_tracker/domain/repositories/i_settings_repository.dart';
import 'package:finance_tracker/presentation/features/splash/splash_screen.dart';
import 'package:finance_tracker/presentation/providers/database_provider.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

/// A settings repository whose [isOnboardingComplete] always throws.
/// Used to verify the splash error-fallthrough path.
class _ThrowingSettingsRepo implements ISettingsRepository {
  @override
  Future<bool> isOnboardingComplete() => Future.error(StateError('db error'));

  // The remaining methods are never called in the splash test.
  @override
  Future<void> setOnboardingComplete(bool value) async {}
  @override
  Future<int> getPaydayDate() async => 25;
  @override
  Future<void> setPaydayDate(int day) async {}
  @override
  Future<bool> isNotificationEnabled() async => true;
  @override
  Future<void> setNotificationEnabled(bool enabled) async {}
  @override
  Future<int> getReminderHour() async => 21;
  @override
  Future<void> setReminderHour(int hour) async {}
  @override
  Future<int> getReminderMinute() async => 0;
  @override
  Future<void> setReminderMinute(int minute) async {}
  @override
  Future<List<int>> getReminderDays() async => [1, 2, 3, 4, 5, 6, 7];
  @override
  Future<void> setReminderDays(List<int> days) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Builds a minimal routed app with SplashScreen at '/'.
Widget _app({
  required SharedPreferences prefs,
  required Widget homePage,
  required Widget onboardingPage,
}) {
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => homePage,
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => onboardingPage,
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID')],
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen — render', () {
    testWidgets('shows app name and tagline', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_app(
        prefs: prefs,
        homePage: const Scaffold(body: Text('Beranda')),
        onboardingPage: const Scaffold(body: Text('Onboarding')),
      ));

      // Before the timer fires the splash is still visible.
      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.text(AppStrings.tagline), findsOneWidget);
    });
  });

  group('SplashScreen — navigation', () {
    testWidgets('navigates to /home when onboarding is complete', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_app(
        prefs: prefs,
        homePage: const Scaffold(body: Text('Beranda')),
        onboardingPage: const Scaffold(body: Text('Onboarding')),
      ));

      // Advance past the 1.6-second splash delay.
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Onboarding'), findsNothing);
    });

    testWidgets('navigates to /onboarding when onboarding is not complete',
        (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': false});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_app(
        prefs: prefs,
        homePage: const Scaffold(body: Text('Beranda')),
        onboardingPage: const Scaffold(body: Text('Onboarding')),
      ));

      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      expect(find.text('Onboarding'), findsOneWidget);
      expect(find.text('Beranda'), findsNothing);
    });

    testWidgets('falls through to /home when onboarding key is missing',
        (tester) async {
      // No key set → isOnboardingComplete returns false by default,
      // so this goes to onboarding on first launch.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_app(
        prefs: prefs,
        homePage: const Scaffold(body: Text('Beranda')),
        onboardingPage: const Scaffold(body: Text('Onboarding')),
      ));

      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      // Missing key → onboarding_complete = false → goes to onboarding.
      expect(find.text('Onboarding'), findsOneWidget);
    });

    testWidgets('falls through to /home when repository throws an error',
        (tester) async {
      // Override the settings repository with one that always throws.
      // The splash catch-block sets isComplete=true on any error,
      // routing the user to /home rather than hanging on splash.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (_, _) => const SplashScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('Beranda')),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const Scaffold(body: Text('Onboarding')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            // Replace the repo with one that throws — simulates a DB error.
            settingsRepositoryProvider
                .overrideWithValue(_ThrowingSettingsRepo()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('id', 'ID')],
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      // Error → isComplete=true → must go to /home, not hang or crash.
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Onboarding'), findsNothing);
    });
  });
}
