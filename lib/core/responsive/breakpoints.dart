import 'package:flutter/material.dart';

/// Four-tier breakpoint system covering all mobile sizes plus tablet.
///
/// Usage:
///   context.screenClass      → ScreenClass enum value
///   context.isTablet         → true on 720dp+
///   context.isSmall          → true on <360dp (budget Android)
enum ScreenClass {
  /// < 360dp — budget Android phones
  smallMobile,

  /// 360–599dp — standard phones (the majority)
  normalMobile,

  /// 600–719dp — large phones (6.7"+), foldables half-open
  largeMobile,

  /// 720dp+ — tablets, foldables fully open
  tablet,
}

extension ScreenClassContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  ScreenClass get screenClass {
    final w = screenWidth;
    if (w < 360) return ScreenClass.smallMobile;
    if (w < 600) return ScreenClass.normalMobile;
    if (w < 720) return ScreenClass.largeMobile;
    return ScreenClass.tablet;
  }

  bool get isMobile => screenClass.index <= ScreenClass.largeMobile.index;
  bool get isTablet => screenClass == ScreenClass.tablet;
  bool get isSmall => screenClass == ScreenClass.smallMobile;
  bool get isLargeMobileOrTablet =>
      screenClass == ScreenClass.largeMobile ||
      screenClass == ScreenClass.tablet;
}
