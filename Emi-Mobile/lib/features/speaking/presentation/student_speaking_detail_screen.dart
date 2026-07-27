import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../data/speaking_models.dart';
import '../data/speaking_providers.dart';
import '../data/speaking_repository.dart';
import 'speaking_recorder_controller.dart';

enum SpeakingPollingStop { terminal, timeout, error }

class SpeakingPollingController {
  SpeakingPollingController({
    required this.fetch,
    this.maxPolls = 12,
    this.interval = const Duration(seconds: 5),
  });

  final Future<SpeakingAttempt> Function() fetch;
  final int maxPolls;
  final Duration interval;
  bool _disposed = false;
  bool _running = false;

  Future<SpeakingPollingStop> poll() async {
    if (_running) return SpeakingPollingStop.error;
    _running = true;
    try {
      for (var count = 0; count < maxPolls && !_disposed; count++) {
        if (interval > Duration.zero) await Future<void>.delayed(interval);
        if (_disposed) return SpeakingPollingStop.error;
        try {
          final attempt = await fetch();
          if (_disposed) return SpeakingPollingStop.error;
          if (!attempt.isProcessing) return SpeakingPollingStop.terminal;
        } catch (_) {
          return SpeakingPollingStop.error;
        }
      }
      return SpeakingPollingStop.timeout;
    } finally {
      _running = false;
    }
  }

  void dispose() => _disposed = true;
}

class StudentSpeakingDetailScreen extends ConsumerStatefulWidget {
  const StudentSpeakingDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  ConsumerState<StudentSpeakingDetailScreen> createState() =>
      _StudentSpeakingDetailScreenState();
}

class _StudentSpeakingDetailScreenState
    extends ConsumerState<StudentSpeakingDetailScreen> {
  final _referencePlayer = AudioPlayer();
  final _previewPlayer = AudioPlayer();
  var _submitting = false;
  var _progress = 0.0;
  String? _attemptId;
  String? _error;
  SpeakingPollingController? _polling;
  String? _pollingMessage;

  @override
  void dispose() {
    _polling?.dispose();
    _referencePlayer.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = ref.watch(speakingExerciseProvider(widget.exerciseId));
    final recorder = ref.watch(speakingRecorderProvider(widget.exerciseId));
    final attempt = _attemptId == null
        ? null
        : ref.watch(speakingAttemptProvider(_attemptId!));

    return PopScope(
      canPop: !recorder.recording && !_submitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Keluar dari latihan?'),
            content: const Text('Rekaman/upload masih berjalan.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Keluar'),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.pop(context);
      },
      child: EmiScaffold(
        title: 'Latihan Speaking',
        child: exercise.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            onRetry: () =>
                ref.invalidate(speakingExerciseProvider(widget.exerciseId)),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              _ExerciseCard(exercise: data),
              const SizedBox(height: EmiSpacing.md),
              if (data.referenceAudio?.url != null ||
                  data.referenceAudioMediaId != null)
                _AudioBox(
                  title: 'Suara Asli',
                  player: _referencePlayer,
                  url: data.referenceAudio?.url,
                  mediaId: data.referenceAudioMediaId,
                  repository: ref.read(speakingRepositoryProvider),
                  beforePlay: () => _previewPlayer.pause(),
                ),
              if (data.referenceAudio?.url != null ||
                  data.referenceAudioMediaId != null)
                const SizedBox(height: EmiSpacing.md),
              _RecorderCard(
                state: recorder,
                onStart: () async {
                  await _referencePlayer.pause();
                  await _previewPlayer.pause();
                  await ref
                      .read(
                        speakingRecorderProvider(widget.exerciseId).notifier,
                      )
                      .start();
                },
                onStop: () => ref
                    .read(speakingRecorderProvider(widget.exerciseId).notifier)
                    .stop(),
                onDelete: () async {
                  await _previewPlayer.stop();
                  await ref
                      .read(
                        speakingRecorderProvider(widget.exerciseId).notifier,
                      )
                      .deleteRecording();
                },
                onOpenSettings: openAppSettings,
              ),
              if (recorder.path != null && !recorder.recording) ...[
                const SizedBox(height: EmiSpacing.md),
                _AudioBox(
                  title: 'Preview Rekaman',
                  player: _previewPlayer,
                  url: recorder.path!,
                  beforePlay: () => _referencePlayer.pause(),
                  local: true,
                ),
                const SizedBox(height: EmiSpacing.md),
                _SubmitCard(
                  submitting: _submitting,
                  progress: _progress,
                  error: _error,
                  onSubmit: () => _submit(recorder.path!, recorder.duration),
                ),
              ],
              if (attempt != null) ...[
                const SizedBox(height: EmiSpacing.md),
                attempt.when(
                  loading: () => const StudentCard(
                    child: Text(
                      'Memuat status...',
                      style: TextStyle(color: StudentStyle.inkMuted),
                    ),
                  ),
                  error: (error, _) => _ErrorState(
                    onRetry: () =>
                        ref.invalidate(speakingAttemptProvider(_attemptId!)),
                  ),
                  data: (data) =>
                      _AttemptResultCard(data, pollingMessage: _pollingMessage),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(String path, Duration duration) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _progress = 0;
      _error = null;
      _attemptId = null;
    });
    try {
      final file = await speakingFileFromPath(path);
      final attempt = await ref
          .read(speakingRepositoryProvider)
          .submitAttempt(
            exerciseId: widget.exerciseId,
            file: file,
            durationSeconds: duration.inSeconds == 0
                ? null
                : duration.inSeconds,
            onSendProgress: (sent, total) {
              if (mounted && total > 0) {
                setState(() => _progress = sent / total);
              }
            },
          );
      if (!mounted) return;
      setState(() => _attemptId = attempt.id);
      _startBoundedPolling(attempt.id);
      ref.invalidate(speakingAttemptsProvider);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _startBoundedPolling(String attemptId) async {
    _polling?.dispose();
    final polling = SpeakingPollingController(
      fetch: () => ref.refresh(speakingAttemptProvider(attemptId).future),
    );
    _polling = polling;
    if (mounted) setState(() => _pollingMessage = null);
    final stop = await polling.poll();
    if (!mounted || _polling != polling) return;
    if (stop == SpeakingPollingStop.timeout) {
      setState(
        () => _pollingMessage =
            'Analisis belum selesai. Tekan Refresh untuk memeriksa lagi.',
      );
    } else if (stop == SpeakingPollingStop.error) {
      setState(
        () => _pollingMessage =
            'Status analisis gagal diperbarui. Tekan Refresh untuk mencoba lagi.',
      );
    }
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});

  final SpeakingExercise exercise;

  @override
  Widget build(BuildContext context) {
    return StudentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: StudentStyle.ink),
          ),
          const SizedBox(height: EmiSpacing.sm),
          if (exercise.promptText != null)
            Text(
              exercise.promptText!,
              style: const TextStyle(color: StudentStyle.inkMuted),
            ),
          if (exercise.targetText != null) ...[
            const SizedBox(height: EmiSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(EmiSpacing.md),
              decoration: BoxDecoration(
                color: StudentStyle.tint,
                borderRadius: BorderRadius.circular(EmiRadii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Target',
                    style: TextStyle(
                      color: StudentStyle.inkMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.targetText!,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: StudentStyle.ink),
                  ),
                  if (exercise.targetTranslation != null)
                    Text(
                      exercise.targetTranslation!,
                      style: const TextStyle(color: StudentStyle.inkMuted),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecorderCard extends StatelessWidget {
  const _RecorderCard({
    required this.state,
    required this.onStart,
    required this.onStop,
    required this.onDelete,
    required this.onOpenSettings,
  });

  final SpeakingRecorderState state;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onDelete;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return StudentCard(
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
                child: const Icon(Icons.mic, color: EmiColors.primary),
              ),
              const SizedBox(width: EmiSpacing.sm),
              Expanded(
                child: Text(
                  'Rekam Suara',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: StudentStyle.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: EmiSpacing.sm),
          Text(
            'Durasi: ${state.duration.inSeconds}s / 30s',
            style: const TextStyle(color: StudentStyle.inkMuted),
          ),
          if (state.permissionDenied) ...[
            const SizedBox(height: EmiSpacing.sm),
            Text(
              state.permanentlyDenied
                  ? 'Izin mikrofon diblokir.'
                  : 'Izin mikrofon ditolak.',
              style: const TextStyle(color: EmiColors.error),
            ),
          ],
          const SizedBox(height: EmiSpacing.md),
          Wrap(
            spacing: EmiSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: state.recording ? onStop : onStart,
                icon: Icon(state.recording ? Icons.stop : Icons.mic),
                label: Text(
                  state.recording
                      ? 'Stop'
                      : state.path == null
                      ? 'Rekam'
                      : 'Rekam Ulang',
                ),
              ),
              if (state.path != null)
                OutlinedButton.icon(
                  onPressed: state.recording ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus'),
                ),
              if (state.permanentlyDenied)
                OutlinedButton(
                  onPressed: onOpenSettings,
                  child: const Text('Buka Pengaturan'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudioBox extends StatefulWidget {
  const _AudioBox({
    required this.title,
    required this.player,
    required this.beforePlay,
    this.url,
    this.mediaId,
    this.repository,
    this.local = false,
  });

  final String title;
  final AudioPlayer player;
  final String? url;
  final String? mediaId;
  final SpeakingRepository? repository;
  final Future<void> Function() beforePlay;
  final bool local;

  @override
  State<_AudioBox> createState() => _AudioBoxState();
}

class _AudioBoxState extends State<_AudioBox> {
  var _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return StudentCard(
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: widget.player.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing == true;
              return IconButton.filled(
                onPressed: _loading ? null : () => _toggle(playing),
                style: IconButton.styleFrom(
                  backgroundColor: EmiColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(playing ? Icons.pause : Icons.play_arrow),
              );
            },
          ),
          const SizedBox(width: EmiSpacing.md),
          Expanded(
            child: Text(
              _error ?? widget.title,
              style: TextStyle(
                color: _error != null ? EmiColors.error : StudentStyle.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(bool playing) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (playing) {
        await widget.player.pause();
      } else {
        await widget.beforePlay();
        if (widget.player.audioSource == null) {
          if (widget.local) {
            await widget.player.setFilePath(widget.url!);
          } else {
            await widget.player.setUrl(await _playbackUrl());
          }
        }
        await widget.player.play();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Audio gagal diputar.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String> _playbackUrl() async {
    final url = widget.url;
    if (url != null && url.isNotEmpty) return url;
    final mediaId = widget.mediaId;
    final repository = widget.repository;
    if (mediaId != null && mediaId.isNotEmpty && repository != null) {
      return repository.temporaryMediaUrl(mediaId);
    }
    throw const AppError(
      type: AppErrorType.unknown,
      message: 'Audio tidak tersedia.',
    );
  }
}

class _SubmitCard extends StatelessWidget {
  const _SubmitCard({
    required this.submitting,
    required this.progress,
    required this.error,
    required this.onSubmit,
  });

  final bool submitting;
  final double progress;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return StudentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: submitting ? null : onSubmit,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(submitting ? 'Mengirim...' : 'Kumpulkan Rekaman'),
            ),
          ),
          if (submitting) ...[
            const SizedBox(height: EmiSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(EmiRadii.pill),
              child: LinearProgressIndicator(
                value: progress == 0 ? null : progress,
                minHeight: 8,
                backgroundColor: StudentStyle.tintStrong,
                valueColor: const AlwaysStoppedAnimation(EmiColors.primary),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: EmiSpacing.sm),
            Text(error!, style: const TextStyle(color: EmiColors.error)),
          ],
        ],
      ),
    );
  }
}

class _AttemptResultCard extends ConsumerStatefulWidget {
  const _AttemptResultCard(this.attempt, {required this.pollingMessage});

  final SpeakingAttempt attempt;
  final String? pollingMessage;

  @override
  ConsumerState<_AttemptResultCard> createState() => _AttemptResultCardState();
}

class _AttemptResultCardState extends ConsumerState<_AttemptResultCard> {
  final _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attempt = widget.attempt;
    return StudentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Status: ${attempt.status}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: StudentStyle.ink),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(speakingAttemptProvider(attempt.id)),
                icon: const Icon(Icons.refresh),
                label: const Text('Muat Ulang'),
              ),
            ],
          ),
          if (attempt.audioUrl != null || attempt.audioMediaId != null) ...[
            const SizedBox(height: EmiSpacing.sm),
            _AudioBox(
              title: 'Rekaman Terkirim',
              player: _player,
              url: attempt.audioUrl,
              mediaId: attempt.audioMediaId,
              repository: ref.read(speakingRepositoryProvider),
              beforePlay: () async {},
            ),
          ],
          if (attempt.isProcessing) ...[
            const SizedBox(height: EmiSpacing.sm),
            Text(
              widget.pollingMessage ?? 'Analisis AI sedang diproses.',
              style: const TextStyle(color: StudentStyle.inkMuted),
            ),
          ],
          if (attempt.aiScore != null)
            _row(context, 'Skor AI', '${attempt.aiScore}'),
          if (attempt.aiTranscription != null)
            _row(context, 'Transkripsi', attempt.aiTranscription!),
          if (attempt.aiAlignment != null)
            _row(context, 'Detail analisis', '${attempt.aiAlignment}'),
          if (attempt.aiError != null)
            _row(context, 'Error AI', attempt.aiError!),
          if (attempt.teacherScore != null)
            _row(context, 'Nilai guru', '${attempt.teacherScore}'),
          if (attempt.teacherFeedback != null)
            _row(context, 'Feedback guru', attempt.teacherFeedback!),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: EmiSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: StudentStyle.inkMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(value, style: const TextStyle(color: StudentStyle.ink)),
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
          title: 'Latihan Belum Bisa Dimuat',
          message: 'Periksa koneksi internetmu, lalu coba lagi.',
          onRetry: onRetry,
        ),
      ],
    );
  }
}
