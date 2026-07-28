using System;
using System.IO;
using System.Text.Json;

namespace EverlastimerWidget;

public sealed class WidgetSettings
{
    public double Left { get; set; } = 100;
    public double Top { get; set; } = 100;
    public double Width { get; set; } = 600;
    public double Height { get; set; } = 430;
    public bool Locked { get; set; } = false;
    public bool AlwaysOnTop { get; set; } = true;
    public string AccentColorHex { get; set; } = "#8B5CF6";
    public string AccentPartnerHex { get; set; } = "#E957FF";

    private static string SettingsDir =>
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "EverlastimerWidget");

    private static string SettingsPath => Path.Combine(SettingsDir, "widget-settings.json");

    public static WidgetSettings Load()
    {
        try
        {
            if (File.Exists(SettingsPath))
            {
                var json = File.ReadAllText(SettingsPath);
                var loaded = JsonSerializer.Deserialize<WidgetSettings>(json);
                if (loaded != null) return loaded;
            }
        }
        catch
        {
            // Corrupt or unreadable settings file — fall back to defaults
            // rather than crash the widget on startup.
        }

        return new WidgetSettings();
    }

    public void Save()
    {
        try
        {
            Directory.CreateDirectory(SettingsDir);
            var json = JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(SettingsPath, json);
        }
        catch
        {
            // Best-effort persistence — a failed save shouldn't crash the
            // widget, it just means position resets next launch.
        }
    }
}