"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, Input, LoadingState, PageHeader, Pagination, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { formatCount, formatOptional, formatPercent } from "./teacher-utils";

export function TeacherStudentList() {
  const { token, user } = useAuth();
  const classId = user?.active_class?.id ?? "";
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const studentsQuery = useQuery({
    queryKey: ["teacher", "students", classId, page],
    queryFn: () => teacherService.studentProgress(token ?? "", { classId, page }),
    enabled: Boolean(token && classId),
  });
  const summaryQuery = useQuery({
    queryKey: ["teacher", "students", classId, "summary"],
    queryFn: () => teacherService.allStudentProgress(token ?? "", classId),
    enabled: Boolean(token && classId),
  });

  const students = useMemo(() => studentsQuery.data?.items ?? [], [studentsQuery.data?.items]);
  const allStudents = summaryQuery.data ?? [];
  const filteredStudents = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return students;
    return students.filter((student) => [
      student.full_name,
      student.class?.name,
    ].filter(Boolean).join(" ").toLowerCase().includes(keyword));
  }, [search, students]);

  return (
    <div className="grid gap-6">
      <PageHeader
        badge="Guru"
        description="Cari siswa, lihat progress modul, dan buka detail belajar dari kelas aktif Anda."
        title="Daftar Siswa"
      />

      {studentsQuery.isLoading || summaryQuery.isLoading ? <LoadingState title="Memuat siswa" /> : null}
      {studentsQuery.isError || summaryQuery.isError ? (
        <ErrorState
          description={getFirstApiError(studentsQuery.error ?? summaryQuery.error)}
          onRetry={() => void Promise.all([studentsQuery.refetch(), summaryQuery.refetch()])}
          title="Gagal memuat siswa"
        />
      ) : null}

      {!studentsQuery.isLoading && !summaryQuery.isLoading && !studentsQuery.isError && !summaryQuery.isError ? (
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
               <StatsCard helper={user?.active_class?.name ?? "Kelas aktif"} label="Total siswa" value={formatCount(allStudents.length)} />
               <StatsCard helper="Rata-rata kelas" label="Progress belajar" value={formatPercent(
                 allStudents.length > 0
                   ? allStudents.reduce((acc, s) => acc + (s.overall_learning_progress_percent ?? 0), 0) / allStudents.length
                   : null
               )} />
               <StatsCard helper="Interaksi kuis" label="Penyelesaian Kuis" value={formatCount(
                 allStudents.reduce((acc, s) => acc + (s.quizzes_completed ?? 0), 0)
               )} />
            </section>

            <Card>
              <CardContent>
                <Input onChange={(event) => setSearch(event.target.value)} placeholder="Cari nama siswa atau kelas..." value={search} />
              </CardContent>
            </Card>

            {filteredStudents.length === 0 ? (
              <Card>
                <CardContent>
                  <EmptyState description="Coba gunakan kata kunci lain." title="Siswa tidak ditemukan" />
                </CardContent>
              </Card>
            ) : null}

            <div className="grid gap-4 md:grid-cols-2">
              {filteredStudents.map((student) => (
                <Card key={student.student_id}>
                  <CardHeader>
                    <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                      <div>
                        <h2 className="text-xl font-black text-ink">{formatOptional(student.full_name)}</h2>
                        <p className="mt-1 text-sm text-slate-600">{formatOptional(student.class?.name)}</p>
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

             <Pagination
               onPageChange={setPage}
               page={studentsQuery.data?.meta?.current_page ?? page}
               totalPages={studentsQuery.data?.meta?.last_page ?? 1}
             />
           </div>
         )
      ) : null}
    </div>
  );
}
