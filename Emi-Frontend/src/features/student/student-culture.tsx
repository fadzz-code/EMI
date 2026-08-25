"use client";

import { useQuery } from "@tanstack/react-query";
import { BookOpen } from "lucide-react";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { CultureMediaPreview } from "@/features/culture/culture-media-preview";
import { getFirstApiError } from "@/lib/api-client";

import { studentService } from "./student-service";
import type { StudentCultureItem } from "./types";

export function StudentCulture() {
  const { token } = useAuth();
  const query = useQuery({ queryKey: ["student", "culture"], queryFn: () => studentService.culture(token ?? ""), enabled: Boolean(token) });
  const items = (query.data?.items ?? []).filter((item) => item.status === "published");

  return (
    <div className="grid gap-8">
      <section className="flex flex-col gap-2">
        <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">Budaya Mekongga</p>
        <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">Kenali Budaya Mekongga</h1>
        <p className="max-w-3xl text-base font-semibold leading-6 text-muted">Baca, dengarkan, dan kenali materi Budaya Mekongga yang sudah diterbitkan untuk kelas Anda.</p>
      </section>
      {query.isLoading ? <LoadingState title="Memuat Budaya Mekongga" /> : null}
      {query.isError ? <ErrorState description={getFirstApiError(query.error)} onRetry={() => void query.refetch()} title="Gagal memuat Budaya Mekongga" /> : null}
      {!query.isLoading && !query.isError ? items.length === 0 ? <Card><CardContent><EmptyState description="Belum ada Budaya Mekongga yang diterbitkan untuk kelas Anda." title="Budaya Mekongga kosong" /></CardContent></Card> : (
       <div className="grid auto-rows-fr gap-6 md:grid-cols-2 xl:grid-cols-3">
         {items.map((item) => <CultureCard item={item} key={item.id} />)}
       </div>
      ) : null}
    </div>
  );
}

function CultureCard({ item }: { item: StudentCultureItem }) {
  return (
    <Card className="flex h-full flex-col overflow-hidden">
      <CardHeader>
        <div className="flex items-start justify-between gap-3">
          <div className="inline-flex size-12 shrink-0 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-primary">
            <BookOpen className="size-6" strokeWidth={2.5} />
          </div>
          <div className="flex flex-wrap justify-end gap-2">
            <Badge tone="blue">Terbit</Badge>
            <Badge tone="neutral">{item.content_type}</Badge>
          </div>
        </div>
        <h2 className="mt-3 line-clamp-2 text-xl font-black text-ink">{item.title}</h2>
        <p className="mt-1 truncate text-sm font-bold text-muted">Kelas: {item.school_class?.name ?? item.class_id}</p>
      </CardHeader>
      <CardContent className="flex flex-1 flex-col">
        <div className="flex flex-1 flex-col gap-4">
          <p className="line-clamp-3 min-h-18 text-sm font-semibold leading-6 text-muted">{item.description ?? "Deskripsi budaya belum tersedia."}</p>
          <div className="mt-auto flex min-h-56 items-center rounded-2xl border-2 border-border bg-surface-muted p-3">
            <div className="w-full"><CultureMediaPreview item={item} /></div>
          </div>
        </div>
      </CardContent>
     </Card>
  );
}
