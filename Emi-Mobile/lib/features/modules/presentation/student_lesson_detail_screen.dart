import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : () => _complete(item),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Tandai Selesai'),
              ),
            ),
            const SizedBox(height: EmiSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => widget.moduleId == null
                    ? context.go('/student/modules')
                    : context.go('/student/modules/${widget.moduleId}'),
                child: const Text('Kembali ke Modul'),
              ),
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
    if (index == 2) context.go('/student/dictionary');
    if (index == 3) context.go('/student/quizzes');
    if (index == 4) context.go('/student/profile');
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.content});

  final StudentLesson lesson;
  final AsyncValue<LessonContent?> content;

  @override
  Widget build(BuildContext context) {
    return StudentCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(EmiSpacing.md),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFB877), Color(0xFFFF8A3D)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (lesson.description != null) ...[
                  const SizedBox(height: EmiSpacing.xs),
                  Text(
                    lesson.description!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
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
                  Text(
                    lesson.contentBody!,
                    style: const TextStyle(
                      color: StudentStyle.ink,
                      height: 1.5,
                    ),
                  )
                else if (lesson.hasExternalUrl)
                  SelectableText(
                    lesson.externalUrl!,
                    style: const TextStyle(color: EmiColors.primary),
                  )
                else
                  const Text(
                    'Konten teks belum tersedia untuk lesson ini.',
                    style: TextStyle(color: StudentStyle.inkMuted),
                  ),
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
      loading: () => _mediaNotice(context, 'Memuat media...'),
      error: (error, _) => _mediaNotice(context, 'Media gagal dimuat.'),
      data: (value) {
        if (value == null || !value.hasUrl) {
          return _mediaNotice(context, 'URL media tidak tersedia.');
        }
        if (lesson.media!.isImage) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(EmiRadii.card),
            child: Image.network(
              value.url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  _mediaNotice(context, 'Gambar gagal dimuat.'),
            ),
          );
        }
        return _mediaNotice(
          context,
          'Media ${lesson.media!.mimeType}: ${value.url}',
        );
      },
    );
  }

  Widget _mediaNotice(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EmiSpacing.md),
      decoration: BoxDecoration(
        color: StudentStyle.tint,
        borderRadius: BorderRadius.circular(EmiRadii.card),
      ),
      child: Text(text, style: const TextStyle(color: StudentStyle.inkMuted)),
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
          title: 'Lesson Belum Bisa Dimuat',
          message: 'Periksa koneksi internetmu, lalu coba lagi.',
          onRetry: onRetry,
        ),
      ],
    );
  }
}
