"use client";

import Link from "next/link";
import { useState } from "react";
import { useQuery } from "@tanstack/react-query";

import {
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  EmptyState,
  ErrorState,
  LoadingState,
  Pagination,
  Table,
  TableCell,
  TableHeader,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { progressReportService } from "./progress-service";
import { ClassProgressPrintReport } from "./progress-print-report";
import { ProgressBar } from "./progress-summary-cards";
import {
  formatDateTime,
  formatNumber,
  formatPercent,
  learningStatus,
  learningStatusLabel,
  statusTone,
} from "./progress-utils";

export function ProgressClassDetail({ classId }: { classId: string }) {
  const { token } = useAuth();
  const [studentPage, setStudentPage] = useState(1);

  const detailQuery = useQuery({
    queryKey: ["admin", "progress", "class-detail", classId, studentPage],
    queryFn: () => progressReportService.classDetail(token ?? "", classId, { page: studentPage, per_page: 12 }),
    enabled: Boolean(token && classId),
  });

  const schoolClass = detailQuery.data?.class;
  const students = detailQuery.data?.students.items ?? [];
  const studentMeta = detailQuery.data?.students.meta;
  const summary = detailQuery.data?.summary;
  const completedStudents = summary?.completed_students;
  const notStartedStudents = summary?.not_started_students;

  function printReport() {
    window.print();
  }

  return (
    <div className="grid gap-6">
      <Link
        className="w-fit rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 py-2 text-sm font-black text-ink transition-colors hover:bg-primary hover:text-primary-foreground"
        href="/admin/progress"
      >
        Kembali ke Progress
      </Link>

      {detailQuery.isLoading ? <LoadingState title="Memuat identitas kelas" /> : null}
      {detailQuery.isError ? (
        <ErrorState
          description={getFirstApiError(detailQuery.error)}
          onRetry={() => void detailQuery.refetch()}
          title="Gagal memuat kelas"
        />
      ) : null}

      {schoolClass ? (
        <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div>
            <Badge tone="blue">ADMIN-18</Badge>
            <h1 className="mt-2 text-3xl font-black text-ink">{schoolClass.name}</h1>
            <p className="mt-2 text-sm leading-6 font-semibold text-muted">
              {schoolClass.school?.name ?? "-"} | {schoolClass.academic_year} | Guru:{" "}
              {schoolClass.teacher?.full_name ?? "Belum tersedia"}
            </p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row">
            <Button
              disabled={detailQuery.isLoading}
              onClick={printReport}
            >
              Cetak PDF
            </Button>
          </div>
        </header>
      ) : null}

      {!detailQuery.isLoading && !detailQuery.isError && summary ? (
        <>
          <section className="grid gap-4 md:grid-cols-3">
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-muted">Siswa selesai modul</p>
                <p className="mt-3 text-3xl font-black text-ink">
                  {formatNumber(completedStudents)}
                </p>
                <p className="mt-2 text-sm font-semibold text-muted">
                  Agregat siswa yang menyelesaikan semua modul terbit.
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-muted">Siswa belum mulai</p>
                <p className="mt-3 text-3xl font-black text-ink">
                  {formatNumber(notStartedStudents)}
                </p>
                <p className="mt-2 text-sm font-semibold text-muted">
                  Agregat siswa yang belum memulai modul.
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-muted">Aktivitas terakhir</p>
                <p className="mt-3 text-xl font-black text-ink">
                  {formatDateTime(summary.last_activity_at)}
                </p>
                <p className="mt-2 text-sm font-semibold text-muted">
                  Aktivitas terbaru seluruh siswa dalam kelas.
                </p>
              </CardContent>
            </Card>
          </section>
        </>
      ) : null}

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Daftar Siswa Kelas</h2>
        </CardHeader>
        <CardContent>
          {detailQuery.isLoading ? <LoadingState title="Memuat siswa kelas" /> : null}
          {detailQuery.isError ? <ErrorState description={getFirstApiError(detailQuery.error)} onRetry={() => void detailQuery.refetch()} title="Gagal memuat progress siswa kelas" /> : null}
          {!detailQuery.isLoading && !detailQuery.isError ? (
            students.length === 0 ? (
              <EmptyState
                description="Belum ada progress siswa di kelas ini."
                title="Progress kelas kosong"
              />
            ) : (
              <div className="grid gap-4">
                <Table>
                  <TableHeader>
                    <tr>
                      <th className="px-4 py-3">Siswa</th>
                      <th className="px-4 py-3">Progress Modul</th>
                      <th className="px-4 py-3">Kuis</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3">Aksi</th>
                    </tr>
                  </TableHeader>
                  <tbody>
                    {students.map((student) => {
                      const status = learningStatus(student);

                      return (
                        <tr key={student.student_id}>
                          <TableCell>
                            <p className="font-black text-ink">{student.full_name}</p>
                            <p className="text-xs font-semibold text-muted">{student.school.name}</p>
                          </TableCell>
                          <TableCell>
                            <ProgressBar value={student.overall_learning_progress_percent} />
                          </TableCell>
                          <TableCell>
                            <p className="font-black text-ink">
                              {formatPercent(student.average_best_quiz_score_percent)}
                            </p>
                            <p className="text-xs font-semibold text-muted">
                              {student.quizzes_completed}/{student.published_quizzes} selesai
                            </p>
                          </TableCell>
                          <TableCell>
                            <Badge tone={statusTone(status)}>{learningStatusLabel(status)}</Badge>
                          </TableCell>
                          <TableCell>
                            <Link
                              className="inline-flex min-h-9 items-center rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 py-1 text-xs font-black text-ink transition-colors hover:bg-primary hover:text-primary-foreground"
                              href={`/admin/progress/students/${student.student_id}`}
                            >
                              Detail Siswa
                            </Link>
                          </TableCell>
                        </tr>
                      );
                    })}
                  </tbody>
                </Table>
                <Pagination
                  onPageChange={setStudentPage}
                  page={studentMeta?.current_page ?? studentPage}
                  totalPages={studentMeta?.last_page ?? 1}
                />
              </div>
            )
          ) : null}
        </CardContent>
      </Card>

      <ClassProgressPrintReport
        completedStudents={completedStudents}
        notStartedStudents={notStartedStudents}
        schoolClass={schoolClass}
        students={students}
        summary={summary}
      />
    </div>
  );
}
