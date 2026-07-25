import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';

import 'hardware_connection.dart';
import 'hardware_packet_parser.dart';

/// Friendly Bluetooth name of the EMI Speaking device, matching the
/// firmware-side name used for pairing (see `Docs/hardware/updatehardware.dart`).
const String kHardwareDeviceName = 'EMI_KOLAKA';

enum HardwareLinkStatus {
  disconnected,
  connecting,
  connected,
  permissionDenied,
  notPaired,
  error,
}

class HardwareConnectResult {
  const HardwareConnectResult({required this.status, this.message});

  final HardwareLinkStatus status;
  final String? message;
}

/// Requests the two Android 12+ runtime permissions required for SPP
/// (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`). Extracted as an injectable
/// function so tests can bypass the real `permission_handler` platform
/// channel, which is unavailable under `flutter test`.
typedef HardwarePermissionRequester = Future<bool> Function();

Future<bool> requestHardwareBluetoothPermissions() async {
  final scanStatus = await Permission.bluetoothScan.request();
  final connectStatus = await Permission.bluetoothConnect.request();
  return scanStatus.isGranted && connectStatus.isGranted;
}

/// Owns the SPP connection lifecycle to the ESP32 and exposes decoded
/// [HardwarePacket]s. Deliberately does not touch audio playback: once the
/// phone is paired with `EMI_KOLAKA`, Android routes all media output
/// (reference audio, recorded playback, and any other app's audio) to the
/// speaker automatically through A2DP — no app code is needed for that
/// path. This service exists purely for the SPP side: PTT status and
/// microphone PCM streaming from the ESP32 to the phone.
class HardwareBluetoothService {
  HardwareBluetoothService({
    HardwareConnector? connector,
    HardwarePermissionRequester? permissionRequester,
  }) : _connector = connector ?? connectToBondedDevice,
       _requestPermissions =
           permissionRequester ?? requestHardwareBluetoothPermissions;

  final HardwareConnector _connector;
  final HardwarePermissionRequester _requestPermissions;
  final _parser = HardwarePacketParser();

  HardwareConnection? _connection;
  StreamSubscription<Uint8List>? _subscription;

  bool get isConnected => _connection?.isConnected ?? false;

  Future<HardwareConnectResult> connect({
    void Function(HardwarePacket packet)? onPacket,
    void Function()? onDisconnected,
  }) async {
    if (isConnected) {
      return const HardwareConnectResult(status: HardwareLinkStatus.connected);
    }

    final granted = await _requestPermissions();
    if (!granted) {
      return const HardwareConnectResult(
        status: HardwareLinkStatus.permissionDenied,
        message: 'Izin Bluetooth ditolak. Aktifkan izin Bluetooth di pengaturan HP.',
      );
    }

    try {
      _parser.reset();
      final connection = await _connector(kHardwareDeviceName);
      _connection = connection;
      _subscription = connection.input.listen(
        (chunk) {
          final packets = _parser.push(chunk);
          for (final packet in packets) {
            onPacket?.call(packet);
          }
        },
        onDone: () {
          _teardown();
          onDisconnected?.call();
        },
        onError: (Object _) {
          _teardown();
          onDisconnected?.call();
        },
        cancelOnError: true,
      );
      return const HardwareConnectResult(status: HardwareLinkStatus.connected);
    } on HardwareDeviceNotPairedException catch (error) {
      return HardwareConnectResult(
        status: HardwareLinkStatus.notPaired,
        message: error.toString(),
      );
    } catch (error) {
      return HardwareConnectResult(
        status: HardwareLinkStatus.error,
        message: 'Gagal terhubung ke alat: $error',
      );
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _connection?.close();
    _connection = null;
    _parser.reset();
  }

  void _teardown() {
    _subscription?.cancel();
    _subscription = null;
    _connection = null;
  }

  Future<void> dispose() => disconnect();
}
