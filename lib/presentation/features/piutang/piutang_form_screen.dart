import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/responsive/app_spacing.dart';
import '../../../core/responsive/app_type_scale.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/piutang_entity.dart';
import '../../../presentation/providers/piutang_provider.dart';

class PiutangFormScreen extends ConsumerStatefulWidget {
  final PiutangEntity? editPiutang;

  const PiutangFormScreen({this.editPiutang, super.key});

  @override
  ConsumerState<PiutangFormScreen> createState() => _PiutangFormScreenState();
}

class _PiutangFormScreenState extends ConsumerState<PiutangFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _catatanController = TextEditingController();

  DateTime _tanggalPinjam = DateTime.now();
  DateTime? _tanggalJatuhTempo;
  bool _isSaving = false;

  bool get _isEditing => widget.editPiutang != null;

  @override
  void initState() {
    super.initState();
    final p = widget.editPiutang;
    if (p != null) {
      _namaController.text = p.namaPeminjam;
      _jumlahController.text = p.jumlahAwal.toInt().toString();
      _catatanController.text = p.catatan ?? '';
      _tanggalPinjam = p.tanggalPinjam;
      _tanggalJatuhTempo = p.tanggalJatuhTempo;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _jumlahController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isJatuhTempo) async {
    final initial = isJatuhTempo
        ? (_tanggalJatuhTempo ?? DateTime.now().add(const Duration(days: 30)))
        : _tanggalPinjam;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isJatuhTempo) {
          _tanggalJatuhTempo = picked;
        } else {
          _tanggalPinjam = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      const uuid = Uuid();
      final rawDigits =
          _jumlahController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final jumlah = double.tryParse(rawDigits) ?? 0;

      final now = DateTime.now();
      final piutang = PiutangEntity(
        id: widget.editPiutang?.id ?? uuid.v4(),
        namaPeminjam: _namaController.text.trim(),
        jumlahAwal: jumlah,
        sisaPiutang: widget.editPiutang?.sisaPiutang ?? jumlah,
        tanggalPinjam: AppDateUtils.dateOnly(_tanggalPinjam),
        tanggalJatuhTempo: _tanggalJatuhTempo != null
            ? AppDateUtils.dateOnly(_tanggalJatuhTempo!)
            : null,
        catatan: _catatanController.text.trim().isEmpty
            ? null
            : _catatanController.text.trim(),
        status: widget.editPiutang?.status ?? 'aktif',
        riwayatPembayaran: widget.editPiutang?.riwayatPembayaran ?? [],
        createdAt: widget.editPiutang?.createdAt ?? now,
        updatedAt: now,
      );

      final notifier = ref.read(piutangNotifierProvider.notifier);
      if (_isEditing) {
        await notifier.updatePiutang(piutang);
      } else {
        await notifier.addPiutang(piutang);
      }

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.errorGeneral} ($e)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppSpacing.pagePadding(context);
    final title = _isEditing ? AppStrings.editPiutang : AppStrings.tambahPiutang;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: p, vertical: p),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(AppStrings.namaPeminjam,
                        style: TextStyle(
                          fontSize: AppTypeScale.sectionTitle(context),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _namaController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan nama peminjam',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nama harus diisi' : null,
                    ),
                    SizedBox(height: AppSpacing.sectionGap(context)),

                    Text(AppStrings.jumlahAwal,
                        style: TextStyle(
                          fontSize: AppTypeScale.sectionTitle(context),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(height: 8),
                    ValueListenableBuilder(
                      valueListenable: _jumlahController,
                      builder: (ctx, value, _) {
                        final raw = value.text.replaceAll(RegExp(r'[^0-9]'), '');
                        final amount = double.tryParse(raw) ?? 0;
                        return Text(
                          CurrencyFormatter.full(amount),
                          style: TextStyle(
                            fontSize: AppTypeScale.heading(context),
                            fontWeight: FontWeight.w700,
                            color: amount > 0
                                ? AppColors.receivable
                                : AppColors.textHint,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _jumlahController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan jumlah piutang',
                        prefixText: 'Rp  ',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Jumlah tidak boleh kosong';
                        }
                        final raw = v.replaceAll(RegExp(r'[^0-9]'), '');
                        final parsed = double.tryParse(raw);
                        if (parsed == null || parsed <= 0) {
                          return 'Jumlah harus lebih dari 0';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSpacing.sectionGap(context)),

                    _DateField(
                      label: AppStrings.tanggalPinjam,
                      date: _tanggalPinjam,
                      onTap: () => _pickDate(false),
                    ),
                    SizedBox(height: AppSpacing.cardGap(context)),

                    _OptionalDateField(
                      label: '${AppStrings.tanggalJatuhTempo} (opsional)',
                      date: _tanggalJatuhTempo,
                      onTap: () => _pickDate(true),
                      onClear: () => setState(() => _tanggalJatuhTempo = null),
                    ),
                    SizedBox(height: AppSpacing.sectionGap(context)),

                    TextFormField(
                      controller: _catatanController,
                      maxLines: 2,
                      maxLength: 200,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Catatan (opsional)',
                        labelText: 'Catatan',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(p, 12, p, p),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    top: BorderSide(color: AppColors.divider, width: 0.5)),
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.receivable,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(AppStrings.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: AppTypeScale.caption(context),
                      color: AppColors.textSecondary,
                    )),
                Text(AppDateUtils.formatFull(date),
                    style: TextStyle(
                      fontSize: AppTypeScale.bodyText(context),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    )),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _OptionalDateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _OptionalDateField({
    required this.label,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_rounded,
              size: 20,
              color: date != null ? AppColors.receivable : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: AppTypeScale.caption(context),
                      color: AppColors.textSecondary,
                    )),
                Text(
                  date != null ? AppDateUtils.formatFull(date!) : 'Belum ditentukan',
                  style: TextStyle(
                    fontSize: AppTypeScale.bodyText(context),
                    fontWeight: FontWeight.w500,
                    color: date != null ? AppColors.textPrimary : AppColors.textHint,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textSecondary, size: 18),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
