/// Pure date-math for computing how far through the current year we are.
///
/// Deliberately has zero Flutter/UI imports — this is the kind of logic
/// that's easy to unit test and easy to reuse from a home-screen widget,
/// a native widget bridge, or a background isolate.
library;

class YearProgress {
  final DateTime now;
  final int year;
  final DateTime startOfYear;
  final DateTime startOfNextYear;

  YearProgress._({
    required this.now,
    required this.year,
    required this.startOfYear,
    required this.startOfNextYear,
  });

  /// Builds a [YearProgress] snapshot. Pass [now] explicitly in tests;
  /// defaults to [DateTime.now] in production.
  factory YearProgress.fromDate(DateTime? now) {
    final effectiveNow = now ?? DateTime.now();
    final year = effectiveNow.year;
    return YearProgress._(
      now: effectiveNow,
      year: year,
      startOfYear: DateTime(year, 1, 1),
      startOfNextYear: DateTime(year + 1, 1, 1),
    );
  }

  bool get isLeapYear =>
      (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

  int get totalDaysInYear => isLeapYear ? 366 : 365;

  Duration get _elapsed => now.difference(startOfYear);
  Duration get _totalYearDuration => startOfNextYear.difference(startOfYear);

  /// 0.0–1.0 fraction of the year elapsed, using sub-day precision
  /// (so the ring advances smoothly, not just once a day).
  double get fraction =>
      (_elapsed.inSeconds / _totalYearDuration.inSeconds).clamp(0.0, 1.0);

  /// Percentage 0.0–100.0, one decimal place expected at display time.
  double get percentComplete => fraction * 100;

  int get daysCompleted => _elapsed.inDays;
  int get daysRemaining => totalDaysInYear - daysCompleted;

  int get currentMonth => now.month; // 1–12

  int get currentWeek {
    // ISO-8601-ish: week number based on days elapsed since Jan 1.
    final dayOfYear = daysCompleted + 1;
    return ((dayOfYear - 1) / 7).floor() + 1;
  }

  int get totalWeeksInYear => (totalDaysInYear / 7).ceil();

  int get currentDayOfYear => daysCompleted + 1;

  int get hoursCompleted => _elapsed.inHours;
  int get totalHoursInYear => totalDaysInYear * 24;
}