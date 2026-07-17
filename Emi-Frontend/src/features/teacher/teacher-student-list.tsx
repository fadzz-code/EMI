"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Search, UserRound } from "lucide-react";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, Input, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { formatCount, formatOptional, formatPercent } from "./teacher-utils";

export function TeacherStudentList() {
  const { token, user } = useAuth();
  const [search, setSearch] = useState("");
  const studentsQuery = useQuery({
    queryKey: ["teacher", "students"],
    queryFn: () => teacherService.studentProgress(token ?? ""),
    enabled: Boolean(token),
  });

  const students = useMemo(() => studentsQuery.data?.items ?? [], [studentsQuery.data?.items]);
  const filteredStudents = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return students;
    return students.filter((student) => [
      student.full_name,
      student.class?.name,
    ].filter(Boolean).join(" ").toLowerCase().includes(keyword));
  }, [search, students]);

  return (
    <div className="grid gap-8">
      <PageHeader
        badge="Guru"
        description="Cari siswa, lihat progress modul, dan buka detail belajar dari kelas aktif Anda."
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
          <div className="grid gap-6">
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

            <Card>
              <CardContent>
                <div className="flex items-center gap-3">
                  <Search className="size-5 shrink-0 text-muted" strokeWidth={2.5} />
                  <Input onChange={(event) => setSearch(event.target.value)} placeholder="Cari nama siswa atau kelas..." value={search} />
                </div>
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
                <Card className="group flex h-full flex-col transition hover:-translate-y-1 hover:shadow-emi" key={student.student_id}>
                  <CardHeader className="flex-1">
                    <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                      <div>
                        <h2 className="text-xl font-black text-foreground">{formatOptional(student.full_name)}</h2>
                        <p className="mt-1 text-sm font-semibold text-muted">{formatOptional(student.class?.name)}</p>
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
                        <dt className="font-black uppercase text-muted">Progress Modul</dt>
                        <dd className="mt-1 flex items-center justify-between">
                          <span className="font-bold text-foreground">
                            {formatCount(student.completed_modules)} / {formatCount(student.published_modules)}
                          </span>
                          <Badge tone="blue">{formatPercent(student.overall_learning_progress_percent)}</Badge>
                        </dd>
                      </div>
                      <div className="rounded-xl border-2 border-border bg-surface-muted p-3">
                        <dt className="font-black uppercase text-muted">Penyelesaian Kuis</dt>
                        <dd className="mt-1 font-bold text-foreground">
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
