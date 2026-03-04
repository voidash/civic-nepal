using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows.Threading;
using NagarikPatro.Core;
using NagarikPatro.Models;

namespace NagarikPatro.ViewModels;

/// <summary>
/// MVVM ViewModel for the calendar popup. Drives the UI via data binding.
/// </summary>
public sealed class CalendarViewModel : INotifyPropertyChanged
{
    private readonly BsCalendarData _cal = BsCalendarData.Instance;
    private readonly CalendarEventStore _eventStore = CalendarEventStore.Instance;
    private readonly GoogleCalendarCache _googleCache = GoogleCalendarCache.Instance;
    private readonly Dispatcher _dispatcher;

    private int _currentYear;
    private int _currentMonth;
    private int? _selectedDay;
    private IReadOnlyList<GoogleCalendarEvent> _upcomingGoogleEvents = [];
    private bool _hasGoogleCachedData;

    public CalendarViewModel()
    {
        _dispatcher = Dispatcher.CurrentDispatcher;

        var today = BsDateConverter.Today();
        _currentYear = today.Year;
        _currentMonth = today.Month;

        Today = today;
        TodayAd = BsDateConverter.BsToAd(today);
        TodayWeekday = BsDateConverter.Weekday(today);

        LoadGoogleEvents();

        _googleCache.CacheChanged += () =>
        {
            // CacheChanged fires from a background thread (FileSystemWatcher / Timer)
            _dispatcher.BeginInvoke(LoadGoogleEvents);
        };
    }

    // Today info (static for session)
    public BsDate Today { get; private set; }
    public DateTime TodayAd { get; private set; }
    public DayOfWeek TodayWeekday { get; private set; }

    // Formatted today strings
    public string TodayNpFormatted => NepaliDateFormatter.FormatNp(Today);
    public string TodayWeekdayNp => NepaliDateFormatter.WeekdayNameNp(TodayWeekday);
    public string TodayAdFormatted => NepaliDateFormatter.FormatAdDate(TodayAd);
    public string TodayDayNp => NepaliDateFormatter.ToNepaliNumeral(Today.Day);

    // Current month navigation
    public int CurrentYear
    {
        get => _currentYear;
        set { _currentYear = value; OnPropertyChanged(); OnMonthChanged(); }
    }

    public int CurrentMonth
    {
        get => _currentMonth;
        set { _currentMonth = value; OnPropertyChanged(); OnMonthChanged(); }
    }

    public int? SelectedDay
    {
        get => _selectedDay;
        set { _selectedDay = value; OnPropertyChanged(); OnPropertyChanged(nameof(SelectedDayEvents)); OnPropertyChanged(nameof(HasSelectedDayContent)); }
    }

    // Derived month info
    public string MonthHeaderNp => $"{NepaliDateFormatter.MonthNameNp(CurrentMonth)} {NepaliDateFormatter.ToNepaliNumeral(CurrentYear)}";
    public string MonthHeaderEn => NepaliDateFormatter.MonthNameEn(CurrentMonth);

    public int DaysInMonth => _cal.DaysInMonth(CurrentYear, CurrentMonth) ?? 30;

    /// <summary>0=Sunday offset for the first day of the month.</summary>
    public int FirstDayOffset => (int)BsDateConverter.FirstWeekday(CurrentYear, CurrentMonth);

    public IReadOnlyList<CalendarDay> CalendarDays
    {
        get
        {
            var events = _eventStore.EventsForMonth(CurrentYear, CurrentMonth);
            var eventDict = events.ToDictionary(e => e.Day);
            var ausp = _eventStore.AuspiciousForMonth(CurrentYear, CurrentMonth);

            var days = new List<CalendarDay>();
            // Compute first day's weekday once, then advance incrementally (O(1) per day)
            var firstWeekday = (int)BsDateConverter.FirstWeekday(CurrentYear, CurrentMonth);
            for (int d = 1; d <= DaysInMonth; d++)
            {
                var weekday = (DayOfWeek)((firstWeekday + d - 1) % 7);
                eventDict.TryGetValue(d, out var dayEvent);

                days.Add(new CalendarDay
                {
                    Day = d,
                    IsToday = Today.Year == CurrentYear && Today.Month == CurrentMonth && Today.Day == d,
                    IsSaturday = weekday == DayOfWeek.Saturday,
                    IsHoliday = dayEvent?.IsHoliday ?? false,
                    Events = dayEvent?.Events ?? [],
                    EventsNp = dayEvent?.EventsNp ?? [],
                    IsAuspiciousWedding = ausp?.BibahaLagan.Contains(d) ?? false,
                    IsAuspiciousBratabandha = ausp?.Bratabandha.Contains(d) ?? false,
                    IsAuspiciousPasni = ausp?.Pasni.Contains(d) ?? false,
                });
            }
            return days;
        }
    }

    // Selected day events
    public IReadOnlyList<SelectedDayEvent> SelectedDayEvents
    {
        get
        {
            if (SelectedDay is not { } day) return [];
            var info = _eventStore.EventsForDay(CurrentYear, CurrentMonth, day);
            if (info == null) return [];
            return info.Events.Zip(info.EventsNp, (en, np) => new SelectedDayEvent(np, en, info.IsHoliday)).ToList();
        }
    }

    public bool HasSelectedDayContent
    {
        get
        {
            if (SelectedDay is not { } day) return false;
            var info = _eventStore.EventsForDay(CurrentYear, CurrentMonth, day);
            if (info != null && info.Events.Count > 0) return true;
            return _eventStore.IsAuspiciousWedding(CurrentYear, CurrentMonth, day)
                || _eventStore.IsAuspiciousBratabandha(CurrentYear, CurrentMonth, day)
                || _eventStore.IsAuspiciousPasni(CurrentYear, CurrentMonth, day);
        }
    }

    // Google Calendar
    public IReadOnlyList<GoogleCalendarEvent> UpcomingGoogleEvents
    {
        get => _upcomingGoogleEvents;
        private set { _upcomingGoogleEvents = value; OnPropertyChanged(); OnPropertyChanged(nameof(HasUpcomingGoogleEvents)); OnPropertyChanged(nameof(NoUpcomingGoogleEvents)); }
    }

    public bool HasGoogleCachedData
    {
        get => _hasGoogleCachedData;
        private set { _hasGoogleCachedData = value; OnPropertyChanged(); OnPropertyChanged(nameof(ShowGoogleSignInPrompt)); }
    }

    public bool ShowGoogleSignInPrompt => !HasGoogleCachedData;
    public bool HasUpcomingGoogleEvents => UpcomingGoogleEvents.Count > 0;
    public bool NoUpcomingGoogleEvents => HasGoogleCachedData && UpcomingGoogleEvents.Count == 0;

    public void LoadGoogleEvents()
    {
        HasGoogleCachedData = _googleCache.HasCachedData;

        if (!HasGoogleCachedData)
        {
            UpcomingGoogleEvents = [];
            return;
        }

        // All-day events for today + timed events in next 24h, deduplicated, top 5
        var allDay = _googleCache.TodayEvents().Where(e => e.IsAllDay);
        var timed = _googleCache.UpcomingEvents(24);

        var seen = new HashSet<string>();
        var merged = new List<GoogleCalendarEvent>();

        foreach (var e in allDay)
        {
            if (seen.Add(e.Id))
                merged.Add(e);
        }
        foreach (var e in timed)
        {
            if (seen.Add(e.Id))
                merged.Add(e);
        }

        UpcomingGoogleEvents = merged.Take(5).ToList();
    }

    // Navigation commands
    public void PreviousMonth()
    {
        SelectedDay = null;
        if (_currentMonth == 1)
        {
            _currentMonth = 12;
            _currentYear--;
        }
        else
        {
            _currentMonth--;
        }
        OnPropertyChanged(nameof(CurrentYear));
        OnPropertyChanged(nameof(CurrentMonth));
        OnMonthChanged();
    }

    public void NextMonth()
    {
        SelectedDay = null;
        if (_currentMonth == 12)
        {
            _currentMonth = 1;
            _currentYear++;
        }
        else
        {
            _currentMonth++;
        }
        OnPropertyChanged(nameof(CurrentYear));
        OnPropertyChanged(nameof(CurrentMonth));
        OnMonthChanged();
    }

    public void SelectDay(int day)
    {
        SelectedDay = SelectedDay == day ? null : day;
    }

    /// <summary>Refresh today's date (called at midnight or wake).</summary>
    public void RefreshToday()
    {
        Today = BsDateConverter.Today();
        TodayAd = BsDateConverter.BsToAd(Today);
        TodayWeekday = BsDateConverter.Weekday(Today);

        OnPropertyChanged(nameof(Today));
        OnPropertyChanged(nameof(TodayAd));
        OnPropertyChanged(nameof(TodayWeekday));
        OnPropertyChanged(nameof(TodayNpFormatted));
        OnPropertyChanged(nameof(TodayWeekdayNp));
        OnPropertyChanged(nameof(TodayAdFormatted));
        OnPropertyChanged(nameof(TodayDayNp));
        OnPropertyChanged(nameof(CalendarDays));

        LoadGoogleEvents();
    }

    private void OnMonthChanged()
    {
        OnPropertyChanged(nameof(MonthHeaderNp));
        OnPropertyChanged(nameof(MonthHeaderEn));
        OnPropertyChanged(nameof(DaysInMonth));
        OnPropertyChanged(nameof(FirstDayOffset));
        OnPropertyChanged(nameof(CalendarDays));
    }

    // INotifyPropertyChanged
    public event PropertyChangedEventHandler? PropertyChanged;
    private void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}

public sealed record SelectedDayEvent(string EventNp, string EventEn, bool IsHoliday);
