import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../data/teacher_providers.dart';
import '../data/teacher_repository.dart';
import 'teacher_shell.dart';

class TeacherClassesScreen extends ConsumerWidget {
  const TeacherClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(teacherClassesProvider);
    return TeacherShell(
      title: 'Kelas',
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(teacherClassesProvider.future),
        child: classes.when(
          loading: () => const _ScrollableLoading(),
          error: (_, _) => _ScrollableFriendly(
            child: FriendlyState(
              icon: Icons.wifi_off_outlined,
              title: 'Kelas belum bisa dimuat',
              message: 'Periksa koneksi internet, lalu coba lagi.',
              onRetry: () => ref.invalidate(teacherClassesProvider),
            ),
          ),
          data: (page) => page.items.isEmpty
              ? const _ScrollableFriendly(
                  child: FriendlyState(
                    icon: Icons.groups_outlined,
                    title: 'Belum ada kelas',
                    message: 'Kelas yang ditugaskan akan tampil di sini.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(EmiSpacing.md),
                  itemCount: page.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: EmiSpacing.md),
                  itemBuilder: (context, index) {
                    final klass = page.items[index];
                    return EmiCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.school_outlined),
                        ),
                        title: Text(klass.name),
                        subtitle: Text(
                          '${klass.schoolName ?? 'Sekolah belum tersedia'}\n${klass.studentsCount} siswa aktif • ${_status(klass.status)}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push('/teacher/classes/${klass.id}'),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class TeacherClassDetailScreen extends ConsumerWidget {
  const TeacherClassDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(teacherClassDetailProvider(id));
    final students = ref.watch(teacherClassStudentsProvider(id));
    return TeacherShell(
      title: 'Detail Kelas',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                EmiSpacing.xs,
                EmiSpacing.xs,
                EmiSpacing.md,
                0,
              ),
              child: TextButton.icon(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/teacher/classes'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(teacherClassDetailProvider(id));
                ref.invalidate(teacherClassStudentsProvider(id));
                await Future.wait([
                  ref.read(teacherClassDetailProvider(id).future),
                  ref.read(teacherClassStudentsProvider(id).future),
                ]);
              },
              child: detail.when(
                loading: () => const _ScrollableLoading(),
                error: (_, _) => _ScrollableFriendly(
                  child: FriendlyState(
                    icon: Icons.wifi_off_outlined,
                    title: 'Detail belum bisa dimuat',
                    message: 'Periksa koneksi internet, lalu coba lagi.',
                    onRetry: () =>
                        ref.invalidate(teacherClassDetailProvider(id)),
                  ),
                ),
                data: (klass) => ListView(
                  padding: const EdgeInsets.all(EmiSpacing.md),
                  children: [
                    EmiCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            klass.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: EmiSpacing.sm),
                          Text(klass.schoolName ?? 'Sekolah belum tersedia'),
                          Text('Status: ${_status(klass.status)}'),
                          Text(
                            'Tingkat: ${klass.gradeLevel ?? 'Belum tersedia'}',
                          ),
                          Text(
                            'Tahun ajaran: ${klass.academicYear ?? 'Belum tersedia'}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: EmiSpacing.lg),
                    Text(
                      'Siswa',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: EmiSpacing.md),
                    students.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(EmiSpacing.lg),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, _) => FriendlyState(
                        icon: Icons.people_outline,
                        title: 'Siswa belum bisa dimuat',
                        message: 'Coba muat kembali daftar siswa.',
                        onRetry: () =>
                            ref.invalidate(teacherClassStudentsProvider(id)),
                      ),
                      data: (page) => page.items.isEmpty
                          ? const EmiCard(
                              child: Text('Belum ada siswa di kelas ini.'),
                            )
                          : Column(
                              children: [
                                for (final student in page.items) ...[
                                  _StudentCard(student: student),
                                  const SizedBox(height: EmiSpacing.md),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});

  final TeacherClassStudent student;

  @override
  Widget build(BuildContext context) => EmiCard(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(student.name),
      subtitle: Text('${student.email}\n${_status(student.status)}'),
      isThreeLine: true,
    ),
  );
}

class _ScrollableLoading extends StatelessWidget {
  const _ScrollableLoading();

  @override
  Widget build(BuildContext context) => const _ScrollableFriendly(
    child: Center(child: CircularProgressIndicator()),
  );
}

class _ScrollableFriendly extends StatelessWidget {
  const _ScrollableFriendly({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [SizedBox(height: 480, child: child)],
  );
}

String _status(String value) => switch (value) {
  'active' || 'approved' => 'Aktif',
  'inactive' => 'Tidak aktif',
  'pending' => 'Menunggu persetujuan',
  'rejected' => 'Tidak disetujui',
  _ => 'Status belum tersedia',
};
