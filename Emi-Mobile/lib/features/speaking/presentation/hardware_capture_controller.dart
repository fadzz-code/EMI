import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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
const int _defaultMaxPcmBytes = 960000;

typedef HardwareCaptureDirectoryProvider = Future<Directory> Function();

class HardwareCaptureController extends StateNotifier<HardwareCaptureData> {
  HardwareCaptureController({
    HardwareBluetoothService? service,
    HardwareCaptureDirectoryProvider? directoryProvider,
    int maxPcmBytes = _defaultMaxPcmBytes,
  }) : _service = service ?? HardwareBluetoothService(),
       _directoryProvider = directoryProvider ?? getTemporaryDirectory,
       _maxPcmBytes = maxPcmBytes,
       super(const HardwareCaptureData());

  final HardwareBluetoothService _service;
  final HardwareCaptureDirectoryProvider _directoryProvider;
  final int _maxPcmBytes;
  HardwareWavWriter? _writer;
  bool _busy = false;
  bool _starting = false;
  bool _releasePending = false;
  bool _disposed = false;
  int _generation = 0;
  int _pendingPcmBytes = 0;
  final List<Uint8List> _pendingPcm = [];

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  Future<void> connect() async {
    if (_disposed || _busy || state.state == HardwareCaptureState.connecting) {
      return;
    }
    final generation = ++_generation;
    _busy = true;
    state = state.copyWith(
      state: HardwareCaptureState.connecting,
      clearError: true,
      clearNotice: true,
    );
    try {
      final result = await _service.connect(
        onPacket: (packet) {
          if (_isCurrent(generation)) _handlePacket(packet);
        },
        onDisconnected: () {
          if (_isCurrent(generation)) _handleDisconnected();
        },
      );
      if (!_isCurrent(generation)) return;
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
      if (_isCurrent(generation)) _busy = false;
    }
  }

  Future<void> disconnect() async {
    if (_disposed) return;
    _generation++;
    _busy = false;
    _starting = false;
    _releasePending = false;
    _pendingPcm.clear();
    _pendingPcmBytes = 0;
    final writer = _writer;
    _writer = null;
    state = const HardwareCaptureData();
    await writer?.abort();
    await _service.disconnect();
  }

  void _handleDisconnected() {
    final wasCapturing =
        state.state == HardwareCaptureState.recording ||
        state.state == HardwareCaptureState.finalizing;
    _generation++;
    _starting = false;
    _releasePending = false;
    _pendingPcm.clear();
    _pendingPcmBytes = 0;
    final writer = _writer;
    _writer = null;
    unawaited(writer?.abort());
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
          !_starting &&
          (state.state == HardwareCaptureState.connected ||
              state.state == HardwareCaptureState.captured)) {
        unawaited(_startRecording());
      } else if (value == kHardwarePttReleased) {
        if (_starting) {
          _releasePending = true;
        } else if (state.state == HardwareCaptureState.recording) {
          unawaited(_finishRecording());
        }
      }
      return;
    }

    if (packet.type == kHardwarePcmPacketType) {
      if (packet.payload.isEmpty || packet.payload.length.isOdd) return;
      if (_starting) {
        if (_pendingPcmBytes + packet.payload.length <= _maxPcmBytes) {
          _pendingPcm.add(Uint8List.fromList(packet.payload));
          _pendingPcmBytes += packet.payload.length;
        } else {
          unawaited(
            _abortRecordingWithError('Rekaman melewati batas 30 detik.'),
          );
        }
        return;
      }
      if (state.state != HardwareCaptureState.recording) return;
      final writer = _writer;
      if (writer == null || !writer.isOpen) return;
      if (writer.bytesWritten + packet.payload.length > _maxPcmBytes) {
        unawaited(_abortRecordingWithError('Rekaman melewati batas 30 detik.'));
        return;
      }
      try {
        writer.addPcm(packet.payload);
      } catch (_) {
        unawaited(
          _abortRecordingWithError(
            'Rekaman alat gagal disimpan. Coba rekam ulang.',
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    final generation = _generation;
    _starting = true;
    _releasePending = false;
    _pendingPcm.clear();
    _pendingPcmBytes = 0;
    HardwareWavWriter? writer;
    try {
      final dir = await _directoryProvider();
      if (!_isCurrent(generation) || !_starting) return;
      final path =
          '${dir.path}${Platform.pathSeparator}emi-hardware-${DateTime.now().millisecondsSinceEpoch}.wav';
      writer = HardwareWavWriter(filePath: path);
      await writer.open();
      if (!_isCurrent(generation) || !_starting) {
        await writer.abort();
        return;
      }
      final oldPath = state.recordedPath;
      _writer = writer;
      for (final chunk in _pendingPcm) {
        writer.addPcm(chunk);
      }
      if (!_isCurrent(generation) || _writer != writer || !_starting) return;
      _pendingPcm.clear();
      _pendingPcmBytes = 0;
      _starting = false;
      state = state.copyWith(
        state: HardwareCaptureState.recording,
        clearRecordedPath: true,
        recordedDurationSeconds: 0,
        clearError: true,
      );
      if (oldPath != null) {
        unawaited(File(oldPath).delete().catchError((_) => File(oldPath)));
      }
    } catch (_) {
      await writer?.abort();
      if (!_isCurrent(generation)) return;
      if (_writer == writer) _writer = null;
      state = state.copyWith(
        state: HardwareCaptureState.connected,
        error: 'Rekaman alat gagal dimulai. Coba lagi.',
      );
    } finally {
      if (_isCurrent(generation)) {
        _starting = false;
        _pendingPcm.clear();
        _pendingPcmBytes = 0;
      }
    }
    if (_isCurrent(generation) &&
        _releasePending &&
        state.state == HardwareCaptureState.recording) {
      _releasePending = false;
      await _finishRecording();
    }
  }

  Future<void> _finishRecording() async {
    final generation = _generation;
    final writer = _writer;
    if (writer == null || state.state != HardwareCaptureState.recording) return;
    state = state.copyWith(state: HardwareCaptureState.finalizing);
    try {
      final path = await writer.finish(minimumBytes: 3200);
      if (!_isCurrent(generation) || _writer != writer) return;
      _writer = null;
      if (path == null) {
        state = state.copyWith(
          state: HardwareCaptureState.connected,
          error:
              'Rekaman terlalu singkat. Tekan PTT lebih lama lalu coba lagi.',
        );
        return;
      }
      final durationSeconds = (writer.bytesWritten / _pcmBytesPerSecond)
          .round()
          .clamp(1, 30);
      state = state.copyWith(
        state: HardwareCaptureState.captured,
        recordedPath: path,
        recordedDurationSeconds: durationSeconds,
        clearError: true,
      );
    } catch (_) {
      await writer.abort();
      if (!_isCurrent(generation) || _writer != writer) return;
      _writer = null;
      state = state.copyWith(
        state: HardwareCaptureState.connected,
        error: 'Rekaman alat gagal diselesaikan. Coba rekam ulang.',
      );
    }
  }

  Future<void> _abortRecordingWithError(String message) async {
    final generation = _generation;
    final writer = _writer;
    _starting = false;
    _releasePending = false;
    _pendingPcm.clear();
    _pendingPcmBytes = 0;
    _writer = null;
    if (!_disposed) {
      state = state.copyWith(
        state: HardwareCaptureState.connected,
        error: message,
      );
    }
    await writer?.abort();
    if (!_isCurrent(generation)) return;
  }

  Future<void> discardRecording() async {
    if (_disposed) return;
    final generation = _generation;
    final path = state.recordedPath;
    if (path != null) {
      await File(path).delete().catchError((_) => File(path));
    }
    if (!_isCurrent(generation)) return;
    state = state.copyWith(
      state: HardwareCaptureState.connected,
      clearRecordedPath: true,
      recordedDurationSeconds: 0,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _starting = false;
    _pendingPcm.clear();
    final writer = _writer;
    _writer = null;
    unawaited(writer?.abort());
    unawaited(_service.dispose());
    super.dispose();
  }
}
