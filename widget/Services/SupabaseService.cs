using System.Diagnostics;
using Microsoft.Extensions.Configuration;
using Supabase;
using Supabase.Realtime;
using Supabase.Realtime.Interfaces;
using Supabase.Realtime.PostgresChanges;

namespace EverlastimerWidget.Services;

/// <summary>
/// Central access point for Supabase operations in the WPF widget.
/// This singleton keeps the client reusable for future features such as
/// support stats, announcements, changelog, themes, and widget data.
/// </summary>
public sealed class SupabaseService
{
    private static SupabaseService? _instance;
    private static readonly object _lock = new();

    private readonly Supabase.Client _client;

    private SupabaseService(IConfiguration configuration)
    {
        var url = configuration["Supabase:Url"];
        var anonKey = configuration["Supabase:AnonKey"];

        if (string.IsNullOrWhiteSpace(url) || string.IsNullOrWhiteSpace(anonKey))
        {
            throw new InvalidOperationException("Supabase configuration is missing. Please set Supabase:Url and Supabase:AnonKey in appsettings.json.");
        }

        _client = new Supabase.Client(url, anonKey, new SupabaseOptions
        {
            AutoRefreshToken = true,
            AutoConnectRealtime = true
        });

        _ = SubscribeToRealtimeAsync();
    }

    public static SupabaseService Initialize(IConfiguration configuration)
    {
        if (_instance is not null)
        {
            return _instance;
        }

        lock (_lock)
        {
            _instance ??= new SupabaseService(configuration);
        }

        return _instance;
    }

    public static SupabaseService Instance => _instance ?? throw new InvalidOperationException("SupabaseService has not been initialized.");

    public Supabase.Client Client => _client;

    /// <summary>
    /// Fires whenever support_stats data changes in Supabase (via Realtime push).
    /// </summary>
    public event EventHandler<SupportStats?>? SupportStatsChanged;

    /// <summary>
    /// Fetches the first support statistics row from the support_stats table.
    /// Returns null if no row exists or if the request fails.
    /// </summary>
    public async Task<SupportStats?> GetSupportStatsAsync()
    {
        try
        {
            var response = await _client
                .From<SupportStats>()
                .Select("*")
                .Range(0, 0)
                .Get();

            var stats = response.Model;

            if (stats is null)
            {
                Debug.WriteLine("Supabase support_stats query returned no rows.");
                return null;
            }

            Debug.WriteLine($"Fetched support stats — Budget: {stats.Budget}, Received: {stats.Received}");

            return stats;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Supabase support_stats query failed: {ex.Message}");
            return null;
        }
    }

    private async Task SubscribeToRealtimeAsync()
    {
        try
        {
            await _client.Realtime.ConnectAsync();

            var channel = _client.Realtime.Channel("support_stats");
            channel.AddPostgresChangeHandler(PostgresChangesOptions.ListenType.All, OnSupportStatsChanged);
            await channel.Subscribe();

            Debug.WriteLine("Realtime subscription to support_stats established.");
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Realtime subscription failed (non-fatal, polling will still work): {ex.Message}");
        }
    }

    private void OnSupportStatsChanged(IRealtimeChannel sender, PostgresChangesResponse change)
    {
        Debug.WriteLine("Realtime: support_stats changed, re-fetching...");
        _ = NotifySupportStatsChangedAsync();
    }

    private async Task NotifySupportStatsChangedAsync()
    {
        var stats = await GetSupportStatsAsync();
        SupportStatsChanged?.Invoke(this, stats);
    }
}
