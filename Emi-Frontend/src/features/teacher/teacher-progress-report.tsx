"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

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
    <div className="grid gap-6">
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
          <div className="grid gap-4">
            <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
              <StatsCard helper={user?.active_class?.name ?? "Kelas aktif"} label="Siswa" value={formatCount(students.length)} />
              <StatsCard helper="Rata-rata kelas" label="Progress" value={formatPercent(averageProgress)} />
              <StatsCard helper="Total selesai" label="Modul" value={formatCount(completedModuleCount)} />
              <StatsCard helper="Total selesai" label="Kuis" value={formatCount(completedQuizCount)} />
            </section>

            <div className="grid gap-3 md:hidden">
              {students.map((row) => (
                <Card key={row.student_id}>
                  <CardContent>
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <h2 className="font-black text-ink">{formatOptional(row.full_name)}</h2>
                        <p className="mt-1 text-sm text-muted">{formatOptional(row.class?.name)}</p>
                      </div>
                      <Badge tone={row.overall_learning_progress_percent === 100 ? "blue" : "neutral"}>
                        {formatPercent(row.overall_learning_progress_percent)}
                      </Badge>
                    </div>
                    <dl className="mt-4 grid gap-3 text-sm sm:grid-cols-2">
                      <div className="rounded-xl bg-slate-50 p-3">
                        <dt className="font-black uppercase text-slate-500">Modul</dt>
                        <dd className="mt-1 font-bold text-ink">{formatCount(row.completed_modules)} / {formatCount(row.published_modules)}</dd>
                      </div>
                      <div className="rounded-xl bg-slate-50 p-3">
                        <dt className="font-black uppercase text-slate-500">Kuis</dt>
                        <dd className="mt-1 font-bold text-ink">{formatCount(row.quizzes_completed)} / {formatCount(row.published_quizzes)}</dd>
                      </div>
                    </dl>
                    <Link
                      className="mt-4 inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-black text-ink shadow-brutal hover:bg-yellow-200"
                      href={teacherRoutes.studentDetail(row.student_id ?? "")}
                    >
                      Lihat Detail
                    </Link>
                  </CardContent>
                </Card>
              ))}
            </div>

            <div className="hidden overflow-hidden rounded-xl border-2 border-ink bg-white shadow-brutal md:block">
              <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b-2 border-ink bg-slate-100 uppercase text-slate-600">
                  <tr>
                    <th className="px-4 py-3 font-black text-ink">Nama Siswa</th>
                    <th className="px-4 py-3 font-black text-ink">Progress Belajar</th>
                    <th className="px-4 py-3 font-black text-ink">Modul Selesai</th>
                    <th className="px-4 py-3 font-black text-ink">Kuis Selesai</th>
                    <th className="px-4 py-3 font-black text-ink">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y border-ink font-medium">
                  {students.map((row) => (
                    <tr className="hover:bg-yellow-50" key={row.student_id}>
                      <td className="px-4 py-3">
                        <div className="font-bold text-ink">{formatOptional(row.full_name)}</div>
                        <div className="text-xs text-slate-500">{formatOptional(row.class?.name)}</div>
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
                          className="font-bold text-blue-600 hover:text-blue-800 hover:underline"
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
