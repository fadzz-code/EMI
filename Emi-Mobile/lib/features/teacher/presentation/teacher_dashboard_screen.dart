import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/teacher_providers.dart';
import '../data/teacher_repository.dart';
import 'teacher_dashboard_widgets.dart';
import 'teacher_shell.dart';
import 'teacher_style.dart';
import 'teacher_widgets.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final dashboard = ref.watch(teacherDashboardProvider);
    return TeacherShell(
      title: 'Beranda Guru',
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(teacherDashboardProvider.future),
        child: dashboard.when(
          loading: () => const _ScrollableLoading(),
          error: (_, _) => _ScrollableState(
            child: FriendlyState(
              icon: Icons.wifi_off_outlined,
              title: 'Data belum bisa dimuat',
              message: 'Periksa koneksi internet, lalu coba lagi.',
              onRetry: () => ref.invalidate(teacherDashboardProvider),
            ),
          ),
          data: (summary) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              TeacherHeroHeader(
                greeting: 'Selamat datang,',
                name: user?.fullName ?? 'Guru EMI',
                message:
                    'Pantau kelas, materi, kuis, dan latihan speaking siswa dari satu tempat.',
                icon: Icons.school_outlined,
                action: IconButton(
                  tooltip: 'Kelas Saya',
                  onPressed: () => context.go('/teacher/classes'),
                  icon: const Icon(Icons.groups_outlined),
                ),
              ),
              const SizedBox(height: EmiSpacing.lg),
              const TeacherNoticeCard(
                icon: Icons.tips_and_updates_outlined,
                title: 'Siap mendampingi kelas hari ini?',
                message:
                    'Periksa materi dan kuis terbaru sebelum memulai pembelajaran.',
              ),
              TeacherSectionHeader('Ringkasan', leading: true),
              LayoutBuilder(
                builder: (context, constraints) => GridView.count(
                  crossAxisCount: constraints.maxWidth >= 720 ? 4 : 2,
                  crossAxisSpacing: EmiSpacing.md,
                  mainAxisSpacing: EmiSpacing.md,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisExtent: 150,
                  children: [
                    TeacherDashboardMetricTile(
                      icon: Icons.school_outlined,
                      label: 'Kelas',
                      value: summary.className ?? 'Kelas belum tersedia',
                      caption: summary.schoolName ?? 'Sekolah belum tersedia',
                      valueMaxLines: 2,
                      compactValue: true,
                    ),
                    for (final metric in summary.metrics.skip(1))
                      TeacherDashboardMetricTile(
                        label: metric.label,
                        value: metric.value,
                        icon: _metricIcon(metric),
                        caption: _metricCaption(metric),
                      ),
                  ],
                ),
              ),
              TeacherSectionHeader(
                'Tindakan Cepat',
                subtitle: 'Akses pintas tugas Guru.',
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: EmiSpacing.sm,
                runSpacing: EmiSpacing.sm,
                children: [
                  TeacherQuickAction(
                    label: 'Modul Kelas',
                    icon: Icons.menu_book_outlined,
                    onTap: () => context.go('/teacher/modules'),
                  ),
                  TeacherQuickAction(
                    label: 'Kuis Kelas',
                    icon: Icons.quiz_outlined,
                    onTap: () => context.go('/teacher/quizzes'),
                  ),
                  TeacherQuickAction(
                    label: 'Progress',
                    icon: Icons.trending_up_outlined,
                    onTap: () => context.go('/teacher/progress'),
                  ),
                  TeacherQuickAction(
                    label: 'Hasil Speaking',
                    icon: Icons.mic_none_outlined,
                    onTap: () => context.go('/teacher/speaking/attempts'),
                  ),
                ],
              ),
              TeacherSectionHeader('Aktivitas Terbaru'),
              if (summary.activities.isEmpty)
                TeacherListCard(
                  child: Text(
                    'Aktivitas siswa akan muncul setelah mereka mulai belajar.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TeacherStyle.inkMuted,
                    ),
                  ),
                )
              else
                for (final activity in summary.activities)
                  TeacherActivityTile(activity: activity),
              TeacherSectionHeader('Kelas Saya'),
              if (summary.classId == null)
                TeacherListCard(
                  child: Text(
                    'Belum ada kelas yang ditugaskan. Hubungi admin sekolah.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TeacherStyle.inkMuted,
                    ),
                  ),
                )
              else
                TeacherListCard(
                  padding: EdgeInsets.zero,
                  onTap: () =>
                      context.push('/teacher/classes/${summary.classId}'),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: TeacherStyle.tint,
                      foregroundColor: EmiColors.primary,
                      child: const Icon(Icons.groups_outlined),
                    ),
                    title: Text(
                      summary.className ?? 'Kelas tanpa nama',
                      style: const TextStyle(color: TeacherStyle.ink),
                    ),
                    subtitle: Text(
                      summary.schoolName ?? 'Sekolah belum tersedia',
                      style: const TextStyle(color: TeacherStyle.inkMuted),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: TeacherStyle.inkMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _metricCaption(TeacherMetric metric) => switch (metric.iconName) {
    'students' => 'Siswa aktif di kelas',
    'learning' => 'materi terbit',
    'quiz' => 'kuis terbit',
    'progress' => 'Rata-rata progress kelas',
    _ => '',
  };

  IconData _metricIcon(TeacherMetric metric) => switch (metric.iconName) {
    'class' => Icons.groups_outlined,
    'students' => Icons.people_outline,
    'learning' => Icons.menu_book_outlined,
    'quiz' => Icons.quiz_outlined,
    _ => Icons.insights_outlined,
  };
}

class _ScrollableLoading extends StatelessWidget {
  const _ScrollableLoading();

  @override
  Widget build(BuildContext context) =>
      const _ScrollableState(child: Center(child: CircularProgressIndicator()));
}

class _ScrollableState extends StatelessWidget {
  const _ScrollableState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [SizedBox(height: 480, child: child)],
  );
}
