using System.Diagnostics;
using System.Text.Json;

namespace NagarikPatro.Core;

/// <summary>
/// Persists user preferences via a simple JSON file in AppData.
/// Also watches tray_settings.json written by the Flutter app and fires
/// TraySettingsChanged whenever it changes.
/// </summary>
public static class AppSettings
{
    public enum Language { Nepali, English }

    // -----------------------------------------------------------------------
    // Native settings (written by this app)
    // -----------------------------------------------------------------------

    private static readonly string SettingsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "NagarikPatro", "settings.json"
    );

    private static Dictionary<string, string>? _cache;

    /// <summary>Kept for tooltip text until fully replaced by tray settings.</summary>
    public static Language MenuBarLanguage
    {
        get => Get("menuBarLanguage", "nepali") == "english" ? Language.English : Language.Nepali;
        set => Set("menuBarLanguage", value == Language.English ? "english" : "nepali");
    }

    public static bool ShowYearInTooltip
    {
        get => Get("showYearInTooltip", "false") == "true";
        set => Set("showYearInTooltip", value ? "true" : "false");
    }

    private static string Get(string key, string defaultValue)
    {
        EnsureLoaded();
        return _cache!.TryGetValue(key, out var val) ? val : defaultValue;
    }

    private static void Set(string key, string value)
    {
        EnsureLoaded();
        _cache![key] = value;
        Save();
    }

    private static void EnsureLoaded()
    {
        if (_cache != null) return;
        _cache = new Dictionary<string, string>();
        if (!File.Exists(SettingsPath)) return;
        try
        {
            var json = File.ReadAllText(SettingsPath);
            using var doc = JsonDocument.Parse(json);
            foreach (var prop in doc.RootElement.EnumerateObject())
                _cache[prop.Name] = prop.Value.GetString() ?? "";
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"AppSettings: failed to load settings: {ex.Message}");
            _cache = new Dictionary<string, string>();
        }
    }

    private static void Save()
    {
        try
        {
            var dir = Path.GetDirectoryName(SettingsPath);
            if (dir != null) Directory.CreateDirectory(dir);
            var options = new JsonSerializerOptions { WriteIndented = true };
            var json = JsonSerializer.Serialize(_cache, options);
            File.WriteAllText(SettingsPath, json);
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"AppSettings: settings save failed: {ex.Message}");
        }
    }

    // -----------------------------------------------------------------------
    // Tray settings (written by Flutter app, read-only from native side)
    // -----------------------------------------------------------------------

    /// <summary>
    /// Path of the tray_settings.json file Flutter writes.
    /// Same parent directory used by the Flutter app's cache files.
    /// </summary>
    public static readonly string TraySettingsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "NagarikPatro", "tray_settings.json"
    );

    private static TraySettingsData? _traySettings;
    private static FileSystemWatcher? _trayWatcher;
    private static System.Threading.Timer? _debounce;

    /// <summary>Fired on the UI thread whenever tray_settings.json changes.</summary>
    public static event Action<TraySettingsData>? TraySettingsChanged;

    /// <summary>Returns the current tray settings (cached; reads file on first call).</summary>
    public static TraySettingsData GetTraySettings()
    {
        _traySettings ??= LoadTraySettings();
        return _traySettings;
    }

    /// <summary>
    /// Starts watching tray_settings.json for changes.
    /// If the directory doesn't exist yet (Flutter hasn't run), retries every 30 s.
    /// Safe to call multiple times — disposes any existing watcher first.
    /// </summary>
    public static void StartTrayWatcher()
    {
        var dir = Path.GetDirectoryName(TraySettingsPath)!;
        if (!Directory.Exists(dir))
        {
            // Flutter hasn't run yet — schedule a retry.
            _debounce?.Dispose();
            _debounce = new System.Threading.Timer(_ =>
            {
                _debounce?.Dispose();
                _debounce = null;
                StartTrayWatcher();
            }, null, 30_000, System.Threading.Timeout.Infinite);
            return;
        }

        _trayWatcher?.Dispose();
        _trayWatcher = new FileSystemWatcher(dir, Path.GetFileName(TraySettingsPath))
        {
            NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.Size | NotifyFilters.FileName,
            EnableRaisingEvents = true,
        };
        _trayWatcher.Changed += OnTrayFileEvent;
        _trayWatcher.Created += OnTrayFileEvent;
    }

    private static void OnTrayFileEvent(object _, FileSystemEventArgs __)
    {
        // Debounce: FSW fires multiple events per single file write.
        _debounce?.Dispose();
        _debounce = new System.Threading.Timer(_ =>
        {
            _traySettings = LoadTraySettings();
            TraySettingsChanged?.Invoke(_traySettings);
        }, null, 500, System.Threading.Timeout.Infinite);
    }

    private static TraySettingsData LoadTraySettings()
    {
        if (!File.Exists(TraySettingsPath)) return new TraySettingsData();
        try
        {
            var json = File.ReadAllText(TraySettingsPath, System.Text.Encoding.UTF8);
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            return new TraySettingsData
            {
                MenuBarLanguage = root.TryGetProperty("menuBarLanguage", out var lang)
                    ? (lang.GetString() == "english" ? Language.English : Language.Nepali)
                    : Language.Nepali,
                ShowYearInTray = root.TryGetProperty("showYearInTray", out var year)
                    && year.GetBoolean(),
                LaunchAtLogin = root.TryGetProperty("launchAtLogin", out var launch)
                    && launch.GetBoolean(),
                ShowTrayWidget = !root.TryGetProperty("showTrayWidget", out var show)
                    || show.GetBoolean(),
            };
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"AppSettings: failed to load tray settings: {ex.Message}");
            return new TraySettingsData();
        }
    }
}

/// <summary>
/// Tray settings value object, matching the schema Flutter writes to tray_settings.json.
/// </summary>
public class TraySettingsData
{
    public AppSettings.Language MenuBarLanguage { get; init; } = AppSettings.Language.Nepali;
    public bool ShowYearInTray { get; init; }
    public bool LaunchAtLogin { get; init; }
    public bool ShowTrayWidget { get; init; } = true;
}
