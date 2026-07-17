import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/teacher_providers.dart';
import '../data/teacher_repository.dart';
import 'teacher_dashboard_widgets.dart';
import 'teacher_shell.dart';

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
              RoleHeroHeader(
                greeting: 'Selamat datang,',
                name: user?.fullName ?? 'Guru EMI',
                message:
                    'Pantau kelas, materi, kuis, dan latihan speaking siswa dari satu tempat.',
                icon: Icons.school_outlined,
                action: IconButton(
                  tooltip: 'Profil',
                  onPressed: () => context.go('/teacher/profile'),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ),
              const SizedBox(height: EmiSpacing.lg),
              Text('Ringkasan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: EmiSpacing.md),
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
              const SizedBox(height: EmiSpacing.lg),
              Text(
                'Tindakan Cepat',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: EmiSpacing.xs),
              const Text('Akses pintas tugas Guru.'),
              const SizedBox(height: EmiSpacing.md),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: EmiSpacing.md,
                mainAxisSpacing: EmiSpacing.md,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  TeacherQuickAction(
                    label: 'Modul Kelas',
                    icon: Icons.menu_book_outlined,
                    onTap: () => _showComingSoon(
                      context,
                      'Modul Kelas',
                      Icons.menu_book_outlined,
                    ),
                  ),
                  TeacherQuickAction(
                    label: 'Kuis Kelas',
                    icon: Icons.quiz_outlined,
                    onTap: () => _showComingSoon(
                      context,
                      'Kuis Kelas',
                      Icons.quiz_outlined,
                    ),
                  ),
                  TeacherQuickAction(
                    label: 'Hasil Speaking',
                    icon: Icons.mic_none_outlined,
                    onTap: () => _showComingSoon(
                      context,
                      'Hasil Speaking',
                      Icons.mic_none_outlined,
                    ),
                  ),
                  TeacherQuickAction(
                    label: 'Aktivitas & Progress Siswa',
                    icon: Icons.insights_outlined,
                    onTap: () => _showComingSoon(
                      context,
                      'Aktivitas & Progress Siswa',
                      Icons.insights_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EmiSpacing.lg),
              Text(
                'Aktivitas Terbaru',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: EmiSpacing.md),
              if (summary.activities.isEmpty)
                const EmiCard(
                  child: Text(
                    'Aktivitas siswa akan muncul setelah mereka mulai belajar.',
                  ),
                )
              else
                for (final activity in summary.activities)
                  TeacherActivityTile(activity: activity),
              const SizedBox(height: EmiSpacing.lg),
              Text(
                'Kelas Saya',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: EmiSpacing.md),
              if (summary.classId == null)
                const EmiCard(
                  child: Text(
                    'Belum ada kelas yang ditugaskan. Hubungi admin sekolah.',
                  ),
                )
              else
                EmiCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.groups_outlined),
                    ),
                    title: Text(summary.className ?? 'Kelas tanpa nama'),
                    subtitle: Text(
                      summary.schoolName ?? 'Sekolah belum tersedia',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push('/teacher/classes/${summary.classId}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label, IconData icon) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EmiSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: EmiSpacing.sm),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: EmiSpacing.xs),
              const Text('Fitur ini sedang disiapkan.'),
              const SizedBox(height: EmiSpacing.md),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
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
