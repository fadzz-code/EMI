"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentService } from "./student-service";
import { badgeToneForProgress, formatCount, formatDate, formatPercent, statusLabel } from "./student-utils";

export function StudentProgressReportPage() {
  const { token } = useAuth();
  const progressQuery = useQuery({
    queryKey: ["student", "reports", "progress"],
    queryFn: () => studentService.getStudentProgressReport(token ?? ""),
    enabled: Boolean(token),
  });

  const report = progressQuery.data;
  const summary = report?.summary;
  const modules = report?.modules?.data ?? [];
  const lastActivity = summary?.last_learning_activity_at ?? summary?.last_quiz_activity_at;

  return (
    <div className="grid gap-6">
      <PageHeader badge="Siswa" description="Pantau perkembangan modul, kuis, dan aktivitas belajar Anda." title="Progress Belajar" />

      {progressQuery.isLoading ? <LoadingState title="Memuat progress belajar" /> : null}
      {progressQuery.isError ? (
        <ErrorState
          description={getFirstApiError(progressQuery.error)}
          onRetry={() => void progressQuery.refetch()}
          title="Gagal memuat progress belajar"
        />
      ) : null}

      {!progressQuery.isLoading && !progressQuery.isError && !summary ? (
        <EmptyState description="Laporan progress belum tersedia dari backend." title="Progress belum tersedia" />
      ) : null}

      {summary ? (
        <>
          <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatsCard helper="Rata-rata progress modul" label="Progress Belajar" value={formatPercent(summary.overall_learning_progress_percent)} />
            <StatsCard helper={`${formatCount(summary.completed_modules)} dari ${formatCount(summary.published_modules)} modul`} label="Modul Selesai" value={formatCount(summary.completed_modules)} />
            <StatsCard helper={`${formatCount(summary.completed_lessons)} dari ${formatCount(summary.total_published_lessons)} materi`} label="Materi Selesai" value={formatCount(summary.completed_lessons)} />
            <StatsCard helper={`${formatCount(summary.quizzes_completed)} dari ${formatCount(summary.published_quizzes)} kuis`} label="Kuis Selesai" value={formatCount(summary.quizzes_completed)} />
          </section>

          <section className="grid gap-4 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Ringkasan Kuis</h2>
              </CardHeader>
              <CardContent>
                <div className="grid gap-3 sm:grid-cols-2">
                  <StatsCard helper="Kuis yang pernah dicoba" label="Dicoba" value={formatCount(summary.quizzes_attempted)} />
                  <StatsCard helper="Nilai terbaik rata-rata" label="Rata-rata Nilai" value={formatPercent(summary.average_best_quiz_score_percent)} />
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Aktivitas Terakhir</h2>
              </CardHeader>
              <CardContent>
                {lastActivity ? (
                  <div className="rounded-2xl border-2 border-ink bg-white p-4">
                    <p className="text-xs font-black uppercase text-slate-500">Terakhir tercatat</p>
                    <p className="mt-2 text-2xl font-black text-ink">{formatDate(lastActivity)}</p>
                  </div>
                ) : (
                  <EmptyState description="Belum ada aktivitas belajar atau kuis yang tercatat." title="Aktivitas belum ada" />
                )}
              </CardContent>
            </Card>
          </section>

          <Card>
            <CardHeader>
              <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                <h2 className="text-xl font-black text-ink">Progress Modul</h2>
                <Link className="text-sm font-black text-blue-700 hover:text-blue-900" href="/student/modules">Buka Modul</Link>
              </div>
            </CardHeader>
            <CardContent>
              {modules.length === 0 ? (
                <EmptyState description="Belum ada modul published yang dikirim backend." title="Modul belum tersedia" />
              ) : (
                <div className="grid gap-3">
                  {modules.map((module) => (
                    <div className="rounded-2xl border-2 border-ink bg-white p-4" key={module.id ?? module.class_module_id ?? module.title}>
                      <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                        <div>
                          <p className="text-lg font-black text-ink">{module.title ?? "Modul"}</p>
                          <p className="mt-1 text-sm text-slate-600">
                            {formatCount(module.completed_lessons)} dari {formatCount(module.total_lessons)} materi selesai
                          </p>
                        </div>
                        <Badge tone={badgeToneForProgress(module.status)}>{statusLabel(module.status)}</Badge>
                      </div>
                      <div className="mt-4 h-3 overflow-hidden rounded-full border border-ink bg-slate-100">
                        <div className="h-full bg-green-500" style={{ width: `${Math.max(0, Math.min(module.progress_percent ?? 0, 100))}%` }} />
                      </div>
                      <p className="mt-2 text-sm font-bold text-ink">Progress: {formatPercent(module.progress_percent)}</p>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </>
      ) : null}
    </div>
  );
}
