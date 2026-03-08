using System.Diagnostics;
using System.Net.Http;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Threading;
using Microsoft.Win32;
using NagarikPatro.Core;
using WinForms = System.Windows.Forms;

namespace NagarikPatro.Views;

/// <summary>
/// Manages the system tray NotifyIcon.
/// Left-click: toggle the Flutter popup via HTTP (localhost:27182).
/// Right-click: minimal context menu (date display + Open + Quit).
/// Tray widget settings (language, year, launch-at-login, visibility) are
/// managed from the Flutter app and delivered via tray_settings.json.
/// </summary>
public sealed class SystemTrayManager : IDisposable
{
    private readonly WinForms.NotifyIcon _notifyIcon;
    private DispatcherTimer? _midnightTimer;

    // Context menu date items (kept live across midnight)
    private WinForms.ToolStripMenuItem? _todayHeader;
    private WinForms.ToolStripMenuItem? _todayAdHeader;

    private static readonly HttpClient _http = new() { Timeout = TimeSpan.FromSeconds(3) };
    private const string TrayServerBase = "http://127.0.0.1:27182";

    // Abbreviated Nepali month names for the tray icon header (3-char)
    private static readonly string[] MonthAbbrevNp =
    [
        "बैश", "जेठ", "असा", "श्र", "भाद", "आश",
        "कार", "मंस", "पौष", "माघ", "फाग", "चैत"
    ];

    public SystemTrayManager()
    {
        _notifyIcon = new WinForms.NotifyIcon
        {
            Icon    = BuildTrayIcon(),
            Visible = true,
            Text    = GetTooltipText(),
        };

        _notifyIcon.MouseClick      += OnTrayClick;
        _notifyIcon.ContextMenuStrip = BuildContextMenu();

        ThemeManager.ThemeChanged += RebuildTrayIcon;
        ScheduleMidnightRefresh();

        // Start watching tray_settings.json written by Flutter.
        AppSettings.StartTrayWatcher();
        AppSettings.TraySettingsChanged += OnTraySettingsChanged;
    }

    // -------------------------------------------------------------------------
    // Tray click — toggle Flutter popup via HTTP
    // -------------------------------------------------------------------------

    private void OnTrayClick(object? sender, WinForms.MouseEventArgs e)
    {
        if (e.Button != WinForms.MouseButtons.Left) return;
        _ = ToggleFlutterPopupAsync();
    }

    private async Task ToggleFlutterPopupAsync()
    {
        try
        {
            await _http.PostAsync($"{TrayServerBase}/popup/toggle", content: null);
        }
        catch (Exception)
        {
            // Flutter not running — launch it, then retry once it's ready.
            LaunchFlutterApp();

            await Task.Delay(3000);
            try
            {
                await _http.PostAsync($"{TrayServerBase}/popup/toggle", content: null);
            }
            catch (Exception)
            {
                _notifyIcon.ShowBalloonTip(3000, "Nagarik Patro",
                    "Starting Nagarik Patro…", WinForms.ToolTipIcon.Info);
            }
        }
    }

    // -------------------------------------------------------------------------
    // Context menu — minimal: date display, Open, Quit
    // -------------------------------------------------------------------------

    private WinForms.ContextMenuStrip BuildContextMenu()
    {
        var menu  = new WinForms.ContextMenuStrip();
        var today = BsDateConverter.Today();

        _todayHeader = new WinForms.ToolStripMenuItem($"आज: {NepaliDateFormatter.FormatNp(today)}")
            { Enabled = false };
        menu.Items.Add(_todayHeader);

        _todayAdHeader = new WinForms.ToolStripMenuItem(
            NepaliDateFormatter.FormatAdDate(BsDateConverter.BsToAd(today)))
            { Enabled = false };
        menu.Items.Add(_todayAdHeader);

        menu.Items.Add(new WinForms.ToolStripSeparator());

        menu.Items.Add("Open Nagarik Patro", null, (_, _) =>
            _ = OpenFullAppAsync());

        menu.Items.Add(new WinForms.ToolStripSeparator());

        menu.Items.Add("Quit", null, (_, _) =>
        {
            Dispose();
            Application.Current.Shutdown();
        });

        return menu;
    }

    private void UpdateContextMenuDate()
    {
        var today = BsDateConverter.Today();
        if (_todayHeader   != null) _todayHeader.Text   = $"आज: {NepaliDateFormatter.FormatNp(today)}";
        if (_todayAdHeader != null) _todayAdHeader.Text = NepaliDateFormatter.FormatAdDate(BsDateConverter.BsToAd(today));
    }

    private void UpdateTooltip() => _notifyIcon.Text = GetTooltipText();

    private static string GetTooltipText()
    {
        var today    = BsDateConverter.Today();
        var ts       = AppSettings.GetTraySettings();
        var showYear = ts.ShowYearInTray;

        return ts.MenuBarLanguage switch
        {
            AppSettings.Language.English =>
                showYear
                    ? $"{NepaliDateFormatter.MonthNameEn(today.Month)} {today.Day}, {today.Year}"
                    : $"{NepaliDateFormatter.MonthNameEn(today.Month)} {today.Day}",
            _ =>
                showYear
                    ? $"{NepaliDateFormatter.MonthNameNp(today.Month)} {NepaliDateFormatter.ToNepaliNumeral(today.Day)}, {NepaliDateFormatter.ToNepaliNumeral(today.Year)}"
                    : NepaliDateFormatter.TrayTooltip(today),
        };
    }

    // -------------------------------------------------------------------------
    // Open full app (expand Flutter window to full-app mode)
    // -------------------------------------------------------------------------

    private async Task OpenFullAppAsync()
    {
        try
        {
            await _http.PostAsync($"{TrayServerBase}/popup/open-app", content: null);
        }
        catch (Exception)
        {
            LaunchFlutterApp();
        }
    }

    // -------------------------------------------------------------------------
    // Tray settings change handler
    // -------------------------------------------------------------------------

    private void OnTraySettingsChanged(TraySettingsData settings)
    {
        Application.Current.Dispatcher.BeginInvoke(() =>
        {
            if (!settings.ShowTrayWidget)
            {
                // Flutter asked us to disappear.
                Dispose();
                Application.Current.Shutdown();
                return;
            }

            // Sync launch-at-login with what Flutter says.
            SyncLaunchAtLogin(settings.LaunchAtLogin);

            UpdateTooltip();
            RebuildTrayIcon();
        });
    }

    // -------------------------------------------------------------------------
    // Launch at login (registry)
    // -------------------------------------------------------------------------

    private static bool IsLaunchAtLoginEnabled()
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(
                @"SOFTWARE\Microsoft\Windows\CurrentVersion\Run");
            return key?.GetValue("NagarikPatro") != null;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"AppSettings: registry read error: {ex.Message}");
            return false;
        }
    }

    private static void SyncLaunchAtLogin(bool desired)
    {
        if (IsLaunchAtLoginEnabled() == desired) return;
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(
                @"SOFTWARE\Microsoft\Windows\CurrentVersion\Run", writable: true);
            if (key == null) return;

            if (desired)
            {
                var exePath = Process.GetCurrentProcess().MainModule?.FileName;
                if (exePath != null) key.SetValue("NagarikPatro", exePath);
            }
            else
            {
                key.DeleteValue("NagarikPatro", throwOnMissingValue: false);
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"AppSettings: registry write error: {ex.Message}");
        }
    }

    // -------------------------------------------------------------------------
    // Launch Flutter app process
    // -------------------------------------------------------------------------

    private const string FlutterExeName = "nagarik_calendar.exe";

    private void LaunchFlutterApp()
    {
        var path = FindFlutterApp();
        if (path != null)
        {
            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName        = path,
                    UseShellExecute = true,
                });
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Failed to launch Nagarik Patro: {ex.Message}");
            }
        }
        else
        {
            _notifyIcon.ShowBalloonTip(4000, "Nagarik Patro not found",
                "Install Nagarik Patro to use this feature.", WinForms.ToolTipIcon.Info);
        }
    }

    private static string? FindFlutterApp()
    {
        var fromRegistry = FindViaAppPaths();
        if (fromRegistry != null) return fromRegistry;

        var localAppData    = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        var programFiles    = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
        var programFilesX86 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);
        var exeDir          = AppContext.BaseDirectory;

        string[] candidates =
        [
            Path.Combine(localAppData, "NagarikPatro",    FlutterExeName),
            Path.Combine(localAppData, "nagarik_calendar", FlutterExeName),
            Path.Combine(localAppData, "Programs", "NagarikPatro", FlutterExeName),
            Path.Combine(localAppData, "Programs", "nagarik_calendar", FlutterExeName),
            Path.Combine(programFiles, "NagarikPatro",    FlutterExeName),
            Path.Combine(programFiles, "nagarik_calendar", FlutterExeName),
            Path.Combine(programFilesX86, "NagarikPatro", FlutterExeName),
            Path.Combine(exeDir,                          FlutterExeName),
        ];

        return Array.Find(candidates, File.Exists);
    }

    private static string? FindViaAppPaths()
    {
        string[] registryPaths =
        [
            $@"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\{FlutterExeName}",
            $@"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\{FlutterExeName}",
        ];

        foreach (var regPath in registryPaths)
        {
            foreach (var hive in new[] { Registry.LocalMachine, Registry.CurrentUser })
            {
                try
                {
                    using var key = hive.OpenSubKey(regPath);
                    var value = key?.GetValue(null) as string;
                    if (value != null && File.Exists(value))
                        return value;
                }
                catch (Exception ex)
                {
                    Debug.WriteLine($"App Paths registry lookup failed: {ex.Message}");
                }
            }
        }
        return null;
    }

    // -------------------------------------------------------------------------
    // Midnight refresh
    // -------------------------------------------------------------------------

    private void ScheduleMidnightRefresh()
    {
        _midnightTimer?.Stop();

        var now           = DateTimeOffset.UtcNow;
        var nepalNow      = now.ToOffset(BsDateConverter.NepalUtcOffset);
        var nepalMidnight = new DateTimeOffset(
            nepalNow.Year, nepalNow.Month, nepalNow.Day, 0, 0, 0,
            BsDateConverter.NepalUtcOffset).AddDays(1);

        var interval = nepalMidnight - now;
        if (interval <= TimeSpan.Zero) interval = TimeSpan.FromMinutes(1);

        _midnightTimer = new DispatcherTimer { Interval = interval };
        _midnightTimer.Tick += (_, _) =>
        {
            UpdateTooltip();
            UpdateContextMenuDate();
            RebuildTrayIcon();
            ScheduleMidnightRefresh();
        };
        _midnightTimer.Start();
    }

    // -------------------------------------------------------------------------
    // Tray icon — text showing abbreviated month + day numeral in current BS date
    // -------------------------------------------------------------------------

    private void RebuildTrayIcon()
    {
        var old = _notifyIcon.Icon;
        _notifyIcon.Icon = BuildTrayIcon();
        old?.Dispose();
    }

    private static System.Drawing.Icon BuildTrayIcon()
    {
        var today      = BsDateConverter.Today();
        var monthAbbr  = today.Month is >= 1 and <= 12
            ? MonthAbbrevNp[today.Month - 1] : "?";
        var dayNumeral = NepaliDateFormatter.ToNepaliNumeral(today.Day);

        const int size = 64;
        var bmp = new System.Drawing.Bitmap(size, size);
        using var g = System.Drawing.Graphics.FromImage(bmp);
        g.SmoothingMode     = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAliasGridFit;
        g.Clear(System.Drawing.Color.Transparent);

        var sf = new System.Drawing.StringFormat
        {
            Alignment     = System.Drawing.StringAlignment.Center,
            LineAlignment = System.Drawing.StringAlignment.Center,
            FormatFlags   = System.Drawing.StringFormatFlags.NoWrap,
        };

        var fgColor = ThemeManager.IsLightTheme
            ? System.Drawing.Color.FromArgb(30, 30, 30)
            : System.Drawing.Color.White;

        using var fgBrush   = new System.Drawing.SolidBrush(fgColor);
        using var monthFont = new System.Drawing.Font("Nirmala UI", 13f, System.Drawing.FontStyle.Regular);
        using var dayFont   = new System.Drawing.Font("Nirmala UI",
            dayNumeral.Length == 1 ? 38f : 28f,
            System.Drawing.FontStyle.Bold);

        g.DrawString(monthAbbr, monthFont, fgBrush,
            new System.Drawing.RectangleF(0, 0, size, 22), sf);
        g.DrawString(dayNumeral, dayFont, fgBrush,
            new System.Drawing.RectangleF(0, 18, size, size - 18), sf);

        var icon32 = new System.Drawing.Bitmap(32, 32);
        using (var gs = System.Drawing.Graphics.FromImage(icon32))
        {
            gs.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
            gs.DrawImage(bmp, 0, 0, 32, 32);
        }
        bmp.Dispose();

        var hIcon = icon32.GetHicon();
        icon32.Dispose();
        try
        {
            return (System.Drawing.Icon)System.Drawing.Icon.FromHandle(hIcon).Clone();
        }
        finally
        {
            DestroyIcon(hIcon);
        }
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool DestroyIcon(IntPtr hIcon);

    // -------------------------------------------------------------------------
    // Disposal
    // -------------------------------------------------------------------------

    public void Dispose()
    {
        AppSettings.TraySettingsChanged -= OnTraySettingsChanged;
        ThemeManager.ThemeChanged -= RebuildTrayIcon;
        _midnightTimer?.Stop();
        _notifyIcon.ContextMenuStrip?.Dispose();
        _notifyIcon.Visible = false;
        _notifyIcon.Dispose();
    }
}
