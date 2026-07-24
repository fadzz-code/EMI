"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Pencil } from "lucide-react";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { TeacherClassNav } from "./teacher-class-nav";
import { teacherService } from "./teacher-service";
import { formatCount, formatDate, formatOptional, statusLabel } from "./teacher-utils";

export function TeacherClassModules({ classId }: { classId: string }) {
  const { token } = useAuth();
  const modulesQuery = useQuery({
    queryKey: ["teacher", "classes", classId, "modules", "page"],
    queryFn: () => teacherService.classModules(token ?? "", classId),
    enabled: Boolean(token && classId),
  });

  const modules = modulesQuery.data?.items ?? [];
  const publishedCount = modules.filter((module) => module.status === "published").length;

  return (
    <div className="grid gap-8">
      <Link className="group inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-primary transition hover:-translate-y-0.5 hover:bg-[var(--color-primary-muted)] hover:shadow-emi" href={teacherRoutes.classes}>
        <ArrowLeft className="size-5" strokeWidth={2.5} /> Kembali ke Daftar Kelas
      </Link>
      <PageHeader badge="Guru" description="Kelola modul pembelajaran yang sudah tersedia untuk kelas Anda." title="Modul Kelas" />

      <TeacherClassNav classId={classId} />

      {modulesQuery.isLoading ? <LoadingState title="Memuat modul kelas" /> : null}
      {modulesQuery.isError ? <ErrorState description={getFirstApiError(modulesQuery.error)} onRetry={() => void modulesQuery.refetch()} title="Gagal memuat modul" /> : null}

      {!modulesQuery.isLoading && !modulesQuery.isError ? (
        modules.length === 0 ? (
          <Card><CardContent><EmptyState description="Belum ada modul kelas yang bisa dikelola." title="Modul belum tersedia" /></CardContent></Card>
        ) : (
          <div className="grid gap-4">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard helper="Semua status" label="Total modul" value={formatCount(modules.length)} />
              <StatsCard helper="Status published" label="Modul terbit" value={formatCount(publishedCount)} />
              <StatsCard helper="Buka kartu modul untuk melihat materi" label="Materi" value="Tersedia" />
            </section>
            <div className="grid auto-rows-fr gap-6 md:grid-cols-2">
              {modules.map((module) => (
                <Card className="flex h-full flex-col transition hover:-translate-y-1 hover:shadow-emi" key={module.id}>
                  <CardHeader>
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <Badge tone={module.status === "published" ? "blue" : "neutral"}>{statusLabel(module.status)}</Badge>
                        <h2 className="mt-2 text-xl font-black text-primary">{module.title}</h2>
                      </div>
                       <Link className="inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5" href={teacherRoutes.moduleEdit(module.id)}>
                         <Pencil className="size-5" strokeWidth={2.5} /> Edit Modul
                       </Link>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm leading-6 text-muted">{formatOptional(module.description)}</p>
                    <dl className="mt-4 grid gap-3 text-sm sm:grid-cols-2">
                      <div className="rounded-xl bg-surface-muted p-3">
                        <dt className="font-black uppercase text-muted">Terbit</dt>
                        <dd className="mt-1 font-bold text-primary">{formatDate(module.published_at)}</dd>
                      </div>
                      <div className="rounded-xl bg-surface-muted p-3">
                        <dt className="font-black uppercase text-muted">Lesson</dt>
                        <dd className="mt-1 font-bold text-primary">{formatCount(module.lessons?.length)}</dd>
                      </div>
                    </dl>
                    <ModuleLessons token={token ?? ""} moduleId={module.id} />
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

function ModuleLessons({ token, moduleId }: { token: string; moduleId: string }) {
  const detailQuery = useQuery({
    queryKey: ["teacher", "class-modules", moduleId],
    queryFn: () => teacherService.classModuleDetail(token, moduleId),
    enabled: Boolean(token && moduleId),
  });
  const lessons = detailQuery.data?.lessons ?? [];

  if (detailQuery.isLoading) {
    return <p className="mt-4 text-sm font-bold text-muted">Memuat lesson...</p>;
  }

  if (detailQuery.isError) {
    return <p className="mt-4 text-sm font-bold text-orange-600">Lesson tidak dapat dimuat: {getFirstApiError(detailQuery.error)}</p>;
  }

  if (lessons.length === 0) {
    return <p className="mt-4 text-sm font-bold text-muted">Materi belum tersedia untuk modul ini.</p>;
  }

  return (
    <div className="mt-4 grid gap-2">
      {lessons.map((lesson) => (
        <details className="rounded-xl border border-border bg-surface p-3" key={lesson.id}>
          <summary className="cursor-pointer font-black text-primary">{lesson.title}</summary>
          <p className="mt-2 text-sm text-muted">{formatOptional(lesson.description)}</p>
          {lesson.content_body ? <p className="mt-2 rounded-lg bg-surface-muted p-3 text-sm text-muted">{lesson.content_body}</p> : null}
        </details>
      ))}
    </div>
  );
}
