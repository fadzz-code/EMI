"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, BarChart3, Pencil } from "lucide-react";

import { Alert, Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { formatCount, formatDate, formatOptional, statusLabel } from "./teacher-utils";

export function TeacherQuizPreview({ classQuizId }: { classQuizId: string }) {
  const { token } = useAuth();

  const quizQuery = useQuery({
    queryKey: ["teacher", "class-quizzes", classQuizId],
    queryFn: () => teacherService.quizDetail(token ?? "", classQuizId),
    enabled: Boolean(token && classQuizId),
  });

  const quiz = quizQuery.data;
  const questions = quiz?.questions ?? [];

  return (
    <div className="grid gap-8">
      <div className="flex flex-wrap gap-3">
        <Link className="inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-primary transition hover:-translate-y-0.5 hover:bg-[var(--color-primary-muted)] hover:shadow-emi" href={teacherRoutes.quizzes}>
          <ArrowLeft className="size-5" strokeWidth={2.5} /> Kembali ke Daftar Kuis
        </Link>
        <Link className="inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5" href={teacherRoutes.quizBuilder(classQuizId)}>
          <Pencil className="size-4" strokeWidth={2.5} /> Edit di Builder
        </Link>
      </div>
      <PageHeader badge="Guru" description="Lihat kuis persis seperti tampilan yang akan dilihat siswa." title="Lihat Kuis (Preview)" />

      {quizQuery.isLoading ? <LoadingState title="Memuat kuis" /> : null}
      {quizQuery.isError ? (
        <ErrorState description={getFirstApiError(quizQuery.error)} onRetry={() => void quizQuery.refetch()} title="Gagal memuat kuis" />
      ) : null}

      {quiz ? (
        <>
          <header className="grid gap-6 rounded-3xl border-2 border-border bg-[var(--color-primary-muted)] p-6 shadow-emi sm:p-8 lg:grid-cols-[1.2fr_auto] lg:items-center">
            <div className="grid gap-5">
              <div className="flex flex-wrap gap-2">
                <Badge tone={quiz.status === "published" ? "blue" : "neutral"}>{statusLabel(quiz.status)}</Badge>
                <Badge tone="yellow">{formatCount(quiz.questions_count)} soal</Badge>
              </div>
              <div>
                <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">{quiz.title}</h1>
                <p className="mt-3 max-w-2xl text-sm font-semibold leading-6 text-muted">{formatOptional(quiz.description)}</p>
              </div>
            </div>
            <div className="flex flex-col gap-3 sm:flex-row lg:flex-col">
              <Link className="inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink shadow-emi transition hover:-translate-y-0.5 hover:bg-surface-muted" href={teacherRoutes.quizResults(classQuizId)}>
                <BarChart3 className="size-4" strokeWidth={2.5} /> Lihat Hasil
              </Link>
            </div>
          </header>

          <Card>
            <CardHeader><h2 className="text-xl font-black text-ink">Detail Kuis</h2></CardHeader>
            <CardContent>
              <dl className="grid gap-3 text-sm sm:grid-cols-2 lg:grid-cols-4">
                <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Durasi</dt><dd className="mt-1 font-bold text-ink">{formatCount(quiz.duration_minutes)} menit</dd></div>
                <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Maks Attempt</dt><dd className="mt-1 font-bold text-ink">{formatCount(quiz.max_attempts)}</dd></div>
                <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Buka</dt><dd className="mt-1 font-bold text-ink">{formatDate(quiz.open_at)}</dd></div>
                <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Tutup</dt><dd className="mt-1 font-bold text-ink">{formatDate(quiz.close_at)}</dd></div>
              </dl>
              {quiz.instructions ? (
                <div className="prose prose-slate mt-4 max-w-none whitespace-pre-wrap rounded-2xl border-2 border-border bg-surface-muted p-4 text-sm font-semibold leading-6 text-ink">
                  {quiz.instructions}
                </div>
              ) : null}
            </CardContent>
          </Card>

          <Card>
            <CardHeader><h2 className="text-xl font-black text-ink">Soal ({formatCount(questions.length)})</h2></CardHeader>
            <CardContent>
              {questions.length === 0 ? (
                <EmptyState description="Kuis ini belum memiliki soal." title="Soal kosong" />
              ) : (
                <div className="grid gap-4">
                  {questions.map((question) => (
                    <div className="rounded-xl border-2 border-border bg-surface-muted p-4" key={question.id}>
                      <div className="flex items-start justify-between gap-3">
                        <p className="font-black text-ink">{question.order_number}. {question.question_text}</p>
                        <Badge>{question.points ?? 0} poin</Badge>
                      </div>
                      {question.image_media?.url ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img alt="Gambar soal" className="mt-3 max-h-48 w-fit rounded-lg border-2 border-border bg-surface object-contain" src={question.image_media.url} />
                      ) : null}
                      {question.options?.length ? (
                        <ol className="mt-3 grid gap-1 text-sm font-semibold text-ink">
                          {question.options.map((option) => (
                            <li key={`${question.id}-${option.order_number}`}>
                              {option.order_number}. {option.option_text}{option.is_correct ? <span className="ml-2 text-xs font-black uppercase text-primary">(Jawaban benar)</span> : null}
                            </li>
                          ))}
                        </ol>
                      ) : question.correct_answer_text ? (
                        <p className="mt-3 text-sm font-semibold text-ink">Jawaban benar: <span className="font-black text-primary">{question.correct_answer_text}</span></p>
                      ) : null}
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </>
      ) : null}

      {!quizQuery.isLoading && !quizQuery.isError && !quiz ? <Alert tone="warning">Kuis tidak ditemukan.</Alert> : null}
    </div>
  );
}
