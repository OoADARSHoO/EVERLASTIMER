import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/update_service.dart';

class UpdateOverlay extends ConsumerWidget {
  final Widget child;

  const UpdateOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateProvider);
    final showOverlay = updateState.status == UpdateStatus.updateAvailable ||
        updateState.status == UpdateStatus.downloading ||
        updateState.status == UpdateStatus.applying;

    return Stack(
      children: [
        child,
        if (showOverlay)
          _UpdatePanel(
            state: updateState,
            onRetry: () =>
                ref.read(updateProvider.notifier).checkForUpdates(),
            onUpdate: () =>
                ref.read(updateProvider.notifier).startUpdate(),
          ),
      ],
    );
  }
}

class _UpdatePanel extends StatelessWidget {
  final UpdateState state;
  final VoidCallback onRetry;
  final VoidCallback onUpdate;

  const _UpdatePanel({
    required this.state,
    required this.onRetry,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: const Color(0xFF15131F),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF26223A)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Update Available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'A new version of Everlastimer is available.\nPlease update to continue.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'v${state.latestVersion?.version ?? "?"}',
                  style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                _buildAction(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAction() {
    switch (state.status) {
      case UpdateStatus.downloading:
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value:
                    state.downloadProgress > 0 ? state.downloadProgress : null,
                minHeight: 8,
                backgroundColor: const Color(0xFF26223A),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              state.downloadProgress > 0
                  ? 'Downloading… ${(state.downloadProgress * 100).toInt()}%'
                  : 'Downloading…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        );
      case UpdateStatus.applying:
        return Column(
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Color(0xFF8B5CF6),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Installing update…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        );
      case UpdateStatus.error:
        return Column(
          children: [
            Text(
              state.errorMessage ?? 'Update failed.',
              style: const TextStyle(color: Color(0xFFE0A458), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2640),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        );
      default:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Update Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        );
    }
  }
}
