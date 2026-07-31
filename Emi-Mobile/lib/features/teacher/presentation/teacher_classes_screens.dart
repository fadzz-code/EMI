import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../data/teacher_providers.dart';
import '../data/teacher_quiz_models.dart';
import '../data/teacher_repository.dart';
import 'teacher_shell.dart';
import 'teacher_style.dart';
import 'teacher_widgets.dart';

class TeacherClassesScreen extends ConsumerStatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  ConsumerState<TeacherClassesScreen> createState() =>
      _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends ConsumerState<TeacherClassesScreen> {
  final searchController = TextEditingController();
  int page = 1;
  String search = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = (page: page, search: search);
    final classes = ref.watch(teacherClassesProvider(query));
    return TeacherShell(
      title: 'Kelas Saya',
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(teacherClassesProvider(query).future),
        child: ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            const TeacherPageHeader(
              icon: Icons.groups_outlined,
              title: 'Kelas Saya',
              subtitle: 'Guru mengajar dari satu kelas aktif.',
            ),
            const SizedBox(height: EmiSpacing.md),
            TeacherSearchField(
              fieldKey: const Key('teacherClassSearch'),
              controller: searchController,
              label: 'Cari kelas',
              onSubmitted: (value) => setState(() {
                search = value.trim();
                page = 1;
              }),
            ),
            const SizedBox(height: EmiSpacing.md),
            classes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Gagal memuat kelas guru',
                message: 'Periksa koneksi internet, lalu coba lagi.',
                onRetry: () => ref.invalidate(teacherClassesProvider(query)),
              ),
              data: (result) => result.items.isEmpty
                  ? const FriendlyState(
                      icon: Icons.groups_outlined,
                      title: 'Kelas belum tersedia',
                      message: 'Tidak ada kelas aktif yang cocok.',
                    )
                  : Column(
                      children: [
                        Wrap(
                          spacing: EmiSpacing.sm,
                          runSpacing: EmiSpacing.sm,
                          children: [
                            TeacherStatChip(
                              label: 'Kelas aktif',
                              value: '${result.total}',
                            ),
                            TeacherStatChip(
                              label: 'Siswa halaman ini',
                              value:
                                  '${result.items.fold<int>(0, (sum, item) => sum + item.studentsCount)}',
                            ),
                          ],
                        ),
                        const SizedBox(height: EmiSpacing.md),
                        for (final klass in result.items) ...[
                          _ClassCard(klass: klass),
                          const SizedBox(height: EmiSpacing.sm),
                        ],
                        if (result.lastPage > 1) ...[
                          const SizedBox(height: EmiSpacing.xs),
                          TeacherPaginationBar(
                            previousKey: const Key('teacherClassesPrevious'),
                            nextKey: const Key('teacherClassesNext'),
                            currentPage: result.currentPage,
                            lastPage: result.lastPage,
                            onPrevious: result.currentPage > 1
                                ? () => setState(() => page--)
                                : null,
                            onNext: result.currentPage < result.lastPage
                                ? () => setState(() => page++)
                                : null,
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherClassDetailScreen extends ConsumerStatefulWidget {
  const TeacherClassDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<TeacherClassDetailScreen> createState() =>
      _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState
    extends ConsumerState<TeacherClassDetailScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final id = widget.id;
    final detail = ref.watch(teacherClassDetailProvider(id));
    return TeacherShell(
      title: 'Detail Kelas',
      fallbackRoute: '/teacher/classes',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teacherClassDetailProvider(id));
          ref.invalidate(
            teacherClassStudentsProvider((classId: id, page: 1, search: '')),
          );
          ref.invalidate(teacherModulesProvider(id));
          ref.invalidate(teacherClassQuizzesProvider(id));
          ref.invalidate(
            teacherClassProgressProvider((classId: id, page: 1, search: '')),
          );
          await ref.read(teacherClassDetailProvider(id).future);
        },
        child: detail.when(
          loading: () => const _Scrollable(child: CircularProgressIndicator()),
          error: (_, _) => _Scrollable(
            child: FriendlyState(
              icon: Icons.wifi_off_outlined,
              title: 'Gagal memuat detail kelas',
              message: 'Periksa koneksi internet, lalu coba lagi.',
              onRetry: () => ref.invalidate(teacherClassDetailProvider(id)),
            ),
          ),
          data: (klass) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              Container(
                padding: const EdgeInsets.all(EmiSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [EmiColors.primary, Color(0xFFFFA968)],
                  ),
                  borderRadius: BorderRadius.circular(TeacherStyle.heroRadius),
                  boxShadow: TeacherStyle.heroShadow(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TeacherStatusChip(
                      label: _status(klass.status),
                      color: Colors.white,
                      textColor: EmiColors.primary,
                    ),
                    const SizedBox(height: EmiSpacing.sm),
                    Text(
                      klass.name,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: EmiSpacing.xs),
                    Text(
                      '${_optional(klass.schoolName)} • Tahun ajaran ${_optional(klass.academicYear)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EmiSpacing.lg),
              _DetailStats(id: id, klass: klass),
              const SizedBox(height: EmiSpacing.lg),
              TeacherSegmentedTabs(
                labels: const [
                  'Ringkasan',
                  'Siswa',
                  'Modul',
                  'Kuis',
                  'Budaya Mekongga',
                ],
                selected: tab,
                onSelected: (value) => setState(() => tab = value),
              ),
              if (tab == 4) ...[
                const SizedBox(height: EmiSpacing.md),
                FilledButton.icon(
                  onPressed: () => context.push('/teacher/culture?classId=$id'),
                  icon: const Icon(Icons.public),
                  label: const Text('Kelola Budaya Kelas'),
                ),
              ],
              const SizedBox(height: EmiSpacing.md),
              switch (tab) {
                0 => _Summary(id: id),
                1 => _Students(id: id),
                2 => _Modules(id: id),
                3 => _Quizzes(id: id),
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.klass});
  final TeacherClass klass;

  @override
  Widget build(BuildContext context) => TeacherListCard(
    padding: const EdgeInsets.all(EmiSpacing.md),
    onTap: () => context.push('/teacher/classes/${klass.id}'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeacherStatusChip(label: _status(klass.status)),
        const SizedBox(height: EmiSpacing.sm),
        Text(klass.name, style: Theme.of(context).textTheme.titleLarge),
        Text(_optional(klass.schoolName)),
        const SizedBox(height: EmiSpacing.md),
        Wrap(
          spacing: EmiSpacing.sm,
          runSpacing: EmiSpacing.sm,
          children: [
            TeacherStatChip(
              label: 'Tahun ajaran',
              value: _optional(klass.academicYear),
            ),
            TeacherStatChip(label: 'Siswa', value: '${klass.studentsCount}'),
            TeacherStatChip(
              label: 'Guru aktif',
              value: _optional(klass.teacherName),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DetailStats extends ConsumerWidget {
  const _DetailStats({required this.id, required this.klass});
  final String id;
  final TeacherClass klass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref
        .watch(teacherClassStudentsProvider((classId: id, page: 1, search: '')))
        .valueOrNull;
    final modules = ref.watch(teacherModulesProvider(id)).valueOrNull;
    return Wrap(
      spacing: EmiSpacing.sm,
      runSpacing: EmiSpacing.sm,
      children: [
        TeacherStatChip(label: 'Sekolah', value: _optional(klass.schoolName)),
        TeacherStatChip(label: 'Guru', value: _optional(klass.teacherName)),
        TeacherStatChip(
          label: 'Siswa',
          value:
              '${klass.studentsCount == 0 ? students?.items.length ?? 0 : klass.studentsCount}',
        ),
        TeacherStatChip(label: 'Modul', value: '${modules?.length ?? 0}'),
      ],
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TeacherSectionHeader(
        'Siswa Kelas',
        icon: Icons.people_outline,
        leading: false,
      ),
      _StudentList(id: id, compact: true),
      TeacherSectionHeader('Progress Belajar', icon: Icons.trending_up),
      _ProgressList(id: id, limit: 8),
      TeacherSectionHeader('Modul Kelas', icon: Icons.menu_book_outlined),
      _ModuleList(id: id, compact: true),
      TeacherSectionHeader('Kuis Kelas', icon: Icons.quiz_outlined),
      _QuizList(id: id, compact: true),
      const SizedBox(height: EmiSpacing.sm),
      TeacherListCard(
        child: Text(
          'Detail kelas ini berfungsi sebagai ringkasan cepat. Untuk mengelola materi atau kuis, gunakan menu Modul dan Kuis.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: EmiColors.textSecondary),
        ),
      ),
    ],
  );
}

class _Students extends ConsumerStatefulWidget {
  const _Students({required this.id});
  final String id;

  @override
  ConsumerState<_Students> createState() => _StudentsState();
}

class _StudentsState extends ConsumerState<_Students> {
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
    final query = (classId: widget.id, page: page, search: search);
    final students = ref.watch(teacherClassStudentsProvider(query));
    return Column(
      children: [
        TeacherSearchField(
          fieldKey: const Key('teacherClassStudentSearch'),
          controller: controller,
          label: 'Cari siswa di kelas ini',
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
        students.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => FriendlyState(
            icon: Icons.people_outline,
            title: 'Gagal memuat siswa',
            message: 'Coba muat kembali daftar siswa.',
            onRetry: () => ref.invalidate(teacherClassStudentsProvider(query)),
          ),
          data: (result) => result.items.isEmpty
              ? FriendlyState(
                  icon: Icons.people_outline,
                  title: search.isEmpty
                      ? 'Siswa kosong'
                      : 'Siswa tidak ditemukan',
                  message: search.isEmpty
                      ? 'Belum ada siswa aktif pada kelas ini.'
                      : 'Coba kata pencarian lain.',
                )
              : Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TeacherStatChip(
                        label: 'Total siswa',
                        value: '${result.total}',
                      ),
                    ),
                    const SizedBox(height: EmiSpacing.md),
                    _StudentCards(students: result.items, progress: const []),
                    if (result.lastPage > 1) ...[
                      const SizedBox(height: EmiSpacing.xs),
                      TeacherPaginationBar(
                        currentPage: result.currentPage,
                        lastPage: result.lastPage,
                        onPrevious: result.currentPage > 1
                            ? () => setState(() => page--)
                            : null,
                        onNext: result.currentPage < result.lastPage
                            ? () => setState(() => page++)
                            : null,
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _StudentList extends ConsumerWidget {
  const _StudentList({required this.id, required this.compact});
  final String id;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(
      teacherClassStudentsProvider((classId: id, page: 1, search: '')),
    );
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Siswa belum bisa dimuat.'),
      data: (page) => page.items.isEmpty
          ? const Text('Belum ada siswa aktif di kelas ini.')
          : _StudentCards(
              students: page.items,
              progress: const [],
              compact: compact,
            ),
    );
  }
}

class _StudentCards extends StatelessWidget {
  const _StudentCards({
    required this.students,
    required this.progress,
    this.compact = false,
  });
  final List<TeacherClassStudent> students;
  final List<TeacherStudentProgress> progress;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final student in students) ...[
        Builder(
          builder: (context) {
            TeacherStudentProgress? row;
            for (final item in progress) {
              if (item.studentId == student.id || item.name == student.name) {
                row = item;
              }
            }
            return TeacherListCard(
              onTap: () => context.push('/teacher/students/${student.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(student.email),
                  Text(_status(student.status)),
                  if (!compact) ...[
                    const SizedBox(height: EmiSpacing.sm),
                    Text('Bergabung: ${_date(student.joinedAt)}'),
                    Text(
                      'Progress: ${row == null ? 'Belum tersedia' : '${row.percent.toStringAsFixed(0)}%'}',
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: EmiSpacing.sm),
      ],
    ],
  );
}

class _ProgressList extends ConsumerWidget {
  const _ProgressList({required this.id, this.limit});
  final String id;
  final int? limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(teacherClassProgressProvider((classId: id, page: 1, search: '')))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Text('Progress belum bisa dimuat.'),
        data: (page) {
          final rows = page.items;
          final shown = limit == null ? rows : rows.take(limit!).toList();
          if (shown.isEmpty) {
            return const Text(
              'Belum ada laporan progress siswa untuk kelas ini.',
            );
          }
          return Column(
            children: [
              for (final row in shown) ...[
                TeacherListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TeacherStatusChip(
                            label: '${row.percent.toStringAsFixed(0)}%',
                          ),
                        ],
                      ),
                      Text(row.className),
                      Text(
                        'Modul: ${row.completedModules} / ${row.publishedModules} • Kuis selesai: ${row.completedQuizzes}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: EmiSpacing.sm),
              ],
            ],
          );
        },
      );
}

class _Modules extends ConsumerWidget {
  const _Modules({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(teacherModulesProvider(id));
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => FriendlyState(
        icon: Icons.menu_book_outlined,
        title: 'Gagal memuat modul',
        message: 'Coba lagi.',
        onRetry: () => ref.invalidate(teacherModulesProvider(id)),
      ),
      data: (items) => items.isEmpty
          ? const FriendlyState(
              icon: Icons.menu_book_outlined,
              title: 'Modul belum tersedia',
              message: 'Belum ada modul kelas yang bisa dikelola.',
            )
          : Column(
              children: [
                Wrap(
                  spacing: EmiSpacing.sm,
                  runSpacing: EmiSpacing.sm,
                  children: [
                    TeacherStatChip(
                      label: 'Total modul',
                      value: '${items.length}',
                    ),
                    TeacherStatChip(
                      label: 'Modul terbit',
                      value:
                          '${items.where((item) => item.status == 'published').length}',
                    ),
                  ],
                ),
                const SizedBox(height: EmiSpacing.md),
                _ModuleCards(items: items),
              ],
            ),
    );
  }
}

class _ModuleList extends ConsumerWidget {
  const _ModuleList({required this.id, required this.compact});
  final String id;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(teacherModulesProvider(id))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Text('Modul belum bisa dimuat.'),
        data: (items) => items.isEmpty
            ? const Text('Belum ada modul kelas yang bisa dikelola.')
            : _ModuleCards(items: items, compact: compact),
      );
}

class _ModuleCards extends StatelessWidget {
  const _ModuleCards({required this.items, this.compact = false});
  final List<TeacherModule> items;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final item in items) ...[
        TeacherListCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TeacherStatusChip(label: _status(item.status)),
              const SizedBox(height: EmiSpacing.xs),
              Text(item.title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                item.description.isEmpty ? 'Belum tersedia' : item.description,
              ),
              if (!compact) ...[
                Text('Lesson: ${item.lessons.length}'),
                const SizedBox(height: EmiSpacing.sm),
                OutlinedButton(
                  onPressed: () =>
                      context.push('/teacher/modules/${item.id}/edit'),
                  child: const Text('Edit Modul'),
                ),
                for (final lesson in item.lessons)
                  ExpansionTile(
                    title: Text(lesson.title),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(EmiSpacing.sm),
                        child: Text(
                          lesson.description.isEmpty
                              ? lesson.contentBody
                              : lesson.description,
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: EmiSpacing.sm),
      ],
    ],
  );
}

class _Quizzes extends ConsumerWidget {
  const _Quizzes({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(teacherClassQuizzesProvider(id))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => FriendlyState(
          icon: Icons.quiz_outlined,
          title: 'Gagal memuat kuis',
          message: 'Coba lagi.',
          onRetry: () => ref.invalidate(teacherClassQuizzesProvider(id)),
        ),
        data: (page) => page.items.isEmpty
            ? const FriendlyState(
                icon: Icons.quiz_outlined,
                title: 'Kuis belum tersedia',
                message: 'Belum ada kuis kelas yang bisa dikelola.',
              )
            : Column(
                children: [
                  Wrap(
                    spacing: EmiSpacing.sm,
                    runSpacing: EmiSpacing.sm,
                    children: [
                      TeacherStatChip(
                        label: 'Total kuis',
                        value: '${page.items.length}',
                      ),
                      TeacherStatChip(
                        label: 'Kuis terbit',
                        value:
                            '${page.items.where((item) => item.status == 'published').length}',
                      ),
                      TeacherStatChip(
                        label: 'Attempt',
                        value:
                            '${page.items.fold<int>(0, (sum, item) => sum + item.attemptsCount)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  _QuizCards(items: page.items),
                ],
              ),
      );
}

class _QuizList extends ConsumerWidget {
  const _QuizList({required this.id, required this.compact});
  final String id;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(teacherClassQuizzesProvider(id))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Text('Kuis belum bisa dimuat.'),
        data: (page) => page.items.isEmpty
            ? const Text('Belum ada kuis kelas yang bisa ditinjau.')
            : _QuizCards(items: page.items, compact: compact),
      );
}

class _QuizCards extends StatelessWidget {
  const _QuizCards({required this.items, this.compact = false});
  final List<TeacherQuiz> items;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final item in items) ...[
        TeacherListCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: EmiSpacing.xs,
                children: [
                  TeacherStatusChip(label: _status(item.status)),
                  if (!compact)
                    TeacherStatusChip(
                      label: item.status != 'draft' || item.attemptsCount > 0
                          ? 'Terkunci'
                          : 'Draft bisa diedit',
                      color: TeacherStyle.tint,
                    ),
                ],
              ),
              const SizedBox(height: EmiSpacing.xs),
              Text(item.title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                item.description.isEmpty ? 'Belum tersedia' : item.description,
              ),
              Text(
                'Soal: ${item.questionsCount} • Attempt: ${item.attemptsCount}',
              ),
              if (!compact) ...[
                Text(
                  '${item.durationMinutes} menit • Buka: ${_date(item.openAt)} • Tutup: ${_date(item.closeAt)}',
                ),
                Wrap(
                  spacing: EmiSpacing.sm,
                  children: [
                    OutlinedButton(
                      onPressed: () =>
                          context.push('/teacher/quizzes/${item.id}'),
                      child: Text(
                        item.status != 'draft' || item.attemptsCount > 0
                            ? 'Lihat Detail'
                            : 'Buka Builder',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          context.push('/teacher/quizzes/${item.id}/results'),
                      child: const Text('Hasil'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: EmiSpacing.sm),
      ],
    ],
  );
}

class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [SizedBox(height: 480, child: Center(child: child))],
  );
}

String _optional(String? value) =>
    value?.trim().isNotEmpty == true ? value! : 'Belum tersedia';
String _date(DateTime? value) => value == null
    ? 'Belum tersedia'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _status(String value) => switch (value) {
  'active' || 'approved' => 'Aktif',
  'inactive' => 'Tidak aktif',
  'pending' => 'Menunggu persetujuan',
  'rejected' => 'Tidak disetujui',
  'published' => 'Terbit',
  'draft' => 'Draft',
  'archived' => 'Arsip',
  _ => 'Status belum tersedia',
};
