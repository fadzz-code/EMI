import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/network/network_status_controller.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_connectivity_banner.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/student_dashboard_providers.dart';
import '../data/student_dashboard_summary.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final summary = ref.watch(studentDashboardSummaryProvider);
    final networkMode = ref.watch(networkStatusControllerProvider).mode;

    return EmiScaffold(
      title: 'Beranda',
      currentIndex: 0,
      onNavTap: (index) => _go(context, index),
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(studentDashboardSummaryProvider.future),
        child: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              StudentPlaceholder(
                icon: Icons.cloud_off_outlined,
                title: 'Data belum bisa dimuat',
                message: 'Periksa koneksi internetmu, lalu coba lagi.',
                onRetry: () => ref.invalidate(studentDashboardSummaryProvider),
              ),
            ],
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              StudentConnectivityBanner(mode: networkMode),
              if (networkMode != NetworkMode.online)
                const SizedBox(height: EmiSpacing.md),
              StudentHeroCard(
                greeting: 'Halo,',
                name: user?.fullName ?? 'Siswa',
                subtitle:
                    data.classInfo?.schoolName ?? 'Lanjutkan belajar Mekongga.',
                actionLabel: 'Lanjut Belajar',
                onAction: () => context.go('/student/modules'),
              ),
              const SizedBox(height: EmiSpacing.lg),
              if (data.emptyState)
                StudentPlaceholder(
                  icon: Icons.school_outlined,
                  title: 'Kelas Aktif Belum Tersedia',
                  message:
                      'Kamu belum tergabung di kelas aktif. Hubungi gurumu.',
                )
              else ...[
                _StatsGrid(summary: data),
                const SizedBox(height: EmiSpacing.lg),
                _ContinueCard(summary: data),
                const SizedBox(height: EmiSpacing.lg),
                _QuickMenu(
                  onTapModules: () => context.go('/student/modules'),
                  onTapDictionary: () => context.go('/student/dictionary'),
                  onTapQuizzes: () => context.go('/student/quizzes'),
                  onTapChatbot: () => context.go('/student/chatbot'),
                  onTapProfile: () => context.go('/student/profile'),
                  onTapOffline: () => context.go('/student/offline'),
                ),
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
    if (index == 2) context.go('/student/dictionary');
    if (index == 3) context.go('/student/quizzes');
    if (index == 4) context.go('/student/profile');
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
        const StudentSectionHeader(
          'Statistik Belajarmu',
          icon: Icons.insights_outlined,
          leading: false,
        ),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: EmiSpacing.md,
          mainAxisSpacing: EmiSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          children: [
            StudentMetricTile(
              icon: Icons.menu_book_outlined,
              label: 'Modul',
              value: '${learning.publishedModules}',
            ),
            StudentMetricTile(
              icon: Icons.check_circle_outline,
              label: 'Selesai',
              value: '${learning.completedModules}',
            ),
            StudentMetricTile(
              icon: Icons.trending_up_outlined,
              label: 'Progress',
              value: '${learning.overallProgressPercent}%',
              highlight: true,
            ),
            StudentMetricTile(
              icon: Icons.quiz_outlined,
              label: 'Kuis',
              value: '${quizzes.available}',
            ),
          ],
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.summary});

  final StudentDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final learning = summary.learning;
    return StudentCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: StudentStyle.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: EmiColors.primary,
                ),
              ),
              const SizedBox(width: EmiSpacing.sm),
              Expanded(
                child: Text(
                  'Lanjutkan Belajar',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: StudentStyle.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: EmiSpacing.md),
          StudentProgressBar(
            value: learning.overallProgressPercent / 100,
            caption:
                '${learning.completedLessons}/${learning.totalLessons} materi selesai',
          ),
        ],
      ),
    );
  }
}

class _QuickMenu extends StatelessWidget {
  const _QuickMenu({
    required this.onTapModules,
    required this.onTapDictionary,
    required this.onTapQuizzes,
    required this.onTapChatbot,
    required this.onTapProfile,
    required this.onTapOffline,
  });

  final VoidCallback onTapModules;
  final VoidCallback onTapDictionary;
  final VoidCallback onTapQuizzes;
  final VoidCallback onTapChatbot;
  final VoidCallback onTapProfile;
  final VoidCallback onTapOffline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudentSectionHeader(
          'Menu Cepat',
          icon: Icons.grid_view_outlined,
          leading: false,
        ),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: EmiSpacing.sm,
          mainAxisSpacing: EmiSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.9,
          children: [
            _QuickMenuItem(
              key: const Key('studentQuickMenuModules'),
              label: 'Modul',
              icon: Icons.menu_book_outlined,
              onTap: onTapModules,
            ),
            _QuickMenuItem(
              key: const Key('studentQuickMenuDictionary'),
              label: 'Kamus',
              icon: Icons.translate_outlined,
              onTap: onTapDictionary,
            ),
            _QuickMenuItem(
              key: const Key('studentQuickMenuQuizzes'),
              label: 'Kuis',
              icon: Icons.quiz_outlined,
              onTap: onTapQuizzes,
            ),
            _QuickMenuItem(
              label: 'Progress',
              icon: Icons.trending_up_outlined,
              onTap: () => context.go('/student/progress'),
            ),
            _QuickMenuItem(
              label: 'Chatbot',
              icon: Icons.auto_awesome_outlined,
              onTap: onTapChatbot,
            ),
            _QuickMenuItem(
              key: const Key('studentQuickMenuOffline'),
              label: 'Offline',
              icon: Icons.offline_bolt_outlined,
              onTap: onTapOffline,
            ),
            _QuickMenuItem(
              key: const Key('studentQuickMenuProfile'),
              label: 'Profil',
              icon: Icons.person_outline,
              onTap: onTapProfile,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  const _QuickMenuItem({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StudentStyle.surface,
        borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
        boxShadow: StudentStyle.softShadow(),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(EmiSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: StudentStyle.tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: EmiColors.primary),
                ),
                const SizedBox(height: EmiSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: StudentStyle.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
