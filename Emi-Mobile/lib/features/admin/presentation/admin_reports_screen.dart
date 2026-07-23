import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../data/admin_progress_models.dart';
import '../data/admin_progress_providers.dart';
import '../data/admin_progress_repository.dart';
import 'admin_shell.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(adminProgressProvider);
    return AdminShell(
      title: 'Progress',
      child: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Error(
          onRetry: () => ref.read(adminProgressProvider.notifier).refresh(),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(adminProgressProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              Text(
                'Progress Siswa',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Text('Pantau progress belajar siswa dan kelas.'),
              const SizedBox(height: EmiSpacing.sm),
              Wrap(
                spacing: EmiSpacing.sm,
                runSpacing: EmiSpacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: () => _sharePdf(),
                    icon: const Icon(Icons.print, size: 24),
                    label: const Text('Cetak PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _shareCsv('progress/students', 'laporan-siswa.csv'),
                    icon: const Icon(Icons.share),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
              const SizedBox(height: EmiSpacing.md),
              Text(
                'Ringkasan Progress',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: EmiSpacing.sm),
              ProgressOverviewSummary(
                data.summary,
                speakingReports: data.speakingReports,
              ),
              const SizedBox(height: EmiSpacing.md),
              _Filters(search: search),
              const SizedBox(height: EmiSpacing.lg),
              const ProgressSectionHeader('Siswa'),
              if (data.students.items.isEmpty)
                const EmiCard(child: Text('Siswa tidak ditemukan.')),
              for (final student in data.students.items)
                ProgressStudentItem(
                  student: student,
                  onTap: () =>
                      context.push('/admin/reports/students/${student.id}'),
                ),
              _Pager(
                meta: data.students.meta,
                onPage: (page) =>
                    ref.read(adminProgressProvider.notifier).students(page),
              ),
              const SizedBox(height: EmiSpacing.lg),
              const ProgressSectionHeader('Kelas'),
              if (data.classes.items.isEmpty)
                const EmiCard(child: Text('Kelas tidak ditemukan.')),
              for (final item in data.classes.items)
                ProgressClassItem(
                  item: item,
                  onTap: () =>
                      context.push('/admin/reports/classes/${item.id}'),
                ),
              _Pager(
                meta: data.classes.meta,
                onPage: (page) =>
                    ref.read(adminProgressProvider.notifier).classes(page),
              ),
              const SizedBox(height: EmiSpacing.lg),
              _RemoteReports(
                repository: ref.read(adminProgressRepositoryProvider),
                onCsv: _shareCsv,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareCsv(String report, String name) async {
    try {
      final controller = ref.read(adminProgressProvider.notifier);
      final bytes = await ref
          .read(adminProgressRepositoryProvider)
          .csv(report, controller.filters);
      final file = File('${(await getTemporaryDirectory()).path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: name),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('CSV gagal disiapkan.')));
    }
  }

  Future<void> _sharePdf() async {
    try {
      final controller = ref.read(adminProgressProvider.notifier);
      final bytes = await ref
          .read(adminProgressRepositoryProvider)
          .pdf(filters: controller.filters);
      final file = File('${(await getTemporaryDirectory()).path}/progress.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Progress'),
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

class _RemoteReports extends StatelessWidget {
  const _RemoteReports({required this.repository, required this.onCsv});
  final AdminProgressRepository repository;
  final Future<void> Function(String, String) onCsv;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const ProgressSectionHeader('Sekolah'),
      FutureBuilder(
        future: repository.schoolReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const LinearProgressIndicator();
          if (snapshot.hasError)
            return const Text('Laporan sekolah belum bisa dimuat.');
          return Column(
            children: [
              for (final item
                  in snapshot.data?.items ?? const <AdminProgressSchool>[])
                EmiCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.activeClasses} kelas · ${item.activeStudents} siswa · Modul ${adminProgressPercent(item.averageLearningProgressPercent)} · Kuis ${adminProgressPercent(item.averageQuizScorePercent)}',
                    ),
                  ),
                ),
              OutlinedButton(
                onPressed: () =>
                    onCsv('progress/schools', 'laporan-sekolah.csv'),
                child: const Text('Export CSV Sekolah'),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: EmiSpacing.lg),
      const ProgressSectionHeader('Hasil Kuis'),
      FutureBuilder(
        future: repository.quizResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const LinearProgressIndicator();
          if (snapshot.hasError)
            return const Text('Hasil kuis belum bisa dimuat.');
          return Column(
            children: [
              for (final item
                  in snapshot.data?.items ?? const <AdminQuizResultRow>[])
                EmiCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item.studentName} · ${item.quizTitle}'),
                    subtitle: Text(
                      '${item.className} · ${item.attemptCount} percobaan · ${adminProgressPercent(item.bestScorePercent)} · ${adminProgressStatus(item.latestStatus)}',
                    ),
                  ),
                ),
              OutlinedButton(
                onPressed: () => onCsv('quiz-results', 'hasil-kuis.csv'),
                child: const Text('Export CSV Hasil Kuis'),
              ),
            ],
          );
        },
      ),
    ],
  );
}

class _Filters extends ConsumerWidget {
  const _Filters({required this.search});
  final TextEditingController search;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(adminProgressProvider.notifier);
    final schools =
        ref.watch(adminProgressSchoolsProvider).valueOrNull ?? const [];
    final classes =
        ref
            .watch(adminProgressClassesProvider(controller.filters.schoolId))
            .valueOrNull ??
        const [];
    void apply({
      String? school,
      String? schoolClass,
      String? learningStatus,
      String? quizStatus,
    }) => controller.apply(
      AdminProgressFilters(
        search: search.text,
        schoolId: school ?? controller.filters.schoolId,
        classId: schoolClass,
        learningStatus: learningStatus ?? controller.filters.learningStatus,
        quizStatus: quizStatus ?? controller.filters.quizStatus,
      ),
    );
    return Column(
      children: [
        TextField(
          controller: search,
          decoration: const InputDecoration(
            labelText: 'Cari siswa atau kelas',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (_) => apply(schoolClass: controller.filters.classId),
        ),
        const SizedBox(height: EmiSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: controller.filters.schoolId,
          decoration: const InputDecoration(
            labelText: 'Sekolah',
            prefixIcon: Icon(Icons.school_outlined, size: 24),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Semua sekolah')),
            ...schools.map(
              (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
            ),
          ],
          onChanged: (value) {
            ref.invalidate(adminProgressClassesProvider);
            apply(school: value);
          },
        ),
        const SizedBox(height: EmiSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: controller.filters.classId,
          decoration: const InputDecoration(
            labelText: 'Kelas',
            prefixIcon: Icon(Icons.groups_outlined, size: 24),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Semua kelas')),
            ...classes.map(
              (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
            ),
          ],
          onChanged: (value) => apply(schoolClass: value),
        ),
        const SizedBox(height: EmiSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: controller.filters.learningStatus,
          decoration: const InputDecoration(
            labelText: 'Status belajar',
            prefixIcon: Icon(Icons.menu_book_outlined, size: 24),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('Semua status')),
            DropdownMenuItem(value: 'not_started', child: Text('Belum mulai')),
            DropdownMenuItem(
              value: 'in_progress',
              child: Text('Sedang belajar'),
            ),
            DropdownMenuItem(value: 'completed', child: Text('Selesai')),
          ],
          onChanged: (value) => apply(
            schoolClass: controller.filters.classId,
            learningStatus: value,
          ),
        ),
        const SizedBox(height: EmiSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: controller.filters.quizStatus,
          decoration: const InputDecoration(
            labelText: 'Status kuis',
            prefixIcon: Icon(Icons.quiz_outlined, size: 24),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('Semua status')),
            DropdownMenuItem(value: 'not_started', child: Text('Belum mulai')),
            DropdownMenuItem(
              value: 'in_progress',
              child: Text('Sedang berjalan'),
            ),
            DropdownMenuItem(value: 'completed', child: Text('Selesai')),
          ],
          onChanged: (value) =>
              apply(schoolClass: controller.filters.classId, quizStatus: value),
        ),
        const SizedBox(height: EmiSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              search.clear();
              controller.apply(const AdminProgressFilters());
            },
            icon: const Icon(Icons.clear),
            label: const Text('Hapus filter'),
          ),
        ),
      ],
    );
  }
}

class ProgressOverviewSummary extends StatelessWidget {
  const ProgressOverviewSummary(
    this.data, {
    super.key,
    required this.speakingReports,
  });
  final AdminProgressSummary data;
  final bool speakingReports;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 720 ? 4 : 2;
      final width =
          (constraints.maxWidth - EmiSpacing.sm * (columns - 1)) / columns;
      return Wrap(
        spacing: EmiSpacing.sm,
        runSpacing: EmiSpacing.sm,
        children: [
          SizedBox(
            width: width,
            child: ProgressMetricTile(
              icon: Icons.people_outline,
              label: 'Siswa aktif',
              value: '${data.activeStudents}',
            ),
          ),
          SizedBox(
            width: width,
            child: ProgressMetricTile(
              icon: Icons.menu_book_outlined,
              label: 'Rata-rata modul',
              value: adminProgressPercent(data.averageModuleProgressPercent),
            ),
          ),
          SizedBox(
            width: width,
            child: ProgressMetricTile(
              icon: Icons.quiz_outlined,
              label: 'Rata-rata kuis akhir',
              value: adminProgressPercent(
                data.averageBestFinalQuizScorePercent,
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: ProgressMetricTile(
              icon: Icons.mic_none,
              label: 'Rata-rata Speaking',
              value: speakingReports ? '-' : 'Belum tersedia',
            ),
          ),
        ],
      );
    },
  );
}

class ProgressMetricTile extends StatelessWidget {
  const ProgressMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 180,
    child: EmiCard(
      padding: const EdgeInsets.all(EmiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28),
          const Spacer(),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

class ProgressSectionHeader extends StatelessWidget {
  const ProgressSectionHeader(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
    child: Text(label, style: Theme.of(context).textTheme.titleLarge),
  );
}

class ProgressStatusBadge extends StatelessWidget {
  const ProgressStatusBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(EmiRadii.card),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EmiSpacing.sm,
        vertical: 4,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    ),
  );
}

class ProgressInfoRow extends StatelessWidget {
  const ProgressInfoRow({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: EmiSpacing.sm),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

class ProgressStudentItem extends StatelessWidget {
  const ProgressStudentItem({
    super.key,
    required this.student,
    required this.onTap,
  });
  final AdminProgressStudent student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
    child: InkWell(
      onTap: onTap,
      child: EmiCard(
        padding: const EdgeInsets.all(EmiSpacing.sm),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_outline, size: 24)),
                const SizedBox(width: EmiSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${student.schoolName} • ${student.className}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 24),
              ],
            ),
            ProgressInfoRow(
              icon: Icons.menu_book_outlined,
              label:
                  '${student.completedModules}/${student.publishedModules} modul • ${adminProgressPercent(student.overallLearningProgressPercent)}',
            ),
            ProgressInfoRow(
              icon: Icons.quiz_outlined,
              label:
                  'Kuis ${adminProgressPercent(student.averageBestQuizScorePercent)}',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ProgressStatusBadge(
                adminProgressStatus(student.learningStatus),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProgressClassItem extends StatelessWidget {
  const ProgressClassItem({super.key, required this.item, required this.onTap});
  final AdminProgressClass item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
    child: InkWell(
      onTap: onTap,
      child: EmiCard(
        padding: const EdgeInsets.all(EmiSpacing.sm),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.groups_outlined, size: 24),
                ),
                const SizedBox(width: EmiSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        item.schoolName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 24),
              ],
            ),
            ProgressInfoRow(
              icon: Icons.people_outline,
              label: '${item.activeStudents} siswa aktif',
            ),
            ProgressInfoRow(
              icon: Icons.menu_book_outlined,
              label:
                  '${item.completedModuleCount}/${item.publishedModules} modul • ${adminProgressPercent(item.averageLearningProgressPercent)}',
            ),
            ProgressInfoRow(
              icon: Icons.quiz_outlined,
              label:
                  '${item.studentsParticipatedInQuiz} peserta • ${adminProgressPercent(item.averageQuizScorePercent)}',
            ),
          ],
        ),
      ),
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
      Text('Halaman ${meta.currentPage} dari ${meta.lastPage}'),
      TextButton(
        onPressed: meta.currentPage < meta.lastPage
            ? () => onPage(meta.currentPage + 1)
            : null,
        child: const Text('Berikutnya'),
      ),
    ],
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: EmiCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Progress gagal dimuat.'),
          OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    ),
  );
}
