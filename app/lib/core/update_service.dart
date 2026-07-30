import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

const _githubRepo = 'OoADARSHoO/EVERLASTIMER';
const _githubApiUrl =
    'https://api.github.com/repos/$_githubRepo/releases/latest';

class UpdateInfo {
  final String version;
  final String? downloadUrl;
  final String? body;

  const UpdateInfo({
    required this.version,
    this.downloadUrl,
    this.body,
  });
}

enum UpdateStatus {
  idle,
  checking,
  updateAvailable,
  downloading,
  applying,
  error,
}

class UpdateState {
  final UpdateStatus status;
  final String? currentVersion;
  final UpdateInfo? latestVersion;
  final double downloadProgress;
  final String? errorMessage;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.currentVersion,
    this.latestVersion,
    this.downloadProgress = 0.0,
    this.errorMessage,
  });
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  Timer? _periodicTimer;

  UpdateNotifier() : super(const UpdateState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      state = UpdateState(currentVersion: info.version);
    } catch (_) {
      state = const UpdateState(currentVersion: '0.0.0');
    }
    checkForUpdates();
    _periodicTimer = Timer.periodic(
      const Duration(hours: 4),
      (_) => checkForUpdates(),
    );
  }

  Future<void> checkForUpdates() async {
    final current = state.currentVersion;
    state = UpdateState(
      status: UpdateStatus.checking,
      currentVersion: current,
    );

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(Uri.parse(_githubApiUrl));
      request.headers.set('Accept', 'application/vnd.github.v3+json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;
      final tagName = json['tag_name'] as String?;
      if (tagName == null || current == null) {
        state = UpdateState(status: UpdateStatus.idle, currentVersion: current);
        return;
      }

      final version = tagName.replaceFirst(RegExp(r'^v'), '');
      final assets = json['assets'] as List? ?? [];

      String? downloadUrl;
      for (final asset in assets) {
        final name = (asset['name'] as String?) ?? '';
        if ((name.toLowerCase().contains('windows') || name.toLowerCase().contains('win')) && name.endsWith('.zip')) {
          downloadUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      if (_isNewer(version, current)) {
        state = UpdateState(
          status: UpdateStatus.updateAvailable,
          currentVersion: current,
          latestVersion: UpdateInfo(
            version: version,
            downloadUrl: downloadUrl,
            body: json['body'] as String?,
          ),
        );
      } else {
        state = UpdateState(status: UpdateStatus.idle, currentVersion: current);
      }
    } catch (_) {
      state = UpdateState(status: UpdateStatus.idle, currentVersion: current);
    }
  }

  bool _isNewer(String remote, String current) {
    final remoteParts =
        remote.split('.').map(int.tryParse).whereType<int>().toList();
    final currentParts =
        current.split('.').map(int.tryParse).whereType<int>().toList();

    for (var i = 0; i < 3; i++) {
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  Future<void> startUpdate() async {
    final url = state.latestVersion?.downloadUrl;
    if (url == null) return;

    state = UpdateState(
      status: UpdateStatus.downloading,
      currentVersion: state.currentVersion,
      latestVersion: state.latestVersion,
    );

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final totalBytes = response.contentLength;

      final tempDir = Directory.systemTemp.createTempSync('everlastimer_update');
      final zipPath = p.join(tempDir.path, 'update.zip');
      final sink = File(zipPath).openWrite();

      var receivedBytes = 0;
      await response.listen(
        (chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes != null && totalBytes > 0) {
            final progress = receivedBytes / totalBytes;
            state = UpdateState(
              status: UpdateStatus.downloading,
              currentVersion: state.currentVersion,
              latestVersion: state.latestVersion,
              downloadProgress: progress,
            );
          }
        },
      ).asFuture();
      await sink.close();
      client.close();

      state = UpdateState(
        status: UpdateStatus.applying,
        currentVersion: state.currentVersion,
        latestVersion: state.latestVersion,
      );

      final appExe = Platform.resolvedExecutable;
      final appDir = p.dirname(appExe);
      final batPath = p.join(tempDir.path, 'update.bat');

      final batContent = '''
@echo off
:wait_loop
tasklist /FI "IMAGENAME eq everlastimer.exe" 2>NUL | find /I "everlastimer.exe" >NUL
if %ERRORLEVEL% == 0 (
    timeout /t 2 /nobreak >nul
    goto wait_loop
)
powershell -NoProfile -WindowStyle Hidden -Command "Expand-Archive -Path '${zipPath.replaceAll("'", "''")}' -DestinationPath '${appDir.replaceAll("'", "''")}' -Force"
start "" "${appDir.replaceAll("'", "''")}\\everlastimer.exe"
rmdir /s /q "${tempDir.path.replaceAll("'", "''")}" 2>nul
del "%~f0"
''';

      await File(batPath).writeAsString(batContent);

      final vbsPath = p.join(tempDir.path, 'update.vbs');
      final vbsContent = 'Set WshShell = CreateObject("WScript.Shell")\n'
          'WshShell.Run "cmd /c \\"\\"${batPath.replaceAll("'", "''")}\\"\\"", 0, False\n';
      await File(vbsPath).writeAsString(vbsContent);

      await Process.start('wscript', [vbsPath],
          mode: ProcessStartMode.detached);
      exit(0);
    } catch (e) {
      state = UpdateState(
        status: UpdateStatus.error,
        currentVersion: state.currentVersion,
        latestVersion: state.latestVersion,
        errorMessage: 'Update failed: $e',
      );
    }
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }
}

final updateProvider = StateNotifierProvider<UpdateNotifier, UpdateState>(
  (ref) => UpdateNotifier(),
);
