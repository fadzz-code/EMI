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
import { ProgressBar, ProgressSummaryCards } from "./progress-summary-cards";
import {
  formatDateTime,
  formatNumber,
  formatPercent,
  latestActivity,
  learningStatus,
  learningStatusLabel,
  statusTone,
} from "./progress-utils";

export function ProgressClassDetail({ classId }: { classId: string }) {
  const { token } = useAuth();
  const [studentPage, setStudentPage] = useState(1);

  const classQuery = useQuery({
    queryKey: ["admin", "progress", "class-detail", classId, studentPage],
    queryFn: () => progressReportService.classDetail(token ?? "", classId, { page: studentPage, per_page: 12 }),
    enabled: Boolean(token && classId),
  });
  const summaryQuery = { ...classQuery, data: classQuery.data?.summary };
  const studentsQuery = { ...classQuery, data: classQuery.data ? { items: classQuery.data.students.data, meta: classQuery.data.students.meta } : undefined };
  const completedStudentsQuery = classQuery;
  const notStartedStudentsQuery = classQuery;
  const schoolClass = classQuery.data?.class;
  const students = studentsQuery.data?.items ?? [];
  const studentMeta = studentsQuery.data?.meta;
  const completedStudents = classQuery.data?.summary.completed_students;
  const notStartedStudents = classQuery.data?.summary.not_started_students;

  function printReport() {
    void progressReportService.downloadPdf(token ?? "", `/admin/reports/progress/classes/${classId}/pdf`);
  }

  return (
    <div className="grid gap-6">
      <Link
        className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100"
        href="/admin/progress"
      >
        Kembali ke Progress
      </Link>

      {classQuery.isLoading ? <LoadingState title="Memuat identitas kelas" /> : null}
      {classQuery.isError ? (
        <ErrorState
          description={getFirstApiError(classQuery.error)}
          onRetry={() => void classQuery.refetch()}
          title="Gagal memuat kelas"
        />
      ) : null}

      {schoolClass ? (
        <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div>
            <Badge tone="yellow">ADMIN-18</Badge>
            <h1 className="mt-2 text-3xl font-black text-ink">{schoolClass.name}</h1>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              {schoolClass.school?.name ?? "-"} | {schoolClass.academic_year} | Guru:{" "}
              {schoolClass.teacher?.full_name ?? "Belum tersedia"}
            </p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row">
            <Button
              disabled={
                classQuery.isLoading ||
                summaryQuery.isLoading ||
                studentsQuery.isLoading ||
                completedStudentsQuery.isLoading ||
                notStartedStudentsQuery.isLoading
              }
              onClick={printReport}
            >
              Cetak PDF
            </Button>
          </div>
        </header>
      ) : null}

      {summaryQuery.isLoading ? <LoadingState title="Memuat ringkasan kelas" /> : null}
      {summaryQuery.isError ? (
        <ErrorState
          description={getFirstApiError(summaryQuery.error)}
          onRetry={() => void summaryQuery.refetch()}
          title="Gagal memuat ringkasan kelas"
        />
      ) : null}
      {!summaryQuery.isLoading && !summaryQuery.isError ? (
        <>
          <ProgressSummaryCards summary={summaryQuery.data} />
          <section className="grid gap-4 md:grid-cols-3">
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-slate-500">Siswa selesai modul</p>
                <p className="mt-3 text-3xl font-black text-ink">
                  {formatNumber(completedStudents)}
                </p>
                <p className="mt-2 text-sm text-slate-600">
                  Dari filter `learning_status=completed`.
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-slate-500">Siswa belum mulai</p>
                <p className="mt-3 text-3xl font-black text-ink">
                  {formatNumber(notStartedStudents)}
                </p>
                <p className="mt-2 text-sm text-slate-600">
                  Dari filter `learning_status=not_started`.
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-slate-500">Aktivitas terakhir</p>
                <p className="mt-3 text-xl font-black text-ink">
                  {formatDateTime(students.map(latestActivity).filter(Boolean).sort().pop())}
                </p>
                <p className="mt-2 text-sm text-slate-600">
                  Diambil dari halaman siswa saat ini.
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
          {studentsQuery.isLoading ? <LoadingState title="Memuat siswa kelas" /> : null}
          {studentsQuery.isError ? (
            <ErrorState
              description={getFirstApiError(studentsQuery.error)}
              onRetry={() => void studentsQuery.refetch()}
              title="Gagal memuat progress siswa kelas"
            />
          ) : null}
          {!studentsQuery.isLoading && !studentsQuery.isError ? (
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
                            <p className="text-xs text-slate-600">{student.school.name}</p>
                          </TableCell>
                          <TableCell>
                            <ProgressBar value={student.overall_learning_progress_percent} />
                          </TableCell>
                          <TableCell>
                            <p className="font-black text-ink">
                              {formatPercent(student.average_best_quiz_score_percent)}
                            </p>
                            <p className="text-xs text-slate-600">
                              {student.quizzes_completed}/{student.published_quizzes} selesai
                            </p>
                          </TableCell>
                          <TableCell>
                            <Badge tone={statusTone(status)}>{learningStatusLabel(status)}</Badge>
                          </TableCell>
                          <TableCell>
                            <Link
                              className="inline-flex min-h-9 items-center rounded-lg border-2 border-ink bg-white px-3 py-1 text-xs font-black text-ink hover:bg-yellow-100"
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

    </div>
  );
}
