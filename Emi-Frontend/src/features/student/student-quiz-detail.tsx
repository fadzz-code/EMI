"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, Pagination, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentQuizService } from "./student-quiz-service";
import { formatCount, formatDate, formatOptional, formatScoreOutOf100, statusLabel } from "./student-utils";

export function StudentQuizDetail({ quizId }: { quizId: string }) {
  const { token } = useAuth();
  const router = useRouter();
  const [historyPage, setHistoryPage] = useState(1);

  const quizQuery = useQuery({
    queryKey: ["student", "quizzes", quizId],
    queryFn: () => studentQuizService.detail(token ?? "", quizId),
    enabled: Boolean(token && quizId),
  });

  const historyQuery = useQuery({
    queryKey: ["student", "quizzes", quizId, "attempts", historyPage],
    queryFn: () => studentQuizService.attempts(token ?? "", quizId, { page: historyPage }),
    enabled: Boolean(token && quizId),
  });

  const startMutation = useMutation({
    mutationFn: () => studentQuizService.startAttempt(token ?? "", quizId),
    onSuccess: (attempt) => {
      if (attempt.status === "in_progress") {
        router.push(`/student/quizzes/${quizId}/attempt?attemptId=${attempt.id}`);
        return;
      }

      router.push(`/student/quizzes/${quizId}/result?attemptId=${attempt.id}`);
    },
  });

  const quiz = quizQuery.data;
  const usedAttempts = quiz?.used_attempts ?? quiz?.attempts_count ?? 0;
  const latestScore = quiz?.latest_result?.score_percent ?? quiz?.latest_score_normalized;
  const hasSubmittedScore = typeof latestScore === "number";

  return (
    <div className="grid gap-6">
      <Link className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100" href="/student/quizzes">
        Kembali ke Daftar Kuis
      </Link>

      {quizQuery.isLoading ? <LoadingState title="Memuat detail kuis" /> : null}
      {quizQuery.isError ? (
        <ErrorState
          description={getFirstApiError(quizQuery.error)}
          onRetry={() => void quizQuery.refetch()}
          title="Gagal memuat detail kuis"
        />
      ) : null}

      {quiz ? (
        <>
          {startMutation.error ? <Alert tone="error">{getFirstApiError(startMutation.error)}</Alert> : null}
          {quiz.attempt_limit_reached ? <Alert tone="warning">Batas percobaan tercapai.</Alert> : null}

          <header className="grid gap-5 rounded-3xl border-2 border-ink bg-[var(--color-primary-muted)] p-5 shadow-brutal lg:grid-cols-[1.3fr_0.7fr] lg:items-center">
            <div className="grid gap-4">
              <div className="flex flex-wrap gap-2 text-sm font-bold text-slate-500">
                {quiz.open_at ? <Badge tone="neutral">Buka: {formatDate(quiz.open_at)}</Badge> : null}
                {quiz.close_at ? <Badge tone="neutral">Tutup: {formatDate(quiz.close_at)}</Badge> : null}
                <Badge tone={quiz.attempt_limit_reached ? "orange" : "blue"}>{quiz.attempt_limit_reached ? "Percobaan habis" : "Siap dikerjakan"}</Badge>
              </div>
              <div>
                <h1 className="text-3xl font-black text-ink">{quiz.title}</h1>
                <p className="mt-2 text-sm leading-6 text-slate-700 whitespace-pre-wrap">{formatOptional(quiz.description)}</p>
              </div>
              <div className="flex flex-col gap-3 sm:flex-row">
                <Button disabled={startMutation.isPending || !quiz.can_start} onClick={() => startMutation.mutate()}>
                  {quiz.has_active_attempt ? "Lanjutkan Kuis" : quiz.can_start ? "Mulai Kerjakan" : "Kuis Tidak Dapat Dimulai"}
                </Button>
              </div>
            </div>
            <div className="rounded-2xl border-2 border-ink bg-white p-4 shadow-brutal">
              <p className="text-xs font-black uppercase text-slate-500">Ringkasan kuis</p>
              <p className="mt-2 text-4xl font-black text-ink">{formatCount(quiz.questions_count)}</p>
              <p className="text-sm font-bold text-slate-600">soal tersedia</p>
              <div className="mt-4 grid gap-2 text-sm font-bold text-slate-700">
                <span>Durasi: {quiz.duration_minutes ? `${quiz.duration_minutes} menit` : "Tidak dibatasi"}</span>
                <span>Percobaan: {quiz.max_attempts ? `${usedAttempts} / ${quiz.max_attempts}` : formatCount(usedAttempts)}</span>
              </div>
            </div>
          </header>

          <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatsCard helper="Total soal yang harus dijawab" label="Jumlah Soal" value={formatCount(quiz.questions_count)} />
            <StatsCard helper="Batas waktu pengerjaan" label="Durasi" value={quiz.duration_minutes ? `${quiz.duration_minutes} menit` : "Tidak dibatasi"} />
            <StatsCard helper="Percobaan terpakai" label="Percobaan" value={quiz.max_attempts ? `${usedAttempts} / ${quiz.max_attempts}` : formatCount(usedAttempts)} />
            <StatsCard helper={hasSubmittedScore ? `Terakhir dikumpulkan: ${formatDate(quiz.latest_submitted_at)}` : "Belum ada percobaan yang selesai"} label="Nilai Terakhir" value={hasSubmittedScore ? formatScoreOutOf100(latestScore) : "Belum dikerjakan"} />
          </section>

          <section className="grid gap-4 sm:grid-cols-3">
            <StatsCard label="Selesai" value={formatCount(quiz.finished_attempts_count)} />
            <StatsCard label="Nilai Terbaik" value={typeof quiz.best_result?.score_percent === "number" ? formatScoreOutOf100(quiz.best_result.score_percent) : "Belum tersedia"} />
            <StatsCard label="Nilai Terakhir" value={hasSubmittedScore ? formatScoreOutOf100(latestScore) : "Belum tersedia"} />
          </section>

          <Card>
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Riwayat Percobaan</h2>
            </CardHeader>
            <CardContent>
              <div className="grid gap-3">
                {(historyQuery.data?.items ?? []).map((attempt) => (
                  <Link className="rounded-xl border-2 border-ink p-3 font-bold" href={`/student/quizzes/${quiz.id}/result?attemptId=${attempt.id}`} key={attempt.id}>
                    Percobaan {attempt.attempt_number} · {statusLabel(attempt.status)} · {typeof attempt.score_percent === "number" ? formatScoreOutOf100(attempt.score_percent) : "Nilai disembunyikan"}
                  </Link>
                ))}
                {!historyQuery.isLoading && !historyQuery.data?.items.length ? <p>Belum ada riwayat percobaan.</p> : null}
                <Pagination onPageChange={setHistoryPage} page={historyQuery.data?.meta?.current_page ?? historyPage} totalPages={historyQuery.data?.meta?.last_page ?? 1} />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Instruksi Pengerjaan</h2>
            </CardHeader>
            <CardContent>
              <div className="prose prose-slate max-w-none text-sm leading-6 text-slate-700 whitespace-pre-wrap">
                {quiz.instructions || "Tidak ada instruksi khusus."}
              </div>
            </CardContent>
          </Card>
        </>
      ) : !quizQuery.isLoading && !quizQuery.isError ? (
        <EmptyState description="Data kuis tidak ditemukan." title="Kuis tidak tersedia" />
      ) : null}
    </div>
  );
}
