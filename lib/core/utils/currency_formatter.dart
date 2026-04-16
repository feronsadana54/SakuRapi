import 'package:intl/intl.dart';

/// Formats amounts as Indonesian Rupiah (IDR).
abstract final class CurrencyFormatter {
  static final NumberFormat _compact = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static final NumberFormat _full = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// "Rp1.500.000" — for list items and chips.
  static String compact(double amount) => _compact.format(amount);

  /// "Rp 1.500.000" — for balance cards and report headings.
  static String full(double amount) => _full.format(amount);

  /// "+Rp 500.000" or "-Rp 200.000" — for delta displays.
  static String signed(double amount) {
    final prefix = amount >= 0 ? '+' : '';
    return '$prefix${full(amount)}';
  }

  /// Parses a user-typed string to a double.
  /// Accepts "1500000", "1.500.000", "1500000.00".
  /// Returns null if parsing fails.
  static double? parse(String input) {
    if (input.isEmpty) return null;
    // Remove currency symbols and spaces
    final cleaned = input
        .replaceAll('Rp', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(cleaned);
  }
}
