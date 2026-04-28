import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/responsive/app_spacing.dart';
import '../../../core/responsive/app_type_scale.dart';
import '../../../core/responsive/responsive_container.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../router/app_router.dart';

/// Layar login SakuRapi.
///
/// Menawarkan dua pilihan:
///   1. Masuk sebagai Tamu — data lokal saja, tanpa akun.
///   2. Masuk dengan Google — Firebase Auth + Firestore sync.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _loadingMode; // 'guest' | 'google'

  // ── Email sign-in ─────────────────────────────────────────────────────────

  void _goToEmailLink() => context.push(AppRoutes.emailLink);

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
    } catch (e, st) {
      dev.log('Guest sign-in error', error: e, stackTrace: st, name: 'LoginScreen');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadingMode = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.errorGeneral)),
      );
    }
  }

  // ── Google sign-in ────────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
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
      _showGoogleErrorDialog(e.toString());
    }
  }

  /// Menampilkan dialog error login Google.
  ///
  /// Pesan yang ditampilkan ke pengguna selalu dalam Bahasa Indonesia.
  /// Detail teknis tidak ditampilkan di UI — hanya tersedia via tombol Salin.
  void _showGoogleErrorDialog(String raw) {
    final friendlyMsg = _googleErrorMessage(raw);
    final lower = raw.toLowerCase();
    final isAndroidConfigError = lower.contains('apiexception: 10') ||
        lower.contains('developer_error') ||
        lower.contains('sign_in_failed') ||
        lower.contains('idtoken kosong');
    final isWebConfigError = lower.contains('[firebase:operation-not-allowed') ||
        lower.contains('[firebase:invalid-api-key') ||
        lower.contains('[firebase:invalid-credential');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 22),
            SizedBox(width: 8),
            Text('Login Gagal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(friendlyMsg, style: const TextStyle(fontSize: 14, height: 1.5)),
            if (isAndroidConfigError) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.expenseLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Checklist Android:\n'
                  '1. SHA-1 debug key sudah didaftarkan di Firebase Console?\n'
                  '2. Google Sign-In diaktifkan di Authentication > Sign-in providers?\n'
                  '3. google-services.json sudah di-download ulang?',
                  style: TextStyle(fontSize: 12, height: 1.6),
                ),
              ),
            ],
            if (isWebConfigError) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.expenseLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Checklist Web:\n'
                  '1. Google Sign-In diaktifkan di Firebase Authentication?\n'
                  '2. Authorized JavaScript Origins sudah mencakup URL dev/produksi?\n'
                  '3. Gunakan port tetap: flutter run -d chrome --web-port 7357',
                  style: TextStyle(fontSize: 12, height: 1.6),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Salin Detail'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: raw));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Detail error disalin ke clipboard.'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  /// Mengonversi kode error Firebase/Google Sign-In ke pesan ramah pengguna dalam Bahasa Indonesia.
  String _googleErrorMessage(String raw) {
    final lower = raw.toLowerCase();

    // Pengguna menutup popup (web)
    if (lower.contains('popup-closed-by-user') ||
        lower.contains('popup_closed') ||
        lower.contains('cancelled-popup-request')) {
      return 'Login dibatalkan.';
    }

    // Browser memblokir popup (web)
    if (lower.contains('popup-blocked')) {
      return 'Browser kamu memblokir popup login Google. '
          'Izinkan popup untuk situs ini, lalu coba lagi.';
    }

    // Pengguna membatalkan (native)
    if (lower.contains('sign_in_cancelled') ||
        lower.contains('canceled') ||
        lower.contains('cancelled')) {
      return 'Login dibatalkan.';
    }

    // Jaringan
    if (lower.contains('network_error') ||
        lower.contains('network-request-failed') ||
        (lower.contains('network') && !lower.contains('sign_in'))) {
      return 'Tidak ada koneksi internet. Coba lagi setelah terhubung ke jaringan.';
    }

    // Kode error Firebase — ekstrak dan terjemahkan
    final firebaseMatch = RegExp(r'\[firebase:([^\]]+)\]').firstMatch(raw);
    final firebaseCode = firebaseMatch?.group(1) ?? '';
    if (firebaseCode == 'invalid-credential' || firebaseCode == 'invalid-api-key') {
      return 'Konfigurasi Firebase tidak valid. Hubungi pengembang.';
    }
    if (firebaseCode == 'operation-not-allowed') {
      return 'Login Google belum diaktifkan di Firebase. Hubungi pengembang.';
    }
    if (firebaseCode == 'user-disabled') {
      return 'Akun ini telah dinonaktifkan.';
    }
    if (firebaseCode == 'account-exists-with-different-credential') {
      return 'Akun sudah terdaftar dengan metode login lain.';
    }

    // Developer/konfigurasi error native (ApiException 10 = DEVELOPER_ERROR)
    if (lower.contains('sign_in_failed') ||
        lower.contains('apiexception: 10') ||
        lower.contains('developer_error') ||
        lower.contains('idtoken kosong')) {
      return 'Login Google belum siap. Pastikan SHA-1 sudah terdaftar di Firebase '
          'Console dan Google Sign-In sudah diaktifkan di Authentication.';
    }

    // Fallback ramah
    return 'Login Google gagal. Coba lagi atau gunakan mode tamu.';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = AppSpacing.pagePadding(context);

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
                  note: AppStrings.googleSyncNote,
                  color: AppColors.primary,
                  bgColor: AppColors.primaryContainer,
                  isLoading: _isLoading && _loadingMode == 'google',
                  onTap: _isLoading ? null : _signInWithGoogle,
                ),
                SizedBox(height: AppSpacing.cardGap(context)),

                // ── Tombol Email Link ──────────────────────────────────
                _LoginButton(
                  icon: Icons.mail_outline_rounded,
                  label: AppStrings.loginWithEmail,
                  note: AppStrings.emailLinkNote,
                  color: AppColors.primary,
                  bgColor: AppColors.primaryContainer,
                  isLoading: false,
                  onTap: _isLoading ? null : _goToEmailLink,
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
                          'Login Google atau Email menyinkronkan data ke cloud. '
                          'Ganti perangkat dan login lagi untuk memulihkan data.',
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
  final VoidCallback? onTap;

  const _LoginButton({
    required this.icon,
    required this.label,
    required this.note,
    required this.color,
    required this.bgColor,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1.5,
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
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: AppTypeScale.bodyText(context),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
