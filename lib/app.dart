import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/user_entity.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/database_provider.dart';
import 'router/app_router.dart';

/// Widget root aplikasi.
///
/// Dibuat di dalam [UncontrolledProviderScope] (lihat main.dart) agar semua
/// Riverpod provider dapat diakses di seluruh widget tree.
///
/// [MaterialApp.router.builder] membungkus setiap halaman dengan
/// [_EmailLinkHandler] yang menangkap URI deep link email sign-in dan
/// menyelesaikan proses autentikasi secara otomatis.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Dua handler transparan membungkus semua halaman:
      // 1. _RealtimeSyncHandler — mulai/hentikan listener Firestore berdasarkan auth state
      // 2. _EmailLinkHandler   — selesaikan sign-in email saat URI deep link masuk
      builder: (context, child) =>
          _RealtimeSyncHandler(child: _EmailLinkHandler(child: child!)),
    );
  }
}

// ── Email Link Handler ────────────────────────────────────────────────────────

/// Mendengarkan [pendingEmailLinkProvider] dan menyelesaikan sign-in email
/// secara otomatis saat URI tautan masuk diterima dari deep link.
///
/// Ditempatkan di atas semua halaman agar navigasi ke home dapat dilakukan
/// tanpa bergantung pada layar mana yang sedang aktif.
class _EmailLinkHandler extends ConsumerStatefulWidget {
  const _EmailLinkHandler({required this.child});
  final Widget child;

  @override
  ConsumerState<_EmailLinkHandler> createState() => _EmailLinkHandlerState();
}

class _EmailLinkHandlerState extends ConsumerState<_EmailLinkHandler> {
  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(pendingEmailLinkProvider, (_, link) async {
      if (link == null) return;

      // Konsumsi segera agar tidak diproses dua kali jika build dipanggil ulang.
      ref.read(pendingEmailLinkProvider.notifier).state = null;

      try {
        final handled =
            await ref.read(currentUserProvider.notifier).handleEmailLink(link);
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        if (handled) context.go(AppRoutes.home);
      } catch (_) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(AppStrings.emailLinkError),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ));
      }
    });

    return widget.child;
  }
}

// ── Realtime Sync Handler ─────────────────────────────────────────────────────

/// Memulai dan menghentikan listener Firestore realtime berdasarkan auth state.
///
/// Widget ini hidup sepanjang masa pakai aplikasi (dibungkus di [App.builder])
/// sehingga listener aktif selama pengguna terautentikasi di layar mana pun.
///
/// **Alur start:**
///   - `initState`: jika pengguna sudah login saat app dibuka, langsung start
///   - `ref.listen`: saat auth state berubah ke authenticated, start listener
///
/// **Alur stop:**
///   - Saat auth state berubah ke null/tamu, stop semua listener
///   - Provider juga memanggil stopListening saat dispose (safety net)
class _RealtimeSyncHandler extends ConsumerStatefulWidget {
  const _RealtimeSyncHandler({required this.child});
  final Widget child;

  @override
  ConsumerState<_RealtimeSyncHandler> createState() =>
      _RealtimeSyncHandlerState();
}

class _RealtimeSyncHandlerState extends ConsumerState<_RealtimeSyncHandler> {
  @override
  void initState() {
    super.initState();
    // Mulai listener jika sesi sudah ada saat widget pertama kali dibuat.
    // Jika auth masih AsyncLoading, ref.listen di build() akan menangani transisi.
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null && user.isAuthenticated) {
      ref.read(realtimeSyncServiceProvider).startListening(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserEntity?>>(currentUserProvider, (prev, next) {
      final prevUser = prev?.valueOrNull;
      final nextUser = next.valueOrNull;
      final syncService = ref.read(realtimeSyncServiceProvider);

      if (nextUser != null && nextUser.isAuthenticated) {
        // Mulai (atau restart jika userId berubah, misalnya akun berbeda).
        syncService.startListening(nextUser.id);
      } else if (prevUser?.isAuthenticated == true) {
        // Pengguna baru saja logout atau downgrade ke tamu.
        syncService.stopListening();
      }
    });

    return widget.child;
  }
}
