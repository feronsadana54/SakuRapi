import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Spacing values that shift per breakpoint.
/// Use [pagePadding], [cardGap], and [sectionGap] for adaptive spacing.
/// Use the fixed constants (xs, sm, md…) for component-internal spacing.
abstract final class AppSpacing {
  // ── Adaptive spacing ──────────────────────────────────────────────────

  static double pagePadding(BuildContext ctx) => switch (ctx.screenClass) {
        ScreenClass.smallMobile => 12.0,
        ScreenClass.normalMobile => 16.0,
        ScreenClass.largeMobile => 20.0,
        ScreenClass.tablet => 28.0,
      };

  static double cardGap(BuildContext ctx) => switch (ctx.screenClass) {
        ScreenClass.smallMobile => 8.0,
        ScreenClass.normalMobile => 12.0,
        ScreenClass.largeMobile => 14.0,
        ScreenClass.tablet => 16.0,
      };

  static double sectionGap(BuildContext ctx) => pagePadding(ctx) * 1.5;

  // ── Fixed constants ───────────────────────────────────────────────────

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
