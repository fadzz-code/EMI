"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Alert, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { activityLabel, formatCount, formatDate, formatOptional, formatPercent } from "./teacher-utils";

export function TeacherDashboard() {
  const { token, user } = useAuth();
  const dashboardQuery = useQuery({
    queryKey: ["teacher", "dashboard"],
    queryFn: () => teacherService.dashboard(token ?? ""),
    enabled: Boolean(token),
  });

  const summary = dashboardQuery.data;
  const teacherClass = summary?.class;

  return (
    <div className="grid gap-6">
      <PageHeader
        badge="Guru"
        description="Pantau kelas aktif, siswa, modul, kuis, dan progress belajar dari data backend."
        title={`Halo, ${user?.full_name ?? "Guru"}`}
      />

      {dashboardQuery.isLoading ? <LoadingState title="Memuat dashboard guru" /> : null}
      {dashboardQuery.isError ? (
        <ErrorState
          description={getFirstApiError(dashboardQuery.error)}
          onRetry={() => void dashboardQuery.refetch()}
          title="Gagal memuat dashboard guru"
        />
      ) : null}

      {summary ? (
        <>
          <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatsCard helper={teacherClass?.school?.name ?? "Assignment aktif guru"} label="Kelas" value={teacherClass?.name ?? "Belum tersedia"} />
            <StatsCard helper="Siswa aktif dari backend" label="Siswa" value={formatCount(summary.students.active)} />
            <StatsCard helper={`${formatCount(summary.learning.published_lessons)} materi terbit`} label="Modul Terbit" value={formatCount(summary.learning.published_modules)} />
            <StatsCard helper="Rata-rata progress kelas" label="Progress" value={formatPercent(summary.learning.average_progress_percent)} />
          </section>

          <section className="grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
            <Card>
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Ringkasan Kelas</h2>
              </CardHeader>
              <CardContent>
                {summary.empty_state || !teacherClass ? (
                  <EmptyState
                    description="Belum ada kelas aktif yang terhubung dengan akun guru ini. Minta Admin menetapkan kelas terlebih dahulu."
                    title="Belum ada kelas aktif"
                  />
                ) : (
                  <div className="grid gap-4">
                    <div className="rounded-2xl border-2 border-ink bg-white p-4">
                      <p className="text-sm font-black uppercase text-slate-500">Kelas aktif</p>
                      <h3 className="mt-2 text-2xl font-black text-ink">{teacherClass.name}</h3>
                      <p className="mt-1 text-sm text-slate-600">{formatOptional(teacherClass.school?.name)}</p>
                    </div>
                    <div className="grid gap-3 sm:grid-cols-3">
                      <StatsCard helper="Sudah mulai belajar" label="Aktif Belajar" value={formatCount(summary.students.with_learning_activity)} />
                      <StatsCard helper="Semua modul selesai" label="Tuntas Modul" value={formatCount(summary.students.completed_all_modules)} />
                      <StatsCard helper="Kuis published" label="Kuis" value={formatCount(summary.quizzes.published_quizzes)} />
                    </div>
                    <div className="flex flex-col gap-2 sm:flex-row">
                      <Link className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-blue-600 px-4 py-2 text-sm font-bold text-white shadow-brutal hover:bg-blue-700" href={teacherRoutes.classes}>
                        Lihat Kelas
                      </Link>
                      <Link className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-bold text-ink shadow-brutal hover:bg-yellow-200" href={teacherRoutes.classDetail(teacherClass.id)}>
                        Detail Kelas
                      </Link>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Aktivitas Terbaru</h2>
              </CardHeader>
              <CardContent>
                {(summary.recent_activity ?? []).length === 0 ? (
                  <EmptyState description="Belum ada aktivitas modul atau kuis dari siswa." title="Aktivitas kosong" />
                ) : (
                  <div className="grid gap-3">
                    {summary.recent_activity?.map((activity, index) => (
                      <div className="rounded-xl border border-slate-200 bg-white p-3" key={`${activity.occurred_at}-${index}`}>
                        <p className="text-xs font-black uppercase text-slate-500">{activityLabel(activity.type)}</p>
                        <p className="mt-1 font-black text-ink">{formatOptional(activity.student_name)}</p>
                        <p className="text-sm text-slate-600">{formatOptional(activity.title)}</p>
                        <p className="mt-1 text-xs text-slate-500">{formatDate(activity.occurred_at)}</p>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </section>

          <Alert tone="info">
            Speaking report: {summary.capabilities?.speaking_reports ? "Tersedia" : "Belum tersedia"}. Data speaking ditampilkan read-only sesuai capability backend.
          </Alert>
        </>
      ) : null}
    </div>
  );
}
