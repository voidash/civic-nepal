using NagarikPatro.Models;

namespace NagarikPatro.Core;

/// <summary>
/// Converts between AD (Gregorian) and BS (Bikram Sambat) calendar systems.
/// Ported from nepali_utils 3.0.8.
/// NO +1 day hack — C# doesn't have Dart's DateTime timezone bug.
/// </summary>
public static class BsDateConverter
{
    /// <summary>Nepal timezone: UTC+5:45 = 20700 seconds.</summary>
    public static readonly TimeSpan NepalUtcOffset = new(5, 45, 0);

    private static BsCalendarData Cal => BsCalendarData.Instance;

    private static readonly int[] EnglishMonths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    private static readonly int[] EnglishLeapMonths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    // MARK: AD → BS

    /// <summary>Convert a DateTimeOffset to BS date (interpreted in Nepal time).</summary>
    public static BsDate AdToBs(DateTimeOffset adDate)
    {
        var nepalTime = adDate.ToOffset(NepalUtcOffset);
        return AdToBs(nepalTime.Year, nepalTime.Month, nepalTime.Day);
    }

    /// <summary>Convert AD year/month/day to BS date. Reference: AD 1913-04-13 = BS 1970/01/01.</summary>
    public static BsDate AdToBs(int adYear, int adMonth, int adDay)
    {
        var adDate = new DateTime(adYear, adMonth, adDay, 0, 0, 0, DateTimeKind.Utc);
        var refDate = new DateTime(1913, 4, 13, 0, 0, 0, DateTimeKind.Utc);
        int difference = (adDate - refDate).Days;

        int bsYear = 1970;
        int bsMonth = 1;
        int bsDay = 1;

        // Advance years
        int daysInYear = Cal.DaysInYear(bsYear) ?? 365;
        while (difference >= daysInYear)
        {
            difference -= daysInYear;
            bsYear++;
            daysInYear = Cal.DaysInYear(bsYear) ?? 365;
        }

        // Advance months
        int daysInMonth = Cal.DaysInMonth(bsYear, bsMonth) ?? 30;
        while (difference >= daysInMonth)
        {
            difference -= daysInMonth;
            bsMonth++;
            daysInMonth = Cal.DaysInMonth(bsYear, bsMonth) ?? 30;
        }

        bsDay += difference;

        return new BsDate(bsYear, bsMonth, bsDay);
    }

    // MARK: BS → AD

    /// <summary>
    /// Convert a BS date to Gregorian (AD).
    /// Reference: BS 1969/09/18 = AD 1913/01/01.
    /// </summary>
    public static DateTime BsToAd(BsDate bsDate)
    {
        var refBs = new BsDate(1969, 9, 18);

        int totalTarget = CountTotalNepaliDays(bsDate.Year, bsDate.Month, bsDate.Day);
        int totalRef = CountTotalNepaliDays(refBs.Year, refBs.Month, refBs.Day);
        int difference = Math.Abs(totalTarget - totalRef);

        int adYear = 1913;
        int adMonth = 1;
        int adDay = 1;

        // Advance years
        while (difference >= (IsLeapYear(adYear) ? 366 : 365))
        {
            difference -= IsLeapYear(adYear) ? 366 : 365;
            adYear++;
        }

        // Advance months
        int[] monthDays = IsLeapYear(adYear) ? EnglishLeapMonths : EnglishMonths;
        int i = 0;
        while (i < monthDays.Length && difference >= monthDays[i])
        {
            adMonth++;
            difference -= monthDays[i];
            i++;
        }

        adDay += difference;

        return new DateTime(adYear, adMonth, adDay, 0, 0, 0, DateTimeKind.Utc);
    }

    // MARK: Today

    /// <summary>Get today's date in BS (based on current Nepal time).</summary>
    public static BsDate Today()
    {
        return AdToBs(DateTimeOffset.UtcNow);
    }

    /// <summary>Get the weekday (0=Sunday, 6=Saturday) for a BS date.</summary>
    public static DayOfWeek Weekday(BsDate bsDate)
    {
        return BsToAd(bsDate).DayOfWeek;
    }

    /// <summary>Get the weekday for the first day of a BS month.</summary>
    public static DayOfWeek FirstWeekday(int year, int month)
    {
        return Weekday(new BsDate(year, month, 1));
    }

    // MARK: Helpers

    private static int CountTotalNepaliDays(int year, int month, int day)
    {
        if (year < 1969) return 0;
        int total = day - 1;

        // Add days for months before current month
        if (Cal.Years.TryGetValue(year, out var yearData))
        {
            for (int m = 1; m < month; m++)
                total += yearData[m];
        }

        // Add days for all years before current year
        for (int y = 1969; y < year; y++)
            total += Cal.DaysInYear(y) ?? 365;

        return total;
    }

    private static bool IsLeapYear(int year) =>
        (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
}
