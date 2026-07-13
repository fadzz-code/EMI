import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../dashboard/data/student_dashboard_providers.dart';
import '../data/student_module.dart';
import '../data/student_module_providers.dart';

class StudentLessonDetailScreen extends ConsumerStatefulWidget {
  const StudentLessonDetailScreen({
    super.key,
    required this.lessonId,
    this.moduleId,
  });

  final String lessonId;
  final String? moduleId;

  @override
  ConsumerState<StudentLessonDetailScreen> createState() =>
      _StudentLessonDetailScreenState();
}

class _StudentLessonDetailScreenState
    extends ConsumerState<StudentLessonDetailScreen> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(studentLessonDetailProvider(widget.lessonId));
    final content = ref.watch(studentLessonContentProvider(widget.lessonId));

    return EmiScaffold(
      title: 'Detail Lesson',
      currentIndex: 1,
      onNavTap: (index) => _go(context, index),
      child: lesson.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(studentLessonDetailProvider(widget.lessonId));
            ref.invalidate(studentLessonContentProvider(widget.lessonId));
          },
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            _LessonCard(lesson: item, content: content),
            const SizedBox(height: EmiSpacing.lg),
            ElevatedButton.icon(
              onPressed: _submitting ? null : () => _complete(item),
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Tandai Selesai'),
            ),
            const SizedBox(height: EmiSpacing.sm),
            OutlinedButton(
              onPressed: () => widget.moduleId == null
                  ? context.go('/student/modules')
                  : context.go('/student/modules/${widget.moduleId}'),
              child: const Text('Kembali ke Modul'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _complete(StudentLesson lesson) async {
    setState(() => _submitting = true);
    try {
      await ref.read(studentModuleRepositoryProvider).completeLesson(lesson.id);
      ref.invalidate(studentLessonDetailProvider(lesson.id));
      ref.invalidate(studentLessonContentProvider(lesson.id));
      ref.invalidate(studentDashboardSummaryProvider);
      if (widget.moduleId != null) {
        ref.invalidate(studentModuleDetailProvider(widget.moduleId!));
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lesson selesai.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _go(BuildContext context, int index) {
    if (index == 0) context.go('/student/dashboard');
    if (index == 1) context.go('/student/modules');
    if (index == 4) context.go('/student/profile');
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.content});

  final StudentLesson lesson;
  final AsyncValue<LessonContent?> content;

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
                  lesson.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (lesson.description != null) ...[
                  const SizedBox(height: EmiSpacing.xs),
                  Text(lesson.description!),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MediaBlock(lesson: lesson, content: content),
                const SizedBox(height: EmiSpacing.md),
                if (lesson.hasTextContent)
                  Text(lesson.contentBody!)
                else if (lesson.hasExternalUrl)
                  SelectableText(lesson.externalUrl!)
                else
                  const Text('Konten teks belum tersedia untuk lesson ini.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaBlock extends StatelessWidget {
  const _MediaBlock({required this.lesson, required this.content});

  final StudentLesson lesson;
  final AsyncValue<LessonContent?> content;

  @override
  Widget build(BuildContext context) {
    if (lesson.media == null) return const SizedBox.shrink();
    return content.when(
      loading: () => const EmiCard(child: Text('Memuat media...')),
      error: (error, _) => EmiCard(child: Text('Media gagal dimuat: $error')),
      data: (value) {
        if (value == null || !value.hasUrl) {
          return const EmiCard(child: Text('URL media tidak tersedia.'));
        }
        if (lesson.media!.isImage) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              value.url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const EmiCard(child: Text('Gambar gagal dimuat.')),
            ),
          );
        }
        return EmiCard(
          child: SelectableText(
            'Media ${lesson.media!.mimeType}: ${value.url}',
          ),
        );
      },
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
