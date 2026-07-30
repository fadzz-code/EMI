import { AudioPlayer, Badge } from "@/components/ui";

type CulturePreviewItem = {
  title: string;
  content_type: string;
  external_url?: string | null;
  media?: {
    url?: string | null;
    original_name?: string | null;
    mime_type?: string | null;
  } | null;
};

function contentUrl(item: CulturePreviewItem) {
  return item.media?.url ?? item.external_url ?? null;
}

function openLabel(type: string) {
  if (type === "pdf") return "Buka PDF";
  if (type === "video") return "Buka Video";
  if (type === "audio") return "Buka Audio";
  return "Buka Konten";
}

export function CultureMediaPreview({ item }: { item: CulturePreviewItem }) {
  const url = contentUrl(item);

  if (!url) {
    return <p className="mt-3 rounded-lg border border-slate-200 bg-slate-50 p-3 text-sm font-bold text-slate-500">Konten belum memiliki URL publik.</p>;
  }

  if (item.content_type === "image") {
    return <div className="mt-3 grid gap-3"><img alt={item.title} className="max-h-64 rounded-xl border-2 border-ink object-cover" src={url} /><OpenContentLink label="Buka Gambar" url={url} /></div>;
  }

  if (item.content_type === "audio") {
    return <div className="mt-3 grid gap-3"><AudioPlayer src={url} title={item.title} /><OpenContentLink label="Buka Audio" url={url} /></div>;
  }

  if (item.content_type === "video") {
    return <div className="mt-3 grid gap-3"><video className="w-full rounded-xl border-2 border-ink" controls src={url}>Browser tidak mendukung pemutar video.</video><OpenContentLink label="Buka Video" url={url} /></div>;
  }

  if (item.content_type === "pdf") {
    return <div className="mt-3 flex flex-wrap items-center gap-3 rounded-xl border border-slate-200 bg-slate-50 p-3"><Badge className="shrink-0" tone="neutral">PDF</Badge><span className="min-w-0 flex-1 truncate text-sm font-bold text-slate-600" title={item.media?.original_name ?? "Dokumen PDF"}>{item.media?.original_name ?? "Dokumen PDF"}</span><OpenContentLink label="Buka PDF" url={url} /></div>;
  }

  return <OpenContentLink label={openLabel(item.content_type)} url={url} />;
}

function OpenContentLink({ label, url }: { label: string; url: string }) {
  return <a className="inline-flex w-fit rounded-lg border-2 border-ink bg-white px-4 py-2 text-sm font-black text-blue-700 underline hover:bg-yellow-100" href={url} rel="noreferrer" target="_blank">{label}</a>;
}
