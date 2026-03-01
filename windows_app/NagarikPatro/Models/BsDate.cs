namespace NagarikPatro.Models;

/// <summary>
/// A date in the Bikram Sambat (BS) calendar system used in Nepal.
/// </summary>
public readonly record struct BsDate(int Year, int Month, int Day) : IComparable<BsDate>
{
    public int CompareTo(BsDate other)
    {
        int cmp = Year.CompareTo(other.Year);
        if (cmp != 0) return cmp;
        cmp = Month.CompareTo(other.Month);
        if (cmp != 0) return cmp;
        return Day.CompareTo(other.Day);
    }

    public override string ToString() => $"{Year}-{Month:D2}-{Day:D2}";
}
