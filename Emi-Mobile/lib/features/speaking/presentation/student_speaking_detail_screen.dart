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
import 'hardware_capture_controller.dart';
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

enum _CaptureSource { microphone, hardware }

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
  var _captureSource = _CaptureSource.microphone;

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
    final hardware = ref.watch(hardwareCaptureProvider);
    final attempt = _attemptId == null
        ? null
        : ref.watch(speakingAttemptProvider(_attemptId!));
    final hardwareBusy =
        hardware.state == HardwareCaptureState.recording ||
        hardware.state == HardwareCaptureState.finalizing;

    return PopScope(
      canPop: !recorder.recording && !hardwareBusy && !_submitting,
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
              _CaptureSourceSwitch(
                source: _captureSource,
                disabled:
                    recorder.recording || hardwareBusy || _submitting,
                onChanged: (source) async {
                  if (source == _captureSource) return;
                  if (source == _CaptureSource.microphone) {
                    await ref
                        .read(hardwareCaptureProvider.notifier)
                        .disconnect();
                  } else {
                    await ref
                        .read(
                          speakingRecorderProvider(
                            widget.exerciseId,
                          ).notifier,
                        )
                        .deleteRecording();
                  }
                  setState(() => _captureSource = source);
                },
              ),
              const SizedBox(height: EmiSpacing.md),
              if (_captureSource == _CaptureSource.microphone)
                _RecorderCard(
                  state: recorder,
                  onStart: () async {
                    await _referencePlayer.pause();
                    await _previewPlayer.pause();
                    await ref
                        .read(
                          speakingRecorderProvider(
                            widget.exerciseId,
                          ).notifier,
                        )
                        .start();
                  },
                  onStop: () => ref
                      .read(
                        speakingRecorderProvider(widget.exerciseId).notifier,
                      )
                      .stop(),
                  onDelete: () async {
                    await _previewPlayer.stop();
                    await ref
                        .read(
                          speakingRecorderProvider(
                            widget.exerciseId,
                          ).notifier,
                        )
                        .deleteRecording();
                  },
                  onOpenSettings: openAppSettings,
                )
              else
                _HardwareCaptureCard(
                  data: hardware,
                  onConnect: () =>
                      ref.read(hardwareCaptureProvider.notifier).connect(),
                  onDisconnect: () =>
                      ref.read(hardwareCaptureProvider.notifier).disconnect(),
                  onOpenSettings: openAppSettings,
                ),
              if (_captureSource == _CaptureSource.microphone &&
                  recorder.path != null) ...[
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
                  onSubmit: () => _submit(
                    recorder.path!,
                    recorder.duration,
                    'mobile_microphone',
                  ),
                ),
              ],
              if (_captureSource == _CaptureSource.hardware &&
                  hardware.recordedPath != null) ...[
                const SizedBox(height: EmiSpacing.md),
                _AudioBox(
                  title: 'Preview Rekaman Alat',
                  player: _previewPlayer,
                  url: hardware.recordedPath!,
                  beforePlay: () => _referencePlayer.pause(),
                  local: true,
                ),
                const SizedBox(height: EmiSpacing.md),
                _SubmitCard(
                  submitting: _submitting,
                  progress: _progress,
                  error: _error,
                  onSubmit: () => _submit(
                    hardware.recordedPath!,
                    Duration(seconds: hardware.recordedDurationSeconds),
                    'mobile_esp32_bluetooth',
                  ),
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

  Future<void> _submit(
    String path,
    Duration duration,
    String captureSource,
  ) async {
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
            captureSource: captureSource,
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

class _CaptureSourceSwitch extends StatelessWidget {
  const _CaptureSourceSwitch({
    required this.source,
    required this.disabled,
    required this.onChanged,
  });

  final _CaptureSource source;
  final bool disabled;
  final ValueChanged<_CaptureSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: disabled
                ? null
                : () => onChanged(_CaptureSource.microphone),
            icon: const Icon(Icons.mic),
            label: const Text('Mikrofon HP'),
            style: OutlinedButton.styleFrom(
              backgroundColor: source == _CaptureSource.microphone
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
            ),
          ),
        ),
        const SizedBox(width: EmiSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: disabled
                ? null
                : () => onChanged(_CaptureSource.hardware),
            icon: const Icon(Icons.bluetooth_audio),
            label: const Text('Alat Speaking EMI'),
            style: OutlinedButton.styleFrom(
              backgroundColor: source == _CaptureSource.hardware
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _HardwareCaptureCard extends StatelessWidget {
  const _HardwareCaptureCard({
    required this.data,
    required this.onConnect,
    required this.onDisconnect,
    required this.onOpenSettings,
  });

  final HardwareCaptureData data;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onOpenSettings;

  String get _statusLabel {
    switch (data.state) {
      case HardwareCaptureState.disconnected:
        return 'Alat belum terhubung.';
      case HardwareCaptureState.connecting:
        return 'Menghubungkan ke alat...';
      case HardwareCaptureState.connected:
        return 'Alat siap. Tekan tombol PTT pada alat untuk mulai merekam.';
      case HardwareCaptureState.recording:
        return 'Sedang merekam dari alat...';
      case HardwareCaptureState.finalizing:
        return 'Menyiapkan rekaman...';
      case HardwareCaptureState.captured:
        return 'Rekaman dari alat siap dikirim.';
      case HardwareCaptureState.error:
        return 'Terjadi masalah pada alat.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected =
        data.state != HardwareCaptureState.disconnected &&
        data.state != HardwareCaptureState.error;
    final busy =
        data.state == HardwareCaptureState.connecting ||
        data.state == HardwareCaptureState.recording ||
        data.state == HardwareCaptureState.finalizing;

    return EmiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alat Speaking EMI',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: EmiSpacing.sm),
          Text(_statusLabel),
          if (data.error != null) ...[
            const SizedBox(height: EmiSpacing.sm),
            Text(
              data.error!,
              style: const TextStyle(color: EmiColors.error),
            ),
          ],
          const SizedBox(height: EmiSpacing.md),
          Wrap(
            spacing: EmiSpacing.sm,
            children: [
              if (!connected)
                FilledButton.icon(
                  onPressed: busy ? null : onConnect,
                  icon: const Icon(Icons.bluetooth_searching),
                  label: Text(
                    data.state == HardwareCaptureState.connecting
                        ? 'Menghubungkan...'
                        : 'Sambungkan Alat',
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed:
                      data.state == HardwareCaptureState.recording ||
                          data.state == HardwareCaptureState.finalizing
                      ? null
                      : onDisconnect,
                  icon: const Icon(Icons.bluetooth_disabled),
                  label: const Text('Putuskan'),
                ),
              OutlinedButton(
                onPressed: onOpenSettings,
                child: const Text('Pengaturan Bluetooth'),
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
            Text(widget.pollingMessage ?? 'Analisis AI sedang diproses.'),
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
