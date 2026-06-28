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

  return (
    <div className="grid gap-6">
      <PageHeader badge="Guru" description="Pilih kelas untuk mengelola konten Budaya Mekongga kelas tersebut." title="Budaya Mekongga" />
      {isLoading ? <LoadingState title="Memuat Budaya Mekongga" /> : null}
      {error ? <ErrorState description={getFirstApiError(error)} onRetry={() => void classesQuery.refetch()} title="Gagal memuat Budaya Mekongga" /> : null}
      {!isLoading && !error ? classes.length === 0 ? <Card><CardContent><EmptyState description="Belum ada kelas yang ditugaskan kepada Anda." title="Kelas kosong" /></CardContent></Card> : (
        <div className="grid gap-4 md:grid-cols-2">
          {classes.map((classItem, index) => {
            const items = cultureQueries[index]?.data?.items ?? [];
            const publishedCount = items.filter((item) => item.status === "published").length;

            return (
              <Card key={classItem.id}>
                <CardContent>
                  <Badge tone="neutral">{items.length} konten</Badge>
                  <h2 className="mt-3 text-xl font-black text-ink">{classItem.name}</h2>
                  <p className="mt-2 text-sm font-bold text-slate-500">{publishedCount} konten terbit</p>
                  {items.length > 0 ? (
                    <div className="mt-4 grid gap-2">
                      {items.slice(0, 3).map((item) => <p className="text-sm text-slate-700" key={item.id}><span className="font-black">{item.title}</span> · {statusLabel(item.status)}</p>)}
                    </div>
                  ) : <p className="mt-4 text-sm text-slate-600">Belum ada konten budaya untuk kelas ini.</p>}
                  <Link className="mt-4 inline-flex rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-black text-ink shadow-brutal" href={teacherRoutes.classCulture(classItem.id)}>Kelola Budaya Kelas</Link>
                </CardContent>
              </Card>
            );
          })}
        </div>
      ) : null}
    </div>
  );
}
