import 'dart:io';
import 'dart:typed_data';

import 'package:emi_mobile/features/speaking/data/hardware_wav_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hardware_wav_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true).catchError((_) => tempDir);
  });

  String pathFor(String name) =>
      '${tempDir.path}${Platform.pathSeparator}$name';

  test('writes a correct 44-byte header from the first byte', () async {
    final path = pathFor('take.wav');
    final writer = HardwareWavWriter(filePath: path);
    await writer.open();
    writer.addPcm(Uint8List.fromList(List.filled(3200, 1)));
    final finished = await writer.finish();

    expect(finished, path);
    final bytes = await File(path).readAsBytes();
    expect(bytes.length, 44 + 3200);

    final header = ByteData.sublistView(bytes, 0, 44);
    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(header.getUint32(4, Endian.little), 36 + 3200);
    expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
    expect(String.fromCharCodes(bytes.sublist(12, 16)), 'fmt ');
    expect(header.getUint16(20, Endian.little), 1); // PCM
    expect(header.getUint16(22, Endian.little), 1); // mono
    expect(header.getUint32(24, Endian.little), 16000); // sample rate
    expect(header.getUint16(34, Endian.little), 16); // bits per sample
    expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');
    expect(header.getUint32(40, Endian.little), 3200);

    // Placeholder header bytes must be fully overwritten, not left dummy.
    expect(bytes.sublist(0, 44), isNot(Uint8List(44)));
  });

  test('streams PCM incrementally without buffering it all in memory first', () async {
    final path = pathFor('stream.wav');
    final writer = HardwareWavWriter(filePath: path);
    await writer.open();
    for (var i = 0; i < 5; i++) {
      writer.addPcm(Uint8List.fromList(List.filled(640, i)));
      expect(writer.bytesWritten, 640 * (i + 1));
    }
    final finished = await writer.finish();
    expect(finished, isNotNull);
    final bytes = await File(path).readAsBytes();
    expect(bytes.length, 44 + 640 * 5);
  });

  test('rejects an empty recording and deletes the partial file', () async {
    final path = pathFor('empty.wav');
    final writer = HardwareWavWriter(filePath: path);
    await writer.open();
    final finished = await writer.finish();

    expect(finished, isNull);
    expect(await File(path).exists(), isFalse);
  });

  test('rejects a too-short recording below the minimum byte threshold', () async {
    final path = pathFor('short.wav');
    final writer = HardwareWavWriter(filePath: path);
    await writer.open();
    writer.addPcm(Uint8List.fromList([1, 2]));
    final finished = await writer.finish(minimumBytes: 3200);

    expect(finished, isNull);
    expect(await File(path).exists(), isFalse);
  });

  test('addPcm throws if called before open (race guard)', () {
    final writer = HardwareWavWriter(filePath: '/tmp/never-opened.wav');
    expect(
      () => writer.addPcm(Uint8List.fromList([1])),
      throwsStateError,
    );
  });

  test('addPcm throws after finish (race guard)', () async {
    final path = pathFor('finished.wav');
    final writer = HardwareWavWriter(filePath: path);
    await writer.open();
    writer.addPcm(Uint8List.fromList(List.filled(3200, 1)));
    await writer.finish();

    expect(
      () => writer.addPcm(Uint8List.fromList([1])),
      throwsStateError,
    );
  });

  test('open throws if called twice without finishing', () async {
    final path = pathFor('double-open.wav');
    final writer = HardwareWavWriter(filePath: path);
    await writer.open();
    expect(writer.open(), throwsStateError);
    await writer.finish();
  });

  test('abort deletes the partial file and stops accepting writes', () async {
    final path = pathFor('aborted.wav');
    final writer = HardwareWavWriter(filePath: path);
    await writer.open();
    writer.addPcm(Uint8List.fromList([1, 2, 3, 4]));
    await writer.abort();

    expect(await File(path).exists(), isFalse);
    expect(
      () => writer.addPcm(Uint8List.fromList([1])),
      throwsStateError,
    );
  });

  test('abort is safe even if open was never called', () async {
    final writer = HardwareWavWriter(
      filePath: pathFor('never-opened-abort.wav'),
    );
    await writer.abort();
  });

  test('finish is a no-op the second time it is called', () async {
    final path = pathFor('double-finish.wav');
    final writer = HardwareWavWriter(filePath: path);
    await writer.open();
    writer.addPcm(Uint8List.fromList(List.filled(3200, 1)));
    final first = await writer.finish();
    final second = await writer.finish();

    expect(first, path);
    expect(second, isNull);
  });

  test('buildWavHeader computes byte rate and block align for stereo', () {
    final header = buildWavHeader(
      dataLength: 1000,
      sampleRate: 44100,
      channels: 2,
      bitsPerSample: 16,
    );
    final view = ByteData.sublistView(header);
    expect(view.getUint32(28, Endian.little), 44100 * 2 * 2); // byteRate
    expect(view.getUint16(32, Endian.little), 4); // blockAlign
  });
}
