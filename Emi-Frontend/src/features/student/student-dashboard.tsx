"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Alert, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentService } from "./student-service";
import { formatCount, formatDate, formatOptional, formatPercent } from "./student-utils";

const linkClass = "inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-ink bg-blue-600 px-4 py-2 text-sm font-black text-white shadow-brutal hover:bg-blue-700";
const secondaryLinkClass = "inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-black text-ink shadow-brutal hover:bg-yellow-200";

export function StudentDashboard() {
  const { token, user } = useAuth();
  const dashboardQuery = useQuery({
    queryKey: ["student", "dashboard"],
    queryFn: () => studentService.dashboard(token ?? ""),
    enabled: Boolean(token),
  });
  const modulesQuery = useQuery({
    queryKey: ["student", "modules", "dashboard"],
    queryFn: () => studentService.modules(token ?? ""),
    enabled: Boolean(token),
  });

  const summary = dashboardQuery.data;
  const nextModule = modulesQuery.data?.items.find((module) => module.progress.status !== "completed") ?? modulesQuery.data?.items[0];

  return (
    <div className="grid gap-6">
      <PageHeader
        badge="Siswa"
        description="Belajar dari modul kelas aktif dan pantau progress pribadi."
        title={`Halo, ${user?.full_name ?? "Siswa"}`}
      />

      {dashboardQuery.isLoading ? <LoadingState title="Memuat dashboard siswa" /> : null}
      {dashboardQuery.isError ? (
        <ErrorState
          description={getFirstApiError(dashboardQuery.error)}
          onRetry={() => void dashboardQuery.refetch()}
          title="Gagal memuat dashboard siswa"
        />
      ) : null}

      {summary ? (
        <>
          <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatsCard helper={summary.class?.school?.name ?? "Kelas aktif"} label="Kelas" value={summary.class?.name ?? "Belum tersedia"} />
            <StatsCard helper="Modul published dari kelas aktif" label="Modul" value={formatCount(summary.learning.published_modules)} />
            <StatsCard helper={`${formatCount(summary.learning.completed_lessons)} dari ${formatCount(summary.learning.total_lessons)} materi`} label="Progress" value={formatPercent(summary.learning.overall_progress_percent)} />
            <StatsCard helper="Kuis published yang dapat diakses" label="Kuis" value={formatCount(summary.quizzes.available)} />
          </section>

          <Card>
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Lanjut Belajar</h2>
            </CardHeader>
            <CardContent>
              {summary.empty_state || !summary.class ? (
                <EmptyState
                  description="Belum ada kelas aktif yang terhubung dengan akun siswa ini. Minta Admin menempatkan siswa ke kelas."
                  title="Kelas belum tersedia"
                />
              ) : !nextModule ? (
                <EmptyState
                  description="Belum ada modul published untuk kelas aktif. Tunggu Admin/Guru menyiapkan materi."
                  title="Modul belum tersedia"
                />
              ) : (
                <div className="grid gap-4">
                  <div className="rounded-2xl border-2 border-ink bg-white p-4">
                    <p className="text-xs font-black uppercase text-slate-500">Rekomendasi belajar</p>
                    <h3 className="mt-2 text-2xl font-black text-ink">{nextModule.title}</h3>
                    <p className="mt-2 text-sm leading-6 text-slate-600">{formatOptional(nextModule.description)}</p>
                    <p className="mt-3 text-sm font-bold text-ink">Progress: {formatPercent(nextModule.progress.progress_percent)}</p>
                  </div>
                  <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                    <Link className={linkClass} href={`/student/modules/${nextModule.id}`}>Lanjut Belajar</Link>
                    <Link className={secondaryLinkClass} href="/student/modules">Modul Saya</Link>
                    <Link className={secondaryLinkClass} href="/student/quizzes">Kuis & LKPD</Link>
                    <Link className={secondaryLinkClass} href="/student/dictionary">Kamus Mekongga</Link>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          <section className="grid gap-4 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <h2 className="text-lg font-black text-ink">Ringkasan Modul</h2>
              </CardHeader>
              <CardContent>
                <div className="grid gap-3 sm:grid-cols-3">
                  <StatsCard helper="Belum dimulai" label="Baru" value={formatCount(summary.learning.not_started_modules)} />
                  <StatsCard helper="Sedang dipelajari" label="Berjalan" value={formatCount(summary.learning.in_progress_modules)} />
                  <StatsCard helper="Sudah selesai" label="Selesai" value={formatCount(summary.learning.completed_modules)} />
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <h2 className="text-lg font-black text-ink">Kuis & Deadline</h2>
              </CardHeader>
              <CardContent>
                {(summary.upcoming_deadlines ?? []).length === 0 ? (
                  <EmptyState description="Belum ada deadline kuis dari backend." title="Tidak ada deadline" />
                ) : (
                  <div className="grid gap-3">
                    {summary.upcoming_deadlines?.map((deadline) => (
                      <div className="rounded-xl border border-slate-200 bg-white p-3" key={deadline.id}>
                        <p className="font-black text-ink">{deadline.title}</p>
                        <p className="text-sm text-slate-600">Ditutup: {formatDate(deadline.close_at)}</p>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </section>

          <Alert tone="info">
            Speaking report: {summary.capabilities?.speaking_reports ? "Tersedia" : "Belum tersedia"}. Nilai kuis tersembunyi tetap mengikuti pengaturan backend.
          </Alert>
        </>
      ) : null}
    </div>
  );
}
