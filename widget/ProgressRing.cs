using System;
using System.Windows;
using System.Windows.Media;

namespace EverlastimerWidget
{
    public class ProgressRing : FrameworkElement
    {
        public static readonly DependencyProperty FractionProperty =
            DependencyProperty.Register("Fraction", typeof(double), typeof(ProgressRing),
                new FrameworkPropertyMetadata(0.0, FrameworkPropertyMetadataOptions.AffectsRender));

        public double Fraction
        {
            get => (double)GetValue(FractionProperty);
            set => SetValue(FractionProperty, value);
        }

        public static readonly DependencyProperty StartColorProperty =
            DependencyProperty.Register("StartColor", typeof(Color), typeof(ProgressRing),
                new FrameworkPropertyMetadata((Color)ColorConverter.ConvertFromString("#8B5CF6"), FrameworkPropertyMetadataOptions.AffectsRender));

        public static readonly DependencyProperty EndColorProperty =
            DependencyProperty.Register("EndColor", typeof(Color), typeof(ProgressRing),
                new FrameworkPropertyMetadata((Color)ColorConverter.ConvertFromString("#E957FF"), FrameworkPropertyMetadataOptions.AffectsRender));

        public Color StartColor
        {
            get => (Color)GetValue(StartColorProperty);
            set => SetValue(StartColorProperty, value);
        }

        public Color EndColor
        {
            get => (Color)GetValue(EndColorProperty);
            set => SetValue(EndColorProperty, value);
        }

        protected override void OnRender(DrawingContext dc)
        {
            base.OnRender(dc);

            double width = ActualWidth;
            double height = ActualHeight;
            if (width <= 0 || height <= 0) return;

            double strokeThickness = 14.0;
            double center = Math.Min(width, height) / 2.0;
            double radius = center - (strokeThickness * 2.0) - 10;

            Point centerPoint = new Point(width / 2.0, height / 2.0);

            var trackPen = new Pen(new SolidColorBrush((Color)ColorConverter.ConvertFromString("#2A1B44")), strokeThickness);
            dc.DrawEllipse(null, trackPen, centerPoint, radius, radius);

            if (Fraction <= 0) return;
            double fraction = Math.Min(Math.Max(Fraction, 0), 1);

            double startAngle = -90;
            double endAngle = startAngle + (fraction * 360);

            double startRad = startAngle * Math.PI / 180.0;
            double endRad = endAngle * Math.PI / 180.0;

            Point startPoint = new Point(
                centerPoint.X + radius * Math.Cos(startRad),
                centerPoint.Y + radius * Math.Sin(startRad));

            Point endPoint = new Point(
                centerPoint.X + radius * Math.Cos(endRad),
                centerPoint.Y + radius * Math.Sin(endRad));

            bool isLargeArc = fraction > 0.5;

            var segment = new ArcSegment(endPoint, new Size(radius, radius), 0, isLargeArc, SweepDirection.Clockwise, true);
            var figure = new PathFigure(startPoint, new[] { segment }, false);
            var geometry = new PathGeometry(new[] { figure });

            var gradientBrush = new LinearGradientBrush
            {
                StartPoint = new Point(0, 1),
                EndPoint = new Point(1, 0),
                GradientStops = new GradientStopCollection
                {
                    new GradientStop(StartColor, 0.0),
                    new GradientStop(EndColor, 1.0)
                }
            };

            int glowPasses = 4;
            for (int i = glowPasses; i >= 1; i--)
            {
                double glowThickness = strokeThickness + (i * 10);
                double opacity = 0.08 / i;
                var glowBrush = gradientBrush.Clone();
                glowBrush.Opacity = opacity;

                var glowPen = new Pen(glowBrush, glowThickness)
                {
                    StartLineCap = PenLineCap.Round,
                    EndLineCap = PenLineCap.Round
                };
                dc.DrawGeometry(null, glowPen, geometry);
            }

            var progressPen = new Pen(gradientBrush, strokeThickness)
            {
                StartLineCap = PenLineCap.Round,
                EndLineCap = PenLineCap.Round
            };
            dc.DrawGeometry(null, progressPen, geometry);

            double dotRadius = strokeThickness * 0.4;
            dc.DrawEllipse(Brushes.White, null, endPoint, dotRadius, dotRadius);
        }
    }
}
