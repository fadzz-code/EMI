"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import {
  Alert,
  Badge,
  Card,
  CardContent,
  CardHeader,
  EmptyState,
  ErrorState,
  LoadingState,
  StatsCard,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";
import { BookOpen, ClipboardList, Mic } from "lucide-react";

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
      <section className="flex flex-col gap-2">
        <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">
          Beranda Guru
        </p>
        <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">
          Selamat datang, {user?.full_name ?? "Guru"}!
        </h1>
        <p className="text-base font-semibold leading-6 text-muted max-w-3xl">
          Pantau kelas, materi, kuis, dan latihan speaking siswa dari satu tempat.
        </p>
      </section>

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
            <StatsCard helper={teacherClass?.school?.name ?? "Menunggu penetapan Admin"} label="Kelas" value={teacherClass?.name ?? "Belum tersedia"} />
            <StatsCard helper="Siswa aktif di kelas" label="Siswa" value={formatCount(summary.students.active)} />
            <StatsCard helper={`${formatCount(summary.learning.published_lessons)} materi terbit`} label="Modul Terbit" value={formatCount(summary.learning.published_modules)} />
            <StatsCard helper="Rata-rata progress kelas" label="Progress" value={formatPercent(summary.learning.average_progress_percent)} />
          </section>

          <section className="grid gap-6 grid-cols-1 lg:grid-cols-3">
            <Card className="h-fit">
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Tindakan Cepat</h2>
                <p className="mt-1 text-sm font-semibold text-muted">Akses pintas tugas guru.</p>
              </CardHeader>
              <CardContent>
                <div className="grid gap-3">
                  <Link
                    className="group flex items-center justify-between gap-3 rounded-[var(--radius-control)] border-2 border-transparent bg-surface px-4 py-3 shadow-emi transition-all hover:-translate-y-1 hover:border-border hover:shadow-[2px_2px_0px_0px_var(--border)]"
                    href={teacherRoutes.modules}
                  >
                    <div className="flex items-center gap-3">
                      <span className="flex size-10 items-center justify-center rounded-full bg-accent/20 text-accent-foreground group-hover:bg-accent">
                        <BookOpen className="size-5" strokeWidth={2.5} />
                      </span>
                      <span className="text-sm font-black text-ink">Modul Kelas</span>
                    </div>
                  </Link>

                  <Link
                    className="group flex items-center justify-between gap-3 rounded-[var(--radius-control)] border-2 border-transparent bg-surface px-4 py-3 shadow-emi transition-all hover:-translate-y-1 hover:border-border hover:shadow-[2px_2px_0px_0px_var(--border)]"
                    href={teacherRoutes.quizzes}
                  >
                    <div className="flex items-center gap-3">
                      <span className="flex size-10 items-center justify-center rounded-full bg-accent/20 text-accent-foreground group-hover:bg-accent">
                        <ClipboardList className="size-5" strokeWidth={2.5} />
                      </span>
                      <span className="text-sm font-black text-ink">Kuis Kelas</span>
                    </div>
                  </Link>

                  <Link
                    className="group flex items-center justify-between gap-3 rounded-[var(--radius-control)] border-2 border-transparent bg-surface px-4 py-3 shadow-emi transition-all hover:-translate-y-1 hover:border-border hover:shadow-[2px_2px_0px_0px_var(--border)]"
                    href={teacherRoutes.speakingResults}
                  >
                    <div className="flex items-center gap-3">
                      <span className="flex size-10 items-center justify-center rounded-full bg-accent/20 text-accent-foreground group-hover:bg-accent">
                        <Mic className="size-5" strokeWidth={2.5} />
                      </span>
                      <span className="text-sm font-black text-ink">Hasil Speaking</span>
                    </div>
                  </Link>
                </div>
              </CardContent>
            </Card>

            <Card className="lg:col-span-2">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <h2 className="text-xl font-black text-ink">Aktivitas & Progress Siswa</h2>
                </div>
              </CardHeader>
              <CardContent>
                {summary.empty_state || !teacherClass ? (
                  <EmptyState
                    description="Belum ada kelas aktif yang terhubung dengan akun guru ini. Minta Admin menetapkan kelas terlebih dahulu."
                    title="Belum ada kelas aktif"
                  />
                ) : (summary.recent_activity ?? []).length === 0 ? (
                  <EmptyState description="Belum ada aktivitas modul atau kuis dari siswa." title="Aktivitas kosong" />
                ) : (
                  <div className="grid gap-3">
                    {summary.recent_activity?.map((activity, index) => {
                      const studentName = activity.student_name ?? "Siswa";
                      const initials = studentName.slice(0, 2).toUpperCase();

                      return (
                        <div className="flex items-center gap-4 rounded-xl border-2 border-transparent bg-surface-muted p-3 transition-colors hover:border-border hover:shadow-[2px_2px_0px_0px_var(--border)]" key={`${activity.occurred_at}-${index}`}>
                          <div className="flex size-10 shrink-0 items-center justify-center rounded-full border-2 border-border bg-white text-sm font-black text-ink">
                            {initials}
                          </div>
                          <div className="flex flex-col gap-0.5 min-w-0 flex-1">
                            <p className="truncate font-black text-ink">{studentName}</p>
                            <p className="truncate text-xs font-semibold text-muted">
                              {formatOptional(activity.title)}
                            </p>
                          </div>
                          <div className="flex flex-col items-end gap-1 shrink-0">
                            <Badge tone={activity.type === 'quiz_completed' ? "yellow" : undefined}>
                              {activityLabel(activity.type)}
                            </Badge>
                            <p className="text-[10px] font-bold text-muted-foreground">{formatDate(activity.occurred_at)}</p>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </CardContent>
            </Card>
          </section>

          <Alert tone="info">
            Hasil speaking: {summary.capabilities?.speaking_reports ? "tersedia untuk ditinjau guru" : "belum ada ringkasan di dashboard"}. Penilaian AI tetap menjadi skor awal dan guru memberi tinjauan akhir.
          </Alert>
        </>
      ) : null}
    </div>
  );
}
