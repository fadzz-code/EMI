"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentService } from "./student-service";
import { badgeToneForProgress, formatCount, formatOptional, formatPercent, statusLabel } from "./student-utils";

export function StudentModuleList() {
  const { token } = useAuth();
  const modulesQuery = useQuery({
    queryKey: ["student", "modules"],
    queryFn: () => studentService.modules(token ?? ""),
    enabled: Boolean(token),
  });

  const modules = modulesQuery.data?.items ?? [];

  return (
    <div className="grid gap-8">
      <PageHeader
        badge="Siswa"
        description="Pilih modul, lihat progress, lalu lanjutkan materi berikutnya."
        title="Modul Saya"
      />

      {modulesQuery.isLoading ? <LoadingState title="Memuat modul siswa" /> : null}
      {modulesQuery.isError ? (
        <ErrorState
          description={getFirstApiError(modulesQuery.error)}
          onRetry={() => void modulesQuery.refetch()}
          title="Gagal memuat modul siswa"
        />
      ) : null}

      {!modulesQuery.isLoading && !modulesQuery.isError ? (
        modules.length === 0 ? (
          <Card>
            <CardContent>
              <EmptyState
                description="Belum ada modul published untuk kelas aktif. Tunggu Admin/Guru menyiapkan materi."
                title="Modul belum tersedia"
              />
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-6">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard helper="Modul yang tersedia" label="Total Modul" value={formatCount(modules.length)} />
              <StatsCard helper="Sudah selesai" label="Selesai" value={formatCount(modules.filter((module) => module.progress.status === "completed").length)} />
              <StatsCard helper="Sedang atau belum mulai" label="Perlu Dipelajari" value={formatCount(modules.filter((module) => module.progress.status !== "completed").length)} />
            </section>

            <div className="grid items-stretch gap-4 md:grid-cols-2 xl:grid-cols-3">
              {modules.map((module, index) => (
                <Card className="flex h-full min-h-[390px] flex-col overflow-hidden bg-surface" key={module.id}>
                  <CardHeader className="flex-1">
                    <div className="flex h-full flex-col gap-3">
                      <div className="flex min-h-7 flex-wrap items-center gap-2">
                        <Badge tone={badgeToneForProgress(module.progress.status)}>{statusLabel(module.progress.status)}</Badge>
                        <Badge tone="neutral">Modul {index + 1}</Badge>
                      </div>
                      <h2 className="line-clamp-2 min-h-14 text-xl font-black leading-7 text-ink">{module.title}</h2>
                      <p className="line-clamp-3 min-h-[72px] text-sm font-semibold leading-6 text-muted">{formatOptional(module.description)}</p>
                    </div>
                  </CardHeader>
                  <CardContent className="mt-auto grid gap-4">
                    <div className="rounded-xl border-2 border-border bg-surface-muted p-4">
                      <div className="flex items-end justify-between gap-3">
                        <p className="text-xs font-black uppercase tracking-wider text-muted">Progress</p>
                        <p className="text-2xl font-black text-ink">{formatPercent(module.progress.progress_percent)}</p>
                      </div>
                      <div className="mt-3 h-3 overflow-hidden rounded-full bg-border/20">
                        <div
                          className="h-full rounded-full bg-primary"
                          style={{ width: `${Math.min(Math.max(module.progress.progress_percent ?? 0, 0), 100)}%` }}
                        />
                      </div>
                      <p className="mt-2 text-xs font-bold text-muted">
                        Materi selesai: {formatCount(module.progress.completed_lessons)} / {formatCount(module.progress.total_lessons)}
                      </p>
                    </div>
                    <Link className="inline-flex min-h-12 items-center justify-center rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition-transform hover:-translate-y-0.5" href={`/student/modules/${module.id}`}>
                      {module.progress.status === "completed" ? "Review Modul" : "Lanjutkan Modul"}
                    </Link>
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
