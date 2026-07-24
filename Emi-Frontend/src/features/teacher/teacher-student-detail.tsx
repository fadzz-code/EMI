"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, ChartNoAxesColumnIncreasing } from "lucide-react";

import { Card, CardContent, CardHeader, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { formatCount, formatOptional, formatPercent } from "./teacher-utils";
import { teacherProgressKey } from "./teacher-workflow";

export function TeacherStudentDetail({ studentId }: { studentId: string }) {
  const { token, user } = useAuth();
  const classId = user?.active_class?.id ?? "";
  const studentQuery = useQuery({
    queryKey: teacherProgressKey(classId, { student_id: studentId }),
    queryFn: () => teacherService.studentDetail(token ?? "", studentId, classId),
    enabled: Boolean(token && studentId && classId),
  });

  const student = studentQuery.data;

  return (
    <div className="grid gap-8">
      <Link
        className="inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-foreground transition hover:-translate-y-0.5 hover:bg-surface-muted hover:shadow-emi"
        href={teacherRoutes.students}
      >
        <ArrowLeft className="size-4" strokeWidth={2.5} />
        Kembali ke Daftar Siswa
      </Link>
      
      {studentQuery.isLoading ? <LoadingState title="Memuat detail siswa" /> : null}
      {studentQuery.isError ? (
        <ErrorState
          description={getFirstApiError(studentQuery.error)}
          onRetry={() => void studentQuery.refetch()}
          title="Gagal memuat detail siswa"
        />
      ) : null}

      {student ? (
        <>
          <PageHeader
            badge="Profil Siswa"
            description={`Kelas aktif: ${user?.active_class?.name ?? "Tidak diketahui"}`}
            title={formatOptional(student.full_name)}
          />

          <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatsCard helper="Kelas terdaftar" label="Kelas" value={formatOptional(student.class?.name)} />
            <StatsCard helper="Progress modul keseluruhan" label="Progress Belajar" value={formatPercent(student.overall_learning_progress_percent)} />
            <StatsCard helper="Modul yang diselesaikan" label="Modul Selesai" value={`${formatCount(student.completed_modules)} dari ${formatCount(student.published_modules)}`} />
            <StatsCard helper="Kuis yang dikerjakan" label="Kuis Selesai" value={`${formatCount(student.quizzes_completed)} dari ${formatCount(student.published_quizzes)}`} />
          </section>

          <section className="grid items-stretch gap-6 xl:grid-cols-2">
            <Card className="flex h-full flex-col">
              <CardHeader>
                <h2 className="text-xl font-black text-foreground">Ringkasan Modul</h2>
              </CardHeader>
              <CardContent className="flex flex-1 flex-col">
                <dl className="grid gap-3 text-sm">
                  <div className="flex items-center justify-between rounded-xl border-2 border-border bg-surface-muted p-3">
                    <dt className="font-black uppercase text-muted">Tersedia di Kelas</dt>
                    <dd className="font-bold text-foreground">{formatCount(student.published_modules)} modul</dd>
                  </div>
                  <div className="flex items-center justify-between rounded-xl border-2 border-border bg-surface-muted p-3">
                    <dt className="font-black uppercase text-muted">Mulai Dikerjakan</dt>
                    <dd className="font-bold text-foreground">{formatCount(student.started_modules)} modul</dd>
                  </div>
                  <div className="flex items-center justify-between rounded-xl border-2 border-border bg-surface-muted p-3">
                    <dt className="font-black uppercase text-muted">Selesai</dt>
                    <dd className="font-bold text-success-foreground">{formatCount(student.completed_modules)} modul</dd>
                  </div>
                </dl>
              </CardContent>
            </Card>

            <Card className="flex h-full flex-col">
              <CardHeader>
                <h2 className="text-xl font-black text-foreground">Ringkasan Kuis</h2>
              </CardHeader>
              <CardContent className="flex flex-1 flex-col">
                <dl className="grid gap-3 text-sm">
                  <div className="flex items-center justify-between rounded-xl border-2 border-border bg-surface-muted p-3">
                    <dt className="font-black uppercase text-muted">Kuis Tersedia</dt>
                    <dd className="font-bold text-foreground">{formatCount(student.published_quizzes)} kuis</dd>
                  </div>
                  <div className="flex items-center justify-between rounded-xl border-2 border-border bg-surface-muted p-3">
                    <dt className="font-black uppercase text-muted">Telah Dicoba</dt>
                    <dd className="font-bold text-foreground">{formatCount(student.quizzes_attempted)} kuis</dd>
                  </div>
                  <div className="flex items-center justify-between rounded-xl border-2 border-border bg-surface-muted p-3">
                    <dt className="font-black uppercase text-muted">Selesai/Nilai Final</dt>
                    <dd className="font-bold text-info-foreground">{formatCount(student.quizzes_completed)} kuis</dd>
                  </div>
                </dl>
                <div className="mt-4">
                  <Link
                    className="inline-flex min-h-11 w-full items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-foreground shadow-emi transition hover:-translate-y-0.5 hover:bg-surface-muted"
                    href={teacherRoutes.progressReport}
                  >
                    Lihat di Laporan Keseluruhan
                    <ChartNoAxesColumnIncreasing className="size-4" strokeWidth={2.5} />
                  </Link>
                </div>
              </CardContent>
            </Card>
          </section>
        </>
      ) : null}
    </div>
  );
}
