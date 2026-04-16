import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../domain/entities/transaction_entity.dart';
import '../presentation/features/home/home_screen.dart';
import '../presentation/features/onboarding/onboarding_screen.dart';
import '../presentation/features/reports/reports_screen.dart';
import '../presentation/features/settings/settings_screen.dart';
import '../presentation/features/shell/app_shell.dart';
import '../presentation/features/splash/splash_screen.dart';
import '../presentation/features/transactions/transaction_form_screen.dart';
import '../presentation/features/transactions/transaction_list_screen.dart';

// ── Route name constants ──────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const transactionList = '/transactions';
  static const transactionAdd = '/transactions/add';
  static const transactionEdit = '/transactions/edit';
  static const reports = '/reports';
  static const settings = '/settings';
}

// ── Router provider ───────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // ── Standalone screens (no shell) ──────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Transaction form (full-screen, no nav bar) ─────────────
      GoRoute(
        path: AppRoutes.transactionAdd,
        builder: (context, state) => const TransactionFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactionEdit,
        builder: (context, state) {
          final tx = state.extra as Transaction?;
          return TransactionFormScreen(editTransaction: tx);
        },
      ),

      // ── Main shell (with bottom nav / nav rail) ────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(
          location: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.transactionList,
            builder: (context, state) => const TransactionListScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.expense),
            const SizedBox(height: 12),
            Text('Halaman tidak ditemukan: ${state.uri}'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    ),
  );
});

