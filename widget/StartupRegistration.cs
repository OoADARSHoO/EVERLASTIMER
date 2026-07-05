using System;
using Microsoft.Win32;

namespace EverlastimerWidget;

/// <summary>
/// Reads/writes the per-user "Run" registry key that controls whether
/// EverlastimerWidget.exe launches automatically when Windows starts.
///
/// This is the entire "connection" between the standalone widget and the
/// Flutter app's Settings page: Everlastimer doesn't talk to this process
/// at runtime at all — it just flips this same registry value, using the
/// widget's own exe path. No IPC, no shared process, no dependency.
/// </summary>
public static class StartupRegistration
{
    private const string RunKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string ValueName = "EverlastimerWidget";

    public static bool IsRegistered()
    {
        using var key = Registry.CurrentUser.OpenSubKey(RunKeyPath, writable: false);
        return key?.GetValue(ValueName) != null;
    }

    public static void Enable(string exePath)
    {
        using var key = Registry.CurrentUser.OpenSubKey(RunKeyPath, writable: true)
            ?? Registry.CurrentUser.CreateSubKey(RunKeyPath);
        // Quote the path in case it contains spaces (e.g. "Program Files").
        key.SetValue(ValueName, $"\"{exePath}\"");
    }

    public static void Disable()
    {
        using var key = Registry.CurrentUser.OpenSubKey(RunKeyPath, writable: true);
        key?.DeleteValue(ValueName, throwOnMissingValue: false);
    }
}