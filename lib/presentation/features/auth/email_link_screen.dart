import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/responsive/app_spacing.dart';
import '../../../core/responsive/app_type_scale.dart';
import '../../../core/responsive/responsive_container.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../router/app_router.dart';

// ── Layar input email ─────────────────────────────────────────────────────────

/// Layar login via Email Link (passwordless).
///
/// Pengguna memasukkan alamat email → aplikasi mengirim tautan masuk →
/// navigasi ke [EmailLinkSentScreen]. Saat pengguna mengklik tautan di
/// emailnya, [_EmailLinkHandler] di [app.dart] menangkap URI dan
/// menyelesaikan proses sign-in secara otomatis.
class EmailLinkScreen extends ConsumerStatefulWidget {
  const EmailLinkScreen({super.key});

  @override
  ConsumerState<EmailLinkScreen> createState() => _EmailLinkScreenState();
}

class _EmailLinkScreenState extends ConsumerState<EmailLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(currentUserProvider.notifier)
          .sendEmailSignInLink(_emailCtrl.text.trim());

      if (!mounted) return;
      context.go(AppRoutes.emailLinkSent);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = _parseError(e.toString());
      });
    }
  }

  String _parseError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('network') ||
        lower.contains('network-request-failed')) {
      return 'Tidak ada koneksi internet. Coba lagi setelah terhubung ke jaringan.';
    }
    if (lower.contains('invalid-email')) {
      return 'Alamat email tidak valid. Periksa kembali penulisannya.';
    }
    if (lower.contains('operation-not-allowed')) {
      return 'Login email belum diaktifkan di Firebase. Hubungi pengembang.';
    }
    if (lower.contains('too-many-requests')) {
      return 'Terlalu banyak permintaan. Tunggu beberapa saat lalu coba lagi.';
    }
    return 'Gagal mengirim link. Pastikan email benar dan coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    final p = AppSpacing.pagePadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Masuk dengan Email'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(p),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AppSpacing.xl),

                  // ── Ikon ──────────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mail_outline_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // ── Judul ──────────────────────────────────────────────
                  Text(
                    'Masuk Tanpa Kata Sandi',
                    style: TextStyle(
                      fontSize: AppTypeScale.heading(context),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Masukkan emailmu, kami akan kirimkan tautan masuk. '
                    'Tidak perlu kata sandi.',
                    style: TextStyle(
                      fontSize: AppTypeScale.bodyText(context),
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: AppSpacing.xl * 1.5),

                  // ── Input email ────────────────────────────────────────
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    enabled: !_isSending,
                    decoration: InputDecoration(
                      labelText: AppStrings.emailInputLabel,
                      hintText: AppStrings.emailInputHint,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppStrings.emailInvalid;
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                          .hasMatch(v.trim())) {
                        return AppStrings.emailInvalid;
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _sendLink(),
                  ),

                  // ── Error message ──────────────────────────────────────
                  if (_errorMessage != null) ...[
                    SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.expenseLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 18, color: AppColors.expense),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: AppTypeScale.caption(context),
                                color: AppColors.expense,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: AppSpacing.lg),

                  // ── Tombol kirim ───────────────────────────────────────
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isSending ? null : _sendLink,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              AppStrings.sendEmailLink,
                              style: TextStyle(
                                fontSize: AppTypeScale.bodyText(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.lg),

                  // ── Catatan keamanan ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.incomeLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.income.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.security_rounded,
                            size: 18, color: AppColors.income),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tautan masuk berlaku sekali dan kedaluwarsa dalam 1 jam. '
                            'Data kamu disinkronkan ke cloud secara otomatis.',
                            style: TextStyle(
                              fontSize: AppTypeScale.caption(context),
                              color: AppColors.textSecondary,
                              height: 1.4,
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
      ),
    );
  }
}

// ── Layar konfirmasi tautan terkirim ──────────────────────────────────────────

/// Layar yang ditampilkan setelah tautan masuk berhasil dikirim ke email.
///
/// Memberikan instruksi langkah demi langkah kepada pengguna.
/// Saat pengguna mengklik tautan di emailnya, [_EmailLinkHandler]
/// secara otomatis menyelesaikan sign-in dan mengarahkan ke home.
class EmailLinkSentScreen extends ConsumerWidget {
  const EmailLinkSentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppSpacing.pagePadding(context);
    final email = ref.read(authServiceProvider).getPendingEmail() ?? '—';

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

                // ── Ikon sukses ────────────────────────────────────────
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.incomeLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      size: 44,
                      color: AppColors.income,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // ── Judul ──────────────────────────────────────────────
                Text(
                  AppStrings.emailLinkSentTitle,
                  style: TextStyle(
                    fontSize: AppTypeScale.heading(context),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Link masuk sudah kami kirim ke:',
                  style: TextStyle(
                    fontSize: AppTypeScale.bodyText(context),
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: AppTypeScale.bodyText(context),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppSpacing.xl),

                // ── Instruksi ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      _Step(
                        number: '1',
                        text: 'Buka aplikasi email di perangkatmu',
                      ),
                      const Divider(height: 20),
                      _Step(
                        number: '2',
                        text:
                            'Temukan email dari noreply@sakurapi-aa6ac.firebaseapp.com',
                      ),
                      const Divider(height: 20),
                      _Step(
                        number: '3',
                        text:
                            'Ketuk tautan "Masuk ke SakuRapi" — kamu akan langsung masuk',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.emailLinkSentNote,
                  style: TextStyle(
                    fontSize: AppTypeScale.caption(context),
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppSpacing.xl),

                // ── Tombol kembali ─────────────────────────────────────
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.login),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppStrings.emailLinkSentBack,
                    style: TextStyle(
                        fontSize: AppTypeScale.bodyText(context)),
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

// ── Helper widget ─────────────────────────────────────────────────────────────

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppTypeScale.bodyText(context),
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
