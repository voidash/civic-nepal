using System.Text.Json;

namespace NagarikPatro.Core;

/// <summary>
/// Loads and queries event and auspicious day data from JSON files.
/// </summary>
public sealed class CalendarEventStore
{
    private static readonly Lazy<CalendarEventStore> _instance = new(() => new CalendarEventStore());
    public static CalendarEventStore Instance => _instance.Value;

    private readonly Dictionary<string, List<DayEventInfo>> _events;
    private readonly Dictionary<string, AuspiciousMonth> _auspicious;

    private CalendarEventStore()
    {
        _events = LoadEvents();
        _auspicious = LoadAuspicious();
    }

    public IReadOnlyList<DayEventInfo> EventsForMonth(int year, int month)
    {
        var key = MonthKey(year, month);
        return _events.TryGetValue(key, out var events) ? events : [];
    }

    public DayEventInfo? EventsForDay(int year, int month, int day)
    {
        return EventsForMonth(year, month).FirstOrDefault(e => e.Day == day);
    }

    public AuspiciousMonth? AuspiciousForMonth(int year, int month)
    {
        var key = MonthKey(year, month);
        return _auspicious.TryGetValue(key, out var ausp) ? ausp : null;
    }

    public bool IsAuspiciousWedding(int year, int month, int day) =>
        AuspiciousForMonth(year, month)?.BibahaLagan.Contains(day) ?? false;

    public bool IsAuspiciousBratabandha(int year, int month, int day) =>
        AuspiciousForMonth(year, month)?.Bratabandha.Contains(day) ?? false;

    public bool IsAuspiciousPasni(int year, int month, int day) =>
        AuspiciousForMonth(year, month)?.Pasni.Contains(day) ?? false;

    // Models

    public sealed record DayEventInfo(
        int Day,
        IReadOnlyList<string> Events,
        IReadOnlyList<string> EventsNp,
        bool IsHoliday
    );

    public sealed record AuspiciousMonth(
        int Year,
        int Month,
        IReadOnlyList<int> BibahaLagan,
        IReadOnlyList<int> Bratabandha,
        IReadOnlyList<int> Pasni
    );

    // Loading

    private static string MonthKey(int year, int month) => $"{year}-{month:D2}";

    private static Dictionary<string, List<DayEventInfo>> LoadEvents()
    {
        var path = Path.Combine(AppContext.BaseDirectory, "Data", "nepali_calendar_events.json");
        if (!File.Exists(path)) return [];

        try
        {
            var json = File.ReadAllText(path);
            using var doc = JsonDocument.Parse(json);
            var result = new Dictionary<string, List<DayEventInfo>>();

            foreach (var prop in doc.RootElement.EnumerateObject())
            {
                if (!prop.Value.TryGetProperty("days", out var daysElement)) continue;

                var dayList = new List<DayEventInfo>();
                foreach (var dayEl in daysElement.EnumerateArray())
                {
                    if (!dayEl.TryGetProperty("day", out var dayProp)) continue;

                    dayList.Add(new DayEventInfo(
                        Day: dayProp.GetInt32(),
                        Events: ParseStringArray(dayEl, "events"),
                        EventsNp: ParseStringArray(dayEl, "events_np"),
                        IsHoliday: dayEl.TryGetProperty("is_holiday", out var h) && h.GetBoolean()
                    ));
                }
                result[prop.Name] = dayList;
            }
            return result;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to load events: {ex.Message}");
            return [];
        }
    }

    private static Dictionary<string, AuspiciousMonth> LoadAuspicious()
    {
        var path = Path.Combine(AppContext.BaseDirectory, "Data", "nepali_calendar_auspicious.json");
        if (!File.Exists(path)) return [];

        try
        {
            var json = File.ReadAllText(path);
            using var doc = JsonDocument.Parse(json);
            var result = new Dictionary<string, AuspiciousMonth>();

            foreach (var prop in doc.RootElement.EnumerateObject())
            {
                var el = prop.Value;
                if (!el.TryGetProperty("year", out var yearProp) ||
                    !el.TryGetProperty("month", out var monthProp))
                    continue;

                result[prop.Name] = new AuspiciousMonth(
                    Year: yearProp.GetInt32(),
                    Month: monthProp.GetInt32(),
                    BibahaLagan: ParseIntArray(el, "bibaha_lagan"),
                    Bratabandha: ParseIntArray(el, "bratabandha"),
                    Pasni: ParseIntArray(el, "pasni")
                );
            }
            return result;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to load auspicious: {ex.Message}");
            return [];
        }
    }

    private static List<string> ParseStringArray(JsonElement parent, string propertyName)
    {
        if (!parent.TryGetProperty(propertyName, out var arr)) return [];
        var list = new List<string>();
        foreach (var item in arr.EnumerateArray())
            list.Add(item.GetString() ?? "");
        return list;
    }

    private static List<int> ParseIntArray(JsonElement parent, string propertyName)
    {
        if (!parent.TryGetProperty(propertyName, out var arr)) return [];
        var list = new List<int>();
        foreach (var item in arr.EnumerateArray())
            list.Add(item.GetInt32());
        return list;
    }
}
