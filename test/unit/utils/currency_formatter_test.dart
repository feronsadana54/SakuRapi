import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.full', () {
    test('formats millions', () {
      expect(CurrencyFormatter.full(1500000), 'Rp 1.500.000');
    });

    test('formats thousands', () {
      expect(CurrencyFormatter.full(50000), 'Rp 50.000');
    });

    test('formats zero', () {
      expect(CurrencyFormatter.full(0), 'Rp 0');
    });

    test('formats single digit', () {
      expect(CurrencyFormatter.full(5), 'Rp 5');
    });
  });

  group('CurrencyFormatter.compact', () {
    test('formats 1.5 million as compact', () {
      expect(CurrencyFormatter.compact(1500000), 'Rp1.500.000');
    });

    test('formats thousands as compact', () {
      expect(CurrencyFormatter.compact(50000), 'Rp50.000');
    });
  });

  group('CurrencyFormatter.parse', () {
    test('parses full format string back to number', () {
      expect(CurrencyFormatter.parse('Rp 1.500.000'), 1500000.0);
    });

    test('parses compact format', () {
      expect(CurrencyFormatter.parse('Rp1.500.000'), 1500000.0);
    });

    test('parses plain digits', () {
      expect(CurrencyFormatter.parse('50000'), 50000.0);
    });

    test('returns null for empty string', () {
      expect(CurrencyFormatter.parse(''), isNull);
    });

    test('returns null for non-numeric string', () {
      expect(CurrencyFormatter.parse('abc'), isNull);
    });
  });
}
