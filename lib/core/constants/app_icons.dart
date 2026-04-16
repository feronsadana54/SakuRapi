import 'package:flutter/material.dart';

/// Maps MaterialIcons codepoints (stored in the database) to compile-time
/// [Icons.*] constants so that Flutter's icon tree-shaker can work in
/// release builds.
///
/// Using `IconData(runtimeCodepoint)` at runtime blocks tree-shaking and
/// causes release build failures. Every icon the app needs must appear here
/// as an explicit `const Icons.*` reference so the tree-shaker can include
/// only the used glyphs.
abstract final class AppIcons {
  static const IconData _fallback = Icons.category;

  // ── Expense icons ──────────────────────────────────────────────────────
  static const IconData restaurant = Icons.restaurant; // 0xe56c
  static const IconData directionsCar = Icons.directions_car; // 0xe1b1
  static const IconData shoppingBag = Icons.shopping_bag; // 0xef6f
  static const IconData receipt = Icons.receipt; // 0xe56b
  static const IconData localHospital = Icons.local_hospital; // 0xe548
  static const IconData movie = Icons.movie; // 0xe415
  static const IconData school = Icons.school; // 0xe80c
  static const IconData home = Icons.home; // 0xe318
  static const IconData style = Icons.style; // 0xe3c4
  static const IconData moreHoriz = Icons.more_horiz; // 0xe5d3

  // ── Income icons ──────────────────────────────────────────────────────
  static const IconData accountBalanceWallet =
      Icons.account_balance_wallet; // 0xe850
  static const IconData cardGiftcard = Icons.card_giftcard; // 0xe8f6
  static const IconData work = Icons.work; // 0xe8f9
  static const IconData trendingUp = Icons.trending_up; // 0xe8e5

  /// Lookup table: DB-stored codepoint → const [IconData].
  static const Map<int, IconData> _map = {
    0xe56c: restaurant,
    0xe1b1: directionsCar,
    0xef6f: shoppingBag,
    0xe56b: receipt,
    0xe548: localHospital,
    0xe415: movie,
    0xe80c: school,
    0xe318: home,
    0xe3c4: style,
    0xe5d3: moreHoriz,
    0xe850: accountBalanceWallet,
    0xe8f6: cardGiftcard,
    0xe8f9: work,
    0xe8e5: trendingUp,
  };

  /// Returns the [Icons.*] constant for [code].
  ///
  /// Falls back to [Icons.category] for any codepoint not in the map,
  /// so the UI always shows something rather than crashing.
  static IconData fromCode(int code) => _map[code] ?? _fallback;
}
