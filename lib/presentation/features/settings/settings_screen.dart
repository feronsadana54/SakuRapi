import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/responsive/app_spacing.dart';
import '../../../core/responsive/app_type_scale.dart';
import '../../../core/responsive/responsive_container.dart';
import '../../../core/services/export_import_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/enums/auth_mode.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/database_provider.dart';
import '../../../presentation/providers/notification_provider.dart';
import '../../../presentation/providers/settings_provider.dart';
import '../../../presentation/providers/transaction_provider.dart';
import '../../../router/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text(AppStrings.errorLoad)),
        data: (settings) => SafeArea(
          child: ResponsiveContainer(
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.pagePadding(context)),
              children: [
                // ── Akun ──────────────────────────────────────────────
                _SectionHeader('Akun'),
                _AccountCard(
                  userAsync: userAsync,
                  onLogout: () => _confirmLogout(context, ref),
                ),
                SizedBox(height: AppSpacing.cardGap(context)),

                // ── Keuangan ──────────────────────────────────────────
                _SectionHeader('Keuangan'),
                _SettingsCard(children: [
                  _PaydayTile(
                    current: settings.paydayDate,
                    onChanged: (d) =>
                        ref.read(settingsProvider.notifier).setPaydayDate(d),
                  ),
                ]),
                SizedBox(height: AppSpacing.cardGap(context)),

                // ── Notifikasi ────────────────────────────────────────
                _SectionHeader('Notifikasi'),
                _ReminderCard(settings: settings),
                SizedBox(height: AppSpacing.cardGap(context)),

                // ── Data ──────────────────────────────────────────────
                _SectionHeader('Data'),
                _SettingsCard(children: [
                  _ActionTile(
                    icon: Icons.upload_file_rounded,
                    iconColor: AppColors.income,
                    title: AppStrings.exportCsv,
                    subtitle: AppStrings.exportCsvDesc,
                    onTap: () => _export(context, ref),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _ActionTile(
                    icon: Icons.download_rounded,
                    iconColor: AppColors.primary,
                    title: AppStrings.importCsv,
                    subtitle: AppStrings.importCsvDesc,
                    onTap: () => _import(context, ref),
                  ),
                ]),
                SizedBox(height: AppSpacing.cardGap(context)),

                // ── Tentang ───────────────────────────────────────────
                _SectionHeader('Tentang'),
                _SettingsCard(children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded,
                        color: AppColors.primary),
                    title: Text(AppStrings.aboutApp,
                        style: TextStyle(
                            fontSize: AppTypeScale.bodyText(context))),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${AppStrings.version} 1.0.0',
                            style: TextStyle(
                                fontSize: AppTypeScale.caption(context),
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(AppStrings.appDescription,
                            style: TextStyle(
                                fontSize: AppTypeScale.caption(context),
                                color: AppColors.textSecondary,
                                height: 1.4)),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logoutTitle),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(currentUserProvider.notifier).signOut();
    if (context.mounted) context.go(AppRoutes.login);
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final txList = ref.read(allTransactionsProvider).valueOrNull ?? [];
    if (txList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(AppStrings.noTransactionsToExport),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    try {
      await ExportImportService().exportAndShare(txList);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppStrings.errorGeneral} ($e)'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final rows = await ExportImportService().pickAndParse();
      if (rows == null || !context.mounted) return;

      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('File tidak memiliki baris data yang valid.'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(AppStrings.importConfirmTitle),
          content: Text('${rows.length} ${AppStrings.importConfirmBody}'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(AppStrings.cancel)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(AppStrings.importCsv)),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(
        content: Text(AppStrings.importing),
        duration: Duration(seconds: 60),
        behavior: SnackBarBehavior.floating,
      ));

      final repo = ref.read(transactionRepositoryProvider);
      final catRepo = ref.read(categoryRepositoryProvider);
      final allCats = await catRepo.getAll();
      final catByName = {for (final c in allCats) c.name.toLowerCase(): c};
      const uuid = Uuid();

      int imported = 0;
      for (final row in rows) {
        final cat = catByName[row.categoryName.toLowerCase()];
        if (cat == null) continue;

        final date = _parseDate(row.date);
        final type = row.type == 'income'
            ? TransactionType.income
            : TransactionType.expense;

        await repo.insert(Transaction(
          id: uuid.v4(),
          type: type,
          amount: row.amount,
          category: cat,
          note: row.note,
          date: AppDateUtils.dateOnly(date),
          createdAt: DateTime.now(),
        ));
        imported++;
      }

      messenger.hideCurrentSnackBar();
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('$imported transaksi berhasil diimpor.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppStrings.errorGeneral} ($e)'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  /// Parses "15 Apr 2026" (SakuRapi export format) to DateTime.
  DateTime _parseDate(String s) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
      'Mei': 5, 'Jun': 6, 'Jul': 7, 'Agu': 8,
      'Sep': 9, 'Okt': 10, 'Nov': 11, 'Des': 12,
    };
    final parts = s.trim().split(' ');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = months[parts[1]];
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.now();
  }
}

// ── Account card ─────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final AsyncValue<dynamic> userAsync;
  final VoidCallback onLogout;

  const _AccountCard({required this.userAsync, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return userAsync.when(
      loading: () => const _SettingsCard(children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceVariant,
            child: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
          ),
          title: Text('Memuat...'),
        ),
      ]),
      error: (e, st) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final isGuest = user.authMode == AuthMode.guest;
        final authIcon = isGuest ? Icons.person_outline_rounded : Icons.g_mobiledata_rounded;
        final authLabel = isGuest ? AppStrings.loginAsGuest : 'Google';
        final authColor = isGuest ? AppColors.textSecondary : AppColors.primary;
        final syncText = isGuest ? AppStrings.dataLocalOnly : AppStrings.dataBackedUp;
        final syncIcon = isGuest ? Icons.phone_android_rounded : Icons.cloud_done_rounded;
        final syncColor = isGuest ? AppColors.textSecondary : AppColors.income;

        return _SettingsCard(children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isGuest ? AppColors.surfaceVariant : AppColors.primaryLight,
              child: Icon(
                authIcon,
                color: authColor,
              ),
            ),
            title: Text(
              user.displayName,
              style: TextStyle(
                fontSize: AppTypeScale.bodyText(context),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(authIcon, size: 13, color: authColor),
                    const SizedBox(width: 4),
                    Text(
                      authLabel,
                      style: TextStyle(
                        fontSize: AppTypeScale.caption(context),
                        color: authColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(syncIcon, size: 13, color: syncColor),
                    const SizedBox(width: 4),
                    Text(
                      syncText,
                      style: TextStyle(
                        fontSize: AppTypeScale.caption(context),
                        color: syncColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.expense),
            title: Text(
              AppStrings.logout,
              style: TextStyle(
                fontSize: AppTypeScale.bodyText(context),
                color: AppColors.expense,
              ),
            ),
            onTap: onLogout,
          ),
        ]);
      },
    );
  }
}

// ── Reminder card (full schedule UI) ─────────────────────────────────────────

class _ReminderCard extends ConsumerWidget {
  final AppSettings settings;
  const _ReminderCard({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = settings.notificationEnabled;

    return _SettingsCard(
      children: [
        // Toggle row — disabled on web (push notifications not supported)
        SwitchListTile(
          secondary: Icon(
            Icons.notifications_outlined,
            color: kIsWeb ? AppColors.textSecondary : AppColors.primary,
          ),
          title: Text(AppStrings.dailyReminder,
              style: TextStyle(fontSize: AppTypeScale.bodyText(context))),
          subtitle: Text(
            kIsWeb
                ? AppStrings.notifNotSupportedOnWeb
                : enabled
                    ? AppStrings.notifScheduled
                    : AppStrings.dailyReminderDesc,
            style: TextStyle(
                fontSize: AppTypeScale.caption(context),
                color: AppColors.textSecondary),
          ),
          value: kIsWeb ? false : enabled,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => _handleToggle(context, ref, v),
        ),

        // Time + days rows (shown only when notifications are enabled on native)
        if (!kIsWeb && enabled) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.access_time_rounded,
                color: AppColors.primary),
            title: Text(AppStrings.reminderTime,
                style: TextStyle(fontSize: AppTypeScale.bodyText(context))),
            trailing: Text(
              _formatTime(settings.reminderHour, settings.reminderMinute),
              style: TextStyle(
                fontSize: AppTypeScale.bodyText(context),
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            onTap: () => _pickTime(context, ref, settings),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _WeekdaySelector(
              selectedDays: settings.reminderDays,
              onChanged: (days) => _handleDaysChanged(context, ref, days),
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _handleToggle(
      BuildContext context, WidgetRef ref, bool enable) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(AppStrings.notifNotSupportedOnWeb),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final granted =
        await ref.read(notificationToggleProvider.notifier).toggle(enable);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        granted && enable
            ? AppStrings.notifScheduled
            : granted
                ? AppStrings.notifDisabled
                : AppStrings.notifPermissionDenied,
      ),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _pickTime(
      BuildContext context, WidgetRef ref, AppSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: settings.reminderHour, minute: settings.reminderMinute),
      helpText: 'Pilih Waktu Pengingat',
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.save,
    );
    if (picked == null || !context.mounted) return;

    final notifier = ref.read(settingsProvider.notifier);
    await notifier.setReminderHour(picked.hour);
    await notifier.setReminderMinute(picked.minute);

    await ref.read(notificationToggleProvider.notifier).reschedule();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(AppStrings.reminderRescheduled),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _handleDaysChanged(
      BuildContext context, WidgetRef ref, List<int> days) async {
    if (days.isEmpty) return; // Require at least one day selected.
    await ref.read(settingsProvider.notifier).setReminderDays(days);
    await ref.read(notificationToggleProvider.notifier).reschedule();
  }
}

// ── Weekday selector ──────────────────────────────────────────────────────────

class _WeekdaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const _WeekdaySelector({
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month_outlined,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              AppStrings.reminderDays,
              style: TextStyle(
                fontSize: AppTypeScale.bodyText(context),
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = i + 1; // 1=Mon … 7=Sun
            final selected = selectedDays.contains(day);
            return _DayChip(
              label: AppStrings.weekdayShort[i],
              selected: selected,
              onTap: () {
                final updated = List<int>.from(selectedDays);
                if (selected) {
                  updated.remove(day);
                } else {
                  updated.add(day);
                  updated.sort();
                }
                onChanged(updated);
              },
            );
          }),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.divider,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: AppTypeScale.caption(context),
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title,
          style: TextStyle(fontSize: AppTypeScale.bodyText(context))),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: AppTypeScale.caption(context),
              color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

class _PaydayTile extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;

  const _PaydayTile({required this.current, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final controller = TextEditingController(text: current.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.setPaydayTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 2,
          decoration:
              const InputDecoration(hintText: '1–31', counterText: ''),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null && v >= 1 && v <= 31) Navigator.pop(ctx, v);
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.calendar_today_rounded,
          color: AppColors.primary),
      title: Text(AppStrings.paydayDate,
          style: TextStyle(fontSize: AppTypeScale.bodyText(context))),
      subtitle: Text(
        '${AppStrings.paydayDateDesc} (tanggal $current)',
        style: TextStyle(
            fontSize: AppTypeScale.caption(context),
            color: AppColors.textSecondary),
      ),
      trailing: Text(
        'Tgl $current',
        style: TextStyle(
          fontSize: AppTypeScale.bodyText(context),
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      onTap: () => _pick(context),
    );
  }
}
