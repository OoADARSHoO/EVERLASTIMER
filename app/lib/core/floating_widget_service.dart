import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The only "connection" between Everlastimer and the standalone
/// EverlastimerWidget.exe: launching it, and asking it to flip its own
/// Windows-startup registry entry. No shared process, no IPC, no runtime
/// dependency — if this fails, the rest of Everlastimer is unaffected.
class FloatingWidgetService {
  /// Tries a few likely locations for EverlastimerWidget.exe, in order:
  ///
  /// 1. Dev layout — EverlastimerWidget published as a sibling project
  ///    folder next to Everlastimer (e.g. both under "BITEKOI LABS").
  ///    Walks upward from wherever the Everlastimer exe is currently
  ///    running from until it finds a sibling EverlastimerWidget folder.
  /// 2. Production layout — a `widget/` subfolder shipped next to the
  ///    installed Everlastimer exe.
  ///
  /// Returns null if none of them exist yet.
  String? get _exePath {
    final exeDir = Directory(File(Platform.resolvedExecutable).parent.path);
    final sep = Platform.pathSeparator;

    // 1. Dev layout: walk up a few levels looking for a sibling folder
    // containing the published exe. Check both "widget" and
    // "EverlastimerWidget" folder names.
    Directory? dir = exeDir;
    for (var i = 0; i < 8 && dir != null; i++) {
      for (final folderName in ['widget', 'EverlastimerWidget']) {
        final candidate = File(
          '${dir.path}$sep$folderName$sep'
          'bin${sep}Release${sep}net8.0-windows${sep}win-x64'
          '${sep}publish${sep}EverlastimerWidget.exe',
        );
        if (candidate.existsSync()) return candidate.path;
      }
      dir = dir.parent;
    }

    // 2. Production layout: widget/EverlastimerWidget.exe next to the
    // installed Everlastimer exe.
    final productionCandidate = File(
      '${exeDir.path}${sep}widget${sep}EverlastimerWidget.exe',
    );
    if (productionCandidate.existsSync()) return productionCandidate.path;

    return null;
  }

  bool get isSupported => Platform.isWindows;

  /// Launches the widget as a fully detached process — closing
  /// Everlastimer afterward has no effect on it.
  Future<FloatingWidgetResult> launchNow() async {
    if (!isSupported) return FloatingWidgetResult.unsupportedPlatform;
    final exePath = _exePath;
    if (exePath == null) return FloatingWidgetResult.exeNotFound;

    try {
      await Process.start(exePath, [], mode: ProcessStartMode.detached);
      return FloatingWidgetResult.success;
    } catch (_) {
      return FloatingWidgetResult.failed;
    }
  }

  Future<FloatingWidgetResult> setStartupEnabled(bool enabled) async {
    if (!isSupported) return FloatingWidgetResult.unsupportedPlatform;
    final exePath = _exePath;
    if (exePath == null) return FloatingWidgetResult.exeNotFound;

    try {
      final result = await Process.run(
        exePath,
        [enabled ? '--enable-startup' : '--disable-startup'],
      );
      return result.exitCode == 0
          ? FloatingWidgetResult.success
          : FloatingWidgetResult.failed;
    } catch (_) {
      return FloatingWidgetResult.failed;
    }
  }

  Future<bool> isStartupEnabled() async {
    if (!isSupported) return false;
    final exePath = _exePath;
    if (exePath == null) return false;
    try {
      final result = await Process.run(exePath, ['--is-startup-enabled']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}

enum FloatingWidgetResult { success, failed, exeNotFound, unsupportedPlatform }

final floatingWidgetServiceProvider = Provider<FloatingWidgetService>((ref) {
  return FloatingWidgetService();
});