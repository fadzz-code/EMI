import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/student_dashboard_providers.dart';
import '../data/student_dashboard_summary.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final summary = ref.watch(studentDashboardSummaryProvider);

    return EmiScaffold(
      title: 'Beranda',
      currentIndex: 0,
      onNavTap: (index) => _go(context, index),
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(studentDashboardSummaryProvider.future),
        child: summary.when(
          loading: () => const _DashboardLoading(),
          error: (error, _) => _DashboardError(
            message: error.toString(),
            onRetry: () => ref.invalidate(studentDashboardSummaryProvider),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              _HeroCard(name: user?.fullName ?? 'Siswa', summary: data),
              const SizedBox(height: EmiSpacing.xl),
              if (data.emptyState)
                const EmiCard(child: Text('Kelas aktif belum tersedia.'))
              else ...[
                _StatsGrid(summary: data),
                const SizedBox(height: EmiSpacing.xl),
                _ContinueCard(summary: data),
                const SizedBox(height: EmiSpacing.xl),
                _QuickMenu(onTapModules: () => context.go('/student/modules')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, int index) {
    if (index == 0) context.go('/student/dashboard');
    if (index == 1) context.go('/student/modules');
    if (index == 4) context.go('/student/profile');
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.name, required this.summary});

  final String name;
  final StudentDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.lg),
      decoration: BoxDecoration(
        color: EmiColors.secondary,
        border: Border.all(color: EmiColors.border, width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [EmiShadows.hard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: EmiColors.surface,
              border: Border.all(color: EmiColors.border, width: 2),
              borderRadius: BorderRadius.circular(EmiRadii.pill),
            ),
            child: Text(summary.classInfo?.name ?? 'Belajar EMI'),
          ),
          const SizedBox(height: EmiSpacing.sm),
          Text(
            'Halo, $name',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: EmiSpacing.xs),
          Text(summary.classInfo?.schoolName ?? 'Lanjutkan belajar Mekongga.'),
          const SizedBox(height: EmiSpacing.md),
          ElevatedButton(
            onPressed: () => context.go('/student/modules'),
            child: const Text('Lanjut Belajar'),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary});

  final StudentDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final learning = summary.learning;
    final quizzes = summary.quizzes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik Belajarmu',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: EmiSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: EmiSpacing.md,
          mainAxisSpacing: EmiSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          children: [
            _StatCard(label: 'Modul', value: '${learning.publishedModules}'),
            _StatCard(label: 'Selesai', value: '${learning.completedModules}'),
            _StatCard(
              label: 'Progress',
              value: '${learning.overallProgressPercent}%',
              color: EmiColors.primary,
            ),
            _StatCard(label: 'Kuis', value: '${quizzes.available}'),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return EmiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: EmiSpacing.xs),
          Text(label),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.summary});

  final StudentDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final learning = summary.learning;
    return EmiCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lanjutkan Belajar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: EmiSpacing.sm),
          Text(
            '${learning.completedLessons}/${learning.totalLessons} materi selesai',
          ),
          const SizedBox(height: EmiSpacing.sm),
          LinearProgressIndicator(value: learning.overallProgressPercent / 100),
        ],
      ),
    );
  }
}

class _QuickMenu extends StatelessWidget {
  const _QuickMenu({required this.onTapModules});

  final VoidCallback onTapModules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Menu Cepat', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: EmiSpacing.md),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: EmiSpacing.sm,
          mainAxisSpacing: EmiSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _QuickMenuItem(
              label: 'Modul',
              icon: Icons.menu_book_outlined,
              onTap: onTapModules,
            ),
            const _QuickMenuItem(
              label: 'Kamus',
              icon: Icons.translate_outlined,
            ),
            const _QuickMenuItem(label: 'Kuis', icon: Icons.quiz_outlined),
            const _QuickMenuItem(
              label: 'Progress',
              icon: Icons.trending_up_outlined,
            ),
            const _QuickMenuItem(label: 'Budaya', icon: Icons.public_outlined),
            const _QuickMenuItem(label: 'Profil', icon: Icons.person_outline),
          ],
        ),
      ],
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  const _QuickMenuItem({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: EmiCard(
        padding: const EdgeInsets.all(EmiSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(height: EmiSpacing.xs),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        EmiCard(
          child: Column(
            children: [
              Text(message),
              const SizedBox(height: EmiSpacing.md),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
