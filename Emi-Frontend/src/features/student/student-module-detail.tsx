"use client";

import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentService } from "./student-service";
import { badgeToneForProgress, contentTypeLabel, formatCount, formatOptional, formatPercent, statusLabel } from "./student-utils";

export function StudentModuleDetail({ moduleId }: { moduleId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const moduleQuery = useQuery({
    queryKey: ["student", "modules", moduleId],
    queryFn: () => studentService.moduleDetail(token ?? "", moduleId),
    enabled: Boolean(token && moduleId),
  });
  const startMutation = useMutation({
    mutationFn: () => studentService.startModule(token ?? "", moduleId),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["student", "modules"] });
    },
  });

  const studentModule = moduleQuery.data;
  const lessons = studentModule?.lessons ?? [];

  return (
    <div className="grid gap-6">
      <Link className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100" href="/student/modules">
        Kembali ke Modul Saya
      </Link>

      {moduleQuery.isLoading ? <LoadingState title="Memuat detail modul" /> : null}
      {moduleQuery.isError ? (
        <ErrorState
          description={getFirstApiError(moduleQuery.error)}
          onRetry={() => void moduleQuery.refetch()}
          title="Gagal memuat detail modul"
        />
      ) : null}

      {studentModule ? (
        <>
          {startMutation.error ? <Alert tone="error">{getFirstApiError(startMutation.error)}</Alert> : null}
          <header className="grid gap-4 rounded-3xl border-2 border-ink bg-white p-5 shadow-brutal">
            <Badge tone={badgeToneForProgress(studentModule.progress.status)}>{statusLabel(studentModule.progress.status)}</Badge>
            <div>
              <h1 className="text-3xl font-black text-ink">{studentModule.title}</h1>
              <p className="mt-2 text-sm leading-6 text-slate-600">{formatOptional(studentModule.description)}</p>
            </div>
            <div className="flex flex-col gap-3 sm:flex-row">
              <Button disabled={startMutation.isPending || studentModule.progress.status !== "not_started"} onClick={() => startMutation.mutate()}>
                Mulai Modul
              </Button>
              <Link className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-bold text-ink shadow-brutal hover:bg-yellow-200" href={lessons[0] ? `/student/lessons/${lessons[0].id}` : "/student/modules"}>
                Buka Materi Pertama
              </Link>
            </div>
          </header>

          <section className="grid gap-4 sm:grid-cols-3">
            <StatsCard helper="Progress backend" label="Progress" value={formatPercent(studentModule.progress.progress_percent)} />
            <StatsCard helper="Materi selesai" label="Selesai" value={formatCount(studentModule.progress.completed_lessons)} />
            <StatsCard helper="Materi published" label="Total Materi" value={formatCount(studentModule.progress.total_lessons || lessons.length)} />
          </section>

          <Card>
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Daftar Materi</h2>
            </CardHeader>
            <CardContent>
              {lessons.length === 0 ? (
                <EmptyState description="Belum ada materi published pada modul ini." title="Materi belum tersedia" />
              ) : (
                <div className="grid gap-3">
                  {lessons.map((lesson, index) => (
                    <div className="grid gap-3 rounded-2xl border border-slate-200 bg-white p-4 sm:grid-cols-[1fr_auto] sm:items-center" key={lesson.id}>
                      <div>
                        <p className="text-xs font-black uppercase text-slate-500">Materi {index + 1} · {contentTypeLabel(lesson.content_type)}</p>
                        <h3 className="mt-1 text-lg font-black text-ink">{lesson.title}</h3>
                        <p className="mt-1 text-sm text-slate-600">{formatOptional(lesson.description)}</p>
                      </div>
                      <Link className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-blue-600 px-4 py-2 text-sm font-bold text-white shadow-brutal hover:bg-blue-700" href={`/student/lessons/${lesson.id}`}>
                        Buka Materi
                      </Link>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </>
      ) : null}
    </div>
  );
}
