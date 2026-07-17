"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowRight } from "lucide-react";

import { Badge, Card, CardContent, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { formatCount, formatOptional, formatPercent } from "./teacher-utils";

export function TeacherProgressReport() {
  const { token, user } = useAuth();
  const progressQuery = useQuery({
    queryKey: ["teacher", "progress", "students", "report"],
    queryFn: () => teacherService.studentProgress(token ?? ""),
    enabled: Boolean(token),
  });

  const students = progressQuery.data?.items ?? [];
  const averageProgress = students.length > 0
    ? students.reduce((acc, student) => acc + (student.overall_learning_progress_percent ?? 0), 0) / students.length
    : null;
  const completedQuizCount = students.reduce((acc, student) => acc + (student.quizzes_completed ?? 0), 0);
  const completedModuleCount = students.reduce((acc, student) => acc + (student.completed_modules ?? 0), 0);

  return (
    <div className="grid gap-8">
      <PageHeader
        badge="Laporan"
        description={`Laporan progress belajar siswa untuk kelas aktif: ${user?.active_class?.name ?? "-"}`}
        title="Laporan Progress Siswa"
      />

      {progressQuery.isLoading ? <LoadingState title="Memuat laporan progress" /> : null}
      {progressQuery.isError ? (
        <ErrorState
          description={getFirstApiError(progressQuery.error)}
          onRetry={() => void progressQuery.refetch()}
          title="Gagal memuat laporan progress"
        />
      ) : null}

      {!progressQuery.isLoading && !progressQuery.isError ? (
        students.length === 0 ? (
          <Card>
            <CardContent>
              <EmptyState
                description="Belum ada data progress dari siswa di kelas Anda."
                title="Laporan kosong"
              />
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-6">
            <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
              <StatsCard helper={user?.active_class?.name ?? "Kelas aktif"} label="Siswa" value={formatCount(students.length)} />
              <StatsCard helper="Rata-rata kelas" label="Progress" value={formatPercent(averageProgress)} />
              <StatsCard helper="Total selesai" label="Modul" value={formatCount(completedModuleCount)} />
              <StatsCard helper="Total selesai" label="Kuis" value={formatCount(completedQuizCount)} />
            </section>

            <div className="grid gap-3 md:hidden">
              {students.map((row) => (
                <Card className="transition hover:-translate-y-1 hover:shadow-emi" key={row.student_id}>
                  <CardContent>
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <h2 className="font-black text-foreground">{formatOptional(row.full_name)}</h2>
                        <p className="mt-1 text-sm text-muted">{formatOptional(row.class?.name)}</p>
                      </div>
                      <Badge tone={row.overall_learning_progress_percent === 100 ? "blue" : "neutral"}>
                        {formatPercent(row.overall_learning_progress_percent)}
                      </Badge>
                    </div>
                    <dl className="mt-4 grid gap-3 text-sm sm:grid-cols-2">
                      <div className="rounded-xl border-2 border-border bg-surface-muted p-3">
                        <dt className="font-black uppercase text-muted">Modul</dt>
                        <dd className="mt-1 font-bold text-foreground">{formatCount(row.completed_modules)} / {formatCount(row.published_modules)}</dd>
                      </div>
                      <div className="rounded-xl border-2 border-border bg-surface-muted p-3">
                        <dt className="font-black uppercase text-muted">Kuis</dt>
                        <dd className="mt-1 font-bold text-foreground">{formatCount(row.quizzes_completed)} / {formatCount(row.published_quizzes)}</dd>
                      </div>
                    </dl>
                    <Link
                      className="mt-4 inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5"
                      href={teacherRoutes.studentDetail(row.student_id ?? "")}
                    >
                      Lihat Detail
                      <ArrowRight className="size-4" strokeWidth={2.5} />
                    </Link>
                  </CardContent>
                </Card>
              ))}
            </div>

            <div className="hidden overflow-hidden rounded-2xl border-2 border-border bg-surface shadow-emi md:block">
              <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b-2 border-border bg-surface-muted uppercase text-muted">
                  <tr>
                    <th className="px-4 py-3 font-black text-foreground">Nama Siswa</th>
                    <th className="px-4 py-3 font-black text-foreground">Progress Belajar</th>
                    <th className="px-4 py-3 font-black text-foreground">Modul Selesai</th>
                    <th className="px-4 py-3 font-black text-foreground">Kuis Selesai</th>
                    <th className="px-4 py-3 font-black text-foreground">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y border-border font-medium">
                  {students.map((row) => (
                    <tr className="hover:bg-surface-muted" key={row.student_id}>
                      <td className="px-4 py-3">
                        <div className="font-bold text-foreground">{formatOptional(row.full_name)}</div>
                        <div className="text-xs text-muted">{formatOptional(row.class?.name)}</div>
                      </td>
                      <td className="px-4 py-3">
                        <Badge tone={row.overall_learning_progress_percent === 100 ? "blue" : "neutral"}>
                          {formatPercent(row.overall_learning_progress_percent)}
                        </Badge>
                      </td>
                      <td className="px-4 py-3">
                        {formatCount(row.completed_modules)} / {formatCount(row.published_modules)}
                      </td>
                      <td className="px-4 py-3">
                        {formatCount(row.quizzes_completed)} / {formatCount(row.published_quizzes)}
                      </td>
                      <td className="px-4 py-3">
                        <Link
                          className="font-bold text-info-foreground hover:text-primary-foreground hover:underline"
                          href={teacherRoutes.studentDetail(row.student_id ?? "")}
                        >
                          Detail
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              </div>
            </div>
          </div>
        )
      ) : null}
    </div>
  );
}
