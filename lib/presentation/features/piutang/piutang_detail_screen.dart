import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/responsive/app_spacing.dart';
import '../../../core/responsive/app_type_scale.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/hutang_entity.dart';
import '../../../domain/entities/piutang_entity.dart';
import '../../../presentation/providers/piutang_provider.dart';
import '../../../router/app_router.dart';

class PiutangDetailScreen extends ConsumerWidget {
  final PiutangEntity piutang;

  const PiutangDetailScreen({required this.piutang, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final piutangAsync = ref.watch(piutangListProvider);
    final livePiutang = piutangAsync.maybeWhen(
      data: (list) => list.where((p) => p.id == piutang.id).firstOrNull,
      orElse: () => null,
    ) ?? piutang;

    final p = AppSpacing.pagePadding(context);
    final isOverdue = livePiutang.tanggalJatuhTempo != null &&
        DateTime.now().isAfter(livePiutang.tanggalJatuhTempo!) &&
        !livePiutang.isLunas;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(livePiutang.namaPeminjam),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push(AppRoutes.piutangEdit, extra: livePiutang),
            tooltip: AppStrings.editPiutang,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.expense,
            onPressed: () => _confirmDelete(context, ref, livePiutang.id),
            tooltip: AppStrings.deletePiutang,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(p),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderCard(piutang: livePiutang, isOverdue: isOverdue),
            SizedBox(height: AppSpacing.sectionGap(context)),

            if (!livePiutang.isLunas) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text(AppStrings.bayarSebagian),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.receivable,
                        side: const BorderSide(color: AppColors.receivable),
                      ),
                      onPressed: () =>
                          _showPaymentDialog(context, ref, livePiutang),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text(AppStrings.tandaiLunas),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.income,
                      ),
                      onPressed: () =>
                          _confirmMarkLunas(context, ref, livePiutang.id),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sectionGap(context)),
            ],

            _InfoSection(piutang: livePiutang, isOverdue: isOverdue),
            SizedBox(height: AppSpacing.sectionGap(context)),

            if (livePiutang.riwayatPembayaran.isNotEmpty) ...[
              Text(
                AppStrings.riwayatPembayaran,
                style: TextStyle(
                  fontSize: AppTypeScale.sectionTitle(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...livePiutang.riwayatPembayaran.map(
                (p) => _PaymentRow(payment: p),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deletePiutang),
        content: const Text(AppStrings.deletePiutangBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(piutangNotifierProvider.notifier).deletePiutang(id);
      if (context.mounted) context.pop();
    }
  }

  Future<void> _confirmMarkLunas(
      BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.konfirmasiLunas),
        content: const Text('Piutang ini akan ditandai sebagai lunas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.income),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.tandaiLunas),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(piutangNotifierProvider.notifier).markAsLunas(id);
    }
  }

  Future<void> _showPaymentDialog(
      BuildContext context, WidgetRef ref, PiutangEntity piutang) async {
    final controller = TextEditingController();
    final catatanController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.bayarSebagian),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sisa piutang: ${CurrencyFormatter.full(piutang.sisaPiutang)}',
                style: TextStyle(
                  fontSize: AppTypeScale.caption(ctx),
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Jumlah yang diterima',
                  prefixText: 'Rp  ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Masukkan jumlah';
                  final amount = double.tryParse(v);
                  if (amount == null || amount <= 0) return 'Jumlah tidak valid';
                  if (amount > piutang.sisaPiutang) return 'Melebihi sisa piutang';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catatanController,
                decoration: const InputDecoration(
                  hintText: 'Catatan (opsional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, double.parse(controller.text));
              }
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      await ref.read(piutangNotifierProvider.notifier).addPayment(
            piutang.id,
            result,
            catatan: catatanController.text.trim().isEmpty
                ? null
                : catatanController.text.trim(),
          );
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final PiutangEntity piutang;
  final bool isOverdue;

  const _HeaderCard({required this.piutang, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: piutang.isLunas
              ? [AppColors.income, const Color(0xFF1B5E20)]
              : [AppColors.receivable, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                piutang.isLunas ? 'LUNAS' : 'AKTIF',
                style: TextStyle(
                  fontSize: AppTypeScale.caption(context),
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              if (isOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'JATUH TEMPO',
                    style: TextStyle(
                      fontSize: AppTypeScale.caption(context) - 1,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.full(piutang.sisaPiutang),
            style: TextStyle(
              fontSize: AppTypeScale.balanceDisplay(context),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            'Sisa dari ${CurrencyFormatter.full(piutang.jumlahAwal)}',
            style: TextStyle(
              fontSize: AppTypeScale.caption(context),
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: piutang.progressPersen,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(piutang.progressPersen * 100).toStringAsFixed(0)}% sudah kembali',
            style: TextStyle(
              fontSize: AppTypeScale.caption(context),
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final PiutangEntity piutang;
  final bool isOverdue;

  const _InfoSection({required this.piutang, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          _InfoRow(label: AppStrings.namaPeminjam, value: piutang.namaPeminjam),
          const Divider(height: 20),
          _InfoRow(
            label: AppStrings.tanggalPinjam,
            value: AppDateUtils.formatFull(piutang.tanggalPinjam),
          ),
          if (piutang.tanggalJatuhTempo != null) ...[
            const Divider(height: 20),
            _InfoRow(
              label: AppStrings.tanggalJatuhTempo,
              value: AppDateUtils.formatFull(piutang.tanggalJatuhTempo!),
              valueColor: isOverdue ? AppColors.expense : null,
            ),
          ],
          const Divider(height: 20),
          _InfoRow(
            label: 'Total Diterima',
            value: CurrencyFormatter.full(piutang.totalDiterima),
            valueColor: AppColors.income,
          ),
          if (piutang.catatan != null) ...[
            const Divider(height: 20),
            _InfoRow(label: 'Catatan', value: piutang.catatan!),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypeScale.bodyText(context),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: AppTypeScale.bodyText(context),
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final PaymentRecord payment;

  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.incomeLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.income.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.income, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.full(payment.amount),
                  style: TextStyle(
                    fontSize: AppTypeScale.bodyText(context),
                    fontWeight: FontWeight.w600,
                    color: AppColors.income,
                  ),
                ),
                if (payment.catatan != null)
                  Text(
                    payment.catatan!,
                    style: TextStyle(
                      fontSize: AppTypeScale.caption(context),
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            AppDateUtils.formatShort(payment.paidAt),
            style: TextStyle(
              fontSize: AppTypeScale.caption(context),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
