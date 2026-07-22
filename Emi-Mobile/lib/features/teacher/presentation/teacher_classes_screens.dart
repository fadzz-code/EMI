import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../data/teacher_providers.dart';
import '../data/teacher_quiz_models.dart';
import '../data/teacher_repository.dart';
import 'teacher_shell.dart';

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
            const _Intro(
              title: 'Kelas Saya',
              description:
                  'Daftar kelas yang dapat Anda akses. Untuk EMI saat ini, guru mengajar dari satu kelas aktif.',
            ),
            const SizedBox(height: EmiSpacing.md),
            TextField(
              key: const Key('teacherClassSearch'),
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Cari kelas',
                prefixIcon: Icon(Icons.search),
              ),
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
                        _Stats(
                          items: [
                            ('Kelas aktif', '${result.total}'),
                            (
                              'Siswa halaman ini',
                              '${result.items.fold<int>(0, (sum, item) => sum + item.studentsCount)}',
                            ),
                            ('Akses', 'Aman'),
                          ],
                        ),
                        const SizedBox(height: EmiSpacing.md),
                        for (final klass in result.items) ...[
                          _ClassCard(klass: klass),
                          const SizedBox(height: EmiSpacing.md),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              key: const Key('teacherClassesPrevious'),
                              onPressed: result.currentPage > 1
                                  ? () => setState(() => page--)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text(
                              'Halaman ${result.currentPage} dari ${result.lastPage}',
                            ),
                            IconButton(
                              key: const Key('teacherClassesNext'),
                              onPressed: result.currentPage < result.lastPage
                                  ? () => setState(() => page++)
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
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
          ref.invalidate(teacherClassStudentsProvider(id));
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
              EmiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Badge(_status(klass.status)),
                    const SizedBox(height: EmiSpacing.sm),
                    Text(
                      klass.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: EmiSpacing.xs),
                    Text(
                      '${_optional(klass.schoolName)} | Tahun ajaran ${_optional(klass.academicYear)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EmiSpacing.md),
              _DetailStats(id: id, klass: klass),
              const SizedBox(height: EmiSpacing.md),
              _Nav(
                selected: tab,
                onSelected: (value) => setState(() => tab = value),
              ),
              const SizedBox(height: EmiSpacing.md),
              switch (tab) {
                0 => _Summary(id: id),
                1 => _Students(id: id),
                2 => _Modules(id: id),
                3 => _Quizzes(id: id),
                _ => const _CultureUnavailable(),
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
  Widget build(BuildContext context) => EmiCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Badge(_status(klass.status)),
        const SizedBox(height: EmiSpacing.sm),
        Text(klass.name, style: Theme.of(context).textTheme.titleLarge),
        Text(_optional(klass.schoolName)),
        const SizedBox(height: EmiSpacing.md),
        _Field(label: 'Tahun ajaran', value: _optional(klass.academicYear)),
        const SizedBox(height: EmiSpacing.sm),
        _Field(label: 'Siswa', value: '${klass.studentsCount}'),
        const SizedBox(height: EmiSpacing.sm),
        _Field(label: 'Guru aktif', value: _optional(klass.teacherName)),
        const SizedBox(height: EmiSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push('/teacher/classes/${klass.id}'),
            child: const Text('Detail'),
          ),
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
    final students = ref.watch(teacherClassStudentsProvider(id)).valueOrNull;
    final modules = ref.watch(teacherModulesProvider(id)).valueOrNull;
    return _Stats(
      items: [
        ('Sekolah', _optional(klass.schoolName)),
        ('Guru', _optional(klass.teacherName)),
        (
          'Siswa',
          '${klass.studentsCount == 0 ? students?.items.length ?? 0 : klass.studentsCount}',
        ),
        ('Modul', '${modules?.length ?? 0}'),
      ],
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: List.generate(5, (index) {
        const labels = [
          'Ringkasan',
          'Siswa',
          'Modul',
          'Kuis',
          'Budaya Mekongga',
        ];
        return Padding(
          padding: const EdgeInsets.only(right: EmiSpacing.sm, bottom: 4),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: selected == index
                  ? EmiColors.secondary
                  : Colors.white,
              side: const BorderSide(color: EmiColors.border, width: 2),
            ),
            onPressed: () => onSelected(index),
            child: Text(labels[index]),
          ),
        );
      }),
    ),
  );
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      _Section(
        title: 'Siswa Kelas',
        child: _StudentList(id: id, compact: true),
      ),
      const SizedBox(height: EmiSpacing.md),
      _Section(
        title: 'Progress Belajar',
        child: _ProgressList(id: id, limit: 8),
      ),
      const SizedBox(height: EmiSpacing.md),
      _Section(
        title: 'Modul Kelas',
        child: _ModuleList(id: id, compact: true),
      ),
      const SizedBox(height: EmiSpacing.md),
      _Section(
        title: 'Kuis Kelas',
        child: _QuizList(id: id, compact: true),
      ),
      const SizedBox(height: EmiSpacing.md),
      const EmiCard(
        child: Text(
          'Detail kelas ini berfungsi sebagai ringkasan cepat. Untuk mengelola materi atau kuis, gunakan menu Modul dan Kuis.',
        ),
      ),
    ],
  );
}

class _Students extends ConsumerWidget {
  const _Students({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(teacherClassStudentsProvider(id));
    final progress =
        ref
            .watch(
              teacherClassProgressProvider((classId: id, page: 1, search: '')),
            )
            .valueOrNull
            ?.items ??
        const [];
    return students.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => FriendlyState(
        icon: Icons.people_outline,
        title: 'Gagal memuat siswa',
        message: 'Coba muat kembali daftar siswa.',
        onRetry: () => ref.invalidate(teacherClassStudentsProvider(id)),
      ),
      data: (page) => page.items.isEmpty
          ? const FriendlyState(
              icon: Icons.people_outline,
              title: 'Siswa kosong',
              message: 'Belum ada siswa aktif pada kelas ini.',
            )
          : Column(
              children: [
                _Stats(
                  items: [
                    ('Total siswa', '${page.items.length}'),
                    ('Progress tersedia', '${progress.length}'),
                    ('Catatan', progress.isEmpty ? 'Belum tersedia' : 'Real'),
                  ],
                ),
                const SizedBox(height: EmiSpacing.md),
                _StudentCards(students: page.items, progress: progress),
              ],
            ),
    );
  }
}

class _StudentList extends ConsumerWidget {
  const _StudentList({required this.id, required this.compact});
  final String id;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(teacherClassStudentsProvider(id));
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
            return InkWell(
              onTap: () => context.push('/teacher/students/${student.id}'),
              child: _InnerCard(
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
                _InnerCard(
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
                          _Badge('${row.percent.toStringAsFixed(0)}%'),
                        ],
                      ),
                      Text(row.className),
                      Text(
                        'Modul: ${row.completedModules} / ${row.publishedModules} | Kuis selesai: ${row.completedQuizzes}',
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
                _Stats(
                  items: [
                    ('Total modul', '${items.length}'),
                    (
                      'Modul terbit',
                      '${items.where((item) => item.status == 'published').length}',
                    ),
                    ('Materi', 'Tersedia'),
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
        _InnerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Badge(_status(item.status)),
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
                  _Stats(
                    items: [
                      ('Total kuis', '${page.items.length}'),
                      (
                        'Kuis terbit',
                        '${page.items.where((item) => item.status == 'published').length}',
                      ),
                      (
                        'Attempt',
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
        _InnerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: EmiSpacing.xs,
                children: [
                  _Badge(_status(item.status)),
                  if (!compact)
                    _Badge(
                      item.status != 'draft' || item.attemptsCount > 0
                          ? 'Terkunci'
                          : 'Draft bisa diedit',
                    ),
                ],
              ),
              const SizedBox(height: EmiSpacing.xs),
              Text(item.title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                item.description.isEmpty ? 'Belum tersedia' : item.description,
              ),
              Text(
                'Soal: ${item.questionsCount} | Attempt: ${item.attemptsCount}',
              ),
              if (!compact) ...[
                Text(
                  '${item.durationMinutes} menit | Buka: ${_date(item.openAt)} | Tutup: ${_date(item.closeAt)}',
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

class _CultureUnavailable extends StatelessWidget {
  const _CultureUnavailable();

  @override
  Widget build(BuildContext context) => const FriendlyState(
    icon: Icons.public_off_outlined,
    title: 'Budaya Mekongga belum tersedia',
    message:
        'Konteks Budaya Mekongga guru belum tersedia di aplikasi mobile. Gunakan web untuk mengelola konten kelas.',
  );
}

class _Intro extends StatelessWidget {
  const _Intro({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => EmiCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Badge('Guru'),
        const SizedBox(height: EmiSpacing.sm),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        Text(description),
      ],
    ),
  );
}

class _Stats extends StatelessWidget {
  const _Stats({required this.items});
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: EmiSpacing.sm,
    runSpacing: EmiSpacing.sm,
    children: [
      for (final item in items)
        SizedBox(
          width: items.length == 4 ? 148 : 190,
          child: _InnerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.$1, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: EmiSpacing.xs),
                Text(item.$2, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => EmiCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: EmiSpacing.md),
        child,
      ],
    ),
  );
}

class _InnerCard extends StatelessWidget {
  const _InnerCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(EmiSpacing.sm),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(EmiRadii.card),
    ),
    child: child,
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => _InnerCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Text(value),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: EmiSpacing.sm, vertical: 5),
    decoration: BoxDecoration(
      color: EmiColors.secondary,
      border: Border.all(color: EmiColors.border),
      borderRadius: BorderRadius.circular(EmiRadii.pill),
    ),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
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
