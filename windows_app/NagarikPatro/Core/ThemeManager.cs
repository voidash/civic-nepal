using Microsoft.Win32;
using System.Windows;

namespace NagarikPatro.Core;

/// <summary>
/// Detects Windows light/dark mode from registry and applies the matching
/// ResourceDictionary into Application.Resources at startup and live on change.
/// Call Initialize() once from App.OnStartup, Shutdown() from App.OnExit.
/// </summary>
public static class ThemeManager
{
    private const string RegistryPath  = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize";
    private const string RegistryValue = "AppsUseLightTheme";

    private static ResourceDictionary? _currentTheme;

    public static bool IsLightTheme { get; private set; }

    /// <summary>Fired on the UI thread whenever the active theme changes.</summary>
    public static event Action? ThemeChanged;

    public static void Initialize()
    {
        ApplyTheme(ReadIsLightFromRegistry());
        SystemEvents.UserPreferenceChanged += OnUserPreferenceChanged;
    }

    public static void Shutdown()
    {
        SystemEvents.UserPreferenceChanged -= OnUserPreferenceChanged;
    }

    private static void OnUserPreferenceChanged(object sender, UserPreferenceChangedEventArgs e)
    {
        if (e.Category != UserPreferenceCategory.General) return;

        var isLight = ReadIsLightFromRegistry();
        if (isLight == IsLightTheme) return;

        // SystemEvents can fire on a background thread — marshal to UI dispatcher.
        Application.Current?.Dispatcher.Invoke(() => ApplyTheme(isLight));
    }

    private static bool ReadIsLightFromRegistry()
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(RegistryPath);
            if (key?.GetValue(RegistryValue) is int value)
                return value != 0;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"ThemeManager: registry read error: {ex.Message}");
        }
        return false;   // default to dark
    }

    private static void ApplyTheme(bool isLight)
    {
        IsLightTheme = isLight;

        var uri = new Uri(
            isLight
                ? "pack://application:,,,/NagarikPatro;component/Resources/Themes/Light.xaml"
                : "pack://application:,,,/NagarikPatro;component/Resources/Themes/Dark.xaml",
            UriKind.Absolute);

        var newDict = new ResourceDictionary { Source = uri };
        var merged  = Application.Current.Resources.MergedDictionaries;

        if (_currentTheme != null)
            merged.Remove(_currentTheme);

        merged.Add(newDict);
        _currentTheme = newDict;

        ThemeChanged?.Invoke();
    }
}
