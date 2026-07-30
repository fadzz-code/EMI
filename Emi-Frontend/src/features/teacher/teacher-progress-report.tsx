"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { ArrowRight, FileDown } from "lucide-react";

import { Badge, Button, Card, CardContent, EmptyState, ErrorState, LoadingState, PageHeader, Pagination, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { TeacherClassProgressPrintReport } from "./teacher-print-report";
import { formatCount, formatOptional, formatPercent } from "./teacher-utils";
import { teacherProgressKey } from "./teacher-workflow";

export function TeacherProgressReport() {
  const { token, user } = useAuth();
  const classId = user?.active_class?.id ?? "";
  const [page, setPage] = useState(1);
  const summaryQuery = useQuery({
    queryKey: ["teacher", "progress", "class", classId],
    queryFn: () => teacherService.classProgress(token ?? "", classId),
    enabled: Boolean(token && classId),
  });
  const progressQuery = useQuery({
    queryKey: teacherProgressKey(classId, { page, view: "report" }),
    queryFn: () => teacherService.studentProgress(token ?? "", { class_id: classId, page }),
    enabled: Boolean(token && classId),
  });

  const students = progressQuery.data?.items ?? [];
  const summary = summaryQuery.data?.summary;

  function printReport() {
    window.print();
  }

  return (
    <div className="grid gap-8">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <PageHeader
          badge="Laporan"
          description={`Laporan progress belajar siswa untuk kelas aktif: ${user?.active_class?.name ?? "-"}`}
          title="Laporan Progress Siswa"
        />
        <Button disabled={progressQuery.isLoading || summaryQuery.isLoading} onClick={printReport} type="button">
          <FileDown className="size-4" strokeWidth={2.5} />
          Cetak PDF
        </Button>
      </div>

      {progressQuery.isLoading || summaryQuery.isLoading ? <LoadingState title="Memuat laporan progress" /> : null}
      {summaryQuery.isError ? <ErrorState description={getFirstApiError(summaryQuery.error)} onRetry={() => void summaryQuery.refetch()} title="Gagal memuat ringkasan kelas" /> : null}
      {progressQuery.isError ? (
        <ErrorState
          description={getFirstApiError(progressQuery.error)}
          onRetry={() => void progressQuery.refetch()}
          title="Gagal memuat laporan progress"
        />
      ) : null}

      {!summaryQuery.isLoading && !summaryQuery.isError && summary ? (
        <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <StatsCard helper={user?.active_class?.name ?? "Kelas aktif"} label="Siswa" value={formatCount(summary.active_students)} />
          <StatsCard helper="Rata-rata kelas" label="Progress" value={formatPercent(summary.average_module_progress_percent)} />
          <StatsCard helper="Siswa selesai semua modul" label="Selesai" value={formatCount(summary.completed_students)} />
          <StatsCard helper="Best final attempt" label="Nilai Kuis" value={formatPercent(summary.average_best_final_quiz_score_percent)} />
        </section>
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
            <Pagination onPageChange={setPage} page={progressQuery.data?.meta?.current_page ?? page} totalPages={progressQuery.data?.meta?.last_page ?? 1} />
          </div>
        )
      ) : null}

      <TeacherClassProgressPrintReport className={user?.active_class?.name} students={students} summary={summary} />
    </div>
  );
}
