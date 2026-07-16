import { describe, expect, it, vi } from "vitest";

import { CONTROL_PACKET_TYPE, Esp32SerialService, ESP32_BAUD_RATE, getSerialSupport, SERIAL_CHOOSER_CANCELLED_MESSAGE, SERIAL_UNSUPPORTED_MESSAGE, STOP_PLAYBACK, type SerialNavigator, type SerialPortLike } from "./esp32-serial-service";
import { encodeSerialPacket } from "./esp32-serial-parser";
import { pcmS16leToWav } from "./pcm-wav";
import { speakingAttemptForm } from "./student-service";

function fakePort(chunks: Uint8Array[] = []) {
  const written: Uint8Array[] = [];
  const port: SerialPortLike = {
    readable: new ReadableStream({ start(controller) { chunks.forEach((chunk) => controller.enqueue(chunk)); } }),
    writable: new WritableStream({ write(chunk) { written.push(chunk); } }),
    open: vi.fn(async () => undefined),
    close: vi.fn(async () => undefined),
  };
  return { port, written };
}

describe("Web Serial support", () => {
  it("rejects insecure context with exact message", () => expect(getSerialSupport({ isSecureContext: false } as Window, { serial: {} } as Navigator & { serial: object })).toEqual({ supported: false, reason: SERIAL_UNSUPPORTED_MESSAGE }));
  it("rejects browser without API", () => expect(getSerialSupport({ isSecureContext: true } as Window, {} as Navigator).supported).toBe(false));
  it("accepts secure supporting browser", () => expect(getSerialSupport({ isSecureContext: true } as Window, { serial: {} } as Navigator & { serial: object }).supported).toBe(true));
});

describe("Esp32SerialService", () => {
  it("uses requestPort only for explicit connection", async () => {
    const { port } = fakePort();
    const api = { requestPort: vi.fn(async () => port), getPorts: vi.fn(async () => []) };
    const service = new Esp32SerialService(() => api);
    expect(await service.connect(true, () => undefined)).toEqual({ status: "connected" });
    expect(api.requestPort).toHaveBeenCalledOnce();
    expect(api.getPorts).not.toHaveBeenCalled();
    await service.disconnect();
  });
  it("uses permitted port for reconnect", async () => {
    const { port } = fakePort();
    const api = { requestPort: vi.fn(async () => port), getPorts: vi.fn(async () => [port]) };
    const service = new Esp32SerialService(() => api);
    expect(await service.connect(false, () => undefined)).toEqual({ status: "connected" });
    expect(api.getPorts).toHaveBeenCalledOnce();
    expect(api.requestPort).not.toHaveBeenCalled();
    expect(port.open).toHaveBeenCalledWith({ baudRate: ESP32_BAUD_RATE });
    await service.disconnect();
  });
  it("returns false when no permitted port", async () => {
    const api: SerialNavigator = { requestPort: vi.fn(), getPorts: vi.fn(async () => []) };
    expect(await new Esp32SerialService(() => api).connect(false, () => undefined)).toEqual({ status: "unavailable" });
  });
  it("delivers packets then disconnects safely", async () => {
    const { port } = fakePort([encodeSerialPacket(1, new Uint8Array([3, 4]))]);
    const service = new Esp32SerialService(() => ({ requestPort: vi.fn(async () => port), getPorts: vi.fn(async () => []) }));
    const received: number[] = [];
    await service.connect(true, (_type, payload) => received.push(...payload));
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(received).toEqual([3, 4]);
    await service.disconnect();
    expect(port.close).toHaveBeenCalled();
  });
  it("treats cross-realm chooser cancellation as neutral", async () => {
    const api: SerialNavigator = { requestPort: vi.fn(async () => { throw { name: "NotFoundError" }; }), getPorts: vi.fn(async () => []) };
    const service = new Esp32SerialService(() => api);
    expect(await service.chooseOther(() => undefined)).toEqual({ status: "cancelled", message: SERIAL_CHOOSER_CANCELLED_MESSAGE });
    expect(service.connected).toBe(false);
  });
  it("keeps stale permitted port knowledge when open fails", async () => {
    const { port } = fakePort();
    vi.mocked(port.open).mockRejectedValueOnce(new Error("gone"));
    const service = new Esp32SerialService(() => ({ requestPort: vi.fn(), getPorts: vi.fn(async () => [port]) }));
    expect(await service.reconnect(() => undefined)).toEqual({ status: "permitted" });
    expect(service.hasPermission).toBe(true);
    expect(service.connected).toBe(false);
  });
  it("deduplicates concurrent connection opens", async () => {
    const { port } = fakePort();
    let release!: () => void;
    vi.mocked(port.open).mockImplementation(() => new Promise<void>((resolve) => { release = resolve; }));
    const api = { requestPort: vi.fn(async () => port), getPorts: vi.fn(async () => []) };
    const service = new Esp32SerialService(() => api);
    const first = service.chooseOther(() => undefined);
    const second = service.chooseOther(() => undefined);
    await Promise.resolve(); release();
    expect(await first).toEqual({ status: "connected" });
    expect(await second).toEqual({ status: "connected" });
    expect(api.requestPort).toHaveBeenCalledOnce();
    expect(port.open).toHaveBeenCalledOnce();
    await service.disconnect();
  });
  it("tears down null readable as permitted", async () => {
    const { port } = fakePort();
    port.readable = null;
    const end = vi.fn();
    const service = new Esp32SerialService(() => ({ requestPort: vi.fn(async () => port), getPorts: vi.fn(async () => []) }));
    expect(await service.chooseOther(() => undefined, end)).toEqual({ status: "permitted" });
    expect(end).toHaveBeenCalledWith("ended");
    expect(service.connected).toBe(false);
  });
  it("reports reader error and preserves permission", async () => {
    const { port } = fakePort();
    port.readable = new ReadableStream({ pull() { throw new Error("off"); } });
    const end = vi.fn();
    const service = new Esp32SerialService(() => ({ requestPort: vi.fn(async () => port), getPorts: vi.fn(async () => []) }));
    await service.chooseOther(() => undefined, end);
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(end).toHaveBeenCalledWith("error");
    expect(service.hasPermission).toBe(true);
  });
  it("reports EOF once and closes session", async () => {
    const { port } = fakePort();
    port.readable = new ReadableStream({ start(controller) { controller.close(); } });
    const end = vi.fn();
    const service = new Esp32SerialService(() => ({ requestPort: vi.fn(async () => port), getPorts: vi.fn(async () => []) }));
    await service.chooseOther(() => undefined, end);
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(end).toHaveBeenCalledOnce();
    expect(service.connected).toBe(false);
  });
  it("restores disconnect listener when reused after dispose", async () => {
    const { port } = fakePort();
    const listeners = new Set<(event: Event & { port?: SerialPortLike }) => void>();
    const api: SerialNavigator = {
      requestPort: vi.fn(async () => port),
      getPorts: vi.fn(async () => [port]),
      addEventListener: vi.fn((_type, listener) => listeners.add(listener)),
      removeEventListener: vi.fn((_type, listener) => listeners.delete(listener)),
    };
    const service = new Esp32SerialService(() => api);
    await service.dispose();
    await service.reconnect(() => undefined);
    expect(listeners.size).toBe(1);
    expect(api.addEventListener).toHaveBeenCalledTimes(2);
    await service.disconnect();
  });
  it("writes stop playback control packet", async () => {
    const { port, written } = fakePort();
    const service = new Esp32SerialService(() => ({ requestPort: vi.fn(async () => port), getPorts: vi.fn(async () => []) }));
    await service.connect(true, () => undefined);
    await service.stopPlayback();
    expect(written).toEqual([encodeSerialPacket(CONTROL_PACKET_TYPE, new Uint8Array([STOP_PLAYBACK]))]);
    await service.disconnect();
  });
});

describe("speakingAttemptForm", () => {
  const file = new File(["audio"], "audio.wav", { type: "audio/wav" });
  it("sends hardware capture source", () => expect(speakingAttemptForm(file, "web_esp32_serial", 1).get("capture_source")).toBe("web_esp32_serial"));
  it("sends microphone capture source", () => expect(speakingAttemptForm(file, "web_microphone").get("capture_source")).toBe("web_microphone"));
  it("omits duration below backend minimum", () => expect(speakingAttemptForm(file, "web_esp32_serial", 0.5).has("audio_duration_seconds")).toBe(false));
  it("floors valid duration", () => expect(speakingAttemptForm(file, "web_esp32_serial", 1.9).get("audio_duration_seconds")).toBe("1"));
  it("keeps hardware preview file bytes unchanged in FormData", async () => {
    const pcm = new Uint8Array(3_200);
    pcm.set([1, 2, 3, 4]);
    const preview = new File([pcmS16leToWav(pcm)], "speaking-emi.wav", { type: "audio/wav" });
    const uploaded = speakingAttemptForm(preview, "web_esp32_serial").get("file");
    expect(uploaded).toBeInstanceOf(File);
    expect((uploaded as File).name).toBe("speaking-emi.wav");
    expect((uploaded as File).type).toBe("audio/wav");
    expect((uploaded as File).size).toBe(preview.size);
    expect(new Uint8Array(await (uploaded as File).arrayBuffer())).toEqual(new Uint8Array(await preview.arrayBuffer()));
  });
});
