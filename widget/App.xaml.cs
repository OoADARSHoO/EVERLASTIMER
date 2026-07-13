using System;
using System.Diagnostics;
using System.IO;
using System.Windows;
using EverlastimerWidget.Services;
using Microsoft.Extensions.Configuration;

namespace EverlastimerWidget;

public partial class App : Application
{
    private IConfiguration? _configuration;

    protected override void OnStartup(StartupEventArgs e)
    {
        _configuration = BuildConfiguration();
        SupabaseService.Initialize(_configuration);

        AppDomain.CurrentDomain.UnhandledException += (_, ex) =>
        {
            File.AppendAllText(Path.Combine(AppContext.BaseDirectory, "startup-errors.log"), ex.ExceptionObject?.ToString() + Environment.NewLine + "---" + Environment.NewLine);
        };

        DispatcherUnhandledException += (_, ex) =>
        {
            File.AppendAllText(Path.Combine(AppContext.BaseDirectory, "startup-errors.log"), ex.Exception?.ToString() + Environment.NewLine + "---" + Environment.NewLine);
            ex.Handled = true;
        };

        // Allow Everlastimer (or the user, or a shortcut) to call this exe
        // with flags to manage Windows-startup registration without
        // actually opening the widget window. Examples:
        //   EverlastimerWidget.exe --enable-startup
        //   EverlastimerWidget.exe --disable-startup
        if (e.Args.Length > 0)
        {
            var exePath = GetExecutablePath();

            switch (e.Args[0])
            {
                case "--enable-startup":
                    StartupRegistration.Enable(exePath);
                    Shutdown();
                    return;
                case "--disable-startup":
                    StartupRegistration.Disable();
                    Shutdown();
                    return;
                case "--is-startup-enabled":
                    // Exit code 0 = enabled, 1 = disabled. Lets the calling
                    // app check state via Process.ExitCode without parsing
                    // stdout.
                    Shutdown(StartupRegistration.IsRegistered() ? 0 : 1);
                    return;
            }
        }

        base.OnStartup(e);
    }

    private static IConfiguration BuildConfiguration()
    {
        var baseDirectory = AppContext.BaseDirectory;
        var builder = new ConfigurationBuilder()
            .SetBasePath(baseDirectory)
            .AddJsonFile("appsettings.json", optional: true, reloadOnChange: false);

        return builder.Build();
    }

    private static string GetExecutablePath()
    {
        var processPath = Environment.ProcessPath;
        if (!string.IsNullOrEmpty(processPath))
        {
            return processPath;
        }

        var mainModulePath = Process.GetCurrentProcess().MainModule?.FileName;
        if (!string.IsNullOrEmpty(mainModulePath))
        {
            return mainModulePath;
        }

        return Path.Combine(AppContext.BaseDirectory, AppDomain.CurrentDomain.FriendlyName);
    }
}