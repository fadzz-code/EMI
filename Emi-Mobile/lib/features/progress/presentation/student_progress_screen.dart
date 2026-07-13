import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../data/student_progress.dart';
import '../data/student_progress_providers.dart';

class StudentProgressScreen extends ConsumerWidget {
  const StudentProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const query = StudentProgressQuery();
    final progress = ref.watch(studentProgressReportProvider(query));

    return EmiScaffold(
      title: 'Progress Belajar',
      child: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(studentProgressReportProvider(query).future),
        child: progress.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              EmiCard(
                child: Column(
                  children: [
                    Text(error.toString()),
                    const SizedBox(height: EmiSpacing.md),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(studentProgressReportProvider(query)),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (report) {
            if (report.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(EmiSpacing.md),
                children: const [
                  EmiCard(child: Text('Progress belum tersedia.')),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                if (report.summary != null)
                  _SummaryCard(summary: report.summary!),
                const SizedBox(height: EmiSpacing.lg),
                Text(
                  'Progress Modul',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: EmiSpacing.md),
                if (report.modules.items.isEmpty)
                  const EmiCard(child: Text('Belum ada progress modul.'))
                else
                  ...report.modules.items.map(
                    (module) => Padding(
                      padding: const EdgeInsets.only(bottom: EmiSpacing.md),
                      child: _ModuleProgressCard(module: module),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final StudentProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return EmiCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(EmiSpacing.md),
            decoration: const BoxDecoration(
              color: EmiColors.secondary,
              border: Border(
                bottom: BorderSide(color: EmiColors.border, width: 2),
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.fullName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (summary.className != null) Text(summary.className!),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summary.overallLearningProgressPercent.round()}%',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: EmiSpacing.sm),
                LinearProgressIndicator(
                  value: (summary.overallLearningProgressPercent / 100).clamp(
                    0,
                    1,
                  ),
                ),
                const SizedBox(height: EmiSpacing.lg),
                Wrap(
                  spacing: EmiSpacing.sm,
                  runSpacing: EmiSpacing.sm,
                  children: [
                    _StatPill(
                      label: 'Modul selesai',
                      value:
                          '${summary.completedModules}/${summary.publishedModules}',
                    ),
                    _StatPill(
                      label: 'Materi selesai',
                      value:
                          '${summary.completedLessons}/${summary.totalPublishedLessons}',
                    ),
                    _StatPill(
                      label: 'Kuis selesai',
                      value:
                          '${summary.quizzesCompleted}/${summary.publishedQuizzes}',
                    ),
                    if (summary.averageBestQuizScorePercent != null)
                      _StatPill(
                        label: 'Rata-rata kuis',
                        value:
                            '${summary.averageBestQuizScorePercent!.round()}%',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleProgressCard extends StatelessWidget {
  const _ModuleProgressCard({required this.module});

  final StudentProgressModule module;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: module.id.isEmpty
          ? null
          : () => context.go('/student/modules/${module.id}'),
      child: EmiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    module.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusPill(status: module.status),
              ],
            ),
            const SizedBox(height: EmiSpacing.md),
            LinearProgressIndicator(
              value: (module.progressPercent / 100).clamp(0, 1),
            ),
            const SizedBox(height: EmiSpacing.sm),
            Text(
              '${module.progressPercent.round()}% • ${module.completedLessons}/${module.totalLessons} materi',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.sm),
      decoration: BoxDecoration(
        color: EmiColors.backgroundWarm,
        border: Border.all(color: EmiColors.border, width: 2),
        borderRadius: BorderRadius.circular(EmiRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EmiSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: status == 'completed' ? EmiColors.success : EmiColors.secondary,
        border: Border.all(color: EmiColors.border, width: 2),
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: Text(status),
    );
  }
}
