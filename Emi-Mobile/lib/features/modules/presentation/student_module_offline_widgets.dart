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
        label: 'MENGUNDUH',
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
                  ? 'MENGUNDUH'
                  : 'MENGUNDUH ${(state.progress! * 100).round()}%',
            ),
          ],
        ),
      );
    }
    if (status == ModuleOfflineStatus.availableOffline) {
      return PopupMenuButton<void>(
        tooltip: 'Tersedia offline',
        onSelected: (_) => _showRemove(context, onRemove),
        itemBuilder: (_) => const [
          PopupMenuItem(value: null, child: Text('Hapus dari Perangkat')),
        ],
        child: const Chip(
          avatar: Icon(Icons.offline_pin_outlined, size: 18),
          label: Text('Tersedia offline'),
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
            ? 'GAGAL MENGUNDUH'
            : update
            ? 'Pembaruan tersedia'
            : 'BELUM DIUNDUH',
      ),
    );
  }

  Future<void> _showRemove(BuildContext context, VoidCallback? onRemove) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Modul'),
        content: const Text(
          'Modul ini tidak bisa diakses saat offline jika dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (accepted == true) onRemove?.call();
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
          const Text(
            'Fitur ini memerlukan koneksi internet',
            textAlign: TextAlign.center,
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
