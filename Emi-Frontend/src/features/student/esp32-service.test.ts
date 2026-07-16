import { describe, expect, it, vi } from "vitest";

import { CONTROL_PACKET_TYPE, Esp32SerialService, ESP32_BAUD_RATE, getSerialSupport, SERIAL_UNSUPPORTED_MESSAGE, STOP_PLAYBACK, type SerialNavigator, type SerialPortLike } from "./esp32-serial-service";
import { encodeSerialPacket } from "./esp32-serial-parser";
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
    expect(await service.connect(true, () => undefined)).toBe(true);
    expect(api.requestPort).toHaveBeenCalledOnce();
    expect(api.getPorts).not.toHaveBeenCalled();
    await service.disconnect();
  });
  it("uses permitted port for reconnect", async () => {
    const { port } = fakePort();
    const api = { requestPort: vi.fn(async () => port), getPorts: vi.fn(async () => [port]) };
    const service = new Esp32SerialService(() => api);
    expect(await service.connect(false, () => undefined)).toBe(true);
    expect(api.getPorts).toHaveBeenCalledOnce();
    expect(api.requestPort).not.toHaveBeenCalled();
    expect(port.open).toHaveBeenCalledWith({ baudRate: ESP32_BAUD_RATE });
    await service.disconnect();
  });
  it("returns false when no permitted port", async () => {
    const api: SerialNavigator = { requestPort: vi.fn(), getPorts: vi.fn(async () => []) };
    expect(await new Esp32SerialService(() => api).connect(false, () => undefined)).toBe(false);
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
});
