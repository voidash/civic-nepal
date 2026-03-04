using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Threading;
using Microsoft.Win32;
using NagarikPatro.Core;
using WinForms = System.Windows.Forms;

namespace NagarikPatro.Views;

/// <summary>
/// Manages the system tray NotifyIcon and popup window lifecycle.
/// Left-click: toggle popup. Right-click: context menu with settings.
/// </summary>
public sealed class SystemTrayManager : IDisposable
{
    private readonly WinForms.NotifyIcon _notifyIcon;
    private CalendarPopup? _popup;
    private DispatcherTimer? _midnightTimer;

    // Context menu items that need live updates
    private WinForms.ToolStripMenuItem? _todayHeader;
    private WinForms.ToolStripMenuItem? _todayAdHeader;
    private WinForms.ToolStripMenuItem? _nepaliLangItem;
    private WinForms.ToolStripMenuItem? _englishLangItem;
    private WinForms.ToolStripMenuItem? _showYearItem;
    private WinForms.ToolStripMenuItem? _launchAtLoginItem;

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

        _notifyIcon.MouseClick       += OnTrayClick;
        _notifyIcon.ContextMenuStrip  = BuildContextMenu();

        ScheduleMidnightRefresh();
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
        menu.Items.Add("Open Nagarik Patro", null, (_, _) => OpenFlutterApp());
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
        var today   = BsDateConverter.Today();
        var lang    = AppSettings.MenuBarLanguage;
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
    // Popup
    // -------------------------------------------------------------------------

    private void OnTrayClick(object? sender, WinForms.MouseEventArgs e)
    {
        if (e.Button != WinForms.MouseButtons.Left) return;
        TogglePopup();
    }

    private void TogglePopup()
    {
        if (_popup != null && _popup.IsVisible)
        {
            _popup.Hide();
            return;
        }

        _popup ??= new CalendarPopup(OpenFlutterApp);
        PositionPopup();
        _popup.Show();
        _popup.Activate();
    }

    private void PositionPopup()
    {
        if (_popup == null) return;
        var workArea = SystemParameters.WorkArea;
        _popup.Left = workArea.Right  - _popup.Width  - 8;
        _popup.Top  = workArea.Bottom - _popup.Height - 8;
    }

    // -------------------------------------------------------------------------
    // Midnight refresh
    // -------------------------------------------------------------------------

    private void ScheduleMidnightRefresh()
    {
        _midnightTimer?.Stop();

        var now         = DateTimeOffset.UtcNow;
        var nepalNow    = now.ToOffset(BsDateConverter.NepalUtcOffset);
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
            _popup?.RefreshToday();
            ScheduleMidnightRefresh();
        };
        _midnightTimer.Start();
    }

    // -------------------------------------------------------------------------
    // Open Flutter app
    // -------------------------------------------------------------------------

    private const string FlutterExeName = "nagarik_calendar.exe";

    private void OpenFlutterApp()
    {
        var path = FindFlutterApp();
        if (path != null)
        {
            try
            {
                System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
                {
                    FileName       = path,
                    UseShellExecute = true,
                });
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to launch Nagarik Patro: {ex.Message}");
                _notifyIcon.ShowBalloonTip(3000, "Nagarik Patro",
                    "Failed to launch the app.", WinForms.ToolTipIcon.Error);
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
        var localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        var programFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
        var exeDir       = AppContext.BaseDirectory;

        string[] candidates =
        [
            Path.Combine(localAppData, "NagarikPatro",    FlutterExeName),
            Path.Combine(localAppData, "nagarik_calendar", FlutterExeName),
            Path.Combine(programFiles, "NagarikPatro",    FlutterExeName),
            Path.Combine(exeDir,                          FlutterExeName),
        ];

        return Array.Find(candidates, File.Exists);
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
            System.Diagnostics.Debug.WriteLine($"Registry read error: {ex.Message}");
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
                var exePath = System.Diagnostics.Process.GetCurrentProcess().MainModule?.FileName;
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
            System.Diagnostics.Debug.WriteLine($"Registry write error: {ex.Message}");
        }
    }

    // -------------------------------------------------------------------------
    // Tray icon — calendar tile showing current BS date
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

        var bmp = new System.Drawing.Bitmap(32, 32);
        using var g = System.Drawing.Graphics.FromImage(bmp);
        g.SmoothingMode      = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
        g.TextRenderingHint  = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;
        g.Clear(System.Drawing.Color.Transparent);

        // White rounded-rect body (full tile)
        using var bodyBrush = new System.Drawing.SolidBrush(System.Drawing.Color.White);
        FillRoundedRect(g, bodyBrush, 0, 0, 32, 32, 3f);

        // Blue header strip (top 10 px, rounded top corners only)
        using var headerBrush = new System.Drawing.SolidBrush(
            System.Drawing.Color.FromArgb(0, 120, 212));
        FillTopRoundedRect(g, headerBrush, 0, 0, 32, 10, 3f);

        var sf = new System.Drawing.StringFormat
        {
            Alignment     = System.Drawing.StringAlignment.Center,
            LineAlignment = System.Drawing.StringAlignment.Center,
        };

        // Month abbreviation in header
        using var monthFont  = new System.Drawing.Font("Nirmala UI", 5.5f, System.Drawing.FontStyle.Bold);
        using var whiteBrush = new System.Drawing.SolidBrush(System.Drawing.Color.White);
        g.DrawString(monthAbbr, monthFont, whiteBrush,
            new System.Drawing.RectangleF(0, 0, 32, 10), sf);

        // Day numeral in body
        using var dayFont  = new System.Drawing.Font("Nirmala UI", 13f, System.Drawing.FontStyle.Bold);
        using var darkBrush = new System.Drawing.SolidBrush(System.Drawing.Color.FromArgb(30, 30, 30));
        g.DrawString(dayNumeral, dayFont, darkBrush,
            new System.Drawing.RectangleF(0, 9, 32, 23), sf);

        var hIcon = bmp.GetHicon();
        bmp.Dispose();
        try
        {
            return (System.Drawing.Icon)System.Drawing.Icon.FromHandle(hIcon).Clone();
        }
        finally
        {
            DestroyIcon(hIcon);
        }
    }

    private static void FillRoundedRect(System.Drawing.Graphics g,
        System.Drawing.Brush brush, float x, float y, float w, float h, float r)
    {
        using var path = new System.Drawing.Drawing2D.GraphicsPath();
        path.AddArc(x,           y,           r * 2, r * 2, 180, 90);
        path.AddArc(x + w - r*2, y,           r * 2, r * 2, 270, 90);
        path.AddArc(x + w - r*2, y + h - r*2, r * 2, r * 2,   0, 90);
        path.AddArc(x,           y + h - r*2, r * 2, r * 2,  90, 90);
        path.CloseFigure();
        g.FillPath(brush, path);
    }

    private static void FillTopRoundedRect(System.Drawing.Graphics g,
        System.Drawing.Brush brush, float x, float y, float w, float h, float r)
    {
        using var path = new System.Drawing.Drawing2D.GraphicsPath();
        path.AddArc(x,           y, r * 2, r * 2, 180, 90);   // top-left arc
        path.AddArc(x + w - r*2, y, r * 2, r * 2, 270, 90);   // top-right arc
        path.AddLine(x + w, y + h, x, y + h);                  // flat bottom
        path.CloseFigure();
        g.FillPath(brush, path);
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool DestroyIcon(IntPtr hIcon);

    // -------------------------------------------------------------------------
    // Disposal
    // -------------------------------------------------------------------------

    public void Dispose()
    {
        _midnightTimer?.Stop();
        GoogleCalendarCache.Instance.Dispose();
        _notifyIcon.ContextMenuStrip?.Dispose();
        _notifyIcon.Visible = false;
        _notifyIcon.Dispose();
        _popup?.Close();
    }
}
