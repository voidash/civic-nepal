namespace NagarikPatro.Core;

/// <summary>
/// Persists user preferences via a simple JSON file in AppData.
/// </summary>
public static class AppSettings
{
    public enum Language { Nepali, English }

    private static readonly string SettingsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "NagarikPatro", "settings.json"
    );

    private static Dictionary<string, string>? _cache;

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
            using var doc = System.Text.Json.JsonDocument.Parse(json);
            foreach (var prop in doc.RootElement.EnumerateObject())
            {
                _cache[prop.Name] = prop.Value.GetString() ?? "";
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to load settings: {ex.Message}");
            _cache = new Dictionary<string, string>();
        }
    }

    private static void Save()
    {
        try
        {
            var dir = Path.GetDirectoryName(SettingsPath);
            if (dir != null) Directory.CreateDirectory(dir);

            var options = new System.Text.Json.JsonSerializerOptions { WriteIndented = true };
            var json = System.Text.Json.JsonSerializer.Serialize(_cache, options);
            File.WriteAllText(SettingsPath, json);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Settings save failed: {ex.Message}");
        }
    }
}
