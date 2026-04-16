import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/utils/date_utils.dart';

void main() {
  group('Payday cycle boundary conditions', () {
    // Helper to extract just the days for readable assertions
    (int startDay, int startMonth, int endDay, int endMonth) cycleOf({
      required int paydayDate,
      required DateTime reference,
    }) {
      final (s, e) = AppDateUtils.getPaydayCycle(
        paydayDate: paydayDate,
        reference: reference,
      );
      return (s.day, s.month, e.day, e.month);
    }

    test('payday=25, day before payday → previous month start', () {
      final r = cycleOf(paydayDate: 25, reference: DateTime(2026, 4, 24));
      expect(r, (25, 3, 24, 4)); // Mar 25 – Apr 24
    });

    test('payday=25, exactly on payday → current month start', () {
      final r = cycleOf(paydayDate: 25, reference: DateTime(2026, 4, 25));
      expect(r, (25, 4, 24, 5)); // Apr 25 – May 24
    });

    test('payday=25, day after payday → current month start', () {
      final r = cycleOf(paydayDate: 25, reference: DateTime(2026, 4, 26));
      expect(r, (25, 4, 24, 5)); // Apr 25 – May 24
    });

    test('payday=1 before 1st → previous month', () {
      // today is Jan 1 exactly → on payday → cycle starts Jan 1
      final r = cycleOf(paydayDate: 1, reference: DateTime(2026, 1, 1));
      expect(r, (1, 1, 31, 1)); // Jan 1 – Jan 31
    });

    test('payday=1 mid-month → current month', () {
      final r = cycleOf(paydayDate: 1, reference: DateTime(2026, 4, 15));
      expect(r, (1, 4, 30, 4)); // Apr 1 – Apr 30
    });

    test('payday=31 in February non-leap → clamped to 28', () {
      // today=Feb 10, 2026: prev payday was Jan 31, next is Feb 28
      // cycle: Jan 31 – Feb 27
      final (s, e) = AppDateUtils.getPaydayCycle(
        paydayDate: 31,
        reference: DateTime(2026, 2, 10),
      );
      expect(s, DateTime(2026, 1, 31));
      expect(e, DateTime(2026, 2, 27));
    });

    test('payday=31 in March → uses March 31 correctly', () {
      // today=Mar 10 → cycle: Feb 28 – Mar 30
      final (s, e) = AppDateUtils.getPaydayCycle(
        paydayDate: 31,
        reference: DateTime(2026, 3, 10),
      );
      expect(s, DateTime(2026, 2, 28)); // Feb clamped
      expect(e, DateTime(2026, 3, 30)); // Mar 31 – 1
    });

    test('payday=31 on March 31 → cycle starts today', () {
      // today=Mar 31 → cycle: Mar 31 – Apr 29 (Apr clamp 31→30, minus 1=29)
      final (s, e) = AppDateUtils.getPaydayCycle(
        paydayDate: 31,
        reference: DateTime(2026, 3, 31),
      );
      expect(s, DateTime(2026, 3, 31));
      expect(e, DateTime(2026, 4, 29));
    });

    test('December after payday crosses into new year', () {
      final (s, e) = AppDateUtils.getPaydayCycle(
        paydayDate: 25,
        reference: DateTime(2026, 12, 30),
      );
      expect(s, DateTime(2026, 12, 25));
      expect(e, DateTime(2027, 1, 24));
    });

    test('January before payday crosses back into previous year', () {
      final (s, e) = AppDateUtils.getPaydayCycle(
        paydayDate: 25,
        reference: DateTime(2027, 1, 10),
      );
      expect(s, DateTime(2026, 12, 25));
      expect(e, DateTime(2027, 1, 24));
    });

    test('cycle end is always one day before next payday', () {
      // For any payday=15, the cycle end should be the 14th of next month
      final (_, e) = AppDateUtils.getPaydayCycle(
        paydayDate: 15,
        reference: DateTime(2026, 4, 20),
      );
      expect(e.day, 14);
    });

    test('cycle duration is always ~30 days for payday=25', () {
      for (var month = 1; month <= 12; month++) {
        final ref = DateTime(2026, month, 26); // always after payday
        final (s, e) = AppDateUtils.getPaydayCycle(
          paydayDate: 25,
          reference: ref,
        );
        final days = e.difference(s).inDays + 1;
        // Should be 28–31 depending on month
        expect(days, greaterThanOrEqualTo(28));
        expect(days, lessThanOrEqualTo(31));
      }
    });
  });
}
