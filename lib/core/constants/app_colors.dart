import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primaryDark = Color(0xFF003C8F);
  static const Color primaryContainer = Color(0xFFE3F2FD);

  // ── Semantic: income & expense ────────────────────────────────────────
  static const Color income = Color(0xFF2E7D32);
  static const Color incomeLight = Color(0xFFE8F5E9);
  static const Color expense = Color(0xFFC62828);
  static const Color expenseLight = Color(0xFFFFEBEE);

  // ── Surface / background ──────────────────────────────────────────────
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F8);
  static const Color cardShadow = Color(0x14000000); // black 8%

  // ── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // ── Hutang & Piutang ──────────────────────────────────────────────────
  static const Color debt = Color(0xFFE65100);         // orange-red for hutang
  static const Color debtLight = Color(0xFFFFF3E0);
  static const Color receivable = Color(0xFF1565C0);   // primary blue for piutang
  static const Color receivableLight = Color(0xFFE3F2FD);

  // ── Misc ──────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shimmer = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
