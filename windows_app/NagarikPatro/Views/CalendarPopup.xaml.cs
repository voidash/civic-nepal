using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using NagarikPatro.Core;
using NagarikPatro.Models;
using NagarikPatro.ViewModels;

namespace NagarikPatro.Views;

public partial class CalendarPopup : Window
{
    private CalendarViewModel ViewModel => (CalendarViewModel)DataContext;

    public CalendarPopup()
    {
        InitializeComponent();
        Deactivated += (_, _) => Hide();
        ViewModel.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(CalendarViewModel.CalendarDays))
                RenderCalendar();
        };
        RenderCalendar();
    }

    public void RefreshToday()
    {
        ViewModel.RefreshToday();
    }

    private void PreviousMonth_Click(object sender, RoutedEventArgs e) => ViewModel.PreviousMonth();
    private void NextMonth_Click(object sender, RoutedEventArgs e) => ViewModel.NextMonth();

    private void OpenApp_Click(object sender, RoutedEventArgs e)
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

    private void RenderCalendar()
    {
        CalendarGrid.Children.Clear();

        int offset = ViewModel.FirstDayOffset;
        var days = ViewModel.CalendarDays;

        // Empty cells before first day
        for (int i = 0; i < offset; i++)
        {
            CalendarGrid.Children.Add(CreateEmptyCell());
        }

        // Day cells
        foreach (var day in days)
        {
            CalendarGrid.Children.Add(CreateDayCell(day));
        }

        // Fill remaining cells to complete the grid
        int totalCells = offset + days.Count;
        int remainder = totalCells % 7;
        if (remainder != 0)
        {
            for (int i = 0; i < 7 - remainder; i++)
                CalendarGrid.Children.Add(CreateEmptyCell());
        }
    }

    private static Border CreateEmptyCell()
    {
        return new Border
        {
            Height = 36,
            BorderBrush = new SolidColorBrush(Color.FromArgb(30, 128, 128, 128)),
            BorderThickness = new Thickness(0.5),
        };
    }

    private Border CreateDayCell(CalendarDay day)
    {
        Color bgColor;
        Brush textBrush;

        if (day.IsToday)
        {
            bgColor = Color.FromRgb(59, 130, 246); // Blue
            textBrush = Brushes.White;
        }
        else if (day.IsSaturday || day.IsHoliday)
        {
            bgColor = Color.FromArgb(15, 239, 68, 68); // Light red
            textBrush = new SolidColorBrush(Color.FromRgb(185, 28, 28));
        }
        else
        {
            bgColor = Colors.Transparent;
            textBrush = SystemColors.WindowTextBrush;
        }

        var textBlock = new TextBlock
        {
            Text = NepaliDateFormatter.ToNepaliNumeral(day.Day),
            FontSize = 14,
            FontWeight = day.IsToday ? FontWeights.Bold : FontWeights.Medium,
            Foreground = textBrush,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            FontFamily = new FontFamily("Nirmala UI"),
        };

        var grid = new Grid();
        grid.Children.Add(textBlock);

        // Event/auspicious dots
        if (!day.IsToday && (day.HasEvents || day.HasAuspicious))
        {
            var dotPanel = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Bottom,
                Margin = new Thickness(0, 0, 0, 3),
            };

            if (day.HasEvents)
            {
                dotPanel.Children.Add(new System.Windows.Shapes.Ellipse
                {
                    Width = 4, Height = 4,
                    Fill = day.IsHoliday
                        ? new SolidColorBrush(Colors.Red)
                        : new SolidColorBrush(Colors.Orange),
                    Margin = new Thickness(1, 0, 1, 0),
                });
            }

            if (day.HasAuspicious)
            {
                dotPanel.Children.Add(new System.Windows.Shapes.Ellipse
                {
                    Width = 4, Height = 4,
                    Fill = new SolidColorBrush(Colors.Green),
                    Margin = new Thickness(1, 0, 1, 0),
                });
            }

            grid.Children.Add(dotPanel);
        }

        var border = new Border
        {
            Height = 36,
            Background = new SolidColorBrush(bgColor),
            BorderBrush = day.IsToday
                ? new SolidColorBrush(Color.FromRgb(59, 130, 246))
                : new SolidColorBrush(Color.FromArgb(30, 128, 128, 128)),
            BorderThickness = new Thickness(day.IsToday ? 1.5 : 0.5),
            Child = grid,
            Cursor = Cursors.Hand,
        };

        int dayNum = day.Day;
        border.MouseLeftButtonDown += (_, _) => ViewModel.SelectDay(dayNum);

        return border;
    }
}
