import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

/// Widget root aplikasi — titik masuk seluruh widget tree.
///
/// Dibuat oleh [main] di dalam [ProviderScope] sehingga semua Riverpod provider
/// dapat diakses di seluruh widget tree.
///
/// Tanggung jawab:
/// - Membangun [MaterialApp.router] yang terhubung ke [routerProvider] (GoRouter).
/// - Menerapkan tema global [AppTheme.light] dan locale Bahasa Indonesia.
/// - TIDAK menangani logika navigasi — itu ada di [SplashScreen].
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
    );
  }
}
