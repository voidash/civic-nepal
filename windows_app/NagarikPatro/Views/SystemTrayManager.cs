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
/// Right-click: context menu.
/// The tray app no longer renders any calendar UI — Flutter owns the popup.
/// </summary>
public sealed class SystemTrayManager : IDisposable
{
    private readonly WinForms.NotifyIcon _notifyIcon;
    private DispatcherTimer? _midnightTimer;

    // Context menu items that need live updates
    private WinForms.ToolStripMenuItem? _todayHeader;
    private WinForms.ToolStripMenuItem? _todayAdHeader;
    private WinForms.ToolStripMenuItem? _nepaliLangItem;
    private WinForms.ToolStripMenuItem? _englishLangItem;
    private WinForms.ToolStripMenuItem? _showYearItem;
    private WinForms.ToolStripMenuItem? _launchAtLoginItem;

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
    // Context menu
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

        // Language submenu
        var langMenu = new WinForms.ToolStripMenuItem("Menu Bar Language");

        _nepaliLangItem = new WinForms.ToolStripMenuItem("नेपाली (Nepali)")
            { Checked = AppSettings.MenuBarLanguage == AppSettings.Language.Nepali };
        _nepaliLangItem.Click += (_, _) => SetLanguage(AppSettings.Language.Nepali);

        _englishLangItem = new WinForms.ToolStripMenuItem("English")
            { Checked = AppSettings.MenuBarLanguage == AppSettings.Language.English };
        _englishLangItem.Click += (_, _) => SetLanguage(AppSettings.Language.English);

        langMenu.DropDownItems.Add(_nepaliLangItem);
        langMenu.DropDownItems.Add(_englishLangItem);
        menu.Items.Add(langMenu);

        // Show year toggle
        _showYearItem = new WinForms.ToolStripMenuItem("Show Year in Tooltip")
            { Checked = AppSettings.ShowYearInTooltip };
        _showYearItem.Click += (_, _) => ToggleShowYear();
        menu.Items.Add(_showYearItem);

        // Launch at login
        _launchAtLoginItem = new WinForms.ToolStripMenuItem("Launch at Login")
            { Checked = IsLaunchAtLoginEnabled() };
        _launchAtLoginItem.Click += (_, _) => ToggleLaunchAtLogin();
        menu.Items.Add(_launchAtLoginItem);

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

    private void SetLanguage(AppSettings.Language lang)
    {
        AppSettings.MenuBarLanguage  = lang;
        _nepaliLangItem!.Checked     = lang == AppSettings.Language.Nepali;
        _englishLangItem!.Checked    = lang == AppSettings.Language.English;
        UpdateTooltip();
    }

    private void ToggleShowYear()
    {
        AppSettings.ShowYearInTooltip = !AppSettings.ShowYearInTooltip;
        _showYearItem!.Checked        = AppSettings.ShowYearInTooltip;
        UpdateTooltip();
    }

    private void UpdateTooltip() => _notifyIcon.Text = GetTooltipText();

    private static string GetTooltipText()
    {
        var today    = BsDateConverter.Today();
        var lang     = AppSettings.MenuBarLanguage;
        var showYear = AppSettings.ShowYearInTooltip;

        return lang switch
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
    // Launch at login
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
            Debug.WriteLine($"Registry read error: {ex.Message}");
            return false;
        }
    }

    private void ToggleLaunchAtLogin()
    {
        bool enable = !IsLaunchAtLoginEnabled();
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(
                @"SOFTWARE\Microsoft\Windows\CurrentVersion\Run", writable: true);
            if (key == null) return;

            if (enable)
            {
                var exePath = Process.GetCurrentProcess().MainModule?.FileName;
                if (exePath != null) key.SetValue("NagarikPatro", exePath);
            }
            else
            {
                key.DeleteValue("NagarikPatro", throwOnMissingValue: false);
            }

            if (_launchAtLoginItem != null) _launchAtLoginItem.Checked = enable;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Registry write error: {ex.Message}");
        }
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
        ThemeManager.ThemeChanged -= RebuildTrayIcon;
        _midnightTimer?.Stop();
        _notifyIcon.ContextMenuStrip?.Dispose();
        _notifyIcon.Visible = false;
        _notifyIcon.Dispose();
    }
}
