"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

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
    queryKey: ["teacher", "progress", "students", classId, "all"],
    queryFn: () => teacherService.allStudentProgress(token ?? "", classId),
    enabled: Boolean(token && classId),
  });

  const students = studentsQuery.data?.items ?? [];
  const progressRows = progressQuery.data ?? [];

  return (
    <div className="grid gap-6">
      <Link className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100" href={teacherRoutes.classes}>
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
          <div className="grid gap-4">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard helper="Siswa aktif di kelas" label="Total siswa" value={formatCount(students.length)} />
              <StatsCard helper="Siswa dengan laporan progres" label="Progres tersedia" value={formatCount(progressRows.length)} />
              <StatsCard helper="Berdasarkan data laporan" label="Status data" value={progressRows.length > 0 ? "Tersedia" : "Belum tersedia"} />
            </section>
            <div className="grid gap-4 md:grid-cols-2">
              {students.map((membership) => {
                const progress = progressRows.find((row) => row.student_id === membership.student.id);

                return (
                  <Card key={membership.membership_id}>
                    <CardHeader>
                      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                        <div>
                          <h2 className="text-xl font-black text-ink">{membership.student.full_name}</h2>
                          <p className="mt-1 text-sm text-slate-600">{membership.student.email}</p>
                          <div className="mt-2"><Badge tone={membership.student.status === "approved" ? "blue" : "neutral"}>{statusLabel(membership.student.status)}</Badge></div>
                        </div>
                        <Link
                          className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-blue-600 px-4 py-2 text-sm font-bold text-white shadow-brutal hover:bg-blue-700"
                          href={teacherRoutes.studentDetail(membership.student.id)}
                        >
                          Lihat Detail
                        </Link>
                      </div>
                    </CardHeader>
                    <CardContent>
                      <dl className="grid gap-3 text-sm sm:grid-cols-2">
                        <div className="rounded-xl bg-slate-50 p-3">
                          <dt className="font-black uppercase text-slate-500">Bergabung</dt>
                          <dd className="mt-1 font-bold text-ink">{formatDate(membership.joined_at)}</dd>
                        </div>
                        <div className="rounded-xl bg-slate-50 p-3">
                          <dt className="font-black uppercase text-slate-500">Progress</dt>
                          <dd className="mt-1 font-bold text-ink">{progress ? formatPercent(progress.overall_learning_progress_percent) : "Belum tersedia"}</dd>
                        </div>
                      </dl>
                      {!progress ? <p className="mt-3 text-sm font-bold text-slate-500">Progress belum tersedia untuk siswa ini.</p> : null}
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
