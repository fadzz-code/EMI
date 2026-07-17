"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, UserRound } from "lucide-react";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { TeacherClassNav } from "./teacher-class-nav";
import { teacherService } from "./teacher-service";
import { formatCount, formatDate, formatPercent, statusLabel } from "./teacher-utils";

export function TeacherClassStudents({ classId }: { classId: string }) {
  const { token } = useAuth();
  const studentsQuery = useQuery({
    queryKey: ["teacher", "classes", classId, "students", "page"],
    queryFn: () => teacherService.classStudents(token ?? "", classId),
    enabled: Boolean(token && classId),
  });
  const progressQuery = useQuery({
    queryKey: ["teacher", "progress", "students"],
    queryFn: () => teacherService.studentProgress(token ?? ""),
    enabled: Boolean(token),
  });

  const students = studentsQuery.data?.items ?? [];
  const progressRows = progressQuery.data?.items ?? [];

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
              <StatsCard helper="Siswa aktif di kelas" label="Total siswa" value={formatCount(students.length)} />
              <StatsCard helper="Jika laporan progress tersedia" label="Progress tersedia" value={formatCount(progressRows.length)} />
              <StatsCard helper="Data kosong bukan dibuat-buat" label="Catatan" value={progressRows.length > 0 ? "Real" : "Belum tersedia"} />
            </section>
            <div className="grid gap-4 md:grid-cols-2">
              {students.map((membership) => {
                const progress = progressRows.find((row) => row.student_id === membership.student.id || row.full_name === membership.student.full_name);

                return (
                  <Card className="group flex h-full flex-col transition hover:-translate-y-1 hover:shadow-emi" key={membership.membership_id}>
                    <CardHeader className="flex-1">
                      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                        <div>
                          <h2 className="text-xl font-black text-foreground">{membership.student.full_name}</h2>
                           <p className="mt-1 text-sm font-semibold text-muted">{membership.student.email}</p>
                          <div className="mt-2"><Badge tone={membership.student.status === "approved" ? "blue" : "neutral"}>{statusLabel(membership.student.status)}</Badge></div>
                        </div>
                        <Link
                          className="inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5"
                          href={teacherRoutes.studentDetail(membership.student.id)}
                        >
                          Lihat Detail
                          <UserRound className="size-4" strokeWidth={2.5} />
                        </Link>
                      </div>
                    </CardHeader>
                    <CardContent>
                      <dl className="grid gap-3 text-sm sm:grid-cols-2">
                        <div className="rounded-xl border-2 border-border bg-surface-muted p-3">
                          <dt className="font-black uppercase text-muted">Bergabung</dt>
                          <dd className="mt-1 font-bold text-foreground">{formatDate(membership.joined_at)}</dd>
                        </div>
                        <div className="rounded-xl border-2 border-border bg-surface-muted p-3">
                          <dt className="font-black uppercase text-muted">Progress</dt>
                          <dd className="mt-1 font-bold text-foreground">{progress ? formatPercent(progress.overall_learning_progress_percent) : "Belum tersedia"}</dd>
                        </div>
                      </dl>
                      {!progress ? <p className="mt-3 text-sm font-bold text-muted">Progress belum tersedia untuk siswa ini.</p> : null}
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          </div>
        )
      ) : null}
    </div>
  );
}
