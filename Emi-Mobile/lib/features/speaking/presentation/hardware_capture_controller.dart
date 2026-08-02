import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/hardware_bluetooth_service.dart';
import '../data/hardware_packet_parser.dart';
import '../data/hardware_wav_writer.dart';

/// Mirrors the web ESP32 capture state machine
/// (`Emi-Frontend/src/features/student/use-esp32-serial-capture.ts`)
/// adapted for the mobile SPP link. Playback is intentionally not part of
/// this state machine: once paired, Android routes app audio (reference
/// audio, recorded preview, attempt playback) to the ESP32 speaker via
/// A2DP automatically, so the existing `just_audio` players in
/// `student_speaking_detail_screen.dart` need no hardware-specific
/// handling.
enum HardwareCaptureState {
  disconnected,
  connecting,
  connected,
  recording,
  finalizing,
  captured,
  error,
}

class HardwareCaptureData {
  const HardwareCaptureData({
    this.state = HardwareCaptureState.disconnected,
    this.recordedPath,
    this.recordedDurationSeconds = 0,
    this.error,
    this.notice,
  });

  final HardwareCaptureState state;
  final String? recordedPath;
  final int recordedDurationSeconds;
  final String? error;
  final String? notice;

  HardwareCaptureData copyWith({
    HardwareCaptureState? state,
    String? recordedPath,
    bool clearRecordedPath = false,
    int? recordedDurationSeconds,
    String? error,
    bool clearError = false,
    String? notice,
    bool clearNotice = false,
  }) {
    return HardwareCaptureData(
      state: state ?? this.state,
      recordedPath: clearRecordedPath
          ? null
          : recordedPath ?? this.recordedPath,
      recordedDurationSeconds:
          recordedDurationSeconds ?? this.recordedDurationSeconds,
      error: clearError ? null : error ?? this.error,
      notice: clearNotice ? null : notice ?? this.notice,
    );
  }
}

final hardwareCaptureProvider =
    StateNotifierProvider.autoDispose<
      HardwareCaptureController,
      HardwareCaptureData
    >((ref) => HardwareCaptureController());

/// Bytes-per-second for mono 16 kHz signed 16-bit PCM, matching the web
/// constant in `pcm-wav.ts` (`PCM_BYTES_PER_SECOND`).
const int _pcmBytesPerSecond = 32000;

/// Same cap as the web integration: min(5 MiB upload minus 44-byte WAV
/// header, 30 seconds of PCM) so a runaway hardware stream cannot exceed
/// what Laravel's upload endpoint will accept.
const int _maxPcmBytes = 960000;

class HardwareCaptureController extends StateNotifier<HardwareCaptureData> {
  HardwareCaptureController({HardwareBluetoothService? service})
    : _service = service ?? HardwareBluetoothService(),
      super(const HardwareCaptureData());

  final HardwareBluetoothService _service;
  HardwareWavWriter? _writer;
  bool _busy = false;

  Future<void> connect() async {
    if (_busy || state.state == HardwareCaptureState.connecting) return;
    _busy = true;
    state = state.copyWith(
      state: HardwareCaptureState.connecting,
      clearError: true,
      clearNotice: true,
    );
    try {
      final result = await _service.connect(
        onPacket: _handlePacket,
        onDisconnected: _handleDisconnected,
      );
      switch (result.status) {
        case HardwareLinkStatus.connected:
          state = state.copyWith(state: HardwareCaptureState.connected);
        case HardwareLinkStatus.permissionDenied:
          state = state.copyWith(
            state: HardwareCaptureState.error,
            error: result.message,
          );
        case HardwareLinkStatus.notPaired:
          state = state.copyWith(
            state: HardwareCaptureState.disconnected,
            error: result.message,
          );
        case HardwareLinkStatus.error:
          state = state.copyWith(
            state: HardwareCaptureState.error,
            error: result.message,
          );
        case HardwareLinkStatus.disconnected:
        case HardwareLinkStatus.connecting:
          state = state.copyWith(state: HardwareCaptureState.disconnected);
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> disconnect() async {
    await _writer?.abort();
    _writer = null;
    await _service.disconnect();
    state = const HardwareCaptureData();
  }

  void _handleDisconnected() {
    final wasCapturing =
        state.state == HardwareCaptureState.recording ||
        state.state == HardwareCaptureState.finalizing;
    unawaited(_writer?.abort());
    _writer = null;
    state = state.copyWith(
      state: HardwareCaptureState.disconnected,
      error: wasCapturing
          ? 'Sambungan alat terputus saat merekam. Hubungkan kembali lalu ulangi rekaman.'
          : null,
    );
  }

  void _handlePacket(HardwarePacket packet) {
    if (packet.type == kHardwareControlPacketType &&
        packet.payload.length == 1) {
      final value = packet.payload[0];
      if (value == kHardwarePttPressed &&
          state.state != HardwareCaptureState.recording) {
        unawaited(_startRecording());
      } else if (value == kHardwarePttReleased &&
          state.state == HardwareCaptureState.recording) {
        unawaited(_finishRecording());
      }
      return;
    }

    if (packet.type == kHardwarePcmPacketType &&
        state.state == HardwareCaptureState.recording) {
      final writer = _writer;
      if (writer == null || !writer.isOpen) return;
      if (writer.bytesWritten + packet.payload.length > _maxPcmBytes) {
        unawaited(_abortRecordingWithError('Rekaman melewati batas 30 detik.'));
        return;
      }
      writer.addPcm(packet.payload);
    }
  }

  Future<void> _startRecording() async {
    await _writer?.abort();
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}${Platform.pathSeparator}emi-hardware-${DateTime.now().millisecondsSinceEpoch}.wav';
    final writer = HardwareWavWriter(filePath: path);
    await writer.open();
    _writer = writer;
    state = state.copyWith(
      state: HardwareCaptureState.recording,
      clearRecordedPath: true,
      recordedDurationSeconds: 0,
      clearError: true,
    );
  }

  Future<void> _finishRecording() async {
    final writer = _writer;
    if (writer == null) return;
    state = state.copyWith(state: HardwareCaptureState.finalizing);
    final path = await writer.finish(minimumBytes: 3200);
    _writer = null;
    if (path == null) {
      state = state.copyWith(
        state: HardwareCaptureState.connected,
        error: 'Rekaman terlalu singkat. Tekan PTT lebih lama lalu coba lagi.',
      );
      return;
    }
    final durationSeconds = (writer.bytesWritten / _pcmBytesPerSecond).ceil();
    state = state.copyWith(
      state: HardwareCaptureState.captured,
      recordedPath: path,
      recordedDurationSeconds: durationSeconds,
      clearError: true,
    );
  }

  Future<void> _abortRecordingWithError(String message) async {
    await _writer?.abort();
    _writer = null;
    state = state.copyWith(
      state: HardwareCaptureState.connected,
      error: message,
    );
  }

  Future<void> discardRecording() async {
    final path = state.recordedPath;
    if (path != null) {
      await File(path).delete().catchError((_) => File(path));
    }
    state = state.copyWith(
      state: HardwareCaptureState.connected,
      clearRecordedPath: true,
      recordedDurationSeconds: 0,
    );
  }

  @override
  void dispose() {
    unawaited(_writer?.abort());
    unawaited(_service.dispose());
    super.dispose();
  }
}
