import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../data/teacher_providers.dart';
import 'teacher_shell.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(teacherDashboardProvider);
    return TeacherShell(
      title: 'Dashboard Guru',
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(teacherDashboardProvider),
        child: dashboard.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              EmiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.toString()),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(teacherDashboardProvider),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (summary) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              EmiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.className ?? 'Belum ada kelas aktif',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(summary.schoolName ?? 'Kelas guru belum ditetapkan.'),
                    if (summary.generatedAt != null)
                      Text('Diperbarui: ${summary.generatedAt}'),
                  ],
                ),
              ),
              const SizedBox(height: EmiSpacing.md),
              if (summary.emptyState)
                const EmiCard(
                  child: Text('Dashboard guru belum memiliki data kelas.'),
                ),
              Wrap(
                spacing: EmiSpacing.md,
                runSpacing: EmiSpacing.md,
                children: [
                  for (final metric in summary.metrics)
                    SizedBox(
                      width: 160,
                      child: EmiCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(metric.label),
                            Text(
                              metric.value,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: EmiSpacing.md),
              EmiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktivitas Terbaru',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (summary.recentActivity.isEmpty)
                      const Text('Aktivitas belum tersedia.'),
                    for (final item in summary.recentActivity)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.title ?? '-'),
                        subtitle: Text(
                          '${item.studentName ?? '-'} • ${item.occurredAt ?? '-'}',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
