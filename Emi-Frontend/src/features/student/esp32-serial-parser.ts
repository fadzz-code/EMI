export const SERIAL_HEADER = new Uint8Array([0xaa, 0x55]);
export const SERIAL_FOOTER = 0xee;
export const SERIAL_MAX_PAYLOAD = 32 * 1024;
export const SERIAL_MAX_BUFFER = SERIAL_MAX_PAYLOAD + 6;
export const SERIAL_PACKET_TYPES = new Set([0x01, 0x02]);

export type SerialPacket = { type: number; payload: Uint8Array };

export class SerialPacketParser {
  private buffer = new Uint8Array();
  private invalidPackets = 0;

  get diagnostics() {
    return { invalidPackets: this.invalidPackets, bufferSize: this.buffer.length };
  }

  push(input: Uint8Array): SerialPacket[] {
    const capacity = SERIAL_MAX_BUFFER - this.buffer.length;
    const chunk = input.length > capacity ? input.subarray(input.length - Math.max(0, capacity)) : input;
    if (input.length > capacity) this.invalidPackets += 1;
    if (chunk.length) {
      const joined = new Uint8Array(this.buffer.length + chunk.length);
      joined.set(this.buffer);
      joined.set(chunk, this.buffer.length);
      this.buffer = joined;
    }

    const packets: SerialPacket[] = [];
    while (this.buffer.length >= 2) {
      const header = this.findHeader();
      if (header < 0) {
        this.buffer = this.buffer[this.buffer.length - 1] === SERIAL_HEADER[0] ? this.buffer.slice(-1) : new Uint8Array();
        break;
      }
      if (header > 0) this.buffer = this.buffer.slice(header);
      if (this.buffer.length < 5) break;
      const type = this.buffer[2];
      const length = (this.buffer[3] << 8) | this.buffer[4];
      if (!SERIAL_PACKET_TYPES.has(type) || length > SERIAL_MAX_PAYLOAD) {
        this.invalidPackets += 1;
        this.buffer = this.buffer.slice(2);
        continue;
      }
      const packetLength = length + 6;
      if (this.buffer.length < packetLength) break;
      if (this.buffer[packetLength - 1] !== SERIAL_FOOTER) {
        this.invalidPackets += 1;
        this.buffer = this.buffer.slice(2);
        continue;
      }
      packets.push({ type, payload: this.buffer.slice(5, packetLength - 1) });
      this.buffer = this.buffer.slice(packetLength);
    }
    return packets;
  }

  reset() {
    this.buffer = new Uint8Array();
    this.invalidPackets = 0;
  }

  private findHeader() {
    for (let index = 0; index < this.buffer.length - 1; index += 1) {
      if (this.buffer[index] === SERIAL_HEADER[0] && this.buffer[index + 1] === SERIAL_HEADER[1]) return index;
    }
    return -1;
  }
}

export function encodeSerialPacket(type: number, payload: Uint8Array) {
  if (!SERIAL_PACKET_TYPES.has(type)) throw new Error("Tipe paket tidak dikenal.");
  if (payload.length > SERIAL_MAX_PAYLOAD) throw new Error("Payload serial terlalu besar.");
  const packet = new Uint8Array(payload.length + 6);
  packet.set(SERIAL_HEADER);
  packet[2] = type;
  packet[3] = payload.length >> 8;
  packet[4] = payload.length & 0xff;
  packet.set(payload, 5);
  packet[packet.length - 1] = SERIAL_FOOTER;
  return packet;
}
