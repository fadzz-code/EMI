"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { ArrowLeft, UserRound } from "lucide-react";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, Pagination, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { TeacherClassNav } from "./teacher-class-nav";
import { teacherService } from "./teacher-service";
import { formatCount, formatOptional, formatPercent, statusLabel } from "./teacher-utils";
import { teacherProgressKey } from "./teacher-workflow";

export function TeacherClassStudents({ classId }: { classId: string }) {
  const { token } = useAuth();
  const [page, setPage] = useState(1);
  const studentsQuery = useQuery({
    queryKey: teacherProgressKey(classId, { page }),
    queryFn: () => teacherService.studentProgress(token ?? "", { class_id: classId, page }),
    enabled: Boolean(token && classId),
  });

  const students = studentsQuery.data?.items ?? [];

  return (
    <div className="grid gap-8">
      <Link className="inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-foreground transition hover:-translate-y-0.5 hover:bg-surface-muted hover:shadow-emi" href={teacherRoutes.classes}>
        <ArrowLeft className="size-4" strokeWidth={2.5} />
        Kembali ke Daftar Kelas
      </Link>
      <PageHeader badge="Guru" description="Daftar siswa aktif di kelas yang ditetapkan untuk Anda." title="Siswa Kelas" />

      <TeacherClassNav classId={classId} />

      {studentsQuery.isLoading ? <LoadingState title="Memuat siswa kelas" /> : null}
      {studentsQuery.isError ? <ErrorState description={getFirstApiError(studentsQuery.error)} onRetry={() => void studentsQuery.refetch()} title="Gagal memuat siswa" /> : null}

      {!studentsQuery.isLoading && !studentsQuery.isError ? (
        students.length === 0 ? (
          <Card><CardContent><EmptyState description="Belum ada siswa aktif pada kelas ini." title="Siswa kosong" /></CardContent></Card>
        ) : (
          <div className="grid gap-6">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard helper="Siswa aktif di kelas" label="Total siswa" value={formatCount(studentsQuery.data?.meta?.total)} />
              <StatsCard helper="Halaman saat ini" label="Progress tersedia" value={formatCount(students.length)} />
              <StatsCard helper="Data canonical progress" label="Catatan" value="Real" />
            </section>
            <div className="grid gap-4 md:grid-cols-2">
              {students.map((student) => (
                  <Card className="group flex h-full flex-col transition hover:-translate-y-1 hover:shadow-emi" key={student.student_id}>
                    <CardHeader className="flex-1">
                      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                        <div>
                          <h2 className="text-xl font-black text-foreground">{formatOptional(student.full_name)}</h2>
                          <p className="mt-1 text-sm font-semibold text-muted">{formatOptional(student.email)}</p>
                          <div className="mt-2"><Badge tone={student.student_status === "approved" ? "blue" : "neutral"}>{statusLabel(student.student_status)}</Badge></div>
                        </div>
                        <Link
                          className="inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5"
                          href={teacherRoutes.studentDetail(student.student_id ?? "")}
                        >
                          Lihat Detail
                          <UserRound className="size-4" strokeWidth={2.5} />
                        </Link>
                      </div>
                    </CardHeader>
                    <CardContent>
                      <dl className="grid gap-3 text-sm sm:grid-cols-2">
                        <div className="rounded-xl border-2 border-border bg-surface-muted p-3">
                          <dt className="font-black uppercase text-muted">Kelas</dt>
                          <dd className="mt-1 font-bold text-foreground">{formatOptional(student.class?.name)}</dd>
                        </div>
                        <div className="rounded-xl border-2 border-border bg-surface-muted p-3">
                          <dt className="font-black uppercase text-muted">Progress</dt>
                          <dd className="mt-1 font-bold text-foreground">{formatPercent(student.overall_learning_progress_percent)}</dd>
                        </div>
                      </dl>
                    </CardContent>
                  </Card>
              ))}
            </div>
            <Pagination onPageChange={setPage} page={studentsQuery.data?.meta?.current_page ?? page} totalPages={studentsQuery.data?.meta?.last_page ?? 1} />
          </div>
        )
      ) : null}
    </div>
  );
}
