using System.Text.Json;

namespace NagarikPatro.Core;

/// <summary>
/// Loads and provides access to the BS calendar month-length tables (282 years).
/// Thread-safe singleton.
/// </summary>
public sealed class BsCalendarData
{
    private static readonly Lazy<BsCalendarData> _instance = new(() => new BsCalendarData());
    public static BsCalendarData Instance => _instance.Value;

    public string Source { get; }
    public string ReferenceAd { get; }
    public int ReferenceBsYear { get; }
    public int ReferenceBsMonth { get; }
    public int ReferenceBsDay { get; }
    public int YearMin { get; }
    public int YearMax { get; }
    public int NepalTzOffsetSeconds { get; }

    public IReadOnlyList<string> MonthNamesEn { get; }
    public IReadOnlyList<string> MonthNamesNp { get; }
    public IReadOnlyList<string> WeekdayNamesEn { get; }
    public IReadOnlyList<string> WeekdayNamesNp { get; }
    public IReadOnlyList<string> WeekdayNamesNpShort { get; }

    /// <summary>
    /// Key: BS year. Value: int[13] where [0]=totalDays, [1..12]=days per month.
    /// </summary>
    public IReadOnlyDictionary<int, int[]> Years { get; }

    private BsCalendarData()
    {
        var path = Path.Combine(AppContext.BaseDirectory, "Data", "bs_calendar_data.json");
        if (!File.Exists(path))
            throw new FileNotFoundException($"bs_calendar_data.json not found at {path}");

        var json = File.ReadAllText(path);
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;

        var meta = root.GetProperty("meta");
        Source = meta.GetProperty("source").GetString()!;
        ReferenceAd = meta.GetProperty("reference_ad").GetString()!;
        var refBs = meta.GetProperty("reference_bs");
        ReferenceBsYear = refBs.GetProperty("year").GetInt32();
        ReferenceBsMonth = refBs.GetProperty("month").GetInt32();
        ReferenceBsDay = refBs.GetProperty("day").GetInt32();
        var yearRange = meta.GetProperty("year_range");
        YearMin = yearRange[0].GetInt32();
        YearMax = yearRange[1].GetInt32();
        NepalTzOffsetSeconds = meta.GetProperty("nepal_tz_offset_seconds").GetInt32();

        MonthNamesEn = ParseStringArray(root.GetProperty("month_names_en"));
        MonthNamesNp = ParseStringArray(root.GetProperty("month_names_np"));
        WeekdayNamesEn = ParseStringArray(root.GetProperty("weekday_names_en"));
        WeekdayNamesNp = ParseStringArray(root.GetProperty("weekday_names_np"));
        WeekdayNamesNpShort = ParseStringArray(root.GetProperty("weekday_names_np_short"));

        var yearsElement = root.GetProperty("years");
        var years = new Dictionary<int, int[]>();
        foreach (var prop in yearsElement.EnumerateObject())
        {
            if (!int.TryParse(prop.Name, out int year)) continue;
            var values = new int[prop.Value.GetArrayLength()];
            int i = 0;
            foreach (var v in prop.Value.EnumerateArray())
                values[i++] = v.GetInt32();
            years[year] = values;
        }
        Years = years;
    }

    public int? DaysInMonth(int year, int month)
    {
        if (month < 1 || month > 12) return null;
        if (!Years.TryGetValue(year, out var data) || data.Length != 13) return null;
        return data[month];
    }

    public int? DaysInYear(int year)
    {
        if (!Years.TryGetValue(year, out var data) || data.Length == 0) return null;
        return data[0];
    }

    public bool IsYearSupported(int year) => Years.ContainsKey(year);

    private static List<string> ParseStringArray(JsonElement element)
    {
        var list = new List<string>();
        foreach (var item in element.EnumerateArray())
            list.Add(item.GetString()!);
        return list;
    }
}
