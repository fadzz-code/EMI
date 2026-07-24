"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowRight, BarChart3, CalendarDays } from "lucide-react";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentService } from "./student-service";
import { badgeToneForProgress, formatCount, formatDate, formatPercent, formatScoreOutOf100, statusLabel } from "./student-utils";

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
    <div className="grid gap-8">
      <header className="flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">Siswa</p>
          <h1 className="mt-2 text-3xl font-black leading-tight text-ink md:text-4xl">Progress Belajar</h1>
          <p className="mt-2 max-w-3xl text-base font-semibold leading-6 text-muted">
            Pantau perkembangan modul, kuis, dan aktivitas belajar Anda.
          </p>
        </div>
        <Link
          className="inline-flex min-h-12 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-5 py-2 text-sm font-black text-primary-foreground shadow-emi transition-transform hover:-translate-y-0.5"
          href="/student/modules"
        >
          Buka Modul
          <ArrowRight className="size-5" strokeWidth={2.5} />
        </Link>
      </header>

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

          <section className="grid items-stretch gap-4 lg:grid-cols-2">
            <Card className="flex h-full flex-col">
              <CardHeader className="flex flex-row items-center gap-3">
                <span className="flex size-11 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-ink">
                  <BarChart3 className="size-5" strokeWidth={2.5} />
                </span>
                <h2 className="text-xl font-black text-ink">Ringkasan Kuis</h2>
              </CardHeader>
              <CardContent className="flex flex-1 flex-col">
                {(summary.submitted_quiz_count ?? summary.quizzes_completed ?? 0) === 0 ? (
                  <EmptyState description="Belum ada kuis submitted, sehingga rata-rata nilai belum tersedia." title="Nilai kuis belum ada" />
                ) : (
                  <div className="grid gap-3 sm:grid-cols-2">
                    <StatsCard helper="Kuis yang sudah submitted" label="Submitted" value={formatCount(summary.submitted_quiz_count ?? summary.quizzes_completed)} />
                    <StatsCard helper="Rata-rata skor terbaik per kuis submitted" label="Rata-rata Nilai Kuis" value={formatScoreOutOf100(summary.average_quiz_score_out_of_100 ?? summary.average_best_quiz_score_percent)} />
                  </div>
                )}
              </CardContent>
            </Card>

            <Card className="flex h-full flex-col">
              <CardHeader className="flex flex-row items-center gap-3">
                <span className="flex size-11 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-ink">
                  <CalendarDays className="size-5" strokeWidth={2.5} />
                </span>
                <h2 className="text-xl font-black text-ink">Aktivitas Terakhir</h2>
              </CardHeader>
              <CardContent className="flex flex-1 flex-col">
                {lastActivity ? (
                  <div className="flex flex-1 flex-col justify-center rounded-2xl border-2 border-border bg-surface-muted p-5">
                    <p className="text-xs font-black uppercase tracking-[0.08em] text-muted">Terakhir tercatat</p>
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
              <h2 className="text-xl font-black text-ink">Progress Modul</h2>
            </CardHeader>
            <CardContent>
              {modules.length === 0 ? (
                <EmptyState description="Belum ada modul published yang dikirim backend." title="Modul belum tersedia" />
              ) : (
                <div className="grid gap-3">
                  {modules.map((module) => (
                    <div className="rounded-2xl border-2 border-border bg-surface-muted p-4 sm:p-5" key={module.id ?? module.class_module_id ?? module.title}>
                      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                        <div>
                          <p className="text-lg font-black text-ink">{module.title ?? "Modul"}</p>
                          <p className="mt-1 text-sm font-semibold text-muted">
                            {formatCount(module.completed_lessons)} dari {formatCount(module.total_lessons)} materi selesai
                          </p>
                        </div>
                        <Badge tone={badgeToneForProgress(module.status)}>{statusLabel(module.status)}</Badge>
                      </div>
                      <div className="mt-4 h-3 overflow-hidden rounded-full bg-border/20">
                        <div className="h-full rounded-full bg-primary" style={{ width: `${Math.max(0, Math.min(module.progress_percent ?? 0, 100))}%` }} />
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
