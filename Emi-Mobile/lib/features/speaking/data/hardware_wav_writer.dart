import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// Wraps raw mono 16 kHz signed 16-bit PCM (as streamed by the ESP32 over
/// SPP) into a playable/uploadable WAV file.
///
/// Laravel's speaking upload endpoint currently normalizes every accepted
/// format (including WAV) through FFmpeg server-side
/// (`Docs/speaking-ai-integration.md`), but it still requires a container
/// format on the wire — raw headerless PCM bytes are not an accepted
/// multipart upload. WAV wrapping therefore stays necessary as long as the
/// Laravel/Speaking AI contract expects a standard audio container; this is
/// not a leftover to delete based on old comments.
///
/// The header is written correctly from the very first byte: a 44-byte
/// placeholder header is written up front, PCM data is streamed to disk as
/// it arrives, and [finish] backpatches the real `RIFF`/`data` sizes once
/// the total byte count is known. No header field is ever left as
/// uninitialized/dummy bytes in the final file.
class HardwareWavWriter {
  HardwareWavWriter({
    required this.filePath,
    this.sampleRate = 16000,
    this.channels = 1,
    this.bitsPerSample = 16,
  });

  final String filePath;
  final int sampleRate;
  final int channels;
  final int bitsPerSample;

  IOSink? _sink;
  int _bytesWritten = 0;
  bool _finished = false;

  bool get isOpen => _sink != null && !_finished;
  int get bytesWritten => _bytesWritten;

  Future<void> open() async {
    if (_sink != null) {
      throw StateError('WAV writer sudah terbuka.');
    }
    final file = File(filePath);
    _sink = file.openWrite();
    _sink!.add(Uint8List(44));
    _bytesWritten = 0;
    _finished = false;
  }

  /// Appends raw PCM bytes. Must be called only between [open] and
  /// [finish]; throws if the writer was never opened or already finished,
  /// so a race between recording start/stop cannot silently drop audio or
  /// write to a closed sink.
  void addPcm(Uint8List pcm) {
    final sink = _sink;
    if (sink == null || _finished) {
      throw StateError('WAV writer belum dibuka atau sudah ditutup.');
    }
    sink.add(pcm);
    _bytesWritten += pcm.length;
  }

  /// Closes the sink and backpatches the header with the real data size.
  ///
  /// Returns `null` (and deletes the partial file) when no PCM bytes were
  /// ever written, so an empty/too-short recording never reaches the
  /// caller as a "valid" file.
  Future<String?> finish({int minimumBytes = 1}) async {
    final sink = _sink;
    if (sink == null || _finished) {
      return null;
    }
    _finished = true;
    await sink.close();
    _sink = null;

    if (_bytesWritten < minimumBytes) {
      await File(filePath).delete().catchError((_) => File(filePath));
      return null;
    }

    final header = buildWavHeader(
      dataLength: _bytesWritten,
      sampleRate: sampleRate,
      channels: channels,
      bitsPerSample: bitsPerSample,
    );
    final fileBytes = await File(filePath).readAsBytes();
    await File(
      filePath,
    ).writeAsBytes(<int>[...header, ...fileBytes.skip(44)], flush: true);
    return filePath;
  }

  /// Aborts the in-progress recording, closing and deleting the partial
  /// file. Safe to call even if [open] was never invoked.
  Future<void> abort() async {
    final sink = _sink;
    _sink = null;
    _finished = true;
    if (sink != null) {
      await sink.close().catchError((_) {});
    }
    await File(filePath).delete().catchError((_) => File(filePath));
  }
}

/// Builds a canonical 44-byte PCM WAV header for [dataLength] bytes of
/// raw audio at [sampleRate]/[channels]/[bitsPerSample].
Uint8List buildWavHeader({
  required int dataLength,
  required int sampleRate,
  required int channels,
  required int bitsPerSample,
}) {
  final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
  final blockAlign = channels * (bitsPerSample ~/ 8);
  final totalDataLen = dataLength + 36;

  final header = ByteData(44);
  header.setUint8(0, 0x52); // R
  header.setUint8(1, 0x49); // I
  header.setUint8(2, 0x46); // F
  header.setUint8(3, 0x46); // F
  header.setUint32(4, totalDataLen, Endian.little);
  header.setUint8(8, 0x57); // W
  header.setUint8(9, 0x41); // A
  header.setUint8(10, 0x56); // V
  header.setUint8(11, 0x45); // E

  header.setUint8(12, 0x66); // f
  header.setUint8(13, 0x6d); // m
  header.setUint8(14, 0x74); // t
  header.setUint8(15, 0x20); // (space)
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM format
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);

  header.setUint8(36, 0x64); // d
  header.setUint8(37, 0x61); // a
  header.setUint8(38, 0x74); // t
  header.setUint8(39, 0x61); // a
  header.setUint32(40, dataLength, Endian.little);

  return header.buffer.asUint8List();
}
