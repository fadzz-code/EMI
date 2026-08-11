import 'dart:async';
import 'dart:io';

import 'package:emi_mobile/features/speaking/data/hardware_bluetooth_service.dart';
import 'package:emi_mobile/features/speaking/data/hardware_connection.dart';
import 'package:emi_mobile/features/speaking/data/hardware_packet_parser.dart';
import 'package:emi_mobile/features/speaking/presentation/hardware_capture_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

/// In-memory [HardwareConnection] double so PTT press/release and PCM
/// streaming can be exercised without a real Bluetooth radio or platform
/// channel.
class _FakeHardwareConnection implements HardwareConnection {
  final _controller = StreamController<Uint8List>.broadcast();
  bool _connected = true;

  @override
  Stream<Uint8List> get input => _controller.stream;

  @override
  bool get isConnected => _connected;

  final List<Uint8List> written = [];

  @override
  void write(Uint8List data) => written.add(data);

  @override
  Future<void> close() async {
    _connected = false;
    await _controller.close();
  }

  void emit(Uint8List bytes) => _controller.add(bytes);

  Future<void> simulateDrop() async {
    _connected = false;
    await _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHardwareConnection connection;
  late HardwareBluetoothService service;
  late HardwareCaptureController controller;
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('hardware_capture_test');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getTemporaryDirectory') {
            return tempDir.path;
          }
          return null;
        });
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  setUp(() {
    connection = _FakeHardwareConnection();
    service = HardwareBluetoothService(
      connector: (_) async => connection,
      permissionRequester: () async => true,
    );
    controller = HardwareCaptureController(service: service);
  });

  tearDown(() {
    controller.dispose();
  });

  Uint8List pttPacket(int value) => encodeHardwarePacket(
    kHardwareControlPacketType,
    Uint8List.fromList([value]),
  );

  Uint8List pcmPacket(List<int> pcmBytes) => encodeHardwarePacket(
    kHardwarePcmPacketType,
    Uint8List.fromList(pcmBytes),
  );

  test('permission selection follows Android SDK without requesting scan', () {
    expect(hardwareBluetoothPermissionForSdk(30), Permission.location);
    expect(hardwareBluetoothPermissionForSdk(31), Permission.bluetoothConnect);
  });

  test('disconnect invalidates a pending connect', () async {
    final pending = Completer<HardwareConnection>();
    final lateConnection = _FakeHardwareConnection();
    controller.dispose();
    service = HardwareBluetoothService(
      connector: (_) => pending.future,
      permissionRequester: () async => true,
    );
    controller = HardwareCaptureController(service: service);

    final connecting = controller.connect();
    await pumpMicrotasks();
    final disconnecting = controller.disconnect();
    pending.complete(lateConnection);
    await Future.wait([connecting, disconnecting]);

    expect(controller.state.state, HardwareCaptureState.disconnected);
    expect(lateConnection.isConnected, isFalse);
  });

  test('disconnect aborts a start waiting for its output directory', () async {
    final directory = Completer<Directory>();
    controller.dispose();
    controller = HardwareCaptureController(
      service: service,
      directoryProvider: () => directory.future,
    );
    await controller.connect();

    connection.emit(pttPacket(kHardwarePttPressed));
    await pumpMicrotasks();
    await controller.disconnect();
    directory.complete(tempDir);
    await pumpMicrotasks();

    expect(controller.state.state, HardwareCaptureState.disconnected);
    expect(
      tempDir.listSync().where((file) => file.path.contains('emi-hardware-')),
      isEmpty,
    );
  });

  test('release during start finalizes after pending PCM replay', () async {
    final directory = Completer<Directory>();
    controller.dispose();
    controller = HardwareCaptureController(
      service: service,
      directoryProvider: () => directory.future,
    );
    await controller.connect();

    connection.emit(pttPacket(kHardwarePttPressed));
    await pumpMicrotasks();
    connection.emit(pcmPacket(List.filled(3200, 1)));
    connection.emit(pttPacket(kHardwarePttReleased));
    directory.complete(tempDir);
    await pumpMicrotasks();
    await pumpEventQueueSettled(controller);

    expect(controller.state.state, HardwareCaptureState.captured);
    final file = File(controller.state.recordedPath!);
    expect(await file.length(), 44 + 3200);
    await file.delete().catchError((_) => file);
  });

  test('pending PCM overflow aborts start before replay', () async {
    final directory = Completer<Directory>();
    controller.dispose();
    controller = HardwareCaptureController(
      service: service,
      directoryProvider: () => directory.future,
      maxPcmBytes: 4,
    );
    await controller.connect();

    connection.emit(pttPacket(kHardwarePttPressed));
    await pumpMicrotasks();
    connection.emit(pcmPacket([1, 2, 3, 4]));
    connection.emit(pcmPacket([5, 6]));
    await pumpMicrotasks();
    directory.complete(tempDir);
    await pumpMicrotasks();

    expect(controller.state.state, HardwareCaptureState.connected);
    expect(controller.state.error, contains('30 detik'));
  });

  test('PTT press starts recording and release finalizes a WAV file', () async {
    await controller.connect();
    expect(controller.state.state, HardwareCaptureState.connected);

    connection.emit(pttPacket(kHardwarePttPressed));
    await pumpMicrotasks();
    expect(controller.state.state, HardwareCaptureState.recording);

    connection.emit(pcmPacket(List.filled(3200, 7)));
    await pumpMicrotasks();

    connection.emit(pttPacket(kHardwarePttReleased));
    await pumpEventQueueSettled(controller);

    expect(controller.state.state, HardwareCaptureState.captured);
    expect(controller.state.recordedPath, isNotNull);
    final file = File(controller.state.recordedPath!);
    expect(await file.exists(), isTrue);
    expect(await file.length(), 44 + 3200);
    await file.delete().catchError((_) => file);
  });

  test('release without press is a no-op (no dangling writer)', () async {
    await controller.connect();

    connection.emit(pttPacket(kHardwarePttReleased));
    await pumpMicrotasks();

    expect(controller.state.state, HardwareCaptureState.connected);
    expect(controller.state.recordedPath, isNull);
  });

  test('too-short recording is rejected and not exposed as captured', () async {
    await controller.connect();

    connection.emit(pttPacket(kHardwarePttPressed));
    await pumpMicrotasks();
    connection.emit(pcmPacket([1, 2])); // far below 3200-byte minimum
    await pumpMicrotasks();
    connection.emit(pttPacket(kHardwarePttReleased));
    await pumpEventQueueSettled(controller);

    expect(controller.state.state, HardwareCaptureState.connected);
    expect(controller.state.recordedPath, isNull);
    expect(controller.state.error, isNotNull);
  });

  test(
    'a second press while already recording does not reopen the writer',
    () async {
      await controller.connect();

      connection.emit(pttPacket(kHardwarePttPressed));
      await pumpMicrotasks();
      connection.emit(pcmPacket(List.filled(1600, 1)));
      await pumpMicrotasks();
      // Duplicate press event (for example a noisy button) must not reset
      // the in-progress recording and lose already-captured bytes.
      connection.emit(pttPacket(kHardwarePttPressed));
      await pumpMicrotasks();
      connection.emit(pcmPacket(List.filled(1600, 2)));
      await pumpMicrotasks();
      connection.emit(pttPacket(kHardwarePttReleased));
      await pumpEventQueueSettled(controller);

      expect(controller.state.state, HardwareCaptureState.captured);
      final file = File(controller.state.recordedPath!);
      expect(await file.length(), 44 + 1600 + 1600);
      await file.delete().catchError((_) => file);
    },
  );

  test('disconnect mid-recording aborts and deletes the partial WAV', () async {
    await controller.connect();

    connection.emit(pttPacket(kHardwarePttPressed));
    await pumpMicrotasks();
    connection.emit(pcmPacket(List.filled(3200, 1)));
    await pumpMicrotasks();

    await connection.simulateDrop();
    await pumpEventQueueSettled(controller);

    expect(controller.state.state, HardwareCaptureState.disconnected);
    expect(controller.state.error, contains('terputus'));
  });

  test(
    'discardRecording deletes the captured file and returns to connected',
    () async {
      await controller.connect();
      connection.emit(pttPacket(kHardwarePttPressed));
      await pumpMicrotasks();
      connection.emit(pcmPacket(List.filled(3200, 1)));
      await pumpMicrotasks();
      connection.emit(pttPacket(kHardwarePttReleased));
      await pumpEventQueueSettled(controller);

      final path = controller.state.recordedPath!;
      await controller.discardRecording();

      expect(controller.state.state, HardwareCaptureState.connected);
      expect(controller.state.recordedPath, isNull);
      expect(await File(path).exists(), isFalse);
    },
  );
}

Future<void> pumpMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
}

/// Polls until the controller settles into a terminal state after a PTT
/// release (`captured`, `connected`+error, or similar) — finishing a WAV
/// involves real file I/O dispatched asynchronously off a stream listener,
/// so a fixed delay is flaky and checking "not finalizing yet" immediately
/// races the listener before it has even transitioned into `finalizing`.
Future<void> pumpEventQueueSettled(HardwareCaptureController controller) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    final state = controller.state.state;
    if (state != HardwareCaptureState.recording &&
        state != HardwareCaptureState.finalizing) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
