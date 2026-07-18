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
  ConsumerState<TeacherStudentsScreen> createState() =>
      _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends ConsumerState<TeacherStudentsScreen> {
  final search = TextEditingController();
  int page = 1;
  String keyword = '';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = (page: page, search: keyword);
    final students = ref.watch(teacherStudentProgressProvider(query));
    return TeacherShell(
      title: 'Daftar Siswa',
      child: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(teacherStudentProgressProvider(query).future),
        child: students.when(
          loading: () => const _State(child: CircularProgressIndicator()),
          error: (_, _) => _State(
            child: FriendlyState(
              icon: Icons.wifi_off_outlined,
              title: 'Gagal memuat siswa',
              message: 'Periksa koneksi internet, lalu coba lagi.',
              onRetry: () =>
                  ref.invalidate(teacherStudentProgressProvider(query)),
            ),
          ),
          data: (result) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              TextField(
                controller: search,
                decoration: const InputDecoration(
                  labelText: 'Cari nama siswa atau kelas...',
                  prefixIcon: Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => setState(() {
                  keyword = value.trim();
                  page = 1;
                }),
              ),
              const SizedBox(height: EmiSpacing.md),
              if (result.items.isEmpty)
                const FriendlyState(
                  icon: Icons.people_outline,
                  title: 'Siswa tidak ditemukan',
                  message: 'Belum ada siswa atau coba gunakan kata kunci lain.',
                )
              else
                for (final student in result.items) ...[
                  _StudentCard(student: student),
                  const SizedBox(height: EmiSpacing.sm),
                ],
              if (result.lastPage > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Halaman sebelumnya',
                      onPressed: page > 1 ? () => setState(() => page--) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('$page / ${result.lastPage}'),
                    IconButton(
                      tooltip: 'Halaman berikutnya',
                      onPressed: page < result.lastPage
                          ? () => setState(() => page++)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
            ],
          ),
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
    final student = ref.watch(teacherStudentDetailProvider(id));
    return TeacherShell(
      title: 'Detail Siswa',
      fallbackRoute: '/teacher/students',
      child: student.when(
        loading: () => const _State(child: CircularProgressIndicator()),
        error: (_, _) => _State(
          child: FriendlyState(
            icon: Icons.wifi_off_outlined,
            title: 'Gagal memuat detail siswa',
            message: 'Periksa koneksi internet, lalu coba lagi.',
            onRetry: () => ref.invalidate(teacherStudentDetailProvider(id)),
          ),
        ),
        data: (row) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            Text(row.name, style: Theme.of(context).textTheme.headlineMedium),
            Text(row.className),
            const SizedBox(height: EmiSpacing.md),
            _Summary(row: row),
            const SizedBox(height: EmiSpacing.md),
            FilledButton(
              onPressed: () => context.go('/teacher/reports/progress'),
              child: const Text('Lihat di Laporan Keseluruhan'),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherProgressScreen extends ConsumerStatefulWidget {
  const TeacherProgressScreen({super.key});

  @override
  ConsumerState<TeacherProgressScreen> createState() =>
      _TeacherProgressScreenState();
}

class _TeacherProgressScreenState extends ConsumerState<TeacherProgressScreen> {
  int page = 1;

  @override
  Widget build(BuildContext context) {
    final query = (page: page, search: '');
    final progress = ref.watch(teacherStudentProgressProvider(query));
    return TeacherShell(
      title: 'Laporan Progress Siswa',
      child: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(teacherStudentProgressProvider(query).future),
        child: progress.when(
          loading: () => const _State(child: CircularProgressIndicator()),
          error: (_, _) => _State(
            child: FriendlyState(
              icon: Icons.wifi_off_outlined,
              title: 'Gagal memuat laporan progress',
              message: 'Periksa koneksi internet, lalu coba lagi.',
              onRetry: () =>
                  ref.invalidate(teacherStudentProgressProvider(query)),
            ),
          ),
          data: (result) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              if (result.items.isEmpty)
                const FriendlyState(
                  icon: Icons.trending_up_outlined,
                  title: 'Laporan kosong',
                  message: 'Belum ada data progress dari siswa di kelas Anda.',
                )
              else
                for (final row in result.items) ...[
                  _StudentCard(student: row),
                  const SizedBox(height: EmiSpacing.sm),
                ],
              if (result.lastPage > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: page > 1 ? () => setState(() => page--) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('$page / ${result.lastPage}'),
                    IconButton(
                      onPressed: page < result.lastPage
                          ? () => setState(() => page++)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});
  final TeacherStudentProgress student;

  @override
  Widget build(BuildContext context) => EmiCard(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(student.name),
      subtitle: Text(
        '${student.className}\nModul ${student.completedModules}/${student.publishedModules} | Kuis ${student.completedQuizzes}/${student.publishedQuizzes}',
      ),
      isThreeLine: true,
      trailing: Text('${student.percent.toStringAsFixed(0)}%'),
      onTap: () => context.push('/teacher/students/${student.studentId}'),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.row});
  final TeacherStudentProgress row;

  @override
  Widget build(BuildContext context) => EmiCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress Belajar: ${row.percent.toStringAsFixed(0)}%'),
        Text('Modul tersedia: ${row.publishedModules}'),
        Text('Modul mulai: ${row.startedModules}'),
        Text('Modul selesai: ${row.completedModules}'),
        Text('Kuis tersedia: ${row.publishedQuizzes}'),
        Text('Kuis dicoba: ${row.attemptedQuizzes}'),
        Text('Kuis selesai: ${row.completedQuizzes}'),
      ],
    ),
  );
}

class _State extends StatelessWidget {
  const _State({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [SizedBox(height: 480, child: Center(child: child))],
  );
}
