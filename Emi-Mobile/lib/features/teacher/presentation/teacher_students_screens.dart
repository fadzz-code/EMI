import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../data/teacher_providers.dart';
import '../data/teacher_repository.dart';
import 'teacher_shell.dart';

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
            Text(
              'Progress Siswa',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: EmiSpacing.xs),
            const Text('Pantau perkembangan belajar siswa di kelas Anda.'),
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
              const SizedBox(height: EmiSpacing.lg),
              Text('Kelas', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: EmiSpacing.md),
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
              data: (klass) => EmiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      klass.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(klass.schoolName ?? 'Sekolah belum tersedia'),
                    Text('Siswa aktif: ${klass.studentsCount}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: EmiSpacing.md),
            TextField(
              key: const Key('teacherProgressStudentSearch'),
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Cari siswa',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
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
              Text(row.name, style: Theme.of(context).textTheme.headlineMedium),
              Text('${row.schoolName} • ${row.className}'),
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
              const SizedBox(height: EmiSpacing.md),
              EmiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail pembelajaran',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
              const EmiCard(child: Text('Progress speaking belum tersedia.')),
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
            EmiCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(metric.$3),
                  const SizedBox(height: EmiSpacing.xs),
                  Text(metric.$1, textAlign: TextAlign.center),
                  Text(
                    metric.$2,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
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
  Widget build(BuildContext context) => EmiCard(
    child: Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
        title: Text(klass.name),
        subtitle: Text(
          '${klass.schoolName ?? 'Sekolah belum tersedia'}\n${klass.studentsCount} siswa',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/teacher/progress/classes/${klass.id}'),
      ),
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
                if (page.lastPage > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: page.currentPage > 1
                            ? () => onPage(page.currentPage - 1)
                            : null,
                        child: const Text('Sebelumnya'),
                      ),
                      Flexible(
                        child: Text(
                          'Halaman ${page.currentPage} dari ${page.lastPage}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      TextButton(
                        onPressed: page.currentPage < page.lastPage
                            ? () => onPage(page.currentPage + 1)
                            : null,
                        child: const Text('Berikutnya'),
                      ),
                    ],
                  ),
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
  Widget build(BuildContext context) => EmiCard(
    child: Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(student.name),
        subtitle: Text(
          '${student.className}\nModul ${student.completedModules}/${student.publishedModules} • Materi ${student.completedLessons}/${student.publishedLessons} • Kuis ${student.completedQuizzes}/${student.publishedQuizzes}',
        ),
        isThreeLine: true,
        trailing: Text(_percent(student.percent)),
        onTap: () =>
            context.push('/teacher/progress/students/${student.studentId}'),
      ),
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
