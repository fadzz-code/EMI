import { encodeSerialPacket, SerialPacketParser } from "./esp32-serial-parser";

export const ESP32_BAUD_RATE = 921_600;
export const PCM_PACKET_TYPE = 0x01;
export const CONTROL_PACKET_TYPE = 0x02;
export const PTT_PRESSED = 0x01;
export const PTT_RELEASED = 0x00;
export const STOP_PLAYBACK = 0x02;
export const HARDWARE_PLAYBACK_CHUNK_BYTES = 512;
export const HARDWARE_PLAYBACK_INTERVAL_MS = 12;
export const HARDWARE_PLAYBACK_FLUSH_DELAY_MS = 50;
export const PLAYBACK_TIMEOUT_MS = 30_000;
export const SERIAL_UNSUPPORTED_MESSAGE = "Alat Speaking EMI belum didukung di browser ini. Gunakan Chrome atau Edge desktop melalui HTTPS atau localhost.";
export const SERIAL_CHOOSER_CANCELLED_MESSAGE = "Pemilihan alat dibatalkan.";

export type SerialPortLike = {
  readable: ReadableStream<Uint8Array> | null;
  writable: WritableStream<Uint8Array> | null;
  open(options: { baudRate: number }): Promise<void>;
  close(): Promise<void>;
};

export type SerialNavigator = {
  requestPort(): Promise<SerialPortLike>;
  getPorts(): Promise<SerialPortLike[]>;
  addEventListener?(type: "disconnect", listener: (event: Event & { port?: SerialPortLike; target?: SerialPortLike }) => void): void;
  removeEventListener?(type: "disconnect", listener: (event: Event & { port?: SerialPortLike; target?: SerialPortLike }) => void): void;
};

export type SerialEndReason = "ended" | "error" | "disconnect";
export type SerialConnectionResult =
  | { status: "connected" }
  | { status: "permitted" }
  | { status: "unavailable" }
  | { status: "cancelled"; message: typeof SERIAL_CHOOSER_CANCELLED_MESSAGE };

export function getSerialSupport(windowValue: Pick<Window, "isSecureContext"> | undefined, navigatorValue: Navigator | undefined) {
  if (!windowValue?.isSecureContext || !navigatorValue || !("serial" in navigatorValue)) return { supported: false, reason: SERIAL_UNSUPPORTED_MESSAGE };
  return { supported: true, reason: null };
}

function browserSerialApi() {
  return (navigator as Navigator & { serial: SerialNavigator }).serial;
}

export class Esp32SerialService {
  private permittedPorts: SerialPortLike[] = [];
  private port: SerialPortLike | null = null;
  private reader: ReadableStreamDefaultReader<Uint8Array> | null = null;
  private parser = new SerialPacketParser();
  private generation = 0;
  private opening: Promise<SerialConnectionResult> | null = null;
  private onEnd: (reason: SerialEndReason) => void = () => undefined;
  private readonly api: SerialNavigator;
  private listening = false;
  private playback: AbortController | null = null;
  private playbackDone: Promise<void> | null = null;
  private readonly disconnectListener = (event: Event & { port?: SerialPortLike; target?: SerialPortLike }) => {
    const disconnected = event.port ?? event.target;
    if (!disconnected || disconnected === this.port) void this.teardown("disconnect", true);
  };

  constructor(getApi: () => SerialNavigator = browserSerialApi) {
    this.api = getApi();
    this.listen();
  }

  get hasPermission() { return this.permittedPorts.length > 0; }
  get connected() { return this.port !== null; }

  reconnect(onPacket: (type: number, payload: Uint8Array) => void, onEnd: (reason: SerialEndReason) => void = () => undefined) {
    return this.connect(false, onPacket, onEnd);
  }

  chooseOther(onPacket: (type: number, payload: Uint8Array) => void, onEnd: (reason: SerialEndReason) => void = () => undefined) {
    return this.connect(true, onPacket, onEnd);
  }

  connect(requestNew: boolean, onPacket: (type: number, payload: Uint8Array) => void, onEnd: (reason: SerialEndReason) => void = () => undefined) {
    this.listen();
    if (this.port) return Promise.resolve<SerialConnectionResult>({ status: "connected" });
    if (this.opening) return this.opening;
    const generation = ++this.generation;
    this.opening = this.open(requestNew, generation, onPacket, onEnd).finally(() => { this.opening = null; });
    return this.opening;
  }

  private async open(requestNew: boolean, generation: number, onPacket: (type: number, payload: Uint8Array) => void, onEnd: (reason: SerialEndReason) => void): Promise<SerialConnectionResult> {
    let port: SerialPortLike | null = null;
    try {
      if (requestNew) port = await this.api.requestPort();
      else {
        this.permittedPorts = await this.api.getPorts();
        port = this.permittedPorts[0] ?? null;
        if (!port) return { status: "unavailable" };
      }
    } catch (error) {
      if (typeof error === "object" && error !== null && "name" in error && error.name === "NotFoundError") return { status: "cancelled", message: SERIAL_CHOOSER_CANCELLED_MESSAGE };
      throw error;
    }
    if (!this.permittedPorts.includes(port)) this.permittedPorts.push(port);
    try {
      await port.open({ baudRate: ESP32_BAUD_RATE });
    } catch (error) {
      if (!requestNew) return { status: "permitted" };
      throw error;
    }
    if (generation !== this.generation) {
      await port.close().catch(() => undefined);
      return { status: "permitted" };
    }
    this.port = port;
    this.onEnd = onEnd;
    this.parser.reset();
    if (!port.readable) {
      await this.teardown("ended", true);
      return { status: "permitted" };
    }
    void this.read(port, generation, onPacket);
    return { status: "connected" };
  }

  playPcm(pcm: Uint8Array, options: { signal?: AbortSignal; timeoutMs?: number; wait?: (milliseconds: number) => Promise<void> } = {}) {
    const writable = this.port?.writable;
    if (!writable) return Promise.reject(new Error("Alat belum terhubung."));
    if (this.playback) return Promise.reject(new Error("Playback alat sedang berjalan."));
    const controller = new AbortController();
    this.playback = controller;
    const done = this.streamPcm(pcm, writable, controller, options);
    this.playbackDone = done;
    return done.finally(() => { if (this.playbackDone === done) this.playbackDone = null; });
  }

  private async streamPcm(pcm: Uint8Array, writable: WritableStream<Uint8Array>, controller: AbortController, options: { signal?: AbortSignal; timeoutMs?: number; wait?: (milliseconds: number) => Promise<void> }) {
    const timeout = setTimeout(() => controller.abort(new Error("Playback alat melewati batas waktu.")), options.timeoutMs ?? PLAYBACK_TIMEOUT_MS);
    const abort = () => controller.abort(options.signal?.reason);
    options.signal?.addEventListener("abort", abort, { once: true });
    const writer = writable.getWriter();
    const wait = options.wait ?? ((milliseconds) => new Promise<void>((resolve) => setTimeout(resolve, milliseconds)));
    try {
      for (let offset = 0; offset < pcm.length; offset += HARDWARE_PLAYBACK_CHUNK_BYTES) {
        if (controller.signal.aborted) throw controller.signal.reason ?? new DOMException("Playback dibatalkan.", "AbortError");
        await writer.write(encodeSerialPacket(PCM_PACKET_TYPE, pcm.slice(offset, offset + HARDWARE_PLAYBACK_CHUNK_BYTES)));
        if (offset + HARDWARE_PLAYBACK_CHUNK_BYTES < pcm.length) await wait(HARDWARE_PLAYBACK_INTERVAL_MS);
      }
    } finally {
      clearTimeout(timeout);
      options.signal?.removeEventListener("abort", abort);
      try {
        await writer.write(encodeSerialPacket(CONTROL_PACKET_TYPE, new Uint8Array([STOP_PLAYBACK])));
        await wait(HARDWARE_PLAYBACK_FLUSH_DELAY_MS);
      } finally {
        writer.releaseLock();
        if (this.playback === controller) this.playback = null;
      }
    }
  }

  async stopPlayback() {
    this.playback?.abort(new DOMException("Playback dibatalkan.", "AbortError"));
    if (this.playback || !this.port?.writable) return;
    const writer = this.port.writable.getWriter();
    try { await writer.write(encodeSerialPacket(CONTROL_PACKET_TYPE, new Uint8Array([STOP_PLAYBACK]))); }
    finally { writer.releaseLock(); }
  }

  disconnect() { return this.teardown("disconnect", false); }

  async dispose() {
    if (this.listening) this.api.removeEventListener?.("disconnect", this.disconnectListener);
    this.listening = false;
    await this.disconnect();
  }

  private listen() {
    if (this.listening) return;
    this.api.addEventListener?.("disconnect", this.disconnectListener);
    this.listening = true;
  }

  private async teardown(reason: SerialEndReason, notify: boolean) {
    const hadSession = Boolean(this.port || this.reader || this.opening);
    this.playback?.abort(new DOMException("Playback dibatalkan.", "AbortError"));
    await this.playbackDone?.catch(() => undefined);
    ++this.generation;
    const reader = this.reader;
    this.reader = null;
    const port = this.port;
    this.port = null;
    this.parser.reset();
    await reader?.cancel().catch(() => undefined);
    await port?.close().catch(() => undefined);
    if (notify && hadSession) this.onEnd(reason);
  }

  private async read(port: SerialPortLike, generation: number, onPacket: (type: number, payload: Uint8Array) => void) {
    const reader = port.readable!.getReader();
    if (generation !== this.generation || port !== this.port) { reader.releaseLock(); return; }
    this.reader = reader;
    let reason: SerialEndReason = "ended";
    try {
      while (generation === this.generation) {
        const { value, done } = await reader.read();
        if (done) break;
        if (value) this.parser.push(value).forEach((packet) => onPacket(packet.type, packet.payload));
      }
    } catch { reason = "error"; }
    finally {
      if (this.reader === reader) this.reader = null;
      reader.releaseLock();
      if (generation === this.generation && this.port === port) await this.teardown(reason, true);
    }
  }
}
