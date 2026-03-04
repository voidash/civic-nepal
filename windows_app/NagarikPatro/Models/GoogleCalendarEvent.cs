using System.Globalization;
using System.Windows.Media;
using NagarikPatro.Core;

namespace NagarikPatro.Models;

/// <summary>
/// A Google Calendar event parsed from the Flutter app's shared cache file.
/// </summary>
public sealed record GoogleCalendarEvent(
    string Id,
    string Title,
    DateTimeOffset StartTime,
    DateTimeOffset EndTime,
    bool IsAllDay,
    string CalendarId,
    byte ColorR,
    byte ColorG,
    byte ColorB,
    string? Location
)
{
    /// <summary>Format start time as "h:mm tt" in Nepal timezone.</summary>
    public string FormattedStartTime
    {
        get
        {
            var nepalTime = StartTime.ToOffset(BsDateConverter.NepalUtcOffset);
            return nepalTime.ToString("h:mm tt", CultureInfo.InvariantCulture);
        }
    }

    /// <summary>Format time range as "9:00 AM – 10:00 AM" in Nepal timezone.</summary>
    public string FormattedTimeRange
    {
        get
        {
            var nepalStart = StartTime.ToOffset(BsDateConverter.NepalUtcOffset);
            var nepalEnd = EndTime.ToOffset(BsDateConverter.NepalUtcOffset);
            var fmt = CultureInfo.InvariantCulture;
            return $"{nepalStart.ToString("h:mm tt", fmt)} – {nepalEnd.ToString("h:mm tt", fmt)}";
        }
    }

    /// <summary>"All day" or the formatted time range.</summary>
    public string TimeDisplay => IsAllDay ? "All day" : FormattedTimeRange;

    /// <summary>Solid color brush from the event's calendar color.</summary>
    public SolidColorBrush ColorBrush => new(Color.FromRgb(ColorR, ColorG, ColorB));

    /// <summary>Light background brush (8% opacity) from the event's calendar color.</summary>
    public SolidColorBrush ColorBrushLight => new(Color.FromArgb(20, ColorR, ColorG, ColorB));

    /// <summary>Parse a "#RRGGBB" hex string into RGB bytes. Falls back to Google blue.</summary>
    public static (byte R, byte G, byte B) ParseHexColor(string? hex)
    {
        if (string.IsNullOrWhiteSpace(hex))
            return (0x42, 0x85, 0xF4); // Google blue

        var h = hex.TrimStart('#');
        if (h.Length == 6 && uint.TryParse(h, NumberStyles.HexNumber, CultureInfo.InvariantCulture, out var val))
        {
            return ((byte)((val >> 16) & 0xFF), (byte)((val >> 8) & 0xFF), (byte)(val & 0xFF));
        }
        return (0x42, 0x85, 0xF4);
    }
}
