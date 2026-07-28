using System;
using System.Diagnostics;
using System.Net.Http;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Toolkit.Uwp.Notifications;

namespace EverlastimerWidget.Services;

/// <summary>
/// Periodically checks the GitHub Releases API for a newer version of
/// Everlastimer and fires a native Windows toast notification when one
/// is found. The notification launches the main Flutter app so the
/// in-app update overlay takes over from there.
/// </summary>
public sealed class GitHubUpdateService : IDisposable
{
    private const string GitHubApiUrl =
        "https://api.github.com/repos/OoADARSHoO/EVERLASTIMER/releases/latest";

    /// <summary>
    /// Should match the version the Flutter app was built with.
    /// Updated manually when a new release is published.
    /// </summary>
    private const string CurrentVersion = "1.0.4";

    private static readonly HttpClient Http = new();
    private Timer? _timer;
    private bool _disposed;

    /// <summary>
    /// Starts a periodic check. The first check fires immediately;
    /// subsequent checks fire at [interval] intervals.
    /// </summary>
    public void StartPeriodicCheck(TimeSpan interval)
    {
        _timer = new Timer(
            async _ => await CheckForUpdateAsync(),
            null,
            TimeSpan.Zero,
            interval);
    }

    public void Stop() => _timer?.Dispose();

    /// <summary>
    /// Returns true if a newer version was found (and a toast was shown).
    /// </summary>
    public async Task<bool> CheckForUpdateAsync()
    {
        try
        {
            var request = new HttpRequestMessage(HttpMethod.Get, GitHubApiUrl);
            request.Headers.Add("User-Agent", "EverlastimerWidget");

            using var response = await Http.SendAsync(request);
            response.EnsureSuccessStatusCode();

            var json = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            var tagName = root.TryGetProperty("tag_name", out var tagProp)
                ? tagProp.GetString()
                : null;

            if (tagName is null) return false;

            var version = tagName.TrimStart('v');

            if (!IsNewerVersion(version, CurrentVersion)) return false;

            ShowToastNotification(version);
            return true;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"GitHub update check failed: {ex.Message}");
            return false;
        }
    }

    private static void ShowToastNotification(string version)
    {
        var flutterExe = FindFlutterExe();

        var builder = new ToastContentBuilder()
            .AddText("Everlastimer Update Available")
            .AddText($"Version {version} is ready to install.");

        if (flutterExe is not null)
        {
            builder.AddButton(new ToastButton()
                .SetContent("Update Now")
                .SetProtocolActivation(new Uri($"file:///{flutterExe}")));
        }

        builder.AddButton(new ToastButton()
            .SetContent("Dismiss"));

        builder.Show();
    }

    private static string? FindFlutterExe()
    {
        var widgetDir = AppContext.BaseDirectory;

        // Walk up to 8 levels looking for the Flutter app's everlastimer.exe
        var dir = new System.IO.DirectoryInfo(widgetDir);
        for (var i = 0; i < 8 && dir is not null; i++)
        {
            foreach (var folderName in new[] { "app", "Everlastimer" })
            {
                var candidate = System.IO.Path.Combine(
                    dir.FullName,
                    folderName,
                    "build", "windows", "x64", "runner", "Debug",
                    "everlastimer.exe");

                if (System.IO.File.Exists(candidate)) return candidate;
            }

            // Also check production layout: sibling folder
            var prodCandidate = System.IO.Path.Combine(
                dir.FullName, "everlastimer.exe");
            if (System.IO.File.Exists(prodCandidate)) return prodCandidate;

            dir = dir.Parent;
        }

        return null;
    }

    private static bool IsNewerVersion(string remote, string current)
    {
        var remoteParts = remote.Split('.');
        var currentParts = current.Split('.');

        var maxLen = Math.Max(remoteParts.Length, currentParts.Length);
        for (var i = 0; i < maxLen; i++)
        {
            var r = i < remoteParts.Length && int.TryParse(remoteParts[i], out var rv) ? rv : 0;
            var c = i < currentParts.Length && int.TryParse(currentParts[i], out var cv) ? cv : 0;
            if (r > c) return true;
            if (r < c) return false;
        }
        return false;
    }

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;
        _timer?.Dispose();
    }
}
