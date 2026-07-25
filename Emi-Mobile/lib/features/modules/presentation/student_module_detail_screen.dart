import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../data/student_module.dart';
import '../data/student_module_providers.dart';

class StudentModuleDetailScreen extends ConsumerWidget {
  const StudentModuleDetailScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(studentModuleDetailProvider(moduleId));

    return EmiScaffold(
      title: 'Detail Modul',
      currentIndex: 1,
      onNavTap: (index) => _go(context, index),
      child: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(studentModuleDetailProvider(moduleId).future),
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            onRetry: () =>
                ref.invalidate(studentModuleDetailProvider(moduleId)),
          ),
          data: (module) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              _ModuleHeader(module: module),
              const SizedBox(height: EmiSpacing.md),
              _ProgressCard(progress: module.progress),
              const StudentSectionHeader(
                'Daftar Lesson',
                icon: Icons.list_alt_outlined,
              ),
              if (module.lessons.isEmpty)
                StudentPlaceholder(
                  icon: Icons.article_outlined,
                  title: 'Belum Ada Lesson',
                  message: 'Materi untuk modul ini belum tersedia.',
                )
              else
                ...module.lessons.map(
                  (lesson) => Padding(
                    padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
                    child: _LessonTile(lesson: lesson),
                  ),
                ),
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

class _ModuleHeader extends StatelessWidget {
  const _ModuleHeader({required this.module});

  final StudentModule module;

  @override
  Widget build(BuildContext context) {
    return StudentCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFB877), Color(0xFFFF8A3D)],
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_outlined,
              size: 52,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: StudentStyle.ink),
                ),
                if (module.description != null) ...[
                  const SizedBox(height: EmiSpacing.xs),
                  Text(
                    module.description!,
                    style: const TextStyle(color: StudentStyle.inkMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final ModuleProgress progress;

  @override
  Widget build(BuildContext context) {
    return StudentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Modul',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: StudentStyle.ink),
          ),
          const SizedBox(height: EmiSpacing.md),
          StudentProgressBar(
            value: progress.progressPercent / 100,
            caption:
                '${progress.completedLessons}/${progress.totalLessons} lesson selesai',
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});

  final StudentLesson lesson;

  @override
  Widget build(BuildContext context) {
    return StudentCard(
      padding: const EdgeInsets.all(EmiSpacing.sm),
      onTap: () => context.go(
        '/student/lessons/${lesson.id}',
        extra: lesson.classModuleId,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: StudentStyle.tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.play_lesson_outlined,
              color: EmiColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: EmiSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: StudentStyle.ink),
                ),
                if (lesson.description != null)
                  Text(
                    lesson.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: StudentStyle.inkMuted),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: StudentStyle.inkMuted),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        StudentPlaceholder(
          icon: Icons.cloud_off_outlined,
          title: 'Modul Belum Bisa Dimuat',
          message: 'Periksa koneksi internetmu, lalu coba lagi.',
          onRetry: onRetry,
        ),
      ],
    );
  }
}
