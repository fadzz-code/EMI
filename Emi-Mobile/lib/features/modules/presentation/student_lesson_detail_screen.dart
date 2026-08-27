import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/network/network_status_controller.dart';
import '../../../shared/media/media_opener.dart';
import '../../../shared/widgets/student_connectivity_banner.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../../dashboard/data/student_dashboard_providers.dart';
import '../data/student_module.dart';
import '../data/student_module_providers.dart';
import 'student_module_offline_providers.dart';
import 'student_module_offline_widgets.dart';
import 'student_module_ui_controller.dart';

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
    final lesson = ref.watch(
      offlineStudentLessonDetailProvider(widget.lessonId),
    );
    final content = ref.watch(
      offlineStudentLessonContentProvider(widget.lessonId),
    );
    final completion =
        ref
            .watch(studentLessonCompletionStateProvider(widget.lessonId))
            .valueOrNull ??
        LessonCompletionSyncStatus.idle;
    final networkMode = ref.watch(networkStatusControllerProvider).mode;

    return EmiScaffold(
      title: 'Detail Lesson',
      currentIndex: 1,
      onNavTap: (index) => _go(context, index),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(offlineStudentLessonDetailProvider(widget.lessonId));
          ref.invalidate(offlineStudentLessonContentProvider(widget.lessonId));
        },
        child: lesson.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            onRetry: () {
              ref.invalidate(offlineStudentLessonDetailProvider(widget.lessonId));
              ref.invalidate(offlineStudentLessonContentProvider(widget.lessonId));
            },
          ),
          data: (item) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
            StudentConnectivityBanner(mode: networkMode),
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
            if (completion != LessonCompletionSyncStatus.idle) ...[
              const SizedBox(height: EmiSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    completion == LessonCompletionSyncStatus.pending
                        ? Icons.schedule
                        : Icons.cloud_done_outlined,
                    size: 16,
                    color: StudentStyle.inkMuted,
                  ),
                  const SizedBox(width: EmiSpacing.xs),
                  Text(
                    completion == LessonCompletionSyncStatus.pending
                        ? 'Selesai · Pending sync'
                        : 'Selesai · Synced',
                    style: const TextStyle(color: StudentStyle.inkMuted),
                  ),
                ],
              ),
            ],
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
      ),
    );
  }

  Future<void> _complete(StudentLesson lesson) async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(studentLessonCompletionControllerProvider)
          .complete(lesson.id);
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

class _LessonCard extends ConsumerWidget {
  const _LessonCard({required this.lesson, required this.content});

  final StudentLesson lesson;
  final AsyncValue<LessonContent?> content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                _MediaBlock(
                  lesson: lesson,
                  content: content,
                  onRetry: () =>
                      ref.invalidate(studentLessonContentProvider(lesson.id)),
                ),
                if (lesson.hasTextContent ||
                    content.valueOrNull?.hasText == true) ...[
                  const SizedBox(height: EmiSpacing.md),
                  Text(
                    content.valueOrNull?.contentBody ?? lesson.contentBody!,
                    style: const TextStyle(
                      color: StudentStyle.ink,
                      height: 1.5,
                    ),
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

class _MediaBlock extends StatefulWidget {
  const _MediaBlock({
    required this.lesson,
    required this.content,
    required this.onRetry,
  });

  final StudentLesson lesson;
  final AsyncValue<LessonContent?> content;
  final VoidCallback onRetry;

  @override
  State<_MediaBlock> createState() => _MediaBlockState();
}

class _MediaBlockState extends State<_MediaBlock> {
  final _player = AudioPlayer();
  final _opener = const ExternalMediaOpener();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.content.when(
      loading: () => _notice('Memuat konten...'),
      error: (_, _) => _notice('Konten gagal dimuat.', retry: true),
      data: (content) {
        final type = content?.type ?? widget.lesson.contentType;
        final media = content?.media ?? widget.lesson.media;
        final url = content?.url ?? widget.lesson.externalUrl;
        if (type == 'text') return const SizedBox.shrink();
        if (url == null || url.trim().isEmpty) {
          return OfflineUnavailableMessage(onRetry: widget.onRetry);
        }
        final local = _localPath(url);
        if (type == 'image' || media?.isImage == true) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(EmiRadii.card),
            child: local == null
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _notice('Gambar gagal dimuat.', retry: true),
                  )
                : Image.file(
                    File(local),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _notice('Gambar offline tidak tersedia.', retry: true),
                  ),
          );
        }
        if (type == 'audio' || media?.isAudio == true) {
          return StudentCard(
            child: StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) => Row(
                children: [
                  IconButton.filled(
                    onPressed: _busy
                        ? null
                        : () =>
                              _toggleAudio(url, snapshot.data?.playing == true),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            snapshot.data?.playing == true
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                  ),
                  const SizedBox(width: EmiSpacing.sm),
                  Expanded(child: Text(_error ?? 'Putar audio materi')),
                ],
              ),
            ),
          );
        }
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : () => _open(url),
            icon: const Icon(Icons.open_in_new),
            label: Text(
              type == 'pdf'
                  ? 'Buka PDF'
                  : type == 'video'
                  ? 'Putar video'
                  : 'Buka tautan',
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleAudio(String url, bool playing) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (playing) {
        await _player.pause();
      } else {
        if (_player.audioSource == null) {
          final local = _localPath(url);
          if (local == null) {
            await _player.setUrl(url);
          } else {
            await _player.setFilePath(local);
          }
        }
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Audio gagal diputar. Coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(String url) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final local = _localPath(url);
      final opened = local == null
          ? await _opener.open(url)
          : await launchUrl(Uri.file(local));
      if (!opened) throw const FormatException();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konten gagal dibuka. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _localPath(String value) {
    final uri = Uri.tryParse(value);
    if (uri?.scheme == 'file') return uri!.toFilePath();
    if (uri?.scheme.isEmpty ?? true) return value;
    return null;
  }

  Widget _notice(String text, {bool retry = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EmiSpacing.md),
      decoration: BoxDecoration(
        color: StudentStyle.tint,
        borderRadius: BorderRadius.circular(EmiRadii.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: StudentStyle.inkMuted),
            ),
          ),
          if (retry)
            TextButton(
              onPressed: widget.onRetry,
              child: const Text('Coba Lagi'),
            ),
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
          title: 'Lesson Belum Bisa Dimuat',
          message: 'Periksa koneksi internetmu, lalu coba lagi.',
          onRetry: onRetry,
        ),
      ],
    );
  }
}
