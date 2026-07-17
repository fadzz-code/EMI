"use client";

import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, BookOpen, Play } from "lucide-react";

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
    <div className="grid gap-8">
      <Link className="inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink transition hover:-translate-y-0.5 hover:bg-surface-muted" href="/student/modules">
        <ArrowLeft className="size-4 text-primary" strokeWidth={2.5} />
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
          <header className="grid gap-6 rounded-3xl border-2 border-border bg-[var(--color-primary-muted)] p-6 shadow-emi sm:p-8 lg:grid-cols-[1.3fr_0.7fr] lg:items-center">
            <div className="grid gap-5">
              <Badge tone={badgeToneForProgress(studentModule.progress.status)}>{statusLabel(studentModule.progress.status)}</Badge>
              <div>
                <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">{studentModule.title}</h1>
                <p className="mt-3 max-w-2xl text-sm font-semibold leading-6 text-muted">{formatOptional(studentModule.description)}</p>
              </div>
              <div className="flex flex-col gap-3 sm:flex-row">
                <Button disabled={startMutation.isPending || studentModule.progress.status !== "not_started"} onClick={() => startMutation.mutate()}>
                  <Play className="size-4" fill="currentColor" strokeWidth={2.5} />
                  Mulai Modul
                </Button>
                <Link className="inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink shadow-emi transition hover:-translate-y-0.5 hover:bg-surface-muted" href={lessons[0] ? `/student/lessons/${lessons[0].id}` : "/student/modules"}>
                  <BookOpen className="size-5 text-primary" strokeWidth={2.5} />
                  Buka Materi Pertama
                </Link>
              </div>
            </div>
            <div className="rounded-2xl border-2 border-border bg-surface p-5 shadow-[4px_4px_0px_0px_var(--border)]">
              <p className="text-xs font-black uppercase tracking-wider text-muted">Progress modul</p>
              <p className="mt-2 text-4xl font-black text-ink">{formatPercent(studentModule.progress.progress_percent)}</p>
              <div className="mt-4 h-3 overflow-hidden rounded-full bg-border/20">
                <div className="h-full rounded-full bg-primary" style={{ width: `${Math.min(Math.max(studentModule.progress.progress_percent ?? 0, 0), 100)}%` }} />
              </div>
              <p className="mt-3 text-sm font-bold text-muted">
                {formatCount(studentModule.progress.completed_lessons)} dari {formatCount(studentModule.progress.total_lessons || lessons.length)} materi selesai.
              </p>
            </div>
          </header>

          <section className="grid gap-4 sm:grid-cols-3">
            <StatsCard helper="Persentase materi yang sudah selesai" label="Progress" value={formatPercent(studentModule.progress.progress_percent)} />
            <StatsCard helper="Materi selesai" label="Selesai" value={formatCount(studentModule.progress.completed_lessons)} />
            <StatsCard helper="Materi yang bisa dipelajari" label="Total Materi" value={formatCount(studentModule.progress.total_lessons || lessons.length)} />
          </section>

          <Card className="bg-surface">
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Daftar Materi</h2>
            </CardHeader>
            <CardContent>
              {lessons.length === 0 ? (
                <EmptyState description="Belum ada materi published pada modul ini." title="Materi belum tersedia" />
              ) : (
                <div className="grid gap-3">
                  {lessons.map((lesson, index) => (
                    <div className="grid gap-4 rounded-2xl border-2 border-border bg-surface-muted p-4 sm:grid-cols-[auto_1fr_auto] sm:items-center" key={lesson.id}>
                      <div className="flex size-11 items-center justify-center rounded-xl border-2 border-border bg-surface text-primary">
                        <BookOpen className="size-5" strokeWidth={2.5} />
                      </div>
                      <div>
                        <p className="text-xs font-black uppercase tracking-wider text-muted">Materi {index + 1} · {contentTypeLabel(lesson.content_type)}</p>
                        <h3 className="mt-1 text-lg font-black text-ink">{lesson.title}</h3>
                        <p className="mt-1 text-sm font-semibold leading-6 text-muted">{formatOptional(lesson.description)}</p>
                      </div>
                      <Link className="inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5" href={`/student/lessons/${lesson.id}`}>
                        Buka Materi
                        <BookOpen className="size-4" strokeWidth={2.5} />
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
