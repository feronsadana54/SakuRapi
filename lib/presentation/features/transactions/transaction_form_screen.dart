import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/responsive/app_spacing.dart';
import '../../../core/responsive/app_type_scale.dart';
import '../../../core/responsive/responsive_container.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../presentation/providers/category_provider.dart';
import '../../../presentation/providers/database_provider.dart';
import '../../../presentation/widgets/category_grid_picker.dart';
import 'package:uuid/uuid.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  /// Null → add mode. Non-null → edit mode.
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

  bool get _isEditing => widget.editTransaction != null;

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

  // ── Validation ──────────────────────────────────────────────────────────

  String? _validateAmount(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.amountRequired;
    final parsed = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsed == null || parsed <= 0) return AppStrings.amountInvalid;
    return null;
  }

  bool _validateCategory() {
    if (_selectedCategory == null) return false;
    return true;
  }

  // ── Date picker ─────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100), // No upper-limit: future dates are allowed.
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

  // ── Save ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final isFormValid = _formKey.currentState!.validate();
    final hasCat = _validateCategory();

    if (!isFormValid || !hasCat) {
      if (!hasCat) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.categoryRequired)),
        );
      }
      return;
    }

    final rawDigits =
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawDigits) ?? 0;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final now = DateTime.now();
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

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.errorGeneral} ($e)')),
      );
    }
  }

  // ── Delete ──────────────────────────────────────────────────────────────

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.errorGeneral} ($e)')),
      );
    }
  }

  // ── Type toggle ─────────────────────────────────────────────────────────

  void _toggleType(TransactionType t) {
    if (t == _type) return;
    setState(() {
      _type = t;
      _selectedCategory = null; // clear category when type changes
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────

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
                        _AmountSection(controller: _amountController, validator: _validateAmount),
                        SizedBox(height: AppSpacing.sectionGap(context)),
                        _SectionLabel(label: AppStrings.category),
                        SizedBox(height: AppSpacing.sm),
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
                            onSelected: (c) =>
                                setState(() => _selectedCategory = c),
                          ),
                        ),
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
                // ── Sticky save button ──────────────────────────────
                Container(
                  padding: EdgeInsets.fromLTRB(
                      padding, 12, padding, padding),
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
                  color: isSelected ? color : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypeScale.bodyText(context),
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      isSelected ? color : AppColors.textSecondary,
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
        // Live formatted preview
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (ctx, value, _) {
            final raw = value.text.replaceAll(RegExp(r'[^0-9]'), '');
            final amount = double.tryParse(raw) ?? 0;
            return Text(
              amount > 0
                  ? CurrencyFormatter.full(amount)
                  : 'Rp 0',
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
