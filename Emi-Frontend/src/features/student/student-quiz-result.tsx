"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Trophy } from "lucide-react";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentQuizService } from "./student-quiz-service";
import { formatCount, formatDate, formatScoreOutOf100, statusLabel } from "./student-utils";

export function StudentQuizResult({ quizId }: { quizId: string }) {
  const { token } = useAuth();
  const searchParams = useSearchParams();
  const attemptId = searchParams.get("attemptId") ?? searchParams.get("attempt_id");

  const attemptQuery = useQuery({
    queryKey: ["student", "quiz-attempts", attemptId],
    queryFn: () => studentQuizService.attemptDetail(token ?? "", attemptId ?? ""),
    enabled: Boolean(token && attemptId),
  });
  const reportQuery = useQuery({
    queryKey: ["student", "quiz-results-report", quizId],
    queryFn: () => studentQuizService.getStudentQuizResultsReport(token ?? "", { quiz_id: quizId, per_page: 1 }),
    enabled: Boolean(token && quizId && !attemptId),
  });

  const attempt = attemptQuery.data;
  const quiz = attempt?.class_quiz;
  const reportRow = reportQuery.data?.rows?.[0];

  return (
    <div className="grid gap-8">
      <Link className="inline-flex min-h-11 w-full items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink shadow-emi hover:bg-surface-muted sm:w-fit" href="/student/quizzes">
        <ArrowLeft className="size-4" strokeWidth={2.5} />
        Kembali ke Daftar Kuis
      </Link>

      {attemptId && attemptQuery.isLoading ? <LoadingState title="Memuat hasil kuis" /> : null}
      {!attemptId && reportQuery.isLoading ? <LoadingState title="Memuat laporan hasil kuis" /> : null}
      {attemptQuery.isError ? (
        <ErrorState
          description={getFirstApiError(attemptQuery.error)}
          onRetry={() => void attemptQuery.refetch()}
          title="Gagal memuat hasil"
        />
      ) : null}
      {reportQuery.isError ? (
        <ErrorState
          description={getFirstApiError(reportQuery.error)}
          onRetry={() => void reportQuery.refetch()}
          title="Gagal memuat laporan hasil"
        />
      ) : null}

      {attemptId && !attemptQuery.isLoading && !attemptQuery.isError && attempt ? (
        <>
          <header className="grid gap-6 rounded-3xl border-2 border-border bg-[var(--color-primary-muted)] p-5 shadow-emi sm:p-8 lg:grid-cols-[1.3fr_0.7fr] lg:items-center">
            <div>
              <div className="mb-4 inline-flex size-12 items-center justify-center rounded-xl border-2 border-border bg-surface text-primary">
                <Trophy className="size-6" strokeWidth={2.5} />
              </div>
              <div><Badge tone="blue">Hasil Kuis</Badge></div>
              <h1 className="mt-3 text-3xl font-black text-ink">{quiz?.title ?? "Hasil Kuis"}</h1>
              <p className="mt-2 text-sm text-muted">Dikumpulkan pada: {formatDate(attempt.submitted_at) || "Belum dikumpulkan"}</p>
            </div>
            <div className="rounded-2xl border-2 border-border bg-surface p-4 shadow-emi">
              <p className="text-xs font-black uppercase text-muted">Nilai akhir</p>
              <p className="mt-2 text-5xl font-black text-ink">{attempt.score_percent !== null ? formatScoreOutOf100(attempt.score_percent) : "-"}</p>
              <p className="mt-2 text-sm font-bold text-muted">
                {attempt.score_points !== null && attempt.max_points !== null
                  ? `${attempt.score_points} dari ${attempt.max_points} poin`
                  : attempt.correct_count !== null
                    ? `${formatCount(attempt.correct_count)} jawaban benar`
                    : "Menunggu penilaian"}
              </p>
            </div>
          </header>

          <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <StatsCard label="Nilai (Skor)" value={attempt.score_percent !== null ? formatScoreOutOf100(attempt.score_percent) : "Belum tersedia"} />
            <StatsCard label="Jawaban Benar" value={attempt.correct_count !== null ? formatCount(attempt.correct_count) : "-"} />
            <StatsCard label="Jawaban Salah" value={attempt.incorrect_count !== null ? formatCount(attempt.incorrect_count) : "-"} />
            <StatsCard label="Tidak Dijawab" value={attempt.unanswered_count !== null ? formatCount(attempt.unanswered_count) : "-"} />
          </section>

          <Card>
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Catatan Hasil</h2>
            </CardHeader>
            <CardContent>
              <div className="text-sm leading-6 text-muted">
                <p>
                  Jika nilai belum tersedia, guru mungkin mengatur agar nilai tidak langsung ditampilkan atau kuis belum selesai dinilai.
                </p>
                <p className="mt-2">
                  Untuk melihat percobaan lain atau kuis yang tersedia, silakan kembali ke halaman kuis.
                </p>
              </div>
            </CardContent>
          </Card>
        </>
      ) : null}

      {!attemptId && !reportQuery.isLoading && !reportQuery.isError && reportRow ? (
        <>
          <header className="grid gap-6 rounded-3xl border-2 border-border bg-[var(--color-primary-muted)] p-5 shadow-emi sm:p-8 lg:grid-cols-[1.3fr_0.7fr] lg:items-center">
            <div>
              <div className="mb-4 inline-flex size-12 items-center justify-center rounded-xl border-2 border-border bg-surface text-primary">
                <Trophy className="size-6" strokeWidth={2.5} />
              </div>
              <div><Badge tone="blue">Laporan Hasil</Badge></div>
              <h1 className="mt-3 text-3xl font-black text-ink">{reportRow.quiz?.title ?? "Hasil Kuis"}</h1>
              <p className="mt-2 text-sm text-muted">Aktivitas terakhir: {formatDate(reportRow.latest_submitted_at)}</p>
            </div>
            <div className="rounded-2xl border-2 border-border bg-surface p-4 shadow-emi">
              <p className="text-xs font-black uppercase text-muted">Nilai terbaik</p>
              <p className="mt-2 text-5xl font-black text-ink">{reportRow.best_score_percent !== null ? formatScoreOutOf100(reportRow.best_score_percent) : "-"}</p>
              <p className="mt-2 text-sm font-bold text-muted">{formatCount(reportRow.final_attempt_count)} percobaan selesai</p>
            </div>
          </header>

          <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <StatsCard label="Nilai Terbaik" value={reportRow.best_score_percent !== null ? formatScoreOutOf100(reportRow.best_score_percent) : "Belum tersedia"} />
            <StatsCard label="Attempt" value={formatCount(reportRow.attempt_count)} />
            <StatsCard label="Attempt Final" value={formatCount(reportRow.final_attempt_count)} />
            <StatsCard label="Status Terakhir" value={statusLabel(reportRow.latest_status)} />
          </section>

          <Card>
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Laporan Hasil Kuis</h2>
            </CardHeader>
            <CardContent>
              {reportRow.quiz?.show_result === false ? (
                <EmptyState description="Nilai kuis ini belum ditampilkan oleh guru." title="Nilai belum ditampilkan" />
              ) : reportRow.final_attempt_count ? (
                <div className="text-sm leading-6 text-muted">
                  <p>Attempt terbaik: {formatCount(reportRow.best_attempt_number)}</p>
                  <p>Dikumpulkan terakhir: {formatDate(reportRow.latest_submitted_at)}</p>
                </div>
              ) : (
                <EmptyState description="Belum ada attempt kuis yang selesai untuk ditampilkan." title="Hasil belum tersedia" />
              )}
            </CardContent>
          </Card>
        </>
      ) : null}

      {attemptId && !attemptQuery.isLoading && !attemptQuery.isError && !attempt ? (
        <EmptyState description="Data hasil kuis tidak ditemukan." title="Hasil tidak tersedia" />
      ) : null}
      {!attemptId && !reportQuery.isLoading && !reportQuery.isError && !reportRow ? (
        <EmptyState description="Laporan hasil kuis belum tersedia untuk kuis ini." title="Hasil tidak tersedia" />
      ) : null}
    </div>
  );
}
