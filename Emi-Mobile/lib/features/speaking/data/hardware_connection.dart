import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Thin abstraction over an active SPP link so [HardwareBluetoothService]
/// (and its consumers) can be unit tested without a real Bluetooth radio.
///
/// Only the capabilities actually used for PTT/mic capture are exposed:
/// receiving inbound framed bytes and detecting when the link closes.
/// Outbound writes are optional (used only for lightweight control
/// acknowledgements, never for audio playback — playback goes through
/// A2DP, not this channel).
abstract class HardwareConnection {
  Stream<Uint8List> get input;
  bool get isConnected;
  void write(Uint8List data);
  Future<void> close();
}

/// Adapts `flutter_bluetooth_serial`'s [BluetoothConnection] to
/// [HardwareConnection].
class BluetoothSerialConnection implements HardwareConnection {
  BluetoothSerialConnection(this._connection);

  final BluetoothConnection _connection;

  @override
  Stream<Uint8List> get input => _connection.input ?? const Stream.empty();

  @override
  bool get isConnected => _connection.isConnected;

  @override
  void write(Uint8List data) => _connection.output.add(data);

  @override
  Future<void> close() => _connection.close();
}

/// Looks up the bonded "EMI_KOLAKA" device and opens an SPP connection.
///
/// Kept as a standalone function (rather than a static method) so tests can
/// substitute a fake without touching the real `flutter_bluetooth_serial`
/// platform channel.
typedef HardwareConnector =
    Future<HardwareConnection> Function(String deviceName);

Future<HardwareConnection> connectToBondedDevice(String deviceName) async {
  final bondedDevices = await FlutterBluetoothSerial.instance
      .getBondedDevices();
  BluetoothDevice? device;
  for (final candidate in bondedDevices) {
    if (candidate.name == deviceName) {
      device = candidate;
      break;
    }
  }
  if (device == null) {
    throw HardwareDeviceNotPairedException(deviceName);
  }
  final connection = await BluetoothConnection.toAddress(device.address);
  return BluetoothSerialConnection(connection);
}

class HardwareDeviceNotPairedException implements Exception {
  const HardwareDeviceNotPairedException(this.deviceName);

  final String deviceName;

  @override
  String toString() =>
      'Perangkat "$deviceName" belum dipasangkan (paired) di pengaturan Bluetooth HP.';
}
