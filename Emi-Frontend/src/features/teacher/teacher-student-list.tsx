"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { formatCount, formatOptional, formatPercent } from "./teacher-utils";

export function TeacherStudentList() {
  const { token, user } = useAuth();
  const studentsQuery = useQuery({
    queryKey: ["teacher", "students"],
    queryFn: () => teacherService.studentProgress(token ?? ""),
    enabled: Boolean(token),
  });

  const students = studentsQuery.data?.items ?? [];

  return (
    <div className="grid gap-6">
      <PageHeader
        badge="Guru"
        description="Daftar siswa dalam kelas aktif Anda berdasarkan data progress."
        title="Daftar Siswa"
      />

      {studentsQuery.isLoading ? <LoadingState title="Memuat siswa" /> : null}
      {studentsQuery.isError ? (
        <ErrorState
          description={getFirstApiError(studentsQuery.error)}
          onRetry={() => void studentsQuery.refetch()}
          title="Gagal memuat siswa"
        />
      ) : null}

      {!studentsQuery.isLoading && !studentsQuery.isError ? (
        students.length === 0 ? (
          <Card>
            <CardContent>
              <EmptyState
                description="Belum ada siswa yang tergabung di kelas Anda."
                title="Siswa belum tersedia"
              />
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-4">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard helper={user?.active_class?.name ?? "Kelas aktif"} label="Total siswa" value={formatCount(students.length)} />
              <StatsCard helper="Rata-rata kelas" label="Progress belajar" value={formatPercent(
                students.length > 0
                  ? students.reduce((acc, s) => acc + (s.overall_learning_progress_percent ?? 0), 0) / students.length
                  : null
              )} />
              <StatsCard helper="Interaksi kuis" label="Penyelesaian Kuis" value={formatCount(
                students.reduce((acc, s) => acc + (s.quizzes_completed ?? 0), 0)
              )} />
            </section>

            <div className="grid gap-4 md:grid-cols-2">
              {students.map((student) => (
                <Card key={student.student_id}>
                  <CardHeader>
                    <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                      <div>
                        <h2 className="text-xl font-black text-ink">{formatOptional(student.student_name)}</h2>
                        <p className="mt-1 text-sm text-slate-600">{formatOptional(student.student_email)}</p>
                      </div>
                      <Link
                        className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-blue-600 px-4 py-2 text-sm font-bold text-white shadow-brutal hover:bg-blue-700"
                        href={teacherRoutes.studentDetail(student.student_id ?? "")}
                      >
                        Lihat Detail
                      </Link>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <dl className="grid gap-3 text-sm sm:grid-cols-2">
                      <div className="rounded-xl bg-slate-50 p-3">
                        <dt className="font-black uppercase text-slate-500">Progress Modul</dt>
                        <dd className="mt-1 flex items-center justify-between">
                          <span className="font-bold text-ink">
                            {formatCount(student.completed_modules)} / {formatCount(student.published_modules)}
                          </span>
                          <Badge tone="blue">{formatPercent(student.overall_learning_progress_percent)}</Badge>
                        </dd>
                      </div>
                      <div className="rounded-xl bg-slate-50 p-3">
                        <dt className="font-black uppercase text-slate-500">Penyelesaian Kuis</dt>
                        <dd className="mt-1 font-bold text-ink">
                          {formatCount(student.quizzes_completed)} / {formatCount(student.published_quizzes)} kuis
                        </dd>
                      </div>
                    </dl>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>
        )
      ) : null}
    </div>
  );
}
