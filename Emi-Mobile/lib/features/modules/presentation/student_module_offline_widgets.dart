import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/student_style.dart';
import 'student_module_ui_controller.dart';

export '../../../shared/widgets/student_connectivity_banner.dart';

class ModuleOfflineAction extends StatelessWidget {
  const ModuleOfflineAction({
    super.key,
    required this.state,
    required this.onDownload,
    required this.onRemove,
  });

  final ModuleOfflineState state;
  final VoidCallback? onDownload;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    if (status == ModuleOfflineStatus.downloading) {
      return Semantics(
        label: 'Downloading',
        value: state.progress == null
            ? null
            : '${(state.progress! * 100).round()}%',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: EmiSpacing.xs),
            Text(
              state.progress == null
                  ? 'Downloading'
                  : 'Downloading ${(state.progress! * 100).round()}%',
            ),
          ],
        ),
      );
    }
    if (status == ModuleOfflineStatus.availableOffline) {
      return PopupMenuButton<void>(
        tooltip: 'Available Offline',
        onSelected: (_) => onRemove?.call(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: null, child: Text('Remove')),
        ],
        child: const Chip(
          avatar: Icon(Icons.offline_pin_outlined, size: 18),
          label: Text('Available Offline'),
        ),
      );
    }
    final retry = status == ModuleOfflineStatus.retry;
    final update = status == ModuleOfflineStatus.updateAvailable;
    return TextButton.icon(
      onPressed: onDownload,
      icon: Icon(
        retry
            ? Icons.refresh
            : update
            ? Icons.system_update_alt
            : Icons.download_outlined,
      ),
      label: Text(
        retry
            ? 'Retry'
            : update
            ? 'Update Available'
            : 'Download',
      ),
    );
  }
}

class OfflineUnavailableMessage extends StatelessWidget {
  const OfflineUnavailableMessage({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EmiSpacing.md),
      decoration: BoxDecoration(
        color: StudentStyle.tint,
        borderRadius: BorderRadius.circular(EmiRadii.card),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: EmiColors.primary),
          const SizedBox(height: EmiSpacing.xs),
          const Text('Konten ini belum tersedia offline.'),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
