import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/responsive/app_spacing.dart';
import '../../../core/responsive/app_type_scale.dart';
import '../../../core/responsive/responsive_container.dart';
import '../../../firebase_options.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../router/app_router.dart';

/// Layar login SakuRapi.
///
/// Menawarkan dua pilihan:
///   1. Masuk sebagai Tamu — data lokal saja, tanpa akun.
///   2. Masuk dengan Google — Firebase Auth + Firestore sync (perlu konfigurasi).
///
/// Google Sign-In menampilkan tombol aktif jika [kFirebaseConfigured] == true,
/// atau menampilkan info "segera hadir" jika belum dikonfigurasi.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _loadingMode; // 'guest' | 'google'

  // ── Guest sign-in ─────────────────────────────────────────────────────────

  Future<void> _signInAsGuest() async {
    setState(() {
      _isLoading = true;
      _loadingMode = 'guest';
    });
    try {
      await ref.read(currentUserProvider.notifier).signInAsGuest();
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadingMode = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.errorGeneral} ($e)')),
      );
    }
  }

  // ── Google sign-in ────────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    // Jika Firebase belum dikonfigurasi, tampilkan pesan informatif
    if (!kFirebaseConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.googleSignInNotConfigured),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMode = 'google';
    });

    try {
      final success =
          await ref.read(currentUserProvider.notifier).signInWithGoogle();
      if (!mounted) return;

      if (success) {
        context.go(AppRoutes.home);
      } else {
        setState(() {
          _isLoading = false;
          _loadingMode = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login dibatalkan.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadingMode = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.googleSignInFailed),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = AppSpacing.pagePadding(context);
    final googleReady = kFirebaseConfigured;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.xl * 2),

                // ── Branding ───────────────────────────────────────────
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                Text(
                  AppStrings.loginTitle,
                  style: TextStyle(
                    fontSize: AppTypeScale.heading(context),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  AppStrings.loginSubtitle,
                  style: TextStyle(
                    fontSize: AppTypeScale.bodyText(context),
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppSpacing.xl * 2),

                // ── Tombol Tamu ────────────────────────────────────────
                _LoginButton(
                  icon: Icons.person_outline_rounded,
                  label: AppStrings.loginAsGuest,
                  note: AppStrings.guestModeNote,
                  color: AppColors.primary,
                  bgColor: AppColors.primaryContainer,
                  isLoading: _isLoading && _loadingMode == 'guest',
                  onTap: _isLoading ? null : _signInAsGuest,
                ),
                SizedBox(height: AppSpacing.cardGap(context)),

                // ── Tombol Google ──────────────────────────────────────
                _LoginButton(
                  icon: Icons.account_circle_outlined,
                  label: AppStrings.loginWithGoogle,
                  note: googleReady
                      ? AppStrings.googleSyncNote
                      : 'Memerlukan konfigurasi Firebase',
                  color: googleReady
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  bgColor: googleReady
                      ? AppColors.primaryContainer
                      : AppColors.surfaceVariant,
                  isLoading: _isLoading && _loadingMode == 'google',
                  isDisabled: !googleReady,
                  onTap: _isLoading ? null : _signInWithGoogle,
                ),

                SizedBox(height: AppSpacing.xl),

                // ── Info tambahan ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.incomeLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.income.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.income),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          googleReady
                              ? 'Login Google menyinkronkan data ke cloud. '
                                'Ganti perangkat dan login lagi untuk memulihkan data.'
                              : 'Mode tamu menyimpan data hanya di perangkat ini. '
                                'Login Google (memerlukan konfigurasi Firebase) '
                                'akan menyinkronkan data ke cloud.',
                          style: TextStyle(
                            fontSize: AppTypeScale.caption(context),
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
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

// ── Login option button ───────────────────────────────────────────────────────

class _LoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String note;
  final Color color;
  final Color bgColor;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _LoginButton({
    required this.icon,
    required this.label,
    required this.note,
    required this.color,
    required this.bgColor,
    required this.isLoading,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.6 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDisabled
                  ? AppColors.divider
                  : color.withValues(alpha: 0.4),
              width: isDisabled ? 0.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: AppTypeScale.bodyText(context),
                            fontWeight: FontWeight.w600,
                            color: isDisabled
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (isDisabled) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Setup diperlukan',
                              style: TextStyle(
                                fontSize: AppTypeScale.caption(context) - 1,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: AppTypeScale.caption(context),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDisabled
                    ? AppColors.divider
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
