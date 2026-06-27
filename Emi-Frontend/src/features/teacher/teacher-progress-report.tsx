"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Badge, Card, CardContent, EmptyState, ErrorState, LoadingState, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { formatCount, formatOptional, formatPercent } from "./teacher-utils";

export function TeacherProgressReport() {
  const { token, user } = useAuth();
  const progressQuery = useQuery({
    queryKey: ["teacher", "progress", "students", "report"],
    queryFn: () => teacherService.studentProgress(token ?? ""),
    enabled: Boolean(token),
  });

  const students = progressQuery.data?.items ?? [];

  return (
    <div className="grid gap-6">
      <PageHeader
        badge="Laporan"
        description={`Laporan progress belajar siswa untuk kelas aktif: ${user?.active_class?.name ?? "-"}`}
        title="Laporan Progress Siswa"
      />

      {progressQuery.isLoading ? <LoadingState title="Memuat laporan progress" /> : null}
      {progressQuery.isError ? (
        <ErrorState
          description={getFirstApiError(progressQuery.error)}
          onRetry={() => void progressQuery.refetch()}
          title="Gagal memuat laporan progress"
        />
      ) : null}

      {!progressQuery.isLoading && !progressQuery.isError ? (
        students.length === 0 ? (
          <Card>
            <CardContent>
              <EmptyState
                description="Belum ada data progress dari siswa di kelas Anda."
                title="Laporan kosong"
              />
            </CardContent>
          </Card>
        ) : (
          <div className="overflow-hidden rounded-xl border-2 border-ink bg-white shadow-brutal">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b-2 border-ink bg-slate-100 uppercase text-slate-600">
                  <tr>
                    <th className="px-4 py-3 font-black text-ink">Nama Siswa</th>
                    <th className="px-4 py-3 font-black text-ink">Progress Belajar</th>
                    <th className="px-4 py-3 font-black text-ink">Modul Selesai</th>
                    <th className="px-4 py-3 font-black text-ink">Kuis Selesai</th>
                    <th className="px-4 py-3 font-black text-ink">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y border-ink font-medium">
                  {students.map((row) => (
                    <tr className="hover:bg-yellow-50" key={row.student_id}>
                      <td className="px-4 py-3">
                        <div className="font-bold text-ink">{formatOptional(row.student_name)}</div>
                        <div className="text-xs text-slate-500">{formatOptional(row.student_email)}</div>
                      </td>
                      <td className="px-4 py-3">
                        <Badge tone={row.overall_learning_progress_percent === 100 ? "blue" : "neutral"}>
                          {formatPercent(row.overall_learning_progress_percent)}
                        </Badge>
                      </td>
                      <td className="px-4 py-3">
                        {formatCount(row.completed_modules)} / {formatCount(row.published_modules)}
                      </td>
                      <td className="px-4 py-3">
                        {formatCount(row.quizzes_completed)} / {formatCount(row.published_quizzes)}
                      </td>
                      <td className="px-4 py-3">
                        <Link
                          className="font-bold text-blue-600 hover:text-blue-800 hover:underline"
                          href={teacherRoutes.studentDetail(row.student_id ?? "")}
                        >
                          Detail
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )
      ) : null}
    </div>
  );
}
