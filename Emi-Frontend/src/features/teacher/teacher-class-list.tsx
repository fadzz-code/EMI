"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

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
    <div className="grid gap-8">
      <PageHeader
        badge="Guru"
        description="Daftar kelas yang dapat Anda akses. Untuk EMI saat ini, guru mengajar dari satu kelas aktif."
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
          <div className="grid gap-6">
            <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
              <StatsCard helper="Kelas yang ditetapkan Admin" label="Kelas aktif" value={formatCount(classesQuery.data?.meta?.total ?? classes.length)} />
              <StatsCard helper="Jumlah dari active_students_count jika tersedia" label="Total siswa" value={formatCount(classes.reduce((sum, item) => sum + (item.active_students_count ?? 0), 0))} />
              <StatsCard helper="Mengikuti assignment aktif" label="Akses" value="Aman" />
            </section>

            <div className="grid items-stretch gap-6 md:grid-cols-2">
              {classes.map((teacherClass) => (
                <Card className="flex h-full flex-col" key={teacherClass.id}>
                  <CardHeader>
                    <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                      <div>
                        <Badge tone={teacherClass.status === "active" ? "blue" : "neutral"}>{statusLabel(teacherClass.status)}</Badge>
                        <h2 className="mt-2 text-xl font-black text-ink">{teacherClass.name}</h2>
                        <p className="mt-1 text-sm font-semibold text-muted">{formatOptional(teacherClass.school?.name)}</p>
                      </div>
                      <Link className="inline-flex min-h-11 items-center justify-center rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition-transform hover:-translate-y-0.5" href={teacherRoutes.classDetail(teacherClass.id)}>
                        Detail
                      </Link>
                    </div>
                  </CardHeader>
                  <CardContent className="flex flex-1 flex-col">
                    <dl className="grid flex-1 gap-3 text-sm sm:grid-cols-2">
                      <div className="rounded-xl border-2 border-border bg-surface-muted p-3">
                        <dt className="font-black uppercase text-muted">Tahun ajaran</dt>
                        <dd className="mt-1 font-bold text-ink">{formatOptional(teacherClass.academic_year)}</dd>
                      </div>
                      <div className="rounded-xl border-2 border-border bg-surface-muted p-3">
                        <dt className="font-black uppercase text-muted">Siswa</dt>
                        <dd className="mt-1 font-bold text-ink">{formatCount(teacherClass.active_students_count)}</dd>
                      </div>
                      <div className="rounded-xl border-2 border-border bg-surface-muted p-3 sm:col-span-2">
                        <dt className="font-black uppercase text-muted">Guru aktif</dt>
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
