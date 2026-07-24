import { describe, expect, it } from "vitest";

import { MAX_PCM_BYTES, MIN_PCM_BYTES, pcmDurationSeconds, pcmS16leToWav } from "./pcm-wav";

describe("PCM WAV", () => {
  it("writes RIFF and WAVE markers", async () => {
    const bytes = new Uint8Array(await pcmS16leToWav(new Uint8Array(MIN_PCM_BYTES)).arrayBuffer());
    expect(new TextDecoder().decode(bytes.slice(0, 4))).toBe("RIFF");
    expect(new TextDecoder().decode(bytes.slice(8, 12))).toBe("WAVE");
  });
  it("writes mono channel", async () => expect(new DataView(await pcmS16leToWav(new Uint8Array(MIN_PCM_BYTES)).arrayBuffer()).getUint16(22, true)).toBe(1));
  it("writes 16 kHz sample rate", async () => expect(new DataView(await pcmS16leToWav(new Uint8Array(MIN_PCM_BYTES)).arrayBuffer()).getUint32(24, true)).toBe(16_000));
  it("writes 16-bit samples", async () => expect(new DataView(await pcmS16leToWav(new Uint8Array(MIN_PCM_BYTES)).arrayBuffer()).getUint16(34, true)).toBe(16));
  it("writes data size", async () => expect(new DataView(await pcmS16leToWav(new Uint8Array(MIN_PCM_BYTES)).arrayBuffer()).getUint32(40, true)).toBe(MIN_PCM_BYTES));
  it("calculates duration", () => expect(pcmDurationSeconds(32_000)).toBe(1));
  it("rejects empty PCM", () => expect(() => pcmS16leToWav(new Uint8Array())).toThrow("Rekaman terlalu singkat"));
  it("rejects odd PCM", () => expect(() => pcmS16leToWav(new Uint8Array(3))).toThrow("Data audio"));
  it("rejects short PCM", () => expect(() => pcmS16leToWav(new Uint8Array(MIN_PCM_BYTES - 2))).toThrow("Rekaman terlalu singkat"));
  it("rejects long PCM", () => expect(() => pcmS16leToWav(new Uint8Array(MAX_PCM_BYTES + 2))).toThrow("Rekaman melewati batas"));
  it("keeps WAV under upload size", () => expect(pcmS16leToWav(new Uint8Array(MAX_PCM_BYTES)).size).toBe(960_044));
});
