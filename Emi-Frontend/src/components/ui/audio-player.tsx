export function AudioPlayer({ src, title }: { src?: string; title: string }) {
  if (!src) {
    return (
      <div className="rounded-lg border-2 border-dashed border-ink bg-white p-4 text-sm font-bold text-slate-600">
        Audio {title} belum tersedia.
      </div>
    );
  }

  return (
    <figure className="rounded-lg border-2 border-ink bg-white p-4">
      <figcaption className="mb-3 text-sm font-black text-ink">{title}</figcaption>
      <audio className="w-full" controls src={src}>
        Browser tidak mendukung pemutar audio.
      </audio>
    </figure>
  );
}
