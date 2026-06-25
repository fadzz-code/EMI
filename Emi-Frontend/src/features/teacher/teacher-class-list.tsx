"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { teacherService } from "./teacher-service";
import { formatCount, formatOptional, statusLabel } from "./teacher-utils";

export function TeacherClassList() {
  const { token } = useAuth();
  const classesQuery = useQuery({
    queryKey: ["teacher", "classes"],
    queryFn: () => teacherService.classes(token ?? ""),
    enabled: Boolean(token),
  });

  const classes = classesQuery.data?.items ?? [];

  return (
    <div className="grid gap-6">
      <PageHeader
        badge="Guru"
        description="Daftar kelas yang dapat diakses guru mengikuti scope backend. Untuk EMI saat ini guru hanya memiliki satu kelas aktif."
        title="Kelas Saya"
      />

      {classesQuery.isLoading ? <LoadingState title="Memuat kelas guru" /> : null}
      {classesQuery.isError ? (
        <ErrorState
          description={getFirstApiError(classesQuery.error)}
          onRetry={() => void classesQuery.refetch()}
          title="Gagal memuat kelas guru"
        />
      ) : null}

      {!classesQuery.isLoading && !classesQuery.isError ? (
        classes.length === 0 ? (
          <Card>
            <CardContent>
              <EmptyState
                description="Belum ada kelas aktif yang terhubung dengan akun guru ini. Minta Admin menetapkan guru ke kelas."
                title="Kelas belum tersedia"
              />
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-4">
            <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
              <StatsCard helper="Scope dari endpoint /classes" label="Kelas aktif" value={formatCount(classesQuery.data?.meta?.total ?? classes.length)} />
              <StatsCard helper="Jumlah dari active_students_count jika tersedia" label="Total siswa" value={formatCount(classes.reduce((sum, item) => sum + (item.active_students_count ?? 0), 0))} />
              <StatsCard helper="Dibatasi assignment aktif backend" label="Akses" value="Read-only" />
            </section>

            <div className="grid gap-4 md:grid-cols-2">
              {classes.map((teacherClass) => (
                <Card key={teacherClass.id}>
                  <CardHeader>
                    <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                      <div>
                        <Badge tone={teacherClass.status === "active" ? "blue" : "neutral"}>{statusLabel(teacherClass.status)}</Badge>
                        <h2 className="mt-2 text-xl font-black text-ink">{teacherClass.name}</h2>
                        <p className="mt-1 text-sm text-slate-600">{formatOptional(teacherClass.school?.name)}</p>
                      </div>
                      <Link className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-blue-600 px-4 py-2 text-sm font-bold text-white shadow-brutal hover:bg-blue-700" href={`/teacher/classes/${teacherClass.id}`}>
                        Detail
                      </Link>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <dl className="grid gap-3 text-sm sm:grid-cols-2">
                      <div className="rounded-xl bg-slate-50 p-3">
                        <dt className="font-black uppercase text-slate-500">Tahun ajaran</dt>
                        <dd className="mt-1 font-bold text-ink">{formatOptional(teacherClass.academic_year)}</dd>
                      </div>
                      <div className="rounded-xl bg-slate-50 p-3">
                        <dt className="font-black uppercase text-slate-500">Siswa</dt>
                        <dd className="mt-1 font-bold text-ink">{formatCount(teacherClass.active_students_count)}</dd>
                      </div>
                      <div className="rounded-xl bg-slate-50 p-3 sm:col-span-2">
                        <dt className="font-black uppercase text-slate-500">Guru aktif</dt>
                        <dd className="mt-1 font-bold text-ink">{formatOptional(teacherClass.active_teacher_assignment?.teacher?.full_name)}</dd>
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
