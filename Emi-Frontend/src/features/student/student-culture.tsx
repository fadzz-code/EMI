"use client";

import { useQuery } from "@tanstack/react-query";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader } from "@/components/ui";
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
    <div className="grid gap-6">
      <PageHeader badge="Siswa" description="Baca, dengarkan, dan kenali materi Budaya Mekongga yang sudah diterbitkan untuk kelas Anda." title="Budaya Mekongga" />
      {query.isLoading ? <LoadingState title="Memuat Budaya Mekongga" /> : null}
      {query.isError ? <ErrorState description={getFirstApiError(query.error)} onRetry={() => void query.refetch()} title="Gagal memuat Budaya Mekongga" /> : null}
      {!query.isLoading && !query.isError ? items.length === 0 ? <Card><CardContent><EmptyState description="Belum ada Budaya Mekongga yang diterbitkan untuk kelas Anda." title="Budaya Mekongga kosong" /></CardContent></Card> : (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {items.map((item) => <CultureCard item={item} key={item.id} />)}
        </div>
      ) : null}
    </div>
  );
}

function CultureCard({ item }: { item: StudentCultureItem }) {
  return (
    <Card className="overflow-hidden">
      <CardHeader>
        <div className="flex flex-wrap gap-2">
          <Badge tone="blue">Terbit</Badge>
          <Badge tone="neutral">{item.content_type}</Badge>
        </div>
        <h2 className="mt-2 text-xl font-black text-ink">{item.title}</h2>
        <p className="mt-1 text-sm font-bold text-slate-500">Kelas: {item.school_class?.name ?? item.class_id}</p>
      </CardHeader>
      <CardContent>
        <div className="grid gap-4">
          <p className="text-sm leading-6 text-slate-700">{item.description ?? "Deskripsi budaya belum tersedia."}</p>
          <div className="rounded-2xl border border-slate-200 bg-white p-3">
            <CultureMediaPreview item={item} />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
