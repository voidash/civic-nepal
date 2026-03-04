using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;
using NagarikPatro.Core;
using NagarikPatro.Models;
using NagarikPatro.ViewModels;

namespace NagarikPatro.Views;

public partial class CalendarPopup : Window
{
    private CalendarViewModel ViewModel => (CalendarViewModel)DataContext;
    private DispatcherTimer? _clockTimer;
    private readonly Action _openApp;

    public CalendarPopup(Action openApp)
    {
        _openApp = openApp;
        InitializeComponent();

        Deactivated += (_, _) => Hide();
        Closed      += (_, _) =>
        {
            _clockTimer?.Stop();
            ThemeManager.ThemeChanged -= OnThemeChanged;
        };

        ViewModel.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName is nameof(CalendarViewModel.CalendarDays)
                                or nameof(CalendarViewModel.SelectedDay))
                RenderCalendar();
        };

        ThemeManager.ThemeChanged += OnThemeChanged;

        UpdateClock();
        UpdateDateBlocks();
        RenderCalendar();

        _clockTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(1) };
        _clockTimer.Tick += (_, _) => UpdateClock();
        _clockTimer.Start();
    }

    public void RefreshToday()
    {
        ViewModel.RefreshToday();
        UpdateDateBlocks();
    }

    private void OnThemeChanged() => RenderCalendar();

    private void UpdateClock()
    {
        // Use the machine's local time (not Nepal time)
        ClockTextBlock.Text = DateTime.Now.ToString("h:mm:ss tt");
    }

    private void UpdateDateBlocks()
    {
        var today   = BsDateConverter.Today();
        var todayAd = BsDateConverter.BsToAd(today);
        AdDateBlock.Text = todayAd.ToString("dddd, MMMM d, yyyy");
        BsDateBlock.Text = NepaliDateFormatter.FormatNp(today);
    }

    private void PreviousMonth_Click(object sender, RoutedEventArgs e) => ViewModel.PreviousMonth();
    private void NextMonth_Click(object sender, RoutedEventArgs e)     => ViewModel.NextMonth();

    private void OpenApp_Click(object sender, RoutedEventArgs e) => _openApp();

    private void RenderCalendar()
    {
        CalendarGrid.Children.Clear();

        int offset = ViewModel.FirstDayOffset;
        var days   = ViewModel.CalendarDays;

        for (int i = 0; i < offset; i++)
            CalendarGrid.Children.Add(CreateEmptyCell());

        foreach (var day in days)
            CalendarGrid.Children.Add(CreateDayCell(day));

        int totalCells = offset + days.Count;
        int remainder  = totalCells % 7;
        if (remainder != 0)
        {
            for (int i = 0; i < 7 - remainder; i++)
                CalendarGrid.Children.Add(CreateEmptyCell());
        }
    }

    private static FrameworkElement CreateEmptyCell() => new Border { Height = 34 };

    private Border CreateDayCell(CalendarDay day)
    {
        bool isSelected = ViewModel.SelectedDay == day.Day;

        Brush bgBrush;
        Brush textBrush;

        if (day.IsToday)
        {
            bgBrush   = new SolidColorBrush(Color.FromRgb(0, 120, 212));   // #0078D4 always
            textBrush = Brushes.White;
        }
        else if (isSelected)
        {
            var selColor = (Color)Application.Current.FindResource("DaySelectedOverlayColor");
            bgBrush   = new SolidColorBrush(selColor);
            textBrush = (Brush)Application.Current.FindResource("DayNormalTextBrush");
        }
        else if (day.IsSaturday || day.IsHoliday)
        {
            bgBrush   = Brushes.Transparent;
            textBrush = (Brush)Application.Current.FindResource("DaySatHolidayBrush");
        }
        else
        {
            bgBrush   = Brushes.Transparent;
            textBrush = (Brush)Application.Current.FindResource("DayNormalTextBrush");
        }

        var textBlock = new TextBlock
        {
            Text                = NepaliDateFormatter.ToNepaliNumeral(day.Day),
            FontSize            = 13,
            FontWeight          = day.IsToday ? FontWeights.SemiBold : FontWeights.Normal,
            Foreground          = textBrush,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment   = VerticalAlignment.Center,
            FontFamily          = new FontFamily("Nirmala UI"),
        };

        var grid = new Grid();
        grid.Children.Add(textBlock);

        if (!day.IsToday && (day.HasEvents || day.HasAuspicious))
        {
            var dotPanel = new StackPanel
            {
                Orientation         = Orientation.Horizontal,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment   = VerticalAlignment.Bottom,
                Margin              = new Thickness(0, 0, 0, 2),
            };

            if (day.HasEvents)
                dotPanel.Children.Add(MakeDot(day.IsHoliday
                    ? (Brush)Application.Current.FindResource("DaySatHolidayBrush")
                    : new SolidColorBrush(Colors.Orange)));

            if (day.HasAuspicious)
                dotPanel.Children.Add(MakeDot(new SolidColorBrush(Color.FromRgb(74, 222, 128))));

            grid.Children.Add(dotPanel);
        }

        // Capture hover brush at cell-creation time so MouseLeave can restore it
        var hoverBg = (Color)Application.Current.FindResource("DayHoverOverlayColor");

        var border = new Border
        {
            Height       = 34,
            Background   = bgBrush,
            CornerRadius = new CornerRadius(4),
            Child        = grid,
            Cursor       = Cursors.Hand,
        };

        if (!day.IsToday && !isSelected)
        {
            border.MouseEnter += (_, _) =>
                border.Background = new SolidColorBrush(hoverBg);
            border.MouseLeave += (_, _) =>
                border.Background = bgBrush;
        }

        int dayNum = day.Day;
        border.MouseLeftButtonDown += (_, _) => ViewModel.SelectDay(dayNum);

        return border;
    }

    private static System.Windows.Shapes.Ellipse MakeDot(Brush fill) =>
        new()
        {
            Width  = 3, Height = 3,
            Fill   = fill,
            Margin = new Thickness(1, 0, 1, 0),
        };
}
