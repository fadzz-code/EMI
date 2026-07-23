import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../data/speaking_models.dart';
import '../data/speaking_providers.dart';
import '../data/speaking_repository.dart';
import 'speaking_recorder_controller.dart';

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
  Timer? _pollTimer;
  var _pollCount = 0;

  @override
  void dispose() {
    _pollTimer?.cancel();
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
            message: error.toString(),
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
              if (recorder.path != null) ...[
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
                  loading: () => const EmiCard(child: Text('Memuat status...')),
                  error: (error, _) => _ErrorState(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(speakingAttemptProvider(_attemptId!)),
                  ),
                  data: _AttemptResultCard.new,
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

  void _startBoundedPolling(String attemptId) {
    _pollTimer?.cancel();
    _pollCount = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_pollCount++ >= 12) {
        timer.cancel();
        return;
      }
      try {
        final next = await ref.refresh(
          speakingAttemptProvider(attemptId).future,
        );
        if (!next.isProcessing) timer.cancel();
      } catch (_) {
        timer.cancel();
      }
    });
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});

  final SpeakingExercise exercise;

  @override
  Widget build(BuildContext context) {
    return EmiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: EmiSpacing.sm),
          if (exercise.promptText != null) Text(exercise.promptText!),
          if (exercise.targetText != null) ...[
            const SizedBox(height: EmiSpacing.md),
            Text('Target', style: Theme.of(context).textTheme.labelLarge),
            Text(
              exercise.targetText!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
          if (exercise.targetTranslation != null)
            Text(exercise.targetTranslation!),
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
    return EmiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rekam Suara', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: EmiSpacing.sm),
          Text('Durasi: ${state.duration.inSeconds}s / 30s'),
          if (state.permissionDenied) ...[
            const SizedBox(height: EmiSpacing.sm),
            Text(
              state.permanentlyDenied
                  ? 'Izin mikrofon diblokir.'
                  : 'Izin mikrofon ditolak.',
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
    return EmiCard(
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: widget.player.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing == true;
              return IconButton.filled(
                onPressed: _loading ? null : () => _toggle(playing),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(playing ? Icons.pause : Icons.play_arrow),
              );
            },
          ),
          const SizedBox(width: EmiSpacing.md),
          Expanded(child: Text(_error ?? widget.title)),
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
    return EmiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            onPressed: submitting ? null : onSubmit,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Text(submitting ? 'Mengirim...' : 'Submit Attempt'),
          ),
          if (submitting)
            LinearProgressIndicator(value: progress == 0 ? null : progress),
          if (error != null)
            Text(error!, style: const TextStyle(color: EmiColors.error)),
        ],
      ),
    );
  }
}

class _AttemptResultCard extends ConsumerStatefulWidget {
  const _AttemptResultCard(this.attempt);

  final SpeakingAttempt attempt;

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
    return EmiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Status: ${attempt.status}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(speakingAttemptProvider(attempt.id)),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
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
          if (attempt.isProcessing)
            const Text(
              'Analisis AI sedang diproses. Refresh manual atau tunggu polling terbatas.',
            ),
          if (attempt.aiScore != null) Text('Skor AI: ${attempt.aiScore}'),
          if (attempt.aiTranscription != null)
            Text('Transkripsi: ${attempt.aiTranscription}'),
          if (attempt.aiAlignment != null)
            Text('Detail analisis: ${attempt.aiAlignment}'),
          if (attempt.aiError != null) Text('Error AI: ${attempt.aiError}'),
          if (attempt.teacherScore != null)
            Text('Nilai guru: ${attempt.teacherScore}'),
          if (attempt.teacherFeedback != null)
            Text('Feedback guru: ${attempt.teacherFeedback}'),
        ],
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: EmiSpacing.sm),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
