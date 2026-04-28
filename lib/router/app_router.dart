import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../domain/entities/hutang_entity.dart';
import '../domain/entities/piutang_entity.dart';
import '../domain/entities/transaction_entity.dart';
import '../presentation/features/auth/email_link_screen.dart';
import '../presentation/features/auth/login_screen.dart';
import '../presentation/features/home/home_screen.dart';
import '../presentation/features/hutang/hutang_detail_screen.dart';
import '../presentation/features/hutang/hutang_form_screen.dart';
import '../presentation/features/hutang/hutang_list_screen.dart';
import '../presentation/features/onboarding/onboarding_screen.dart';
import '../presentation/features/piutang/piutang_detail_screen.dart';
import '../presentation/features/piutang/piutang_form_screen.dart';
import '../presentation/features/piutang/piutang_list_screen.dart';
import '../presentation/features/reports/reports_screen.dart';
import '../presentation/features/settings/settings_screen.dart';
import '../presentation/features/shell/app_shell.dart';
import '../presentation/features/splash/splash_screen.dart';
import '../presentation/features/transactions/transaction_form_screen.dart';
import '../presentation/features/transactions/transaction_list_screen.dart';

// ── Konstanta nama rute ───────────────────────────────────────────────────────
//
// Semua rute aplikasi terdaftar di sini.
// Gunakan konstanta ini (bukan string literal) di semua pemanggil context.go/push
// agar perubahan nama rute hanya perlu dilakukan di satu tempat.

/// Daftar semua nama rute aplikasi.
/// Rute di dalam [ShellRoute] menampilkan bottom navigation bar.
/// Rute di luar shell adalah layar penuh (form, detail, splash, login).
abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const emailLink = '/login/email';
  static const emailLinkSent = '/login/email/sent';
  static const home = '/home';
  static const transactionList = '/transactions';
  static const transactionAdd = '/transactions/add';
  static const transactionEdit = '/transactions/edit';
  static const hutangList = '/hutang';
  static const hutangAdd = '/hutang/add';
  static const hutangEdit = '/hutang/edit';
  static const hutangDetail = '/hutang/detail';
  static const piutangList = '/piutang';
  static const piutangAdd = '/piutang/add';
  static const piutangEdit = '/piutang/edit';
  static const piutangDetail = '/piutang/detail';
  static const reports = '/reports';
  static const settings = '/settings';
}

// ── Provider router ───────────────────────────────────────────────────────────

/// Provider GoRouter yang mengonfigurasi seluruh sistem navigasi aplikasi.
///
/// Titik masuk navigasi: [AppRoutes.splash] (/splash).
/// Setelah splash, navigasi dilanjutkan ke /onboarding, /login, atau /home
/// tergantung status onboarding dan autentikasi pengguna.
///
/// Struktur rute:
/// - Rute standalone (splash, onboarding, login, form): ditampilkan tanpa shell
/// - [ShellRoute]: membungkus layar utama dengan bottom nav bar via [AppShell]
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // ── Layar standalone (tanpa shell/nav bar) ─────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailLink,
        builder: (context, state) => const EmailLinkScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailLinkSent,
        builder: (context, state) => const EmailLinkSentScreen(),
      ),

      // ── Form transaksi (layar penuh, tanpa nav bar) ───────────
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

      // ── Form/detail hutang (layar penuh, tanpa nav bar) ───────
      // Extra berisi HutangEntity saat edit/detail, null saat tambah baru.
      GoRoute(
        path: AppRoutes.hutangAdd,
        builder: (context, state) => const HutangFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.hutangEdit,
        builder: (context, state) {
          final hutang = state.extra as HutangEntity?;
          return HutangFormScreen(editHutang: hutang);
        },
      ),
      GoRoute(
        path: AppRoutes.hutangDetail,
        builder: (context, state) {
          final hutang = state.extra as HutangEntity;
          return HutangDetailScreen(hutang: hutang);
        },
      ),

      // ── Form/detail piutang (layar penuh, tanpa nav bar) ──────
      // Extra berisi PiutangEntity saat edit/detail, null saat tambah baru.
      GoRoute(
        path: AppRoutes.piutangAdd,
        builder: (context, state) => const PiutangFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.piutangEdit,
        builder: (context, state) {
          final piutang = state.extra as PiutangEntity?;
          return PiutangFormScreen(editPiutang: piutang);
        },
      ),
      GoRoute(
        path: AppRoutes.piutangDetail,
        builder: (context, state) {
          final piutang = state.extra as PiutangEntity;
          return PiutangDetailScreen(piutang: piutang);
        },
      ),

      // ── Shell utama (dengan bottom nav / nav rail) ────────────
      // Semua rute di dalam ShellRoute dibungkus AppShell yang menampilkan
      // NavigationBar (ponsel) atau NavigationRail (tablet).
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
            path: AppRoutes.hutangList,
            builder: (context, state) => const HutangListScreen(),
          ),
          GoRoute(
            path: AppRoutes.piutangList,
            builder: (context, state) => const PiutangListScreen(),
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
