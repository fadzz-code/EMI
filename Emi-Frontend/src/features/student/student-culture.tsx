"use client";

import { useQuery } from "@tanstack/react-query";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentService } from "./student-service";
import type { StudentCultureItem } from "./types";

export function StudentCulture() {
  const { token } = useAuth();
  const query = useQuery({ queryKey: ["student", "culture"], queryFn: () => studentService.culture(token ?? ""), enabled: Boolean(token) });
  const items = (query.data?.items ?? []).filter((item) => item.status === "published");

  return (
    <div className="grid gap-6">
      <PageHeader badge="Siswa" description="Materi Budaya Mekongga dari kelas Anda." title="Budaya Mekongga" />
      {query.isLoading ? <LoadingState title="Memuat Budaya Mekongga" /> : null}
      {query.isError ? <ErrorState description={getFirstApiError(query.error)} onRetry={() => void query.refetch()} title="Gagal memuat Budaya Mekongga" /> : null}
      {!query.isLoading && !query.isError ? items.length === 0 ? <Card><CardContent><EmptyState description="Belum ada Budaya Mekongga yang diterbitkan untuk kelas Anda." title="Budaya Mekongga kosong" /></CardContent></Card> : (
        <div className="grid gap-4 md:grid-cols-2">
          {items.map((item) => <CultureCard item={item} key={item.id} />)}
        </div>
      ) : null}
    </div>
  );
}

function CultureCard({ item }: { item: StudentCultureItem }) {
  const url = item.media?.url ?? item.external_url;
  return <Card><CardHeader><div className="flex flex-wrap gap-2"><Badge tone="blue">Published</Badge><Badge tone="neutral">{item.content_type}</Badge></div><h2 className="mt-2 text-xl font-black text-ink">{item.title}</h2></CardHeader><CardContent><p className="text-sm text-slate-600">{item.description ?? "Tanpa deskripsi"}</p><p className="mt-2 text-sm font-bold text-slate-500">Kelas: {item.school_class?.name ?? item.class_id}</p><CultureContent item={item} url={url} /></CardContent></Card>;
}

function CultureContent({ item, url }: { item: StudentCultureItem; url?: string | null }) {
  if (!url) return <p className="mt-3 text-sm font-bold text-slate-500">Konten belum memiliki URL publik.</p>;
  if (item.content_type === "image") return <img alt={item.title} className="mt-3 max-h-64 rounded-xl border-2 border-ink object-cover" src={url} />;
  if (item.content_type === "audio") return <audio className="mt-3 w-full" controls src={url} />;
  if (item.content_type === "video") return <video className="mt-3 w-full rounded-xl border-2 border-ink" controls src={url} />;
  return <a className="mt-3 inline-flex font-black text-blue-700 underline" href={url} rel="noreferrer" target="_blank">Buka konten</a>;
}
