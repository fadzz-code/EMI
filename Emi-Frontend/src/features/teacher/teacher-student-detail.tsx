"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Card, CardContent, CardHeader, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { formatCount, formatOptional, formatPercent } from "./teacher-utils";

export function TeacherStudentDetail({ studentId }: { studentId: string }) {
  const { token, user } = useAuth();
  
  const studentQuery = useQuery({
    queryKey: ["teacher", "students", studentId],
    queryFn: () => teacherService.studentDetail(token ?? "", studentId),
    enabled: Boolean(token && studentId),
  });

  const student = studentQuery.data;

  return (
    <div className="grid gap-6">
      <Link
        className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100"
        href={teacherRoutes.students}
      >
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

          <section className="grid gap-6 xl:grid-cols-2">
            <Card>
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Ringkasan Modul</h2>
              </CardHeader>
              <CardContent>
                <dl className="grid gap-3 text-sm">
                  <div className="flex items-center justify-between rounded-xl bg-slate-50 p-3">
                    <dt className="font-black uppercase text-slate-500">Tersedia di Kelas</dt>
                    <dd className="font-bold text-ink">{formatCount(student.published_modules)} modul</dd>
                  </div>
                  <div className="flex items-center justify-between rounded-xl bg-slate-50 p-3">
                    <dt className="font-black uppercase text-slate-500">Mulai Dikerjakan</dt>
                    <dd className="font-bold text-ink">{formatCount(student.started_modules)} modul</dd>
                  </div>
                  <div className="flex items-center justify-between rounded-xl bg-slate-50 p-3">
                    <dt className="font-black uppercase text-slate-500">Selesai</dt>
                    <dd className="font-bold text-ink text-green-700">{formatCount(student.completed_modules)} modul</dd>
                  </div>
                </dl>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Ringkasan Kuis</h2>
              </CardHeader>
              <CardContent>
                <dl className="grid gap-3 text-sm">
                  <div className="flex items-center justify-between rounded-xl bg-slate-50 p-3">
                    <dt className="font-black uppercase text-slate-500">Kuis Tersedia</dt>
                    <dd className="font-bold text-ink">{formatCount(student.published_quizzes)} kuis</dd>
                  </div>
                  <div className="flex items-center justify-between rounded-xl bg-slate-50 p-3">
                    <dt className="font-black uppercase text-slate-500">Telah Dicoba</dt>
                    <dd className="font-bold text-ink">{formatCount(student.quizzes_attempted)} kuis</dd>
                  </div>
                  <div className="flex items-center justify-between rounded-xl bg-slate-50 p-3">
                    <dt className="font-black uppercase text-slate-500">Selesai/Nilai Final</dt>
                    <dd className="font-bold text-ink text-blue-700">{formatCount(student.quizzes_completed)} kuis</dd>
                  </div>
                </dl>
                <div className="mt-4">
                  <Link
                    className="inline-flex w-full min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-white px-4 py-2 text-sm font-bold text-ink shadow-brutal hover:bg-slate-100"
                    href={teacherRoutes.progressReport}
                  >
                    Lihat di Laporan Keseluruhan
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
