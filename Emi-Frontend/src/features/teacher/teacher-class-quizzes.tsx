"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { teacherService } from "./teacher-service";
import { formatCount, formatDate, formatOptional, formatPercent, statusLabel } from "./teacher-utils";

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
      <Link className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100" href={`/teacher/classes/${classId}`}>
        Kembali ke Detail Kelas
      </Link>
      <PageHeader badge="Guru" description="Kuis kelas dan attempt dibaca dari endpoint backend teacher-accessible." title="Kuis Kelas" />

      {quizzesQuery.isLoading ? <LoadingState title="Memuat kuis kelas" /> : null}
      {quizzesQuery.isError ? <ErrorState description={getFirstApiError(quizzesQuery.error)} onRetry={() => void quizzesQuery.refetch()} title="Gagal memuat kuis" /> : null}

      {!quizzesQuery.isLoading && !quizzesQuery.isError ? (
        quizzes.length === 0 ? (
          <Card><CardContent><EmptyState description="Belum ada kuis kelas dari backend." title="Kuis belum tersedia" /></CardContent></Card>
        ) : (
          <div className="grid gap-4">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard helper="Semua status" label="Total kuis" value={formatCount(quizzes.length)} />
              <StatsCard helper="Status published" label="Kuis terbit" value={formatCount(publishedCount)} />
              <StatsCard helper="Dari withCount attempts" label="Attempt" value={formatCount(quizzes.reduce((sum, quiz) => sum + (quiz.attempts_count ?? 0), 0))} />
            </section>
            <div className="grid gap-4 md:grid-cols-2">
              {quizzes.map((quiz) => (
                <Card key={quiz.id}>
                  <CardHeader>
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <Badge tone={quiz.status === "published" ? "blue" : "neutral"}>{statusLabel(quiz.status)}</Badge>
                        <h2 className="mt-2 text-xl font-black text-ink">{quiz.title}</h2>
                      </div>
                      <span className="rounded-lg border border-slate-200 px-2 py-1 text-xs font-black text-slate-500">{formatCount(quiz.duration_minutes)} menit</span>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm leading-6 text-slate-600">{formatOptional(quiz.description)}</p>
                    <dl className="mt-4 grid gap-3 text-sm sm:grid-cols-2">
                      <div className="rounded-xl bg-slate-50 p-3">
                        <dt className="font-black uppercase text-slate-500">Soal</dt>
                        <dd className="mt-1 font-bold text-ink">{formatCount(quiz.questions_count)}</dd>
                      </div>
                      <div className="rounded-xl bg-slate-50 p-3">
                        <dt className="font-black uppercase text-slate-500">Attempt</dt>
                        <dd className="mt-1 font-bold text-ink">{formatCount(quiz.attempts_count)}</dd>
                      </div>
                      <div className="rounded-xl bg-slate-50 p-3">
                        <dt className="font-black uppercase text-slate-500">Buka</dt>
                        <dd className="mt-1 font-bold text-ink">{formatDate(quiz.open_at)}</dd>
                      </div>
                      <div className="rounded-xl bg-slate-50 p-3">
                        <dt className="font-black uppercase text-slate-500">Tutup</dt>
                        <dd className="mt-1 font-bold text-ink">{formatDate(quiz.close_at)}</dd>
                      </div>
                    </dl>
                    <QuizDetails token={token ?? ""} quizId={quiz.id} />
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

function QuizDetails({ token, quizId }: { token: string; quizId: string }) {
  const detailQuery = useQuery({
    queryKey: ["teacher", "class-quizzes", quizId],
    queryFn: () => teacherService.quizDetail(token, quizId),
    enabled: Boolean(token && quizId),
  });
  const attemptsQuery = useQuery({
    queryKey: ["teacher", "class-quizzes", quizId, "attempts"],
    queryFn: () => teacherService.quizAttempts(token, quizId),
    enabled: Boolean(token && quizId),
  });
  const questions = detailQuery.data?.questions ?? [];
  const attempts = attemptsQuery.data?.items ?? [];

  return (
    <div className="mt-4 grid gap-4">
      <div>
        <h3 className="font-black text-ink">Soal</h3>
        {detailQuery.isLoading ? <p className="text-sm font-bold text-slate-500">Memuat soal...</p> : null}
        {detailQuery.isError ? <p className="text-sm font-bold text-orange-600">Soal tidak dapat dimuat: {getFirstApiError(detailQuery.error)}</p> : null}
        {!detailQuery.isLoading && !detailQuery.isError ? (
          questions.length === 0 ? <p className="text-sm font-bold text-slate-500">Soal belum tersedia.</p> : (
            <ol className="mt-2 grid gap-2">
              {questions.map((question) => <li className="rounded-xl border border-slate-200 bg-white p-3 text-sm" key={question.id}>{question.order_number}. {question.question_text}</li>)}
            </ol>
          )
        ) : null}
      </div>
      <div>
        <h3 className="font-black text-ink">Attempt Siswa</h3>
        {attemptsQuery.isLoading ? <p className="text-sm font-bold text-slate-500">Memuat attempt...</p> : null}
        {attemptsQuery.isError ? <p className="text-sm font-bold text-orange-600">Attempt tidak dapat dimuat: {getFirstApiError(attemptsQuery.error)}</p> : null}
        {!attemptsQuery.isLoading && !attemptsQuery.isError ? (
          attempts.length === 0 ? <p className="text-sm font-bold text-slate-500">Belum ada attempt/result siswa dari backend.</p> : (
            <div className="mt-2 grid gap-2">
              {attempts.map((attempt) => (
                <div className="rounded-xl border border-slate-200 bg-white p-3" key={attempt.id}>
                  <p className="font-black text-ink">{formatOptional(attempt.student?.full_name)}</p>
                  <p className="text-sm text-slate-600">Status: {statusLabel(attempt.status)} | Skor: {formatPercent(attempt.score_percent)}</p>
                </div>
              ))}
            </div>
          )
        ) : null}
      </div>
    </div>
  );
}
