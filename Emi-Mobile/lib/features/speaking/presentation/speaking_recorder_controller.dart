import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class SpeakingRecorderState {
  const SpeakingRecorderState({
    this.path,
    this.duration = Duration.zero,
    this.recording = false,
    this.permissionDenied = false,
    this.permanentlyDenied = false,
    this.error,
  });

  final String? path;
  final Duration duration;
  final bool recording;
  final bool permissionDenied;
  final bool permanentlyDenied;
  final String? error;

  SpeakingRecorderState copyWith({
    String? path,
    bool clearPath = false,
    Duration? duration,
    bool? recording,
    bool? permissionDenied,
    bool? permanentlyDenied,
    String? error,
    bool clearError = false,
  }) {
    return SpeakingRecorderState(
      path: clearPath ? null : path ?? this.path,
      duration: duration ?? this.duration,
      recording: recording ?? this.recording,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      permanentlyDenied: permanentlyDenied ?? this.permanentlyDenied,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final speakingRecorderProvider = StateNotifierProvider.autoDispose
    .family<SpeakingRecorderController, SpeakingRecorderState, String>(
      (ref, exerciseId) => SpeakingRecorderController(),
    );

class SpeakingRecorderController extends StateNotifier<SpeakingRecorderState> {
  SpeakingRecorderController() : super(const SpeakingRecorderState());

  final _recorder = AudioRecorder();
  Timer? _timer;

  Future<void> start() async {
    await stop(delete: false);
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      state = state.copyWith(
        permissionDenied: true,
        permanentlyDenied: status.isPermanentlyDenied,
        clearError: true,
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}${Platform.pathSeparator}emi-speaking-${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
    state = SpeakingRecorderState(path: path, recording: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = state.duration + const Duration(seconds: 1);
      if (next.inSeconds >= 30) {
        state = state.copyWith(duration: const Duration(seconds: 30));
        unawaited(stop());
      } else {
        state = state.copyWith(duration: next);
      }
    });
  }

  Future<void> stop({bool delete = false}) async {
    _timer?.cancel();
    _timer = null;
    if (await _recorder.isRecording()) {
      final path = await _recorder.stop();
      state = state.copyWith(path: path, recording: false);
    }
    if (delete && state.path != null) {
      await File(state.path!).delete().catchError((_) => File(state.path!));
      state = state.copyWith(clearPath: true, duration: Duration.zero);
    } else {
      state = state.copyWith(recording: false);
    }
  }

  Future<void> deleteRecording() => stop(delete: true);

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_recorder.stop().catchError((_) => null));
    _recorder.dispose();
    super.dispose();
  }
}
