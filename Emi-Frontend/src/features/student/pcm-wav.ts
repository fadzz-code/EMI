export const PCM_SAMPLE_RATE = 16_000;
export const PCM_BYTES_PER_SECOND = 32_000;
export const WAV_HEADER_BYTES = 44;
export const MAX_UPLOAD_BYTES = 5 * 1024 * 1024;
export const MAX_DURATION_SECONDS = 30;
export const MIN_DURATION_SECONDS = 0.1;
export const MAX_PCM_BYTES = Math.min(MAX_UPLOAD_BYTES - WAV_HEADER_BYTES, MAX_DURATION_SECONDS * PCM_BYTES_PER_SECOND);
export const MIN_PCM_BYTES = MIN_DURATION_SECONDS * PCM_BYTES_PER_SECOND;

export function pcmDurationSeconds(byteLength: number) {
  return byteLength / PCM_BYTES_PER_SECOND;
}

export function validatePcm(pcm: Uint8Array) {
  if (pcm.byteLength % 2 !== 0) throw new Error("Data audio ESP32 tidak lengkap.");
  if (pcm.byteLength < MIN_PCM_BYTES) throw new Error("Rekaman terlalu singkat. Rekam minimal 0,1 detik.");
  if (pcm.byteLength > MAX_PCM_BYTES) throw new Error("Rekaman melewati batas 30 detik.");
}

export function pcmS16leToWav(pcm: Uint8Array) {
  validatePcm(pcm);
  const buffer = new ArrayBuffer(WAV_HEADER_BYTES + pcm.byteLength);
  const view = new DataView(buffer);
  const bytes = new Uint8Array(buffer);
  const text = (offset: number, value: string) => [...value].forEach((character, index) => view.setUint8(offset + index, character.charCodeAt(0)));
  text(0, "RIFF");
  view.setUint32(4, 36 + pcm.byteLength, true);
  text(8, "WAVE");
  text(12, "fmt ");
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, 1, true);
  view.setUint32(24, PCM_SAMPLE_RATE, true);
  view.setUint32(28, PCM_BYTES_PER_SECOND, true);
  view.setUint16(32, 2, true);
  view.setUint16(34, 16, true);
  text(36, "data");
  view.setUint32(40, pcm.byteLength, true);
  bytes.set(pcm, WAV_HEADER_BYTES);
  return new Blob([buffer], { type: "audio/wav" });
}
