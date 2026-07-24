import { describe, expect, it } from "vitest";

import { encodeSerialPacket, SERIAL_MAX_BUFFER, SERIAL_MAX_PAYLOAD, SerialPacketParser } from "./esp32-serial-parser";

const packet = (type = 1, payload = new Uint8Array([1, 2])) => encodeSerialPacket(type, payload);

describe("SerialPacketParser", () => {
  it("parses complete packet", () => expect(new SerialPacketParser().push(packet())).toHaveLength(1));
  it("keeps fragmented header", () => {
    const parser = new SerialPacketParser();
    expect(parser.push(new Uint8Array([0xaa]))).toEqual([]);
    expect(parser.push(packet().slice(1))).toHaveLength(1);
  });
  it("keeps fragmented payload", () => {
    const parser = new SerialPacketParser();
    const value = packet(1, new Uint8Array([1, 2, 3, 4]));
    expect(parser.push(value.slice(0, 7))).toEqual([]);
    expect(parser.push(value.slice(7))).toEqual([{ type: 1, payload: new Uint8Array([1, 2, 3, 4]) }]);
  });
  it("parses multiple packets", () => expect(new SerialPacketParser().push(new Uint8Array([...packet(), ...packet(2, new Uint8Array([0]))]))).toHaveLength(2));
  it("skips noise", () => expect(new SerialPacketParser().push(new Uint8Array([9, 8, ...packet()]))).toHaveLength(1));
  it("recovers after bad footer", () => {
    const parser = new SerialPacketParser();
    const bad = packet();
    bad[bad.length - 1] = 0;
    expect(parser.push(new Uint8Array([...bad, ...packet(2, new Uint8Array([1]))]))).toEqual([{ type: 2, payload: new Uint8Array([1]) }]);
    expect(parser.diagnostics.invalidPackets).toBe(1);
  });
  it("rejects oversized declared payload immediately", () => {
    const parser = new SerialPacketParser();
    expect(parser.push(new Uint8Array([0xaa, 0x55, 1, 0xff, 0xff]))).toEqual([]);
    expect(parser.diagnostics.bufferSize).toBeLessThan(5);
    expect(parser.diagnostics.invalidPackets).toBe(1);
  });
  it("rejects unknown type and recovers", () => {
    const parser = new SerialPacketParser();
    const unknown = new Uint8Array([0xaa, 0x55, 7, 0, 0, 0xee]);
    expect(parser.push(new Uint8Array([...unknown, ...packet()]))).toHaveLength(1);
    expect(parser.diagnostics.invalidPackets).toBe(1);
  });
  it("parses sequential audio packets", () => {
    const parser = new SerialPacketParser();
    expect(parser.push(packet(1, new Uint8Array([1])))[0].payload).toEqual(new Uint8Array([1]));
    expect(parser.push(packet(1, new Uint8Array([2])))[0].payload).toEqual(new Uint8Array([2]));
  });
  it("bounds internal buffer", () => {
    const parser = new SerialPacketParser();
    parser.push(new Uint8Array(SERIAL_MAX_BUFFER + 100).fill(0xaa));
    expect(parser.diagnostics.bufferSize).toBeLessThanOrEqual(SERIAL_MAX_BUFFER);
  });
  it("enforces encoder type and 32 KiB payload ceiling", () => {
    expect(() => encodeSerialPacket(7, new Uint8Array())).toThrow("Tipe paket tidak dikenal.");
    expect(() => encodeSerialPacket(1, new Uint8Array(SERIAL_MAX_PAYLOAD + 1))).toThrow("Payload serial terlalu besar.");
  });
});
