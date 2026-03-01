namespace NagarikPatro.Models;

/// <summary>
/// A day in the calendar with associated metadata.
/// </summary>
public sealed class CalendarDay
{
    public int Day { get; init; }
    public bool IsToday { get; init; }
    public bool IsSaturday { get; init; }
    public bool IsHoliday { get; init; }
    public IReadOnlyList<string> Events { get; init; } = [];
    public IReadOnlyList<string> EventsNp { get; init; } = [];
    public bool IsAuspiciousWedding { get; init; }
    public bool IsAuspiciousBratabandha { get; init; }
    public bool IsAuspiciousPasni { get; init; }

    public bool HasEvents => Events.Count > 0;
    public bool HasAuspicious => IsAuspiciousWedding || IsAuspiciousBratabandha || IsAuspiciousPasni;
}
