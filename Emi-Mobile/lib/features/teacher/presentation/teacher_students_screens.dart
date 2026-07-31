import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../data/teacher_providers.dart';
import '../data/teacher_repository.dart';
import 'teacher_shell.dart';
import 'teacher_style.dart';
import 'teacher_widgets.dart';

class TeacherStudentsScreen extends ConsumerStatefulWidget {
  const TeacherStudentsScreen({super.key});
  @override
  ConsumerState<TeacherStudentsScreen> createState() => _TeacherStudentsState();
}

class _TeacherStudentsState extends ConsumerState<TeacherStudentsScreen> {
  int page = 1;
  String search = '';
  @override
  Widget build(BuildContext context) {
    final query = (page: page, search: search);
    return TeacherShell(
      title: 'Daftar Siswa',
      child: _ProgressResult(
        value: ref.watch(teacherStudentProgressProvider(query)),
        onRefresh: () =>
            ref.refresh(teacherStudentProgressProvider(query).future),
        onRetry: () => ref.invalidate(teacherStudentProgressProvider(query)),
        onPage: (value) => setState(() => page = value),
      ),
    );
  }
}

class TeacherProgressScreen extends ConsumerStatefulWidget {
  const TeacherProgressScreen({super.key});
  @override
  ConsumerState<TeacherProgressScreen> createState() => _TeacherProgressState();
}

class _TeacherProgressState extends ConsumerState<TeacherProgressScreen> {
  static const query = (page: 1, search: '');
  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(teacherClassesProvider(query));
    final progress = ref.watch(teacherStudentProgressProvider(query));
    return TeacherShell(
      title: 'Progress',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teacherClassesProvider(query));
          ref.invalidate(teacherStudentProgressProvider(query));
          await Future.wait([
            ref.read(teacherClassesProvider(query).future),
            ref.read(teacherStudentProgressProvider(query).future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            const TeacherPageHeader(
              icon: Icons.trending_up_outlined,
              title: 'Progress Siswa',
              subtitle: 'Pantau perkembangan belajar siswa di kelas Anda.',
            ),
            const SizedBox(height: EmiSpacing.lg),
            if (classes.isLoading || progress.isLoading)
              const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (classes.hasError || progress.hasError)
              FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Gagal memuat progress',
                message: 'Periksa koneksi internet, lalu coba lagi.',
                onRetry: () =>
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.invalidate(teacherClassesProvider(query));
                      ref.invalidate(teacherStudentProgressProvider(query));
                    }),
              )
            else ...[
              _SummaryGrid(
                classes: classes.requireValue.total,
                students: progress.requireValue.total,
              ),
              TeacherSectionHeader('Kelas', icon: Icons.groups_outlined),
              if (classes.requireValue.items.isEmpty)
                const FriendlyState(
                  icon: Icons.groups_outlined,
                  title: 'Kelas belum tersedia',
                  message: 'Belum ada kelas aktif yang dapat dipantau.',
                )
              else
                for (final klass in classes.requireValue.items) ...[
                  _ClassProgressCard(klass: klass),
                  const SizedBox(height: EmiSpacing.sm),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

class TeacherClassProgressScreen extends ConsumerStatefulWidget {
  const TeacherClassProgressScreen({super.key, required this.classId});
  final String classId;
  @override
  ConsumerState<TeacherClassProgressScreen> createState() =>
      _TeacherClassProgressState();
}

class _TeacherClassProgressState
    extends ConsumerState<TeacherClassProgressScreen> {
  final controller = TextEditingController();
  Timer? debounce;
  int page = 1;
  String search = '';
  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = (classId: widget.classId, page: page, search: search);
    final detail = ref.watch(teacherClassDetailProvider(widget.classId));
    final progress = ref.watch(teacherClassProgressProvider(query));
    return TeacherShell(
      title: 'Progress Kelas',
      fallbackRoute: '/teacher/progress',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teacherClassDetailProvider(widget.classId));
          ref.invalidate(teacherClassProgressProvider(query));
          await ref.read(teacherClassDetailProvider(widget.classId).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            detail.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Gagal memuat detail kelas',
                message: 'Periksa koneksi internet, lalu coba lagi.',
                onRetry: () =>
                    ref.invalidate(teacherClassDetailProvider(widget.classId)),
              ),
              data: (klass) => TeacherPageHeader(
                icon: Icons.groups_outlined,
                title: klass.name,
                subtitle:
                    '${klass.schoolName ?? 'Sekolah belum tersedia'} • ${klass.studentsCount} siswa aktif',
              ),
            ),
            const SizedBox(height: EmiSpacing.md),
            TeacherSearchField(
              fieldKey: const Key('teacherProgressStudentSearch'),
              controller: controller,
              label: 'Cari siswa',
              onClear: () {
                controller.clear();
                setState(() {
                  search = '';
                  page = 1;
                });
              },
              onChanged: (value) {
                setState(() {});
                debounce?.cancel();
                debounce = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) {
                    setState(() {
                      search = value.trim();
                      page = 1;
                    });
                  }
                });
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            _ProgressResult(
              value: progress,
              onRefresh: () =>
                  ref.refresh(teacherClassProgressProvider(query).future),
              onRetry: () =>
                  ref.invalidate(teacherClassProgressProvider(query)),
              onPage: (value) => setState(() => page = value),
              embedded: true,
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherStudentDetailScreen extends ConsumerWidget {
  const TeacherStudentDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(teacherStudentDetailProvider(id));
    return TeacherShell(
      title: 'Detail Progress Siswa',
      fallbackRoute: '/teacher/progress',
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(teacherStudentDetailProvider(id).future),
        child: value.when(
          loading: () => const _State(child: CircularProgressIndicator()),
          error: (_, _) => _State(
            child: FriendlyState(
              icon: Icons.wifi_off_outlined,
              title: 'Gagal memuat detail progress',
              message: 'Periksa koneksi internet, lalu coba lagi.',
              onRetry: () => ref.invalidate(teacherStudentDetailProvider(id)),
            ),
          ),
          data: (row) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              TeacherPageHeader(
                icon: Icons.person_outline,
                title: row.name,
                subtitle: '${row.schoolName} • ${row.className}',
              ),
              const SizedBox(height: EmiSpacing.md),
              _MetricGrid(
                metrics: [
                  (
                    'Progress belajar',
                    _percent(row.percent),
                    Icons.trending_up_outlined,
                  ),
                  (
                    'Modul selesai',
                    '${row.completedModules}/${row.publishedModules}',
                    Icons.menu_book_outlined,
                  ),
                  (
                    'Materi selesai',
                    '${row.completedLessons}/${row.publishedLessons}',
                    Icons.article_outlined,
                  ),
                  (
                    'Kuis selesai',
                    '${row.completedQuizzes}/${row.publishedQuizzes}',
                    Icons.quiz_outlined,
                  ),
                ],
              ),
              TeacherSectionHeader(
                'Detail Pembelajaran',
                icon: Icons.school_outlined,
              ),
              TeacherListCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${_status(row.learningStatus)}'),
                    Text('Modul dimulai: ${row.startedModules}'),
                    Text('Kuis dicoba: ${row.attemptedQuizzes}'),
                    Text(
                      'Rata-rata nilai kuis: ${row.averageQuizScore == null ? 'Belum tersedia' : _percent(row.averageQuizScore!)}',
                    ),
                    Text(
                      'Aktivitas belajar terakhir: ${_date(row.lastLearningActivityAt)}',
                    ),
                    Text(
                      'Aktivitas kuis terakhir: ${_date(row.lastQuizActivityAt)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EmiSpacing.md),
              TeacherListCard(
                child: Text(
                  'Progress speaking belum tersedia.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EmiColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.classes, required this.students});
  final int classes;
  final int students;
  @override
  Widget build(BuildContext context) => _MetricGrid(
    metrics: [
      ('Kelas', '$classes', Icons.groups_outlined),
      ('Siswa', '$students', Icons.people_outline),
      ('Modul selesai', 'Belum tersedia', Icons.task_alt_outlined),
      ('Rata-rata nilai', 'Belum tersedia', Icons.insights_outlined),
    ],
  );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final List<(String, String, IconData)> metrics;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 720 ? 4 : 2;
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: EmiSpacing.sm,
        mainAxisSpacing: EmiSpacing.sm,
        mainAxisExtent: 184,
        children: [
          for (final metric in metrics)
            TeacherListCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: TeacherStyle.tint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(metric.$3, color: EmiColors.primary),
                  ),
                  const SizedBox(height: EmiSpacing.xs),
                  Text(
                    metric.$1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: TeacherStyle.inkMuted),
                  ),
                  Text(
                    metric.$2,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: TeacherStyle.ink),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

class _ClassProgressCard extends StatelessWidget {
  const _ClassProgressCard({required this.klass});
  final TeacherClass klass;
  @override
  Widget build(BuildContext context) => TeacherListCard(
    padding: EdgeInsets.zero,
    child: ListTile(
      onTap: () => context.push('/teacher/progress/classes/${klass.id}'),
      leading: CircleAvatar(
        backgroundColor: TeacherStyle.tint,
        foregroundColor: EmiColors.primary,
        child: const Icon(Icons.groups_outlined),
      ),
      title: Text(klass.name, style: const TextStyle(color: TeacherStyle.ink)),
      subtitle: Text(
        '${klass.schoolName ?? 'Sekolah belum tersedia'}\n${klass.studentsCount} siswa',
        style: const TextStyle(color: TeacherStyle.inkMuted),
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right, color: TeacherStyle.inkMuted),
    ),
  );
}

class _ProgressResult extends StatelessWidget {
  const _ProgressResult({
    required this.value,
    required this.onRefresh,
    required this.onRetry,
    required this.onPage,
    this.embedded = false,
  });
  final AsyncValue<TeacherStudentProgressPage> value;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<int> onPage;
  final bool embedded;
  @override
  Widget build(BuildContext context) {
    final body = value.when(
      loading: () => const _State(child: CircularProgressIndicator()),
      error: (_, _) => _State(
        child: FriendlyState(
          icon: Icons.wifi_off_outlined,
          title: 'Gagal memuat progress siswa',
          message: 'Periksa koneksi internet, lalu coba lagi.',
          onRetry: onRetry,
        ),
      ),
      data: (page) => page.items.isEmpty
          ? const FriendlyState(
              icon: Icons.people_outline,
              title: 'Progress siswa belum tersedia',
              message: 'Belum ada siswa atau data yang cocok.',
            )
          : Column(
              children: [
                for (final row in page.items) ...[
                  _StudentCard(student: row),
                  const SizedBox(height: EmiSpacing.sm),
                ],
                if (page.lastPage > 1) ...[
                  const SizedBox(height: EmiSpacing.xs),
                  TeacherPaginationBar(
                    currentPage: page.currentPage,
                    lastPage: page.lastPage,
                    onPrevious: page.currentPage > 1
                        ? () => onPage(page.currentPage - 1)
                        : null,
                    onNext: page.currentPage < page.lastPage
                        ? () => onPage(page.currentPage + 1)
                        : null,
                  ),
                ],
              ],
            ),
    );
    if (embedded) return body;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [body],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});
  final TeacherStudentProgress student;
  @override
  Widget build(BuildContext context) => TeacherListCard(
    padding: EdgeInsets.zero,
    onTap: () =>
        context.push('/teacher/progress/students/${student.studentId}'),
    child: ListTile(
      title: Text(
        student.name,
        style: const TextStyle(color: TeacherStyle.ink),
      ),
      subtitle: Text(
        '${student.className}\nModul ${student.completedModules}/${student.publishedModules} • Materi ${student.completedLessons}/${student.publishedLessons} • Kuis ${student.completedQuizzes}/${student.publishedQuizzes}',
        style: const TextStyle(color: TeacherStyle.inkMuted),
      ),
      isThreeLine: true,
      trailing: TeacherStatusChip(label: _percent(student.percent)),
    ),
  );
}

class _State extends StatelessWidget {
  const _State({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 420, child: Center(child: child));
}

String _percent(num value) =>
    '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%';
String _status(String value) => switch (value) {
  'completed' => 'Selesai',
  'in_progress' => 'Sedang berjalan',
  'not_started' => 'Belum mulai',
  _ => 'Belum tersedia',
};
String _date(DateTime? value) => value == null
    ? 'Belum tersedia'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
