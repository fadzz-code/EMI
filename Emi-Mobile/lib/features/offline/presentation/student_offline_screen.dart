import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../../modules/presentation/student_module_offline_providers.dart';
import '../data/offline_learning_providers.dart';
import '../domain/offline_learning_summary.dart';

class StudentOfflineScreen extends ConsumerWidget {
  const StudentOfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(offlineLearningSummaryProvider);
    final isSyncing = false;

    return EmiScaffold(
      title: 'Belajar Offline',
      currentIndex: 0,
      onNavTap: (index) => _go(context, index),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(offlineLearningSummaryProvider);
          if (!isSyncing) {
             await ref.read(moduleSyncCoordinatorProvider).trigger();
          }
        },
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              StudentPlaceholder(
                icon: Icons.error_outline,
                title: 'Data tidak tersedia',
                message: 'Terjadi kesalahan saat memuat data offline.',
                onRetry: () => ref.invalidate(offlineLearningSummaryProvider),
              ),
            ],
          ),
          data: (summary) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              _SyncBanner(
                isSyncing: isSyncing,
                onSync: () =>
                    ref.read(moduleSyncCoordinatorProvider).trigger(),
              ),
              const SizedBox(height: EmiSpacing.lg),
              _SavedDataCard(summary: summary),
              const SizedBox(height: EmiSpacing.md),
              _ActivityCard(summary: summary),
              const SizedBox(height: EmiSpacing.lg),
              _OfflineLinksCard(),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, int index) {
    if (index == 0) context.go('/student/dashboard');
    if (index == 1) context.go('/student/modules');
    if (index == 2) context.go('/student/dictionary');
    if (index == 3) context.go('/student/quizzes');
    if (index == 4) context.go('/student/profile');
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.isSyncing, required this.onSync});

  final bool isSyncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.md),
      decoration: BoxDecoration(
        color: StudentStyle.surface,
        borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
        border: Border.all(color: StudentStyle.tintStrong),
        boxShadow: StudentStyle.softShadow(),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSyncing ? StudentStyle.tint : EmiColors.surface,
              shape: BoxShape.circle,
            ),
            child: isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: EmiColors.primary,
                    ),
                  )
                : const Icon(Icons.sync, color: StudentStyle.inkMuted),
          ),
          const SizedBox(width: EmiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSyncing ? 'Sedang sinkronisasi...' : 'Sinkronisasi Data',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: StudentStyle.ink),
                ),
                Text(
                  'Kirim progress dan ambil pembaruan',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: StudentStyle.inkMuted),
                ),
              ],
            ),
          ),
          if (!isSyncing)
            TextButton(onPressed: onSync, child: const Text('Coba Sinkronkan')),
        ],
      ),
    );
  }
}

class _SavedDataCard extends StatelessWidget {
  const _SavedDataCard({required this.summary});
  final OfflineLearningSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudentSectionHeader(
          'Tersimpan di Perangkat',
          icon: Icons.sd_storage_outlined,
          leading: false,
        ),
        StudentCard(
          padding: const EdgeInsets.all(EmiSpacing.md),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.menu_book,
                label: 'Modul',
                value: '${summary.moduleCount} modul',
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.category,
                label: 'Kategori Kamus',
                value: '${summary.categoryCount} kategori',
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.translate,
                label: 'Entri Kamus',
                value: '${summary.entryCount} kata',
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.folder,
                label: 'Total Ruang',
                value: summary.formattedTotalSize,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.summary});
  final OfflineLearningSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudentSectionHeader(
          'Aktivitas Belajar',
          icon: Icons.local_activity_outlined,
          leading: false,
        ),
        StudentCard(
          padding: const EdgeInsets.all(EmiSpacing.md),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.schedule,
                label: 'Menunggu dikirim',
                value: '${summary.pendingActivities} item',
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.error_outline,
                label: 'Gagal terkirim',
                value: '${summary.failedActivities} item',
                valueColor: EmiColors.error,
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.lock_outline,
                label: 'Perlu login ulang',
                value: '${summary.authBlockedActivities} item',
                valueColor: EmiColors.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfflineLinksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudentSectionHeader(
          'Kelola Data',
          icon: Icons.settings_outlined,
          leading: false,
        ),
        StudentCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book, color: EmiColors.primary),
                title: const Text('Kelola Modul Offline'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/student/modules?offline=true'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.translate, color: EmiColors.primary),
                title: const Text('Kelola Kamus Offline'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/student/dictionary'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: StudentStyle.inkMuted),
        const SizedBox(width: EmiSpacing.sm),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: StudentStyle.ink),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: valueColor ?? StudentStyle.ink,
          ),
        ),
      ],
    );
  }
}