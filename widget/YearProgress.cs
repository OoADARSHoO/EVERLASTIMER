using System;

namespace EverlastimerWidget;

/// <summary>
/// Pure date-math for year progress. Deliberately mirrors the logic in
/// the Flutter app's lib/core/year_progress.dart so the two stay in sync
/// conceptually, even though they're two separate codebases with no
/// runtime connection to each other.
/// </summary>
public sealed class YearProgress
{
    public DateTime Now { get; }
    public int Year { get; }
    public DateTime StartOfYear { get; }
    public DateTime StartOfNextYear { get; }

    private YearProgress(DateTime now)
    {
        Now = now;
        Year = now.Year;
        StartOfYear = new DateTime(Year, 1, 1);
        StartOfNextYear = new DateTime(Year + 1, 1, 1);
    }

    public static YearProgress FromNow() => new(DateTime.Now);

    public bool IsLeapYear => DateTime.IsLeapYear(Year);

    public int TotalDaysInYear => IsLeapYear ? 366 : 365;

    private TimeSpan Elapsed => Now - StartOfYear;
    private TimeSpan TotalYearDuration => StartOfNextYear - StartOfYear;

    /// 0.0–1.0 fraction of the year elapsed, sub-day precision so the ring
    /// advances smoothly rather than jumping once a day.
    public double Fraction
    {
        get
        {
            var f = Elapsed.TotalSeconds / TotalYearDuration.TotalSeconds;
            return Math.Clamp(f, 0.0, 1.0);
        }
    }

    public double PercentComplete => Fraction * 100.0;

    public int DaysCompleted => (int)Elapsed.TotalDays;
    public int DaysRemaining => TotalDaysInYear - DaysCompleted;

    public int CurrentMonth => Now.Month;

    public int CurrentWeek
    {
        get
        {
            var dayOfYear = DaysCompleted + 1;
            return ((dayOfYear - 1) / 7) + 1;
        }
    }

    public int TotalWeeksInYear => (int)Math.Ceiling(TotalDaysInYear / 7.0);

    public int CurrentDayOfYear => DaysCompleted + 1;

    public long HoursCompleted => (long)Elapsed.TotalHours;
    public int TotalHoursInYear => TotalDaysInYear * 24;
}