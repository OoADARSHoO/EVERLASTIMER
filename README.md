# Everlastimer

A minimal, always-on desktop year-progress tracker for Windows. Displays a beautiful circular progress ring showing how much of the year has passed, alongside detailed time stats.

Built with **Flutter** (Windows desktop) for the main application and **WPF (.NET 8)** for the desktop overlay widget.

## Features

- Circular progress ring with gradient fill and glow
- Detailed stats: month, week, day, hour progress
- Floating desktop widget (always-on-top overlay)
- Multiple display styles (Ring, Bar, Dial, Minimal)
- Customizable accent colors and themes
- Firebase-backed authentication and cloud sync

## Project Structure

```
EVERLASTIMER/
├── app/            Flutter Windows desktop application
├── widget/         WPF desktop overlay widget
├── installer/      Inno Setup installer script
├── .github/        GitHub Actions workflows
└── docs/           Documentation
```

## Building from Source

### Prerequisites

- Flutter 3.32.5+ (stable channel)
- .NET 8 SDK
- Visual Studio 2022 (with Windows desktop and .NET desktop workloads)
- Inno Setup 6 (for installer)

### Build Commands

```powershell
# Flutter app
cd app
flutter pub get
flutter build windows --release

# WPF widget
cd widget
dotnet publish EverlastimerWidget.csproj -c Release -r win-x64 --self-contained true

# Installer (output at installer/Output/)
iscc installer/everlastimer.iss /DMyAppVersion=1.0.0 /DSourceDir=path/to/artifacts
```

## License

MIT
