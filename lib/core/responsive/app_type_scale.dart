import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Font sizes that scale per breakpoint.
/// Never hard-code font sizes in widgets — always call these.
abstract final class AppTypeScale {
  /// Hero number shown on the balance card.
  static double balanceDisplay(BuildContext ctx) => switch (ctx.screenClass) {
        ScreenClass.smallMobile => 26.0,
        ScreenClass.normalMobile => 30.0,
        ScreenClass.largeMobile => 34.0,
        ScreenClass.tablet => 40.0,
      };

  /// Section headings ("Transaksi Terbaru", "Laporan Harian", …).
  static double sectionTitle(BuildContext ctx) => switch (ctx.screenClass) {
        ScreenClass.smallMobile => 14.0,
        ScreenClass.normalMobile => 15.0,
        ScreenClass.largeMobile => 16.0,
        ScreenClass.tablet => 18.0,
      };

  /// Default body text (transaction list items, descriptions).
  static double bodyText(BuildContext ctx) => switch (ctx.screenClass) {
        ScreenClass.smallMobile => 12.0,
        ScreenClass.normalMobile => 13.0,
        ScreenClass.largeMobile => 14.0,
        ScreenClass.tablet => 15.0,
      };

  /// Small label / caption (dates, secondary info).
  static double caption(BuildContext ctx) => bodyText(ctx) - 1;

  /// Large section header / screen title.
  static double heading(BuildContext ctx) => sectionTitle(ctx) + 4;

  /// Stat number on report cards.
  static double statNumber(BuildContext ctx) => switch (ctx.screenClass) {
        ScreenClass.smallMobile => 18.0,
        ScreenClass.normalMobile => 20.0,
        ScreenClass.largeMobile => 22.0,
        ScreenClass.tablet => 26.0,
      };
}
