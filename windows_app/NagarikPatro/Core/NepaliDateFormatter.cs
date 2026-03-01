using NagarikPatro.Models;

namespace NagarikPatro.Core;

/// <summary>
/// Formats BS dates with Nepali numerals and localized strings.
/// </summary>
public static class NepaliDateFormatter
{
    private static readonly char[] NepaliDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    private static BsCalendarData Cal => BsCalendarData.Instance;

    /// <summary>Convert an integer to Nepali (Devanagari) numeral string.</summary>
    public static string ToNepaliNumeral(int number)
    {
        var str = number.ToString();
        var result = new char[str.Length];
        for (int i = 0; i < str.Length; i++)
        {
            int digit = str[i] - '0';
            result[i] = (digit >= 0 && digit <= 9) ? NepaliDigits[digit] : str[i];
        }
        return new string(result);
    }

    /// <summary>Month name in Nepali (1-based).</summary>
    public static string MonthNameNp(int month) =>
        month >= 1 && month <= 12 ? Cal.MonthNamesNp[month - 1] : "";

    /// <summary>Month name in English (1-based).</summary>
    public static string MonthNameEn(int month) =>
        month >= 1 && month <= 12 ? Cal.MonthNamesEn[month - 1] : "";

    /// <summary>Weekday name in Nepali. DayOfWeek.Sunday=0.</summary>
    public static string WeekdayNameNp(DayOfWeek weekday) =>
        Cal.WeekdayNamesNp[(int)weekday];

    /// <summary>Weekday name in English.</summary>
    public static string WeekdayNameEn(DayOfWeek weekday) =>
        Cal.WeekdayNamesEn[(int)weekday];

    /// <summary>Short weekday name in Nepali.</summary>
    public static string WeekdayNameNpShort(DayOfWeek weekday) =>
        Cal.WeekdayNamesNpShort[(int)weekday];

    /// <summary>Format: "१५ बैशाख २०८१"</summary>
    public static string FormatNp(BsDate date) =>
        $"{ToNepaliNumeral(date.Day)} {MonthNameNp(date.Month)} {ToNepaliNumeral(date.Year)}";

    /// <summary>Format: "15 Baisakh 2081"</summary>
    public static string FormatEn(BsDate date) =>
        $"{date.Day} {MonthNameEn(date.Month)} {date.Year}";

    /// <summary>Format AD date: "Apr 13, 2024"</summary>
    public static string FormatAdDate(DateTime date) =>
        date.ToString("MMM d, yyyy");

    /// <summary>Format for the tray tooltip.</summary>
    public static string TrayTooltip(BsDate date) =>
        $"{MonthNameNp(date.Month)} {ToNepaliNumeral(date.Day)}, {ToNepaliNumeral(date.Year)}";
}
