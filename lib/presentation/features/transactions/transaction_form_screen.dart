import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/system_categories.dart';
import '../../../core/responsive/app_spacing.dart';
import '../../../core/responsive/app_type_scale.dart';
import '../../../core/responsive/responsive_container.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/hutang_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../presentation/providers/category_provider.dart';
import '../../../presentation/providers/database_provider.dart';
import '../../../presentation/providers/hutang_provider.dart';
import '../../../presentation/widgets/category_grid_picker.dart';

/// Form tambah / edit transaksi.
///
/// Fitur integrasi Hutang:
///   Jika kategori yang dipilih adalah "Pembayaran Hutang" ([SystemCategories.pembayaranHutang]):
///     1. Tampilkan dropdown untuk memilih hutang aktif.
///     2. Validasi: jumlah tidak boleh melebihi sisa hutang.
///     3. Saat simpan: buat transaksi pengeluaran + panggil
///        [HutangNotifier.updateAfterPayment] untuk memperbarui sisa hutang.
///
/// Alur data saat menyimpan pembayaran hutang:
///   Form → insert Transaction (expense) ke DB
///       → HutangNotifier.updateAfterPayment() → update sisa + riwayat hutang
///       → allTransactionsProvider reaktif → saldo + laporan terupdate otomatis
class TransactionFormScreen extends ConsumerStatefulWidget {
  /// Null = mode tambah. Non-null = mode edit.
  final Transaction? editTransaction;

  const TransactionFormScreen({this.editTransaction, super.key});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState
    extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  Category? _selectedCategory;
  late DateTime _selectedDate;
  bool _isSaving = false;

  // ── State integrasi hutang ─────────────────────────────────────────────────
  // Hanya relevan saat kategori "Pembayaran Hutang" dipilih.
  HutangEntity? _selectedHutang;

  bool get _isEditing => widget.editTransaction != null;

  /// Apakah kategori yang dipilih adalah "Pembayaran Hutang" (sistem).
  bool get _isPembayaranHutang =>
      _selectedCategory?.id == SystemCategories.pembayaranHutangId;

  @override
  void initState() {
    super.initState();
    final tx = widget.editTransaction;
    _type = tx?.type ?? TransactionType.expense;
    _selectedDate = tx?.date ?? DateTime.now();
    _selectedCategory = tx?.category;
    if (tx != null) {
      _amountController.text = tx.amount.toInt().toString();
      _noteController.text = tx.note ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Validasi ──────────────────────────────────────────────────────────────

  String? _validateAmount(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.amountRequired;
    final parsed = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsed == null || parsed <= 0) return AppStrings.amountInvalid;

    // Saat membayar hutang, jumlah tidak boleh melebihi sisa hutang
    if (_isPembayaranHutang && _selectedHutang != null) {
      if (parsed > _selectedHutang!.sisaHutang) {
        return '${AppStrings.jumlahMelebihiSisa}'
            '${CurrencyFormatter.full(_selectedHutang!.sisaHutang)}';
      }
    }

    return null;
  }

  bool _validateCategory() => _selectedCategory != null;

  /// Validasi tambahan untuk alur pembayaran hutang.
  /// Mengembalikan pesan error atau null jika valid.
  String? _validateHutangSelection() {
    if (!_isPembayaranHutang) return null;
    if (_selectedHutang == null) return AppStrings.pilihHutang;
    return null;
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Simpan ────────────────────────────────────────────────────────────────

  /// Menyimpan transaksi baru atau memperbarui transaksi yang sedang diedit.
  ///
  /// **Alur normal (kategori biasa):**
  ///   1. Validasi form + kategori.
  ///   2. repo.insert(tx) / repo.update(tx) → tulis ke SQLite via Drift.
  ///   3. allTransactionsProvider memancar ulang → HomeSummary & laporan terupdate.
  ///   4. Navigator.pop() → kembali ke layar sebelumnya.
  ///
  /// **Alur khusus (kategori "Pembayaran Hutang"):**
  ///   1. Validasi form + validasi hutang yang dipilih.
  ///   2. repo.insert(tx) → buat transaksi pengeluaran di SQLite.
  ///   3. hutangNotifier.updateAfterPayment() → kurangi sisaHutang di tabel hutang.
  ///      PENTING: updateAfterPayment TIDAK membuat transaksi baru (sudah dibuat langkah 2).
  ///   4. Kedua stream (allTransactionsProvider + hutangListProvider) memancar ulang.
  ///
  /// **Efek ke state/UI setelah _save():**
  ///   - [allTransactionsProvider] → [homeSummaryProvider] → HomeScreen rebuild
  ///   - [hutangListProvider] → HutangListScreen rebuild (jika pembayaran hutang)
  ///   - Laporan (daily/monthly/yearly) refresh otomatis via FutureProvider kedaluwarsa
  Future<void> _save() async {
    final isFormValid = _formKey.currentState!.validate();
    final hasCat = _validateCategory();
    final hutangError = _validateHutangSelection();

    if (!isFormValid || !hasCat || hutangError != null) {
      if (!hasCat) {
        _showSnack(AppStrings.categoryRequired);
      } else if (hutangError != null) {
        _showSnack(hutangError);
      }
      return;
    }

    final rawDigits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawDigits) ?? 0;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final now = DateTime.now();

      // Buat/perbarui transaksi utama
      final tx = Transaction(
        id: widget.editTransaction?.id ?? const Uuid().v4(),
        type: _type,
        amount: amount,
        category: _selectedCategory!,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: AppDateUtils.dateOnly(_selectedDate),
        createdAt: widget.editTransaction?.createdAt ?? now,
      );

      if (_isEditing) {
        await repo.update(tx);
      } else {
        await repo.insert(tx);
      }

      // ── Integrasi Hutang ─────────────────────────────────────────────────
      // Jika kategori "Pembayaran Hutang" dan ada hutang yang dipilih,
      // perbarui record hutang (sisa + riwayat) TANPA membuat transaksi baru
      // (transaksi sudah dibuat di atas).
      if (_isPembayaranHutang && _selectedHutang != null) {
        final catatan = _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim();
        await ref.read(hutangNotifierProvider.notifier).updateAfterPayment(
              _selectedHutang!.id,
              amount,
              catatan: catatan,
              paidAt: AppDateUtils.dateOnly(_selectedDate),
            );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('${AppStrings.errorGeneral} ($e)');
    }
  }

  // ── Hapus ─────────────────────────────────────────────────────────────────

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteTransactionTitle),
        content: const Text(AppStrings.deleteTransactionBody),
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

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(transactionRepositoryProvider)
          .delete(widget.editTransaction!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('${AppStrings.errorGeneral} ($e)');
    }
  }

  // ── Toggle tipe pemasukan/pengeluaran ─────────────────────────────────────

  void _toggleType(TransactionType t) {
    if (t == _type) return;
    setState(() {
      _type = t;
      _selectedCategory = null;
      _selectedHutang = null; // Reset hutang saat ganti tipe
    });
  }

  // ── Callback pemilihan kategori ───────────────────────────────────────────

  void _onCategorySelected(Category c) {
    setState(() {
      _selectedCategory = c;
      // Reset hutang jika kategori berubah dari "Pembayaran Hutang"
      if (c.id != SystemCategories.pembayaranHutangId) {
        _selectedHutang = null;
      }
    });
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final padding = AppSpacing.pagePadding(context);
    final catAsync = ref.watch(categoriesForTypeProvider(_type));
    final title = _isEditing
        ? AppStrings.editTransaction
        : AppStrings.addTransaction;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: AppStrings.cancel,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.expense,
              onPressed: _isSaving ? null : _delete,
              tooltip: AppStrings.delete,
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: padding, vertical: padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TypeToggle(
                          current: _type,
                          onChanged: _toggleType,
                        ),
                        SizedBox(height: AppSpacing.cardGap(context)),
                        _AmountSection(
                          controller: _amountController,
                          validator: _validateAmount,
                        ),
                        SizedBox(height: AppSpacing.sectionGap(context)),
                        _SectionLabel(label: AppStrings.category),
                        const SizedBox(height: 8),
                        catAsync.when(
                          loading: () => const SizedBox(
                              height: 120,
                              child: AppLoadingIndicator()),
                          error: (e, _) => Text(AppStrings.errorLoad,
                              style: const TextStyle(
                                  color: AppColors.expense)),
                          data: (cats) => CategoryGridPicker(
                            categories: cats,
                            selected: _selectedCategory,
                            onSelected: _onCategorySelected,
                          ),
                        ),

                        // ── Hutang picker (muncul saat "Pembayaran Hutang") ──
                        if (_isPembayaranHutang) ...[
                          SizedBox(height: AppSpacing.sectionGap(context)),
                          _HutangPicker(
                            selectedHutang: _selectedHutang,
                            onHutangSelected: (h) =>
                                setState(() => _selectedHutang = h),
                          ),
                        ],

                        SizedBox(height: AppSpacing.sectionGap(context)),
                        _DateField(
                          date: _selectedDate,
                          onTap: _pickDate,
                        ),
                        SizedBox(height: AppSpacing.cardGap(context)),
                        _NoteField(controller: _noteController),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // ── Tombol simpan sticky ─────────────────────────────────
                Container(
                  padding:
                      EdgeInsets.fromLTRB(padding, 12, padding, padding),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                        top: BorderSide(
                            color: AppColors.divider, width: 0.5)),
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : Text(AppStrings.save),
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

// ── Hutang picker (section baru) ──────────────────────────────────────────────

/// Menampilkan daftar hutang aktif agar pengguna bisa memilih hutang yang dibayar.
///
/// Ditampilkan hanya ketika kategori "Pembayaran Hutang" dipilih.
/// Jika tidak ada hutang aktif, tampilkan pesan informatif.
class _HutangPicker extends ConsumerWidget {
  final HutangEntity? selectedHutang;
  final ValueChanged<HutangEntity?> onHutangSelected;

  const _HutangPicker({
    required this.selectedHutang,
    required this.onHutangSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hutangAsync = ref.watch(hutangListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(label: AppStrings.pilihHutang),
        const SizedBox(height: 8),
        hutangAsync.when(
          loading: () => const SizedBox(
              height: 56, child: AppLoadingIndicator()),
          error: (e, _) => Text(AppStrings.errorLoad,
              style: const TextStyle(color: AppColors.expense)),
          data: (list) {
            final aktif = list.where((h) => !h.isLunas).toList();

            // Tidak ada hutang aktif → tampilkan pesan validasi
            if (aktif.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.debtLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.debt.withValues(alpha: 0.3),
                      width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.debt, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.belumAdaHutangUntukDibayar,
                        style: TextStyle(
                          fontSize: AppTypeScale.caption(context),
                          color: AppColors.debt,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Tampilkan dropdown hutang aktif
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.debt.withValues(alpha: 0.4),
                    width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<HutangEntity>(
                  value: selectedHutang,
                  hint: Text(
                    AppStrings.pilihHutangHint,
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: AppTypeScale.bodyText(context),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.debt),
                  isExpanded: true,
                  onChanged: onHutangSelected,
                  items: aktif.map((h) {
                    return DropdownMenuItem<HutangEntity>(
                      value: h,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            h.namaKreditur,
                            style: TextStyle(
                              fontSize: AppTypeScale.bodyText(context),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Sisa: ${CurrencyFormatter.full(h.sisaHutang)}',
                            style: TextStyle(
                              fontSize: AppTypeScale.caption(context),
                              color: AppColors.debt,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        if (selectedHutang != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.debtLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.debt, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sisa hutang: ${CurrencyFormatter.full(selectedHutang!.sisaHutang)}. '
                    'Jumlah maksimal pembayaran: ${CurrencyFormatter.full(selectedHutang!.sisaHutang)}',
                    style: TextStyle(
                      fontSize: AppTypeScale.caption(context),
                      color: AppColors.debt,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final TransactionType current;
  final ValueChanged<TransactionType> onChanged;

  const _TypeToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _TypeButton(
            label: AppStrings.expense,
            icon: Icons.arrow_upward_rounded,
            isSelected: current == TransactionType.expense,
            color: AppColors.expense,
            onTap: () => onChanged(TransactionType.expense),
          ),
          const SizedBox(width: 4),
          _TypeButton(
            label: AppStrings.income,
            icon: Icons.arrow_downward_rounded,
            isSelected: current == TransactionType.income,
            color: AppColors.income,
            onTap: () => onChanged(TransactionType.income),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? color
                      : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypeScale.bodyText(context),
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: isSelected
                      ? color
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountSection extends StatelessWidget {
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  const _AmountSection(
      {required this.controller, required this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Preview jumlah yang diformat
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (ctx, value, _) {
            final raw = value.text.replaceAll(RegExp(r'[^0-9]'), '');
            final amount = double.tryParse(raw) ?? 0;
            return Text(
              amount > 0 ? CurrencyFormatter.full(amount) : 'Rp 0',
              style: TextStyle(
                fontSize: AppTypeScale.balanceDisplay(context),
                fontWeight: FontWeight.w700,
                color: amount > 0
                    ? AppColors.textPrimary
                    : AppColors.textHint,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppTypeScale.sectionTitle(context),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: AppStrings.enterAmount,
            prefixText: 'Rp  ',
            prefixStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppTypeScale.bodyText(context),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({required this.date, required this.onTap});

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
                Text(
                  AppStrings.date,
                  style: TextStyle(
                    fontSize: AppTypeScale.caption(context),
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  AppDateUtils.formatFull(date),
                  style: TextStyle(
                    fontSize: AppTypeScale.bodyText(context),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
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

class _NoteField extends StatelessWidget {
  final TextEditingController controller;

  const _NoteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 2,
      maxLength: 200,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: AppStrings.optionalNote,
        labelText: AppStrings.note,
        prefixIcon: const Icon(Icons.notes_rounded,
            color: AppColors.textSecondary),
        counterStyle:
            TextStyle(fontSize: AppTypeScale.caption(context)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: AppTypeScale.sectionTitle(context),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
