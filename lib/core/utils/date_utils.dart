import 'package:intl/intl.dart';

/// Date/time helpers used throughout the app.
/// All methods are pure functions — no side effects.
abstract final class AppDateUtils {
  static final _dayFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final _shortFormat = DateFormat('d MMM yyyy', 'id_ID');
  static final _monthFormat = DateFormat('MMMM yyyy', 'id_ID');
  static final _yearFormat = DateFormat('yyyy');
  static final _timeFormat = DateFormat('HH:mm', 'id_ID');
  static final _dayMonthFormat = DateFormat('d MMM', 'id_ID');

  // ── Formatters ────────────────────────────────────────────────────────

  /// "Senin, 15 April 2026"
  static String formatFull(DateTime date) => _dayFormat.format(date);

  /// "15 Apr 2026"
  static String formatShort(DateTime date) => _shortFormat.format(date);

  /// "April 2026"
  static String formatMonth(DateTime date) => _monthFormat.format(date);

  /// "2026"
  static String formatYear(DateTime date) => _yearFormat.format(date);

  /// "09:00"
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// "15 Apr" — for chart axis labels
  static String formatDayMonth(DateTime date) => _dayMonthFormat.format(date);

  // ── Date range constructors ───────────────────────────────────────────

  /// Returns [date] with time stripped (midnight).
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// First moment of the day (inclusive lower bound).
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Last moment of the day (inclusive upper bound via <nextDay).
  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  /// First day of the given month.
  static DateTime firstDayOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// Last day of the given month.
  static DateTime lastDayOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0);

  /// January 1st of the given year.
  static DateTime firstDayOfYear(DateTime date) => DateTime(date.year, 1, 1);

  /// December 31st of the given year.
  static DateTime lastDayOfYear(DateTime date) => DateTime(date.year, 12, 31);

  // ── Payday cycle ──────────────────────────────────────────────────────

  /// Clamps [day] to the last valid day of [month]/[year].
  /// Handles February, short months, etc.
  static int clampToMonth(int day, int month, int year) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return day.clamp(1, lastDay);
  }

  /// Computes the current payday cycle boundaries.
  ///
  /// Given [paydayDate] (1–31) and a [reference] date (defaults to today),
  /// returns [cycleStart, cycleEnd] inclusive.
  ///
  /// Example: paydayDate=25, today=Apr 15
  ///   → cycleStart=Mar 25, cycleEnd=Apr 24
  ///
  /// Example: paydayDate=25, today=Apr 28
  ///   → cycleStart=Apr 25, cycleEnd=May 24
  static (DateTime cycleStart, DateTime cycleEnd) getPaydayCycle({
    required int paydayDate,
    DateTime? reference,
  }) {
    final today = reference ?? DateTime.now();

    int clampedDay(int month, int year) =>
        clampToMonth(paydayDate, month, year);

    final thisMonthPayday = DateTime(
      today.year,
      today.month,
      clampedDay(today.month, today.year),
    );

    if (today.day >= thisMonthPayday.day) {
      // We are on or after payday → cycle started this month
      final cycleStart = thisMonthPayday;
      final nextMonth = today.month == 12 ? 1 : today.month + 1;
      final nextYear = today.month == 12 ? today.year + 1 : today.year;
      final cycleEndPayday = DateTime(
        nextYear,
        nextMonth,
        clampedDay(nextMonth, nextYear),
      );
      final cycleEnd = cycleEndPayday.subtract(const Duration(days: 1));
      return (cycleStart, cycleEnd);
    } else {
      // We are before payday → cycle started last month
      final prevMonth = today.month == 1 ? 12 : today.month - 1;
      final prevYear = today.month == 1 ? today.year - 1 : today.year;
      final cycleStart = DateTime(
        prevYear,
        prevMonth,
        clampedDay(prevMonth, prevYear),
      );
      final cycleEnd = thisMonthPayday.subtract(const Duration(days: 1));
      return (cycleStart, cycleEnd);
    }
  }

  // ── Greeting ──────────────────────────────────────────────────────────

  /// Returns a time-appropriate Indonesian greeting.
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  // ── Relative label ────────────────────────────────────────────────────

  /// "Hari Ini", "Kemarin", or "15 Apr 2026"
  static String relativeLabel(DateTime date) {
    final now = dateOnly(DateTime.now());
    final d = dateOnly(date);
    if (d == now) return 'Hari Ini';
    if (d == now.subtract(const Duration(days: 1))) return 'Kemarin';
    return formatShort(date);
  }
}
