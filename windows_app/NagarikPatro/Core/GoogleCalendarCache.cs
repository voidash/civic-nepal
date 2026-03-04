using System.Globalization;
using System.IO;
using System.Text.Json;
using System.Windows.Threading;
using NagarikPatro.Models;

namespace NagarikPatro.Core;

/// <summary>
/// Reads Google Calendar events from a shared JSON cache written by the Flutter app.
/// Cache path: %APPDATA%\NagarikPatro\google_calendar_cache.json
/// </summary>
public sealed class GoogleCalendarCache : IDisposable
{
    private static readonly Lazy<GoogleCalendarCache> _instance = new(() => new GoogleCalendarCache());
    public static GoogleCalendarCache Instance => _instance.Value;

    private const string CacheFileName = "google_calendar_cache.json";
    private const int DebounceMs = 500;
    private const int DirectoryPollIntervalSeconds = 30;

    private readonly object _lock = new();
    private CachedGoogleData? _cachedData;
    private FileSystemWatcher? _watcher;
    private System.Threading.Timer? _debounceTimer;
    private DispatcherTimer? _directoryPollTimer;
    private bool _disposed;

    /// <summary>Fired when the cache file changes on disk (debounced).</summary>
    public event Action? CacheChanged;

    private GoogleCalendarCache()
    {
        InitializeWatcher();
    }

    // MARK: - Public API

    /// <summary>Read and parse the cache file. Returns null if missing or invalid.</summary>
    public CachedGoogleData? ReadCache()
    {
        var path = ResolveCachePath();
        if (path == null || !File.Exists(path))
            return null;

        try
        {
            // Open with FileShare.ReadWrite — Flutter may be writing concurrently
            using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
            using var doc = JsonDocument.Parse(stream);
            var root = doc.RootElement;

            DateTimeOffset? lastSynced = null;
            if (root.TryGetProperty("lastSynced", out var lsProp) && lsProp.ValueKind == JsonValueKind.String)
            {
                if (DateTimeOffset.TryParse(lsProp.GetString(), CultureInfo.InvariantCulture,
                        DateTimeStyles.RoundtripKind, out var ls))
                    lastSynced = ls;
            }

            string? userEmail = null;
            if (root.TryGetProperty("userEmail", out var emailProp) && emailProp.ValueKind == JsonValueKind.String)
                userEmail = emailProp.GetString();

            var events = new List<GoogleCalendarEvent>();
            if (root.TryGetProperty("events", out var eventsArr) && eventsArr.ValueKind == JsonValueKind.Array)
            {
                foreach (var el in eventsArr.EnumerateArray())
                {
                    var evt = ParseEvent(el);
                    if (evt != null)
                        events.Add(evt);
                }
            }

            var data = new CachedGoogleData(lastSynced, userEmail, events);
            lock (_lock)
            {
                _cachedData = data;
            }
            return data;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"GoogleCalendarCache: Failed to read cache: {ex.Message}");
            return null;
        }
    }

    /// <summary>Today's Google Calendar events (Nepal timezone).</summary>
    public IReadOnlyList<GoogleCalendarEvent> TodayEvents()
    {
        var cache = ReadCache();
        if (cache == null) return [];

        var (start, end) = DayBounds(0);
        return cache.Events.Where(e => e.StartTime >= start && e.StartTime < end).ToList();
    }

    /// <summary>Upcoming timed events from now within the given hours window.</summary>
    public IReadOnlyList<GoogleCalendarEvent> UpcomingEvents(int hours = 24)
    {
        var cache = ReadCache();
        if (cache == null) return [];

        var now = DateTimeOffset.UtcNow;
        var end = now.AddHours(hours);
        return cache.Events.Where(e => !e.IsAllDay && e.EndTime > now && e.StartTime < end).ToList();
    }

    /// <summary>Whether the cache file exists and was successfully parsed.</summary>
    public bool HasCachedData => ReadCache() != null;

    /// <summary>User email from the cache.</summary>
    public string? UserEmail => ReadCache()?.UserEmail;

    // MARK: - FileSystemWatcher

    private void InitializeWatcher()
    {
        var dir = ResolveCacheDirectory();
        if (dir != null && Directory.Exists(dir))
        {
            StartWatcher(dir);
        }
        else
        {
            // Directory doesn't exist yet — poll until it appears
            StartDirectoryPolling();
        }
    }

    private void StartWatcher(string directory)
    {
        try
        {
            _watcher = new FileSystemWatcher(directory, CacheFileName)
            {
                NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.Size | NotifyFilters.CreationTime,
                EnableRaisingEvents = true,
            };

            _watcher.Changed += OnCacheFileChanged;
            _watcher.Created += OnCacheFileChanged;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"GoogleCalendarCache: Failed to start watcher: {ex.Message}");
        }
    }

    private void OnCacheFileChanged(object sender, FileSystemEventArgs e)
    {
        // Debounce: FSW fires multiple events per write
        _debounceTimer?.Dispose();
        _debounceTimer = new System.Threading.Timer(_ =>
        {
            lock (_lock)
            {
                _cachedData = null; // Invalidate
            }
            CacheChanged?.Invoke();
        }, null, DebounceMs, System.Threading.Timeout.Infinite);
    }

    private void StartDirectoryPolling()
    {
        _directoryPollTimer = new DispatcherTimer
        {
            Interval = TimeSpan.FromSeconds(DirectoryPollIntervalSeconds),
        };
        _directoryPollTimer.Tick += (_, _) =>
        {
            var dir = ResolveCacheDirectory();
            if (dir != null && Directory.Exists(dir))
            {
                _directoryPollTimer.Stop();
                _directoryPollTimer = null;
                StartWatcher(dir);
                // If file already exists, notify
                if (File.Exists(Path.Combine(dir, CacheFileName)))
                    CacheChanged?.Invoke();
            }
        };
        _directoryPollTimer.Start();
    }

    // MARK: - Path resolution

    /// <summary>Resolve the directory containing the cache file.</summary>
    private static string? ResolveCacheDirectory()
    {
        var appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        var localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);

        // Check %APPDATA%\NagarikPatro first, then %LOCALAPPDATA%\NagarikPatro
        string[] candidates =
        [
            Path.Combine(appData, "NagarikPatro"),
            Path.Combine(localAppData, "NagarikPatro"),
        ];

        foreach (var dir in candidates)
        {
            if (File.Exists(Path.Combine(dir, CacheFileName)))
                return dir;
        }

        // Return first candidate as default even if directory doesn't exist yet
        return !string.IsNullOrEmpty(appData) ? candidates[0] : null;
    }

    /// <summary>Resolve the full path to the cache file, or null if no candidate directory.</summary>
    private static string? ResolveCachePath()
    {
        var dir = ResolveCacheDirectory();
        return dir != null ? Path.Combine(dir, CacheFileName) : null;
    }

    // MARK: - Parsing

    private static GoogleCalendarEvent? ParseEvent(JsonElement el)
    {
        if (!el.TryGetProperty("id", out var idProp) || idProp.ValueKind != JsonValueKind.String)
            return null;
        if (!el.TryGetProperty("title", out var titleProp) || titleProp.ValueKind != JsonValueKind.String)
            return null;
        if (!el.TryGetProperty("startTime", out var startProp) || startProp.ValueKind != JsonValueKind.String)
            return null;

        var id = idProp.GetString()!;
        var title = titleProp.GetString()!;

        if (!DateTimeOffset.TryParse(startProp.GetString(), CultureInfo.InvariantCulture,
                DateTimeStyles.RoundtripKind, out var startTime))
            return null;

        DateTimeOffset endTime;
        if (el.TryGetProperty("endTime", out var endProp) && endProp.ValueKind == JsonValueKind.String &&
            DateTimeOffset.TryParse(endProp.GetString(), CultureInfo.InvariantCulture,
                DateTimeStyles.RoundtripKind, out var parsedEnd))
        {
            endTime = parsedEnd;
        }
        else
        {
            endTime = startTime.AddHours(1); // Default 1 hour
        }

        var isAllDay = el.TryGetProperty("isAllDay", out var allDayProp) &&
                       allDayProp.ValueKind == JsonValueKind.True;

        var calendarId = el.TryGetProperty("calendarId", out var calProp) && calProp.ValueKind == JsonValueKind.String
            ? calProp.GetString()! : "primary";

        string? colorHex = el.TryGetProperty("colorHex", out var colorProp) && colorProp.ValueKind == JsonValueKind.String
            ? colorProp.GetString() : null;

        string? location = el.TryGetProperty("location", out var locProp) && locProp.ValueKind == JsonValueKind.String
            ? locProp.GetString() : null;

        var (r, g, b) = GoogleCalendarEvent.ParseHexColor(colorHex);

        return new GoogleCalendarEvent(id, title, startTime, endTime, isAllDay, calendarId, r, g, b, location);
    }

    // MARK: - Day bounds

    private static (DateTimeOffset Start, DateTimeOffset End) DayBounds(int daysFromNow)
    {
        var now = DateTimeOffset.UtcNow;
        var nepalNow = now.ToOffset(BsDateConverter.NepalUtcOffset);
        var nepalToday = new DateTimeOffset(
            nepalNow.Year, nepalNow.Month, nepalNow.Day, 0, 0, 0,
            BsDateConverter.NepalUtcOffset
        );
        var dayStart = nepalToday.AddDays(daysFromNow);
        var dayEnd = dayStart.AddDays(1);
        return (dayStart, dayEnd);
    }

    // MARK: - IDisposable

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        _debounceTimer?.Dispose();
        _directoryPollTimer?.Stop();

        if (_watcher != null)
        {
            _watcher.EnableRaisingEvents = false;
            _watcher.Dispose();
        }
    }
}

/// <summary>Parsed cache data from the Flutter app's Google Calendar cache.</summary>
public sealed record CachedGoogleData(
    DateTimeOffset? LastSynced,
    string? UserEmail,
    IReadOnlyList<GoogleCalendarEvent> Events
);
