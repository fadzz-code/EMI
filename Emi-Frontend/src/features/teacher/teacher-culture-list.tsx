"use client";

import Link from "next/link";
import { useQueries, useQuery } from "@tanstack/react-query";

import { Badge, Card, CardContent, EmptyState, ErrorState, LoadingState, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { statusLabel } from "./teacher-utils";

export function TeacherCultureList() {
  const { token } = useAuth();
  const classesQuery = useQuery({ queryKey: ["teacher", "culture", "classes"], queryFn: () => teacherService.classes(token ?? ""), enabled: Boolean(token) });
  const classes = classesQuery.data?.items ?? [];
  const cultureQueries = useQueries({
    queries: classes.map((classItem) => ({
      queryKey: ["teacher", "classes", classItem.id, "culture"],
      queryFn: () => teacherService.classCulture(token ?? "", classItem.id),
      enabled: Boolean(token && classItem.id),
    })),
  });
  const isLoading = classesQuery.isLoading || cultureQueries.some((query) => query.isLoading);
  const error = classesQuery.error ?? cultureQueries.find((query) => query.error)?.error;
  const items = cultureQueries.flatMap((query) => query.data?.items ?? []);

  return (
    <div className="grid gap-6">
      <PageHeader badge="Guru" description="Budaya Mekongga dari kelas yang ditugaskan kepada Anda." title="Budaya Mekongga" />
      {isLoading ? <LoadingState title="Memuat Budaya Mekongga" /> : null}
      {error ? <ErrorState description={getFirstApiError(error)} onRetry={() => void classesQuery.refetch()} title="Gagal memuat Budaya Mekongga" /> : null}
      {!isLoading && !error ? items.length === 0 ? <Card><CardContent><EmptyState description="Belum ada item Budaya Mekongga pada kelas Anda." title="Budaya Mekongga kosong" /></CardContent></Card> : (
        <div className="grid gap-4 md:grid-cols-2">
          {items.map((item) => (
            <Card key={item.id}>
              <CardContent>
                <div className="flex flex-wrap items-center gap-2"><Badge tone={item.status === "published" ? "blue" : item.status === "archived" ? "neutral" : "yellow"}>{statusLabel(item.status)}</Badge><Badge tone="neutral">{item.content_type}</Badge></div>
                <h2 className="mt-3 text-xl font-black text-ink">{item.title}</h2>
                <p className="mt-2 text-sm text-slate-600">{item.description ?? "Tanpa deskripsi"}</p>
                <p className="mt-3 text-sm font-bold text-slate-500">Kelas: {item.school_class?.name ?? classes.find((classItem) => classItem.id === item.class_id)?.name ?? item.class_id}</p>
                <Link className="mt-4 inline-flex rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-black text-ink shadow-brutal" href={teacherRoutes.classCulture(item.class_id)}>Kelola kelas</Link>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : null}
    </div>
  );
}
