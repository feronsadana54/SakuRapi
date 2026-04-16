import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils.getPaydayCycle', () {
    test('before payday — cycle started last month', () {
      // payday=25, today=Apr 15 → cycle: Mar 25 – Apr 24
      final (start, end) = AppDateUtils.getPaydayCycle(
        paydayDate: 25,
        reference: DateTime(2026, 4, 15),
      );
      expect(start, DateTime(2026, 3, 25));
      expect(end, DateTime(2026, 4, 24));
    });

    test('on payday exactly — cycle starts today', () {
      // payday=25, today=Apr 25 → cycle: Apr 25 – May 24
      final (start, end) = AppDateUtils.getPaydayCycle(
        paydayDate: 25,
        reference: DateTime(2026, 4, 25),
      );
      expect(start, DateTime(2026, 4, 25));
      expect(end, DateTime(2026, 5, 24));
    });

    test('after payday — cycle started this month', () {
      // payday=25, today=Apr 28 → cycle: Apr 25 – May 24
      final (start, end) = AppDateUtils.getPaydayCycle(
        paydayDate: 25,
        reference: DateTime(2026, 4, 28),
      );
      expect(start, DateTime(2026, 4, 25));
      expect(end, DateTime(2026, 5, 24));
    });

    test('year boundary — December before payday', () {
      // payday=25, today=Dec 20 → cycle: Nov 25 – Dec 24
      final (start, end) = AppDateUtils.getPaydayCycle(
        paydayDate: 25,
        reference: DateTime(2026, 12, 20),
      );
      expect(start, DateTime(2026, 11, 25));
      expect(end, DateTime(2026, 12, 24));
    });

    test('year boundary — December after payday', () {
      // payday=25, today=Dec 28 → cycle: Dec 25 – Jan 24
      final (start, end) = AppDateUtils.getPaydayCycle(
        paydayDate: 25,
        reference: DateTime(2026, 12, 28),
      );
      expect(start, DateTime(2026, 12, 25));
      expect(end, DateTime(2027, 1, 24));
    });

    test('paydayDate=31 clamps to Feb 28 in non-leap year', () {
      // payday=31, today=Feb 10, 2026 (non-leap) → cycle: Jan 31 – Feb 27
      final (start, end) = AppDateUtils.getPaydayCycle(
        paydayDate: 31,
        reference: DateTime(2026, 2, 10),
      );
      expect(start, DateTime(2026, 1, 31));
      expect(end, DateTime(2026, 2, 27)); // Feb 28 - 1 day
    });

    test('paydayDate=31 clamps to Feb 29 in leap year', () {
      // payday=31, today=Feb 10, 2028 (leap) → cycle: Jan 31 – Feb 28
      final (start, end) = AppDateUtils.getPaydayCycle(
        paydayDate: 31,
        reference: DateTime(2028, 2, 10),
      );
      expect(start, DateTime(2028, 1, 31));
      expect(end, DateTime(2028, 2, 28)); // Feb 29 - 1 day
    });

    test('paydayDate=31 in April (30-day month) clamps to 30', () {
      // payday=31, today=Apr 10 → prev payday was Mar 31
      // → cycle: Mar 31 – Apr 29
      final (start, end) = AppDateUtils.getPaydayCycle(
        paydayDate: 31,
        reference: DateTime(2026, 4, 10),
      );
      expect(start, DateTime(2026, 3, 31));
      expect(end, DateTime(2026, 4, 29)); // Apr 30 - 1 day
    });

    test('paydayDate=1 — cycle starts at first of month', () {
      // payday=1, today=Apr 15 → cycle: Apr 1 – Apr 30
      final (start, end) = AppDateUtils.getPaydayCycle(
        paydayDate: 1,
        reference: DateTime(2026, 4, 15),
      );
      expect(start, DateTime(2026, 4, 1));
      expect(end, DateTime(2026, 4, 30));
    });
  });

  group('AppDateUtils.clampToMonth', () {
    test('clamps 31 to 28 in Feb of non-leap year', () {
      expect(AppDateUtils.clampToMonth(31, 2, 2026), 28);
    });

    test('clamps 31 to 29 in Feb of leap year', () {
      expect(AppDateUtils.clampToMonth(31, 2, 2028), 29);
    });

    test('clamps 31 to 30 in April', () {
      expect(AppDateUtils.clampToMonth(31, 4, 2026), 30);
    });

    test('valid day unchanged', () {
      expect(AppDateUtils.clampToMonth(15, 4, 2026), 15);
    });

    test('clamps 0 to 1', () {
      expect(AppDateUtils.clampToMonth(0, 4, 2026), 1);
    });
  });

  group('AppDateUtils date constructors', () {
    test('firstDayOfMonth', () {
      final result =
          AppDateUtils.firstDayOfMonth(DateTime(2026, 4, 15));
      expect(result, DateTime(2026, 4, 1));
    });

    test('lastDayOfMonth for April', () {
      final result =
          AppDateUtils.lastDayOfMonth(DateTime(2026, 4, 15));
      expect(result, DateTime(2026, 4, 30));
    });

    test('lastDayOfMonth for February in leap year', () {
      final result =
          AppDateUtils.lastDayOfMonth(DateTime(2028, 2, 1));
      expect(result, DateTime(2028, 2, 29));
    });

    test('firstDayOfYear', () {
      final result = AppDateUtils.firstDayOfYear(DateTime(2026, 4, 15));
      expect(result, DateTime(2026, 1, 1));
    });

    test('lastDayOfYear', () {
      final result = AppDateUtils.lastDayOfYear(DateTime(2026, 4, 15));
      expect(result, DateTime(2026, 12, 31));
    });
  });
}
