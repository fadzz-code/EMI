import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/teacher_repository.dart';
import '../data/teacher_providers.dart';
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
        onRefresh: () async => ref.invalidate(teacherDashboardProvider),
        child: dashboard.when(
          loading: () => const _LoadingState(),
          error: (_, _) => FriendlyState(
            icon: Icons.wifi_off_outlined,
            title: 'Data belum bisa dimuat',
            message: 'Periksa koneksi internetmu, lalu coba lagi.',
            onRetry: () => ref.invalidate(teacherDashboardProvider),
          ),
          data: (summary) => summary.emptyState
              ? const _EmptyTeacherDashboard()
              : ListView(
                  padding: const EdgeInsets.all(EmiSpacing.md),
                  children: [
                    RoleHeroHeader(
                      greeting: 'Selamat datang,',
                      name: user?.fullName ?? 'Guru EMI',
                      message: 'Mari lihat kegiatan belajar kelas hari ini.',
                      icon: Icons.school_outlined,
                      action: IconButton(
                        tooltip: 'Profil',
                        onPressed: () => context.go('/teacher/profile'),
                        icon: const Icon(Icons.account_circle_outlined),
                      ),
                    ),
                    const SizedBox(height: EmiSpacing.xl),
                    Text(
                      'Ringkasan Hari Ini',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: EmiSpacing.md),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: EmiSpacing.md,
                      mainAxisSpacing: EmiSpacing.md,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisExtent: 150,
                      children: [
                        for (final metric in summary.metrics)
                          SimpleStatItem(
                            label: metric.label,
                            value: metric.value,
                            icon: _metricIcon(metric),
                            highlight: metric.highlight,
                          ),
                      ],
                    ),
                    const SizedBox(height: EmiSpacing.xl),
                    Text(
                      'Menu Cepat',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: EmiSpacing.md),
                    const Wrap(
                      spacing: EmiSpacing.sm,
                      runSpacing: EmiSpacing.sm,
                      children: [
                        QuickActionItem(
                          label: 'Kelas Saya',
                          icon: Icons.groups_outlined,
                        ),
                        QuickActionItem(
                          label: 'Daftar Siswa',
                          icon: Icons.people_outline,
                        ),
                        QuickActionItem(
                          label: 'Modul Belajar',
                          icon: Icons.menu_book_outlined,
                        ),
                        QuickActionItem(
                          label: 'Kuis',
                          icon: Icons.quiz_outlined,
                        ),
                        QuickActionItem(
                          label: 'Hasil Speaking',
                          icon: Icons.mic_none_outlined,
                        ),
                        QuickActionItem(
                          label: 'Kemajuan Siswa',
                          icon: Icons.trending_up_outlined,
                        ),
                      ],
                    ),
                    if (summary.recentActivity.isNotEmpty) ...[
                      const SizedBox(height: EmiSpacing.xl),
                      Text(
                        'Kegiatan Terbaru',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: EmiSpacing.sm),
                      for (final item in summary.recentActivity.take(3))
                        ListTile(
                          leading: const Icon(Icons.history_outlined),
                          title: Text(item.title ?? 'Kegiatan belajar'),
                          subtitle: Text(item.studentName ?? 'Siswa'),
                        ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  IconData _metricIcon(TeacherMetric metric) => switch (metric.iconName) {
    'class' => Icons.groups_outlined,
    'students' => Icons.people_outline,
    'learning' => Icons.menu_book_outlined,
    'review' => Icons.fact_check_outlined,
    _ => Icons.insights_outlined,
  };
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EmptyTeacherDashboard extends StatelessWidget {
  const _EmptyTeacherDashboard();

  @override
  Widget build(BuildContext context) {
    return const FriendlyState(
      icon: Icons.school_outlined,
      title: 'Belum Ada Kelas',
      message:
          'Admin belum menempatkan kamu ke kelas. Hubungi admin sekolah untuk mendapatkan bantuan.',
    );
  }
}
