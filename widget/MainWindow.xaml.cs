using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;
using EverlastimerWidget.Services;

namespace EverlastimerWidget;

public partial class MainWindow : Window
{
    private const double DefaultWidth = 600;
    private const double DefaultHeight = 430;

    private readonly WidgetSettings _settings;
    private readonly DispatcherTimer _timer;
    private readonly GitHubUpdateService _updateService;

    public MainWindow()
    {
        InitializeComponent();

        _settings = WidgetSettings.Load();
        NormalizeWindowPlacement();
        ApplySettingsToWindow();

        _timer = new DispatcherTimer
        {
            Interval = TimeSpan.FromMinutes(1)
        };
        _timer.Tick += (_, _) => Refresh();
        _timer.Start();

        _updateService = new GitHubUpdateService();
        _updateService.StartPeriodicCheck(TimeSpan.FromHours(6));

        Loaded += (_, _) => Refresh();
    }

    private void NormalizeWindowPlacement()
    {
        var workArea = SystemParameters.WorkArea;
        var width = Math.Min(Math.Max(_settings.Width, 360), workArea.Width);
        var height = Math.Min(Math.Max(_settings.Height, 258), workArea.Height);

        var left = double.IsNaN(_settings.Left) || double.IsInfinity(_settings.Left) ? 100 : _settings.Left;
        var top = double.IsNaN(_settings.Top) || double.IsInfinity(_settings.Top) ? 100 : _settings.Top;

        var isOffScreen = left + width < workArea.Left - 20
            || left > workArea.Right + 20
            || top + height < workArea.Top - 20
            || top > workArea.Bottom + 20;

        if (isOffScreen || left < workArea.Left || left > workArea.Right - width || top > workArea.Bottom - height)
        {
            left = workArea.Left + Math.Max(0, (workArea.Width - width) / 2);
            top = workArea.Top + Math.Max(0, (workArea.Height - height) / 2);
        }

        _settings.Left = left;
        _settings.Top = top;
        _settings.Width = width;
        _settings.Height = height;
        _settings.Save();
    }

    private void ApplySettingsToWindow()
    {
        Left = _settings.Left;
        Top = _settings.Top;
        Width = _settings.Width > 0 ? _settings.Width : DefaultWidth;
        Height = _settings.Height > 0 ? _settings.Height : DefaultHeight;
        Topmost = _settings.AlwaysOnTop;

        LockMenuItem.IsChecked = _settings.Locked;
        AlwaysOnTopMenuItem.IsChecked = _settings.AlwaysOnTop;
        PinButton.Content = _settings.Locked ? "\uD83D\uDD12" : "\uD83D\uDCCC";
    }

    private void Refresh()
    {
        var yp = YearProgress.FromNow();

        PercentRun.Text = yp.PercentComplete.ToString("0.0");
        DaysCompletedText.Text = yp.DaysCompleted.ToString();
        DaysRemainingText.Text = yp.DaysRemaining.ToString();

        UpdatedText.Text = $"Updated {DateTime.Now:h:mm tt}";

        RingControl.Fraction = yp.Fraction;

        UpdateCalendar();
    }

    private void UpdateCalendar()
    {
        var today = DateTime.Today;
        MonthYearText.Text = today.ToString("MMMM yyyy");

        var firstDay = new DateTime(today.Year, today.Month, 1);
        var daysInMonth = DateTime.DaysInMonth(today.Year, today.Month);
        var startOffset = ((int)firstDay.DayOfWeek + 6) % 7;

        var accentColor = (Color)ColorConverter.ConvertFromString(_settings.AccentColorHex);
        var textSecondary = (Color)ColorConverter.ConvertFromString("#E6FFFFFF");

        CalendarDaysGrid.Children.Clear();

        var dayCounter = 1;
        for (var row = 0; row < 6; row++)
        {
            for (var col = 0; col < 7; col++)
            {
                var cellIndex = row * 7 + col;
                var container = new Grid();

                if (cellIndex >= startOffset && dayCounter <= daysInMonth)
                {
                    var isToday = dayCounter == today.Day;

                    if (isToday)
                    {
                        container.Children.Add(new Border
                        {
                            Width = 22,
                            Height = 22,
                            CornerRadius = new CornerRadius(11),
                            Background = new SolidColorBrush(accentColor),
                            HorizontalAlignment = HorizontalAlignment.Center,
                            VerticalAlignment = VerticalAlignment.Center,
                        });
                    }

                    container.Children.Add(new TextBlock
                    {
                        Text = dayCounter.ToString(),
                        FontSize = 11,
                        FontWeight = isToday ? FontWeights.Bold : FontWeights.Normal,
                        Foreground = new SolidColorBrush(isToday ? Colors.White : textSecondary),
                        HorizontalAlignment = HorizontalAlignment.Center,
                        VerticalAlignment = VerticalAlignment.Center,
                    });

                    dayCounter++;
                }

                Grid.SetRow(container, row);
                Grid.SetColumn(container, col);
                CalendarDaysGrid.Children.Add(container);
            }
        }
    }

    private void RootBorder_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (_settings.Locked) return;
        if (e.OriginalSource is Button) return;

        if (e.ClickCount == 1)
        {
            DragMove();
            PersistGeometry();
        }
    }

    private void PersistGeometry()
    {
        _settings.Left = Left;
        _settings.Top = Top;
        _settings.Width = Width;
        _settings.Height = Height;
        _settings.Save();
    }

    private void Window_SizeChanged(object sender, SizeChangedEventArgs e)
    {
        PersistGeometry();
    }

    private void ResizeLeft_DragDelta(object sender, DragDeltaEventArgs e)
    {
        if (_settings.Locked) return;
        double newWidth = Width - e.HorizontalChange;
        if (newWidth >= MinWidth)
        {
            Left += e.HorizontalChange;
            Width = newWidth;
        }
    }

    private void ResizeRight_DragDelta(object sender, DragDeltaEventArgs e)
    {
        if (_settings.Locked) return;
        double newWidth = Width + e.HorizontalChange;
        if (newWidth >= MinWidth)
        {
            Width = newWidth;
        }
    }

    private void ResizeTop_DragDelta(object sender, DragDeltaEventArgs e)
    {
        if (_settings.Locked) return;
        double newHeight = Height - e.VerticalChange;
        if (newHeight >= MinHeight)
        {
            Top += e.VerticalChange;
            Height = newHeight;
        }
    }

    private void ResizeBottom_DragDelta(object sender, DragDeltaEventArgs e)
    {
        if (_settings.Locked) return;
        double newHeight = Height + e.VerticalChange;
        if (newHeight >= MinHeight)
        {
            Height = newHeight;
        }
    }

    private void PinButton_Click(object sender, RoutedEventArgs e)
    {
        _settings.Locked = !_settings.Locked;
        LockMenuItem.IsChecked = _settings.Locked;
        PinButton.Content = _settings.Locked ? "\uD83D\uDD12" : "\uD83D\uDCCC";
        _settings.Save();
    }

    private void MenuButton_Click(object sender, RoutedEventArgs e)
    {
        OptionsMenu.IsOpen = true;
    }

    private void LockMenuItem_Click(object sender, RoutedEventArgs e)
    {
        _settings.Locked = LockMenuItem.IsChecked;
        PinButton.Content = _settings.Locked ? "\uD83D\uDD12" : "\uD83D\uDCCC";
        _settings.Save();
    }

    private void AlwaysOnTopMenuItem_Click(object sender, RoutedEventArgs e)
    {
        _settings.AlwaysOnTop = AlwaysOnTopMenuItem.IsChecked;
        Topmost = _settings.AlwaysOnTop;
        _settings.Save();
    }

    private void ResetMenuItem_Click(object sender, RoutedEventArgs e)
    {
        Left = 100;
        Top = 100;
        Width = DefaultWidth;
        Height = DefaultHeight;
        PersistGeometry();
    }

    private void CloseMenuItem_Click(object sender, RoutedEventArgs e)
    {
        _updateService.Dispose();
        Close();
    }
}
