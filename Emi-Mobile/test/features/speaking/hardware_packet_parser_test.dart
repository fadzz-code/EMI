import 'dart:typed_data';

import 'package:emi_mobile/features/speaking/data/hardware_packet_parser.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _packet({int type = 1, Uint8List? payload}) {
  return encodeHardwarePacket(type, payload ?? Uint8List.fromList([1, 2]));
}

void main() {
  group('HardwarePacketParser', () {
    test('parses complete packet', () {
      final parser = HardwarePacketParser();
      expect(parser.push(_packet()), hasLength(1));
    });

    test('keeps fragmented header across pushes', () {
      final parser = HardwarePacketParser();
      expect(parser.push(Uint8List.fromList([0xaa])), isEmpty);
      final full = _packet();
      expect(parser.push(Uint8List.sublistView(full, 1)), hasLength(1));
    });

    test('keeps fragmented payload across pushes', () {
      final parser = HardwarePacketParser();
      final value = _packet(payload: Uint8List.fromList([1, 2, 3, 4]));
      expect(parser.push(Uint8List.sublistView(value, 0, 7)), isEmpty);
      final packets = parser.push(Uint8List.sublistView(value, 7));
      expect(packets, hasLength(1));
      expect(packets.single.type, 1);
      expect(packets.single.payload, Uint8List.fromList([1, 2, 3, 4]));
    });

    test('parses multiple adjacent packets in one push', () {
      final parser = HardwarePacketParser();
      final first = _packet();
      final second = _packet(type: 2, payload: Uint8List.fromList([0]));
      final combined = Uint8List.fromList([...first, ...second]);
      expect(parser.push(combined), hasLength(2));
    });

    test('skips noise before a valid header', () {
      final parser = HardwarePacketParser();
      final combined = Uint8List.fromList([9, 8, ..._packet()]);
      expect(parser.push(combined), hasLength(1));
    });

    test('recovers after a corrupted footer', () {
      final parser = HardwarePacketParser();
      final bad = _packet();
      bad[bad.length - 1] = 0;
      final good = _packet(type: 2, payload: Uint8List.fromList([1]));
      final packets = parser.push(Uint8List.fromList([...bad, ...good]));
      expect(packets, hasLength(1));
      expect(packets.single.type, 2);
      expect(parser.invalidPacketCount, 1);
    });

    test('rejects an oversized declared length immediately', () {
      final parser = HardwarePacketParser();
      final packets = parser.push(
        Uint8List.fromList([0xaa, 0x55, 1, 0xff, 0xff]),
      );
      expect(packets, isEmpty);
      expect(parser.bufferedBytes, lessThan(5));
      expect(parser.invalidPacketCount, 1);
    });

    test('rejects an unknown packet type and resynchronizes', () {
      final parser = HardwarePacketParser();
      final unknown = Uint8List.fromList([0xaa, 0x55, 7, 0, 0, 0xee]);
      final combined = Uint8List.fromList([...unknown, ..._packet()]);
      expect(parser.push(combined), hasLength(1));
      expect(parser.invalidPacketCount, 1);
    });

    test('parses sequential PCM-like packets independently', () {
      final parser = HardwarePacketParser();
      final first = parser.push(_packet(payload: Uint8List.fromList([1])));
      final second = parser.push(_packet(payload: Uint8List.fromList([2])));
      expect(first.single.payload, Uint8List.fromList([1]));
      expect(second.single.payload, Uint8List.fromList([2]));
    });

    test('bounds internal buffer growth against a noise flood', () {
      final parser = HardwarePacketParser();
      parser.push(
        Uint8List(kHardwareMaxBufferBytes + 100)
          ..fillRange(0, kHardwareMaxBufferBytes + 100, 0xaa),
      );
      expect(parser.bufferedBytes, lessThanOrEqualTo(kHardwareMaxBufferBytes));
    });

    test('reset clears buffered bytes and diagnostics', () {
      final parser = HardwarePacketParser();
      parser.push(Uint8List.fromList([0xaa]));
      parser.reset();
      expect(parser.bufferedBytes, 0);
      expect(parser.invalidPacketCount, 0);
    });
  });

  group('encodeHardwarePacket', () {
    test('rejects unknown packet types', () {
      expect(() => encodeHardwarePacket(7, Uint8List(0)), throwsArgumentError);
    });

    test('rejects payloads above the maximum size', () {
      expect(
        () => encodeHardwarePacket(
          kHardwarePcmPacketType,
          Uint8List(kHardwareMaxPayloadBytes + 1),
        ),
        throwsArgumentError,
      );
    });

    test('round-trips through the parser', () {
      final parser = HardwarePacketParser();
      final payload = Uint8List.fromList([10, 20, 30]);
      final encoded = encodeHardwarePacket(kHardwareControlPacketType, payload);
      final packets = parser.push(encoded);
      expect(packets.single.type, kHardwareControlPacketType);
      expect(packets.single.payload, payload);
    });
  });
}
