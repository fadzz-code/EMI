"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Alert, Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { formatCount, formatDate, formatOptional, statusLabel } from "./teacher-utils";

export function TeacherModuleList() {
  const { token, user } = useAuth();
  const classId = user?.active_class?.id;

  const modulesQuery = useQuery({
    queryKey: ["teacher", "classes", classId, "modules", "page"],
    queryFn: () => teacherService.classModules(token ?? "", classId!),
    enabled: Boolean(token && classId),
  });

  const modules = modulesQuery.data?.items ?? [];
  const publishedCount = modules.filter((module) => module.status === "published").length;

  return (
    <div className="grid gap-6">
      <PageHeader badge="Guru" description="Kelola modul pembelajaran kelas, cek status terbit, dan buka editor materi." title="Modul Kelas" />

      {!classId ? (
        <Alert tone="warning">Anda belum memiliki kelas aktif. Minta Admin untuk menetapkan Anda ke sebuah kelas.</Alert>
      ) : null}

      {modulesQuery.isLoading ? <LoadingState title="Memuat modul kelas" /> : null}
      {modulesQuery.isError ? <ErrorState description={getFirstApiError(modulesQuery.error)} onRetry={() => void modulesQuery.refetch()} title="Gagal memuat modul" /> : null}

      {!modulesQuery.isLoading && !modulesQuery.isError && classId ? (
        modules.length === 0 ? (
          <Card><CardContent><EmptyState description="Belum ada modul kelas yang bisa dikelola." title="Modul belum tersedia" /></CardContent></Card>
        ) : (
          <div className="grid gap-4">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard helper={user?.active_class?.name ?? "Kelas aktif"} label="Total modul" value={formatCount(modules.length)} />
              <StatsCard helper="Status published" label="Modul terbit" value={formatCount(publishedCount)} />
              <StatsCard helper="Buka editor untuk mengatur materi" label="Aksi" value="Kelola" />
            </section>
            <div className="grid gap-4 md:grid-cols-2">
              {modules.map((module) => (
                <Card key={module.id}>
                  <CardHeader>
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <h2 className="text-xl font-black text-ink">{module.title}</h2>
                        <div className="mt-2 flex items-center gap-2">
                          <Badge tone={module.status === "published" ? "blue" : "neutral"}>{statusLabel(module.status)}</Badge>
                          <span className="rounded-lg border border-slate-200 px-2 py-0.5 text-xs font-black text-slate-500">Urutan: {formatOptional(module.sort_order)}</span>
                        </div>
                      </div>
                      <Link className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-bold text-ink shadow-brutal hover:bg-yellow-200" href={teacherRoutes.moduleEdit(module.id)}>
                        Edit Modul
                      </Link>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm leading-6 text-slate-600 line-clamp-2">{formatOptional(module.description)}</p>
                    <dl className="mt-4 grid gap-3 text-sm sm:grid-cols-2">
                      <div className="rounded-xl bg-slate-50 p-3">
                        <dt className="font-black uppercase text-slate-500">Terbit</dt>
                        <dd className="mt-1 font-bold text-ink">{formatDate(module.published_at)}</dd>
                      </div>
                      <div className="rounded-xl bg-slate-50 p-3">
                        <dt className="font-black uppercase text-slate-500">Lesson</dt>
                        <dd className="mt-1 font-bold text-ink">
                          {module.lessons ? formatCount(module.lessons.length) : "Lihat di edit"}
                        </dd>
                      </div>
                    </dl>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>
        )
      ) : null}
    </div>
  );
}
