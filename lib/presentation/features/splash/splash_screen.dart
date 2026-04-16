import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/database_provider.dart';
import '../../../router/app_router.dart';

/// Layar pertama yang ditampilkan setiap kali aplikasi dibuka.
///
/// Menampilkan logo + nama aplikasi selama 1,6 detik, lalu memutuskan navigasi:
///
///   1. [SettingsRepository.isOnboardingComplete] == false  → /onboarding
///   2. [AuthService.getCurrentUser] == null               → /login
///   3. pengguna sudah login                               → /home
///   4. exception atau timeout apapun                      → /home (fail-safe)
///
/// Semua operasi I/O dibungkus timeout 3 detik agar repository yang bermasalah
/// tidak membuat pengguna terjebak di splash selamanya.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  Timer? _navTimer;

  static const _splashDelay = Duration(milliseconds: 1600);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _navTimer = Timer(_splashDelay, _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    bool onboardingComplete = false;
    bool isLoggedIn = false;

    try {
      final repo = ref.read(settingsRepositoryProvider);
      onboardingComplete = await repo
          .isOnboardingComplete()
          .timeout(const Duration(seconds: 3));

      if (onboardingComplete) {
        final authService = ref.read(authServiceProvider);
        final user = await authService
            .getCurrentUser()
            .timeout(const Duration(seconds: 3));
        isLoggedIn = user != null;
      }
    } catch (_) {
      // On error/timeout → go to home to avoid being stuck
      onboardingComplete = true;
      isLoggedIn = true;
    }

    if (!mounted) return;

    if (!onboardingComplete) {
      context.go(AppRoutes.onboarding);
    } else if (!isLoggedIn) {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.appName,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.tagline,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
