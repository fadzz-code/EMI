export const PLAYBACK_SAMPLE_RATE = 16_000;

export async function decodeToPlaybackPcm(file: Blob, audioContextFactory: () => AudioContext = () => new AudioContext()): Promise<Uint8Array> {
  const context = audioContextFactory();
  try {
    const decoded = await context.decodeAudioData(await file.arrayBuffer());
    const frames = Math.ceil(decoded.duration * PLAYBACK_SAMPLE_RATE);
    const offline = new OfflineAudioContext(1, Math.max(1, frames), PLAYBACK_SAMPLE_RATE);
    const source = offline.createBufferSource();
    const mono = offline.createBuffer(1, decoded.length, decoded.sampleRate);
    const channel = mono.getChannelData(0);
    for (let index = 0; index < decoded.numberOfChannels; index += 1) {
      const input = decoded.getChannelData(index);
      for (let sample = 0; sample < input.length; sample += 1) channel[sample] += input[sample] / decoded.numberOfChannels;
    }
    source.buffer = mono;
    source.connect(offline.destination);
    source.start();
    const rendered = await offline.startRendering();
    const pcm = new Uint8Array(rendered.length * 2);
    const view = new DataView(pcm.buffer);
    const samples = rendered.getChannelData(0);
    for (let index = 0; index < samples.length; index += 1) {
      const value = Math.max(-1, Math.min(1, samples[index]));
      view.setInt16(index * 2, value < 0 ? value * 0x8000 : value * 0x7fff, true);
    }
    return pcm;
  } finally {
    await context.close();
  }
}
