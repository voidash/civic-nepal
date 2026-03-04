using System.Windows;
using System.Windows.Threading;
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

    // Today header items — updated at midnight to avoid stale display
    private WinForms.ToolStripMenuItem? _todayHeader;
    private WinForms.ToolStripMenuItem? _todayAdHeader;

    // Settings menu items (need references for checked state updates)
    private WinForms.ToolStripMenuItem? _nepaliLangItem;
    private WinForms.ToolStripMenuItem? _englishLangItem;
    private WinForms.ToolStripMenuItem? _showYearItem;

    public SystemTrayManager()
    {
        _notifyIcon = new WinForms.NotifyIcon
        {
            Icon = System.Drawing.SystemIcons.Application,
            Visible = true,
            Text = GetTooltipText(),
        };

        _notifyIcon.MouseClick += OnTrayClick;
        _notifyIcon.ContextMenuStrip = BuildContextMenu();

        ScheduleMidnightRefresh();
    }

    private WinForms.ContextMenuStrip BuildContextMenu()
    {
        var menu = new WinForms.ContextMenuStrip();

        // Today's date (non-interactive header)
        var today = BsDateConverter.Today();
        _todayHeader = new WinForms.ToolStripMenuItem($"आज: {NepaliDateFormatter.FormatNp(today)}")
        {
            Enabled = false,
        };
        menu.Items.Add(_todayHeader);

        _todayAdHeader = new WinForms.ToolStripMenuItem(NepaliDateFormatter.FormatAdDate(BsDateConverter.BsToAd(today)))
        {
            Enabled = false,
        };
        menu.Items.Add(_todayAdHeader);

        menu.Items.Add(new WinForms.ToolStripSeparator());

        // Language submenu
        var langMenu = new WinForms.ToolStripMenuItem("Menu Bar Language");

        _nepaliLangItem = new WinForms.ToolStripMenuItem("नेपाली (Nepali)")
        {
            Checked = AppSettings.MenuBarLanguage == AppSettings.Language.Nepali,
        };
        _nepaliLangItem.Click += (_, _) => SetLanguage(AppSettings.Language.Nepali);

        _englishLangItem = new WinForms.ToolStripMenuItem("English")
        {
            Checked = AppSettings.MenuBarLanguage == AppSettings.Language.English,
        };
        _englishLangItem.Click += (_, _) => SetLanguage(AppSettings.Language.English);

        langMenu.DropDownItems.Add(_nepaliLangItem);
        langMenu.DropDownItems.Add(_englishLangItem);
        menu.Items.Add(langMenu);

        // Show year toggle
        _showYearItem = new WinForms.ToolStripMenuItem("Show Year in Tooltip")
        {
            Checked = AppSettings.ShowYearInTooltip,
        };
        _showYearItem.Click += (_, _) => ToggleShowYear();
        menu.Items.Add(_showYearItem);

        menu.Items.Add(new WinForms.ToolStripSeparator());

        // Open Flutter app
        menu.Items.Add("Open Nagarik Patro", null, (_, _) => OpenFlutterApp());

        menu.Items.Add(new WinForms.ToolStripSeparator());

        // Quit
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
        if (_todayHeader != null)
            _todayHeader.Text = $"आज: {NepaliDateFormatter.FormatNp(today)}";
        if (_todayAdHeader != null)
            _todayAdHeader.Text = NepaliDateFormatter.FormatAdDate(BsDateConverter.BsToAd(today));
    }

    private void SetLanguage(AppSettings.Language lang)
    {
        AppSettings.MenuBarLanguage = lang;
        _nepaliLangItem!.Checked = lang == AppSettings.Language.Nepali;
        _englishLangItem!.Checked = lang == AppSettings.Language.English;
        UpdateTooltip();
    }

    private void ToggleShowYear()
    {
        AppSettings.ShowYearInTooltip = !AppSettings.ShowYearInTooltip;
        _showYearItem!.Checked = AppSettings.ShowYearInTooltip;
        UpdateTooltip();
    }

    private void UpdateTooltip()
    {
        _notifyIcon.Text = GetTooltipText();
    }

    private static string GetTooltipText()
    {
        var today = BsDateConverter.Today();
        var lang = AppSettings.MenuBarLanguage;
        var showYear = AppSettings.ShowYearInTooltip;

        return lang switch
        {
            AppSettings.Language.English =>
                showYear ? $"{NepaliDateFormatter.MonthNameEn(today.Month)} {today.Day}, {today.Year}"
                         : $"{NepaliDateFormatter.MonthNameEn(today.Month)} {today.Day}",
            _ =>
                showYear ? $"{NepaliDateFormatter.MonthNameNp(today.Month)} {NepaliDateFormatter.ToNepaliNumeral(today.Day)}, {NepaliDateFormatter.ToNepaliNumeral(today.Year)}"
                         : NepaliDateFormatter.TrayTooltip(today),
        };
    }

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

        _popup ??= new CalendarPopup();
        PositionPopup();
        _popup.Show();
        _popup.Activate();
    }

    private void PositionPopup()
    {
        if (_popup == null) return;

        var workArea = SystemParameters.WorkArea;
        _popup.Left = workArea.Right - _popup.Width - 8;
        _popup.Top = workArea.Bottom - _popup.Height - 8;
    }

    private void ScheduleMidnightRefresh()
    {
        _midnightTimer?.Stop();

        var now = DateTimeOffset.UtcNow;
        var nepalNow = now.ToOffset(BsDateConverter.NepalUtcOffset);
        var nepalMidnight = new DateTimeOffset(
            nepalNow.Year, nepalNow.Month, nepalNow.Day, 0, 0, 0,
            BsDateConverter.NepalUtcOffset
        ).AddDays(1);

        var interval = nepalMidnight - now;
        if (interval <= TimeSpan.Zero)
            interval = TimeSpan.FromMinutes(1);

        _midnightTimer = new DispatcherTimer { Interval = interval };
        _midnightTimer.Tick += (_, _) =>
        {
            UpdateTooltip();
            UpdateContextMenuDate();
            _popup?.RefreshToday();
            ScheduleMidnightRefresh();
        };
        _midnightTimer.Start();
    }

    private static void OpenFlutterApp()
    {
        try
        {
            var appName = "nepal_civic.exe";
            var localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            var possiblePath = Path.Combine(localAppData, "NagarikPatro", appName);

            if (File.Exists(possiblePath))
            {
                System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
                {
                    FileName = possiblePath,
                    UseShellExecute = true,
                });
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to open Flutter app: {ex.Message}");
        }
    }

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
