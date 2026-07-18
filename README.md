# Everlastimer

Minimal floating year-end tracker for your Windows desktop.

Stay aware of how much of the year has passed — without opening a browser or a full app. Everlastimer gives you a **Flutter desktop app** with detailed year-progress stats and a **lightweight WPF overlay widget** that floats on your screen at all times.

## Features

- **Year-progress ring** — Circular progress ring showing the percentage of the year elapsed
- **Multiple display styles** — Ring, Bar, Dial, Minimal (selectable in the app)
- **Live desktop widget** — Always-on-top WPF overlay, draggable, resizable, lockable
- **Supabase-powered support stats** — Monthly budget tracking with live cost breakdown (hosting, database, CDN, APIs, etc.)
- **Real-time updates** — Supabase Realtime pushes changes to the widget instantly
- **Theme system** — 5 built-in presets (Midnight, Nebula, Glass Purple, Arctic, Mono), 9 accent colors, transparency control, custom themes
- **Settings persistence** — Widget position, size, and lock state are saved across sessions
- **Windows startup** — Optional auto-launch for the widget (via Registry Run key)

## Screenshots

_Coming soon._

## Project Structure

```
everlastimer/
├── app/                  # Flutter Windows desktop application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/         # Year progress math, theme system, tab navigation
│   │   ├── features/     # Home, Settings, Support, Themes, Widgets screens
│   │   └── widgets/      # Progress ring, bar, dial, sidebar, stat cards
│   └── pubspec.yaml
├── widget/               # WPF .NET 8 overlay widget
│   ├── MainWindow.xaml   # Floating glassmorphism UI
│   ├── YearProgress.cs   # Progress math (mirrors Dart logic)
│   ├── ProgressRing.cs   # Custom circular progress render
│   ├── Services/         # Supabase client, Realtime, support stats model
│   └── appsettings.json  # Supabase URL and key
├── installer/            # Inno Setup installer script
├── docs/                 # Documentation snippets
└── .github/workflows/    # CI/CD release pipeline
```

## Technologies

| Component | Stack |
|-----------|-------|
| Desktop app | Flutter 3.32.5, Dart 3.8, Riverpod, Supabase Flutter |
| Overlay widget | .NET 8, WPF, supabase-csharp 0.16.2 |
| Backend | Supabase (PostgreSQL, Realtime) |
| Installer | Inno Setup 6 |
| CI/CD | GitHub Actions (windows-latest) |

## Prerequisites

- [Flutter SDK](https://flutter.dev) 3.32.5+ (stable channel)
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Visual Studio 2022](https://visualstudio.microsoft.com/) (Windows + .NET desktop workloads)
- [Inno Setup 6](https://jrsoftware.org/isinfo.php) (optional, for building the installer)

## Build & Run

### Flutter App

```powershell
cd app
flutter pub get
flutter build windows --release
```

Output: `app\build\windows\x64\runner\Release\`

For development:

```powershell
cd app
flutter run -d windows
```

### WPF Widget

```powershell
cd widget
dotnet publish -c Release -r win-x64 --self-contained true
```

Output: `widget\bin\Release\net8.0-windows\win-x64\publish\`

CLI flags:

| Flag | Description |
|------|-------------|
| `--enable-startup` | Register widget to launch at Windows startup |
| `--disable-startup` | Remove widget from Windows startup |
| `--is-startup-enabled` | Exit code 0 (enabled) or 1 (disabled) |

### Installer

```powershell
iscc installer/everlastimer.iss /DMyAppVersion=1.0.0 /DSourceDir=path\to\artifacts
```

Output: `installer\Output\Everlastimer-setup-1.0.0.exe`

## Release

Push a version tag to trigger the CI release pipeline:

```powershell
git tag v1.0.0
git push origin v1.0.0
```

The workflow (`.github/workflows/release.yml`) builds both apps, packages them into a ZIP and an Inno Setup installer, then publishes a GitHub Release with both assets attached. You can also trigger it manually via the GitHub Actions tab with a version input.

## License

MIT — see [LICENSE](LICENSE).

Copyright 2026 BITEKOI LABS
