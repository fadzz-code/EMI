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
    <div className="grid gap-6">
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
          <div className="grid gap-4">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard helper="Modul yang tersedia" label="Total Modul" value={formatCount(modules.length)} />
              <StatsCard helper="Sudah selesai" label="Selesai" value={formatCount(modules.filter((module) => module.progress.status === "completed").length)} />
              <StatsCard helper="Sedang atau belum mulai" label="Perlu Dipelajari" value={formatCount(modules.filter((module) => module.progress.status !== "completed").length)} />
            </section>

            <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
              {modules.map((module, index) => (
                <Card key={module.id}>
                  <CardHeader>
                    <div className="grid gap-3">
                      <div className="flex flex-wrap items-center gap-2">
                        <Badge tone={badgeToneForProgress(module.progress.status)}>{statusLabel(module.progress.status)}</Badge>
                        <Badge tone="neutral">Modul {index + 1}</Badge>
                      </div>
                      <h2 className="text-xl font-black text-ink">{module.title}</h2>
                      <p className="text-sm leading-6 text-slate-600">{formatOptional(module.description)}</p>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="grid gap-4">
                      <div className="rounded-xl bg-slate-50 p-3">
                        <p className="text-xs font-black uppercase text-slate-500">Progress</p>
                        <p className="mt-1 text-2xl font-black text-ink">{formatPercent(module.progress.progress_percent)}</p>
                        <div className="mt-3 h-2 overflow-hidden rounded-full bg-white">
                          <div
                            className="h-full rounded-full bg-blue-600"
                            style={{ width: `${Math.min(Math.max(module.progress.progress_percent ?? 0, 0), 100)}%` }}
                          />
                        </div>
                        <p className="mt-1 text-xs text-slate-500">
                          Materi selesai: {formatCount(module.progress.completed_lessons)} / {formatCount(module.progress.total_lessons)}
                        </p>
                      </div>
                      <Link className="inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-ink bg-blue-600 px-4 py-2 text-sm font-black text-white shadow-brutal hover:bg-blue-700" href={`/student/modules/${module.id}`}>
                        {module.progress.status === "completed" ? "Review Modul" : "Lanjutkan Modul"}
                      </Link>
                    </div>
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
