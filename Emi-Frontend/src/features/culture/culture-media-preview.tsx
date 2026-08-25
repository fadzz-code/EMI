import type { ReactNode } from "react";
import { ExternalLink, Link2 } from "lucide-react";

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
    return <div className="grid h-52 place-items-center rounded-xl bg-surface-muted p-4 text-center text-sm font-bold text-muted">Konten belum memiliki URL publik.</div>;
  }

  if (item.content_type === "image") {
    return <PreviewFrame label="Buka Gambar" url={url}><img alt={item.title} className="h-full w-full rounded-lg object-contain" src={url} /></PreviewFrame>;
  }

  if (item.content_type === "audio") {
    return <PreviewFrame label="Buka Audio" url={url}><div className="w-full"><AudioPlayer src={url} title={item.title} /></div></PreviewFrame>;
  }

  if (item.content_type === "video") {
    return <PreviewFrame label="Buka Video" url={url}><video className="max-h-full w-full rounded-lg" controls src={url}>Browser tidak mendukung pemutar video.</video></PreviewFrame>;
  }

  if (item.content_type === "pdf") {
    return <PreviewFrame label="Buka PDF" url={url}><div className="flex w-full items-center gap-3 rounded-lg border border-slate-200 bg-slate-50 p-3"><Badge className="shrink-0" tone="neutral">PDF</Badge><span className="min-w-0 flex-1 truncate text-sm font-bold text-slate-600" title={item.media?.original_name ?? "Dokumen PDF"}>{item.media?.original_name ?? "Dokumen PDF"}</span></div></PreviewFrame>;
  }

  return <PreviewFrame label={openLabel(item.content_type)} url={url}><div className="grid place-items-center gap-3 text-center"><span className="grid size-14 place-items-center rounded-2xl border-2 border-border bg-surface text-primary shadow-emi"><Link2 className="size-7" strokeWidth={2.5} /></span><div><p className="font-black text-ink">Konten siap dibuka</p><p className="mt-1 text-xs font-semibold text-muted">Buka materi di tab baru</p></div></div></PreviewFrame>;
}

function PreviewFrame({ children, label, url }: { children: ReactNode; label: string; url: string }) {
  return <div className="grid h-52 grid-rows-[minmax(0,1fr)_auto] gap-3 rounded-xl bg-surface-muted p-3"><div className="flex min-h-0 items-center justify-center overflow-hidden">{children}</div><OpenContentLink label={label} url={url} /></div>;
}

function OpenContentLink({ label, url }: { label: string; url: string }) {
  return <a className="inline-flex min-h-11 w-full items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5 hover:bg-orange-300" href={url} rel="noreferrer" target="_blank">{label}<ExternalLink className="size-4" strokeWidth={2.5} /></a>;
}
