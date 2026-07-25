import 'dart:typed_data';

/// Frame format shared with the Web ESP32 Serial integration
/// (`Emi-Frontend/src/features/student/esp32-serial-parser.ts`):
///
/// `AA 55 | TYPE | LENGTH_BE (2 bytes) | PAYLOAD | EE`
///
/// - TYPE 0x01: raw PCM signed 16-bit little-endian, mono, 16000 Hz.
/// - TYPE 0x02: control/status byte. Incoming payload 0x01 means PTT
///   pressed (start capture); payload 0x00 means PTT released (finish
///   capture).
///
/// See `Docs/speaking-ai-integration.md` ("ESP32 Web Serial") for the
/// authoritative protocol description this mobile parser must match.
const int kHardwareHeaderByte0 = 0xaa;
const int kHardwareHeaderByte1 = 0x55;
const int kHardwareFooterByte = 0xee;
const int kHardwarePcmPacketType = 0x01;
const int kHardwareControlPacketType = 0x02;
const int kHardwarePttPressed = 0x01;
const int kHardwarePttReleased = 0x00;

/// Matches the web parser's bound: one maximum framed packet
/// (32 KiB payload + 6 bytes framing).
const int kHardwareMaxPayloadBytes = 32 * 1024;
const int kHardwareMaxBufferBytes = kHardwareMaxPayloadBytes + 6;

final Set<int> _knownPacketTypes = {
  kHardwarePcmPacketType,
  kHardwareControlPacketType,
};

class HardwarePacket {
  const HardwarePacket({required this.type, required this.payload});

  final int type;
  final Uint8List payload;
}

/// Parses the ESP32 SPP byte stream into discrete [HardwarePacket]s.
///
/// Buffers partial/fragmented input across calls to [push], resynchronizes
/// after noise or corrupted framing, and rejects declared lengths above
/// [kHardwareMaxPayloadBytes] so a malicious/garbled stream cannot force
/// unbounded memory growth.
class HardwarePacketParser {
  Uint8List _buffer = Uint8List(0);
  int _invalidPackets = 0;

  int get invalidPacketCount => _invalidPackets;
  int get bufferedBytes => _buffer.length;

  List<HardwarePacket> push(Uint8List input) {
    final capacity = kHardwareMaxBufferBytes - _buffer.length;
    final Uint8List chunk;
    if (input.length > capacity) {
      _invalidPackets += 1;
      final start = input.length - (capacity < 0 ? 0 : capacity);
      chunk = input.sublist(start < 0 ? 0 : start);
    } else {
      chunk = input;
    }

    if (chunk.isNotEmpty) {
      final joined = Uint8List(_buffer.length + chunk.length);
      joined.setAll(0, _buffer);
      joined.setAll(_buffer.length, chunk);
      _buffer = joined;
    }

    final packets = <HardwarePacket>[];
    while (_buffer.length >= 2) {
      final headerIndex = _findHeader();
      if (headerIndex < 0) {
        _buffer = _buffer.isNotEmpty && _buffer.last == kHardwareHeaderByte0
            ? Uint8List.fromList([_buffer.last])
            : Uint8List(0);
        break;
      }
      if (headerIndex > 0) {
        _buffer = Uint8List.sublistView(_buffer, headerIndex);
      }
      if (_buffer.length < 5) break;

      final type = _buffer[2];
      final length = (_buffer[3] << 8) | _buffer[4];
      if (!_knownPacketTypes.contains(type) ||
          length > kHardwareMaxPayloadBytes) {
        _invalidPackets += 1;
        _buffer = Uint8List.sublistView(_buffer, 2);
        continue;
      }

      final packetLength = length + 6;
      if (_buffer.length < packetLength) break;
      if (_buffer[packetLength - 1] != kHardwareFooterByte) {
        _invalidPackets += 1;
        _buffer = Uint8List.sublistView(_buffer, 2);
        continue;
      }

      packets.add(
        HardwarePacket(
          type: type,
          payload: Uint8List.sublistView(_buffer, 5, packetLength - 1),
        ),
      );
      _buffer = Uint8List.sublistView(_buffer, packetLength);
    }
    return packets;
  }

  void reset() {
    _buffer = Uint8List(0);
    _invalidPackets = 0;
  }

  int _findHeader() {
    for (var index = 0; index < _buffer.length - 1; index += 1) {
      if (_buffer[index] == kHardwareHeaderByte0 &&
          _buffer[index + 1] == kHardwareHeaderByte1) {
        return index;
      }
    }
    return -1;
  }
}

/// Builds an outbound framed packet, matching [HardwarePacketParser]'s
/// framing exactly. Used for control packets (for example acknowledging
/// hardware status); PCM playback itself is routed through A2DP, not this
/// SPP channel, so payloads sent here are expected to stay small.
Uint8List encodeHardwarePacket(int type, Uint8List payload) {
  if (!_knownPacketTypes.contains(type)) {
    throw ArgumentError('Tipe paket tidak dikenal: $type');
  }
  if (payload.length > kHardwareMaxPayloadBytes) {
    throw ArgumentError('Payload melebihi batas maksimum.');
  }
  final packet = Uint8List(payload.length + 6);
  packet[0] = kHardwareHeaderByte0;
  packet[1] = kHardwareHeaderByte1;
  packet[2] = type;
  packet[3] = (payload.length >> 8) & 0xff;
  packet[4] = payload.length & 0xff;
  packet.setAll(5, payload);
  packet[packet.length - 1] = kHardwareFooterByte;
  return packet;
}
