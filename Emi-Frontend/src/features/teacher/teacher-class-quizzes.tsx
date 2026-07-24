"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, BarChart3, LockKeyhole, Pencil } from "lucide-react";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { TeacherClassNav } from "./teacher-class-nav";
import { teacherService } from "./teacher-service";
import { formatCount, formatDate, formatOptional, statusLabel } from "./teacher-utils";
import type { TeacherClassQuiz } from "./types";

function isQuizLocked(quiz: TeacherClassQuiz) {
  return quiz.status !== "draft" || (quiz.attempts_count ?? 0) > 0;
}

export function TeacherClassQuizzes({ classId }: { classId: string }) {
  const { token } = useAuth();
  const quizzesQuery = useQuery({
    queryKey: ["teacher", "classes", classId, "quizzes", "page"],
    queryFn: () => teacherService.classQuizzes(token ?? "", classId),
    enabled: Boolean(token && classId),
  });

  const quizzes = quizzesQuery.data?.items ?? [];
  const publishedCount = quizzes.filter((quiz) => quiz.status === "published").length;

  return (
    <div className="grid gap-6">
      <Link className="inline-flex w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 py-2 text-sm font-black text-ink transition-colors hover:bg-surface-muted" href={teacherRoutes.classes}>
        <ArrowLeft className="size-4" />Kembali ke Daftar Kelas
      </Link>
      <PageHeader badge="Guru" description="Kelola kuis kelas, pantau attempt siswa, dan buka hasil penilaian." title="Kuis Kelas" />

      <TeacherClassNav classId={classId} />

      {quizzesQuery.isLoading ? <LoadingState title="Memuat kuis kelas" /> : null}
      {quizzesQuery.isError ? <ErrorState description={getFirstApiError(quizzesQuery.error)} onRetry={() => void quizzesQuery.refetch()} title="Gagal memuat kuis" /> : null}

      {!quizzesQuery.isLoading && !quizzesQuery.isError ? (
        quizzes.length === 0 ? (
          <Card><CardContent><EmptyState description="Belum ada kuis kelas yang bisa dikelola." title="Kuis belum tersedia" /></CardContent></Card>
        ) : (
          <div className="grid gap-4">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard helper="Semua status" label="Total kuis" value={formatCount(quizzes.length)} />
              <StatsCard helper="Status published" label="Kuis terbit" value={formatCount(publishedCount)} />
              <StatsCard helper="Percobaan siswa yang tercatat" label="Attempt" value={formatCount(quizzes.reduce((sum, quiz) => sum + (quiz.attempts_count ?? 0), 0))} />
            </section>
            <div className="grid auto-rows-fr gap-4 md:grid-cols-2">
              {quizzes.map((quiz) => {
                const locked = isQuizLocked(quiz);
                return (
                  <Card className="flex h-full flex-col transition hover:-translate-y-1 hover:shadow-emi" key={quiz.id}>
                    <CardHeader>
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <div className="flex flex-wrap gap-2"><Badge tone={quiz.status === "published" ? "blue" : "neutral"}>{statusLabel(quiz.status)}</Badge>{locked ? <Badge tone="yellow"><LockKeyhole className="mr-1 size-3" />Terkunci</Badge> : <Badge tone="blue"><Pencil className="mr-1 size-3" />Draft bisa diedit</Badge>}</div>
                          <h2 className="mt-2 text-xl font-black text-ink">{quiz.title}</h2>
                        </div>
                        <span className="rounded-lg border-2 border-border bg-surface-muted px-2 py-1 text-xs font-black text-muted">{formatCount(quiz.duration_minutes)} menit</span>
                      </div>
                    </CardHeader>
                    <CardContent className="flex flex-1 flex-col">
                      <p className="text-sm font-semibold leading-6 text-muted">{formatOptional(quiz.description)}</p>
                      <dl className="mt-4 grid gap-3 text-sm sm:grid-cols-2">
                        <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Soal</dt><dd className="mt-1 font-bold text-ink">{formatCount(quiz.questions_count)}</dd></div>
                        <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Attempt</dt><dd className="mt-1 font-bold text-ink">{formatCount(quiz.attempts_count)}</dd></div>
                        <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Buka</dt><dd className="mt-1 font-bold text-ink">{formatDate(quiz.open_at)}</dd></div>
                        <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Tutup</dt><dd className="mt-1 font-bold text-ink">{formatDate(quiz.close_at)}</dd></div>
                      </dl>
                      <div className="mt-auto flex flex-wrap gap-2 pt-4"><Link className="inline-flex min-h-11 flex-1 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition-transform hover:-translate-y-0.5" href={teacherRoutes.quizBuilder(quiz.id)}>{locked ? <LockKeyhole className="size-4" /> : <Pencil className="size-4" />}{locked ? "Lihat Detail" : "Buka Builder"}</Link><Link className="inline-flex min-h-11 flex-1 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink transition-colors hover:bg-surface-muted" href={teacherRoutes.quizResults(quiz.id)}><BarChart3 className="size-4" />Hasil</Link></div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          </div>
        )
      ) : null}
    </div>
  );
}
