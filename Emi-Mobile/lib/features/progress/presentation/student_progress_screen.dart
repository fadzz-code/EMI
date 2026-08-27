import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/network/network_status_controller.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_connectivity_banner.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../data/student_progress.dart';
import '../data/student_progress_providers.dart';

class StudentProgressScreen extends ConsumerWidget {
  const StudentProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const query = StudentProgressQuery();
    final progress = ref.watch(studentProgressReportProvider(query));
    final networkMode = ref.watch(networkStatusControllerProvider).mode;

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
              StudentPlaceholder(
                icon: Icons.cloud_off_outlined,
                title: 'Progress Belum Bisa Dimuat',
                message: 'Periksa koneksi internetmu, lalu coba lagi.',
                onRetry: () =>
                    ref.invalidate(studentProgressReportProvider(query)),
              ),
            ],
          ),
          data: (report) {
            if (report.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(EmiSpacing.md),
                children: [
                  StudentConnectivityBanner(mode: networkMode),
                  StudentPlaceholder(
                    icon: Icons.trending_up_outlined,
                    title: 'Progress Belum Tersedia',
                    message: 'Mulai belajar untuk melihat progressmu di sini.',
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                StudentConnectivityBanner(mode: networkMode),
                if (report.summary != null)
                  _SummaryCard(summary: report.summary!),
                const StudentSectionHeader(
                  'Progress Modul',
                  icon: Icons.menu_book_outlined,
                ),
                if (report.modules.items.isEmpty)
                  StudentPlaceholder(
                    icon: Icons.menu_book_outlined,
                    title: 'Belum Ada Progress Modul',
                    message: 'Progress modulmu akan muncul setelah kamu mulai.',
                  )
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
    return StudentCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(EmiSpacing.lg),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFB877), Color(0xFFFF8A3D)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.fullName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (summary.className != null)
                  Text(
                    summary.className!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                const SizedBox(height: EmiSpacing.md),
                Text(
                  '${summary.overallLearningProgressPercent.round()}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: EmiSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(EmiRadii.pill),
                  child: LinearProgressIndicator(
                    value: (summary.overallLearningProgressPercent / 100).clamp(
                      0,
                      1,
                    ),
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: Wrap(
              spacing: EmiSpacing.sm,
              runSpacing: EmiSpacing.sm,
              children: [
                StudentStatChip(
                  label: 'Modul selesai',
                  value:
                      '${summary.completedModules}/${summary.publishedModules}',
                ),
                StudentStatChip(
                  label: 'Materi selesai',
                  value:
                      '${summary.completedLessons}/${summary.totalPublishedLessons}',
                ),
                StudentStatChip(
                  label: 'Kuis selesai',
                  value:
                      '${summary.quizzesCompleted}/${summary.publishedQuizzes}',
                ),
                if (summary.averageBestQuizScorePercent != null)
                  StudentStatChip(
                    label: 'Rata-rata kuis',
                    value: '${summary.averageBestQuizScorePercent!.round()}%',
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
    return StudentCard(
      onTap: module.id.isEmpty
          ? null
          : () => context.go('/student/modules/${module.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  module.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: StudentStyle.ink),
                ),
              ),
              const SizedBox(width: EmiSpacing.sm),
              StudentStatusChip(
                label: studentProgressStatus(module.status),
                status: module.status,
              ),
            ],
          ),
          const SizedBox(height: EmiSpacing.md),
          StudentProgressBar(
            value: module.progressPercent / 100,
            caption:
                '${module.progressPercent.round()}% • ${module.completedLessons}/${module.totalLessons} materi',
          ),
        ],
      ),
    );
  }
}
