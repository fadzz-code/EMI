import { encodeSerialPacket, SerialPacketParser } from "./esp32-serial-parser";

export const ESP32_BAUD_RATE = 921_600;
export const PCM_PACKET_TYPE = 0x01;
export const CONTROL_PACKET_TYPE = 0x02;
export const PTT_PRESSED = 0x01;
export const PTT_RELEASED = 0x00;
export const STOP_PLAYBACK = 0x02;
export const SERIAL_UNSUPPORTED_MESSAGE = "Alat Speaking EMI belum didukung di browser ini. Gunakan Chrome atau Edge desktop melalui HTTPS atau localhost.";

export type SerialPortLike = {
  readable: ReadableStream<Uint8Array> | null;
  writable: WritableStream<Uint8Array> | null;
  open(options: { baudRate: number }): Promise<void>;
  close(): Promise<void>;
};

export type SerialNavigator = {
  requestPort(): Promise<SerialPortLike>;
  getPorts(): Promise<SerialPortLike[]>;
};

export type SerialEndReason = "ended" | "error";

export function getSerialSupport(windowValue: Pick<Window, "isSecureContext"> | undefined, navigatorValue: Navigator | undefined) {
  if (!windowValue?.isSecureContext || !navigatorValue || !("serial" in navigatorValue)) return { supported: false, reason: SERIAL_UNSUPPORTED_MESSAGE };
  return { supported: true, reason: null };
}

function browserSerialApi() {
  return (navigator as Navigator & { serial: SerialNavigator }).serial;
}

export class Esp32SerialService {
  private port: SerialPortLike | null = null;
  private reader: ReadableStreamDefaultReader<Uint8Array> | null = null;
  private parser = new SerialPacketParser();
  private reading = false;
  private closing = false;

  constructor(private readonly getApi: () => SerialNavigator = browserSerialApi) {}

  async connect(requestNew: boolean, onPacket: (type: number, payload: Uint8Array) => void, onEnd: (reason: SerialEndReason) => void = () => undefined) {
    if (this.port) throw new Error("Alat sudah terhubung.");
    const api = this.getApi();
    const permitted = requestNew ? [] : await api.getPorts();
    const port = permitted[0] ?? (requestNew ? await api.requestPort() : null);
    if (!port) return false;
    await port.open({ baudRate: ESP32_BAUD_RATE });
    this.port = port;
    this.reading = true;
    this.closing = false;
    void this.read(port, onPacket, onEnd);
    return true;
  }

  async stopPlayback() {
    if (!this.port?.writable) return;
    const writer = this.port.writable.getWriter();
    try {
      await writer.write(encodeSerialPacket(CONTROL_PACKET_TYPE, new Uint8Array([STOP_PLAYBACK])));
    } finally {
      writer.releaseLock();
    }
  }

  async disconnect() {
    if (this.closing) return;
    this.closing = true;
    this.reading = false;
    const reader = this.reader;
    this.reader = null;
    await reader?.cancel().catch(() => undefined);
    const port = this.port;
    this.port = null;
    this.parser.reset();
    await port?.close().catch(() => undefined);
    this.closing = false;
  }

  private async read(port: SerialPortLike, onPacket: (type: number, payload: Uint8Array) => void, onEnd: (reason: SerialEndReason) => void) {
    if (!port.readable) {
      if (this.reading) onEnd("ended");
      return;
    }
    const reader = port.readable.getReader();
    this.reader = reader;
    let reason: SerialEndReason = "ended";
    try {
      while (this.reading) {
        const { value, done } = await reader.read();
        if (done) break;
        if (value) this.parser.push(value).forEach((packet) => onPacket(packet.type, packet.payload));
      }
    } catch (error) {
      reason = "error";
      if (this.reading && process.env.NODE_ENV === "development") console.debug("Alat EMI read failed", error instanceof Error ? error.message : "unknown error");
    } finally {
      if (this.reader === reader) this.reader = null;
      reader.releaseLock();
      if (this.reading && this.port === port) {
        this.reading = false;
        this.port = null;
        onEnd(reason);
        await port.close().catch(() => undefined);
      }
    }
  }
}
