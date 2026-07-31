import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/admin_progress_models.dart';
import '../data/admin_progress_providers.dart';
import 'admin_reports_screen.dart';
import 'admin_shell.dart';
import 'admin_style.dart';
import 'admin_widgets.dart';

class AdminStudentProgressScreen extends ConsumerStatefulWidget {
  const AdminStudentProgressScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<AdminStudentProgressScreen> createState() =>
      _AdminStudentProgressScreenState();
}

class _AdminStudentProgressScreenState
    extends ConsumerState<AdminStudentProgressScreen> {
  int page = 1;
  @override
  Widget build(BuildContext context) => AdminShell(
    title: 'Detail Siswa',
    fallbackRoute: '/admin/reports',
    child: ref
        .watch(adminStudentProgressProvider((id: widget.id, page: page)))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Detail siswa gagal dimuat.')),
          data: (data) => ListView(
            key: const Key('adminScreen-student-progress-detail'),
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.student.fullName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.student.email.isEmpty
                          ? 'Email tidak tersedia'
                          : data.student.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminStyle.inkMuted,
                      ),
                    ),
                    Text(
                      '${data.progress.schoolName} • ${data.progress.className}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminStyle.inkMuted,
                      ),
                    ),
                    Text(
                      'Status akun: ${adminProgressStatus(data.student.status)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminStyle.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EmiSpacing.md),
              _PdfButton(
                onPressed: () => _sharePdf(studentId: widget.id),
                label: 'Bagikan PDF siswa',
              ),
              const ProgressSectionHeader('Progress belajar'),
              StudentLearningMetricGrid(progress: data.progress),
              const ProgressSectionHeader('Ringkasan kuis'),
              StudentQuizMetricGrid(summary: data.quizSummary),
              const ProgressSectionHeader('Riwayat kuis'),
              if (data.quizzes.items.isEmpty)
                const AdminCard(child: Text('Riwayat kuis belum tersedia.')),
              for (final quiz in data.quizzes.items) ...[
                AdminCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AdminStyle.tint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.quiz_outlined,
                          size: 22,
                          color: EmiColors.primary,
                        ),
                      ),
                      const SizedBox(width: EmiSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quiz.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${quiz.attemptCount} percobaan • Nilai ${adminProgressPercent(quiz.bestScorePercent)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AdminStyle.inkMuted),
                            ),
                            Text(
                              adminProgressDate(quiz.latestSubmittedAt),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AdminStyle.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      ProgressStatusBadge(
                        adminProgressStatus(quiz.latestStatus),
                        tone: emiStatusToneFromKey(quiz.latestStatus),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: EmiSpacing.sm),
              ],
              _Pager(
                meta: data.quizzes.meta,
                onPage: (value) => setState(() => page = value),
              ),
              const SizedBox(height: EmiSpacing.sm),
              const AdminCard(child: Text('Laporan speaking belum tersedia.')),
            ],
          ),
        ),
  );

  Future<void> _sharePdf({String? studentId}) async {
    try {
      final bytes = await ref
          .read(adminProgressRepositoryProvider)
          .pdf(studentId: studentId);
      final file = File(
        '${(await getTemporaryDirectory()).path}/progress-siswa.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Progress siswa'),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PDF gagal disiapkan.')));
      }
    }
  }
}

class AdminClassProgressScreen extends ConsumerStatefulWidget {
  const AdminClassProgressScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<AdminClassProgressScreen> createState() =>
      _AdminClassProgressScreenState();
}

class _AdminClassProgressScreenState
    extends ConsumerState<AdminClassProgressScreen> {
  int page = 1;
  @override
  Widget build(BuildContext context) => AdminShell(
    title: 'Detail Kelas',
    fallbackRoute: '/admin/reports',
    child: ref
        .watch(adminClassProgressProvider((id: widget.id, page: page)))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Detail kelas gagal dimuat.')),
          data: (data) => ListView(
            key: const Key('adminScreen-class-progress-detail'),
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.schoolClass.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.schoolClass.schoolName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminStyle.inkMuted,
                      ),
                    ),
                    Text(
                      'Tahun ajaran: ${data.schoolClass.academicYear.isEmpty ? '-' : data.schoolClass.academicYear}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminStyle.inkMuted,
                      ),
                    ),
                    Text(
                      'Guru: ${data.schoolClass.teacherName ?? '-'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminStyle.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EmiSpacing.md),
              _PdfButton(onPressed: _sharePdf, label: 'Bagikan PDF kelas'),
              const ProgressSectionHeader('Ringkasan'),
              ClassMetricGrid(
                summary: data.summary,
                speakingReports: data.speakingReports,
              ),
              const ProgressSectionHeader('Siswa'),
              if (data.students.items.isEmpty)
                const AdminCard(child: Text('Siswa tidak ditemukan.')),
              for (final student in data.students.items)
                ProgressStudentItem(
                  student: student,
                  onTap: () =>
                      context.push('/admin/reports/students/${student.id}'),
                ),
              _Pager(
                meta: data.students.meta,
                onPage: (value) => setState(() => page = value),
              ),
              const SizedBox(height: EmiSpacing.sm),
              const AdminCard(child: Text('Laporan speaking belum tersedia.')),
            ],
          ),
        ),
  );

  Future<void> _sharePdf() async {
    try {
      final bytes = await ref
          .read(adminProgressRepositoryProvider)
          .pdf(classId: widget.id);
      final file = File(
        '${(await getTemporaryDirectory()).path}/progress-kelas.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Progress kelas'),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PDF gagal disiapkan.')));
      }
    }
  }
}

class ProgressMetricGrid extends StatelessWidget {
  const ProgressMetricGrid({super.key, required this.metrics});
  final List<ProgressMetricTile> metrics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - EmiSpacing.sm) / 2;
      return Wrap(
        spacing: EmiSpacing.sm,
        runSpacing: EmiSpacing.sm,
        children: [
          for (final metric in metrics) SizedBox(width: width, child: metric),
        ],
      );
    },
  );
}

class StudentLearningMetricGrid extends StatelessWidget {
  const StudentLearningMetricGrid({super.key, required this.progress});
  final AdminProgressStudent progress;

  @override
  Widget build(BuildContext context) => ProgressMetricGrid(
    metrics: [
      ProgressMetricTile(
        icon: Icons.menu_book_outlined,
        label: 'Progress modul',
        value: adminProgressPercent(progress.overallLearningProgressPercent),
      ),
      ProgressMetricTile(
        icon: Icons.task_alt_outlined,
        label: 'Modul selesai',
        value: '${progress.completedModules}/${progress.publishedModules}',
      ),
      ProgressMetricTile(
        icon: Icons.article_outlined,
        label: 'Pelajaran selesai',
        value: '${progress.completedLessons}/${progress.totalPublishedLessons}',
      ),
      ProgressMetricTile(
        icon: Icons.quiz_outlined,
        label: 'Kuis selesai',
        value: '${progress.quizzesCompleted}/${progress.publishedQuizzes}',
      ),
    ],
  );
}

class StudentQuizMetricGrid extends StatelessWidget {
  const StudentQuizMetricGrid({super.key, required this.summary});
  final AdminQuizSummary summary;

  @override
  Widget build(BuildContext context) => ProgressMetricGrid(
    metrics: [
      ProgressMetricTile(
        icon: Icons.people_outline,
        label: 'Partisipasi',
        value: adminProgressPercent(summary.participationRatePercent),
      ),
      ProgressMetricTile(
        icon: Icons.task_alt_outlined,
        label: 'Penyelesaian',
        value: adminProgressPercent(summary.completionRatePercent),
      ),
      ProgressMetricTile(
        icon: Icons.emoji_events_outlined,
        label: 'Rata-rata nilai terbaik',
        value: adminProgressPercent(summary.averageBestScorePercent),
      ),
    ],
  );
}

class ClassMetricGrid extends StatelessWidget {
  const ClassMetricGrid({
    super.key,
    required this.summary,
    required this.speakingReports,
  });
  final AdminClassProgressSummary summary;
  final bool speakingReports;

  @override
  Widget build(BuildContext context) => ProgressMetricGrid(
    metrics: [
      ProgressMetricTile(
        icon: Icons.people_outline,
        label: 'Siswa aktif',
        value: '${summary.activeStudents}',
      ),
      ProgressMetricTile(
        icon: Icons.menu_book_outlined,
        label: 'Rata-rata modul',
        value: adminProgressPercent(summary.averageModuleProgressPercent),
      ),
      ProgressMetricTile(
        icon: Icons.quiz_outlined,
        label: 'Rata-rata kuis',
        value: adminProgressPercent(summary.averageBestFinalQuizScorePercent),
      ),
      ProgressMetricTile(
        icon: Icons.task_alt_outlined,
        label: 'Siswa selesai',
        value: '${summary.completedStudents}',
      ),
      ProgressMetricTile(
        icon: Icons.hourglass_empty,
        label: 'Siswa belum mulai',
        value: '${summary.notStartedStudents}',
      ),
      ProgressMetricTile(
        icon: Icons.schedule_outlined,
        label: 'Aktivitas terakhir',
        value: adminProgressDate(summary.lastActivityAt),
      ),
      ProgressMetricTile(
        icon: Icons.mic_none,
        label: 'Rata-rata Speaking',
        value: speakingReports ? '-' : 'Belum tersedia',
      ),
    ],
  );
}

class _PdfButton extends StatelessWidget {
  const _PdfButton({required this.onPressed, required this.label});
  final VoidCallback onPressed;
  final String label;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.picture_as_pdf),
      label: Text(label),
    ),
  );
}

class _Pager extends StatelessWidget {
  const _Pager({required this.meta, required this.onPage});
  final AdminProgressMeta meta;
  final ValueChanged<int> onPage;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      TextButton(
        onPressed: meta.currentPage > 1
            ? () => onPage(meta.currentPage - 1)
            : null,
        child: const Text('Sebelumnya'),
      ),
      Flexible(
        child: Text(
          'Halaman ${meta.currentPage} dari ${meta.lastPage}',
          textAlign: TextAlign.center,
        ),
      ),
      TextButton(
        onPressed: meta.currentPage < meta.lastPage
            ? () => onPage(meta.currentPage + 1)
            : null,
        child: const Text('Berikutnya'),
      ),
    ],
  );
}
