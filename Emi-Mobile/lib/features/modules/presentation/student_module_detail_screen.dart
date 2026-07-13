import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
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
            message: error.toString(),
            onRetry: () =>
                ref.invalidate(studentModuleDetailProvider(moduleId)),
          ),
          data: (module) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              _ModuleHeader(module: module),
              const SizedBox(height: EmiSpacing.lg),
              _ProgressCard(progress: module.progress),
              const SizedBox(height: EmiSpacing.lg),
              Text(
                'Daftar Lesson',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: EmiSpacing.md),
              if (module.lessons.isEmpty)
                const EmiCard(child: Text('Belum ada lesson tersedia.'))
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
    if (index == 4) context.go('/student/profile');
  }
}

class _ModuleHeader extends StatelessWidget {
  const _ModuleHeader({required this.module});

  final StudentModule module;

  @override
  Widget build(BuildContext context) {
    return EmiCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(EmiSpacing.md),
            decoration: const BoxDecoration(
              color: EmiColors.secondary,
              border: Border(
                bottom: BorderSide(color: EmiColors.border, width: 2),
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (module.description != null) ...[
                  const SizedBox(height: EmiSpacing.xs),
                  Text(module.description!),
                ],
              ],
            ),
          ),
          Container(
            height: 160,
            margin: const EdgeInsets.all(EmiSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDBC9),
              border: Border.all(color: EmiColors.border, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: EmiColors.border,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.menu_book_outlined, size: 48),
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
    return EmiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Modul',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: EmiSpacing.sm),
          LinearProgressIndicator(value: progress.progressPercent / 100),
          const SizedBox(height: EmiSpacing.xs),
          Text(
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
    return InkWell(
      onTap: () => context.go(
        '/student/lessons/${lesson.id}',
        extra: lesson.classModuleId,
      ),
      child: Container(
        padding: const EdgeInsets.all(EmiSpacing.sm),
        decoration: BoxDecoration(
          color: EmiColors.surface,
          border: Border.all(color: EmiColors.border, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline),
            const SizedBox(width: EmiSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (lesson.description != null)
                    Text(
                      lesson.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
