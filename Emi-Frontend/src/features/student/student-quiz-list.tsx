"use client";

import { useState } from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, Pagination, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentQuizService } from "./student-quiz-service";
import { formatCount, formatDate, formatOptional, formatScoreOutOf100 } from "./student-utils";

export function StudentQuizList() {
  const { token } = useAuth();
  const [page, setPage] = useState(1);

  const quizzesQuery = useQuery({
    queryKey: ["student", "quizzes", page],
    queryFn: () => studentQuizService.quizzes(token ?? "", { page }),
    enabled: Boolean(token),
  });

  const quizzes = quizzesQuery.data?.items ?? [];
  const meta = quizzesQuery.data?.meta;
  const completedCount = quizzes.filter((quiz) => typeof quiz.latest_score_normalized === "number").length;
  const openCount = quizzes.filter((quiz) => quiz.can_start).length;

  return (
    <div className="grid gap-6">
      <PageHeader
        badge="Siswa"
        description="Daftar kuis dan LKPD dari kelas aktif Anda."
        title="Kuis & LKPD"
      />

      {quizzesQuery.isLoading ? <LoadingState title="Memuat kuis" /> : null}
      {quizzesQuery.isError ? (
        <ErrorState
          description={getFirstApiError(quizzesQuery.error)}
          onRetry={() => void quizzesQuery.refetch()}
          title="Gagal memuat kuis"
        />
      ) : null}

      {!quizzesQuery.isLoading && !quizzesQuery.isError ? (
        quizzes.length === 0 ? (
          <Card>
            <CardContent>
              <EmptyState
                description="Belum ada kuis atau evaluasi yang diberikan untuk kelas Anda saat ini."
                title="Kuis belum tersedia"
              />
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-4">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard helper="Total evaluasi yang tersedia" label="Total Kuis" value={formatCount(quizzes.length)} />
              <StatsCard helper="Sudah punya nilai terakhir" label="Sudah Dikerjakan" value={formatCount(completedCount)} />
              <StatsCard helper="Masih bisa dibuka" label="Bisa Dikerjakan" value={formatCount(openCount)} />
            </section>
            <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
              {quizzes.map((quiz) => {
                const usedAttempts = quiz.used_attempts ?? quiz.attempts_count ?? 0;
                const hasSubmittedScore = typeof quiz.latest_result?.score_percent === "number" || typeof quiz.latest_score_normalized === "number";
                const latestScore = quiz.latest_result?.score_percent ?? quiz.latest_score_normalized;

                return (
                <Card className="overflow-hidden" key={quiz.id}>
                  <CardHeader>
                    <div className="grid gap-3">
                      {quiz.open_at || quiz.close_at ? (
                        <div className="flex flex-wrap gap-2 text-xs font-bold text-slate-500">
                          {quiz.open_at ? <span>Buka: {formatDate(quiz.open_at)}</span> : null}
                          {quiz.close_at ? <span>Tutup: {formatDate(quiz.close_at)}</span> : null}
                        </div>
                      ) : (
                        <span className="text-xs font-bold text-slate-500">Jadwal terbuka</span>
                      )}
                      <h2 className="text-xl font-black text-ink">{quiz.title}</h2>
                      <p className="text-sm leading-6 text-slate-600 line-clamp-2">{formatOptional(quiz.description)}</p>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="grid gap-4">
                      <div className="flex flex-wrap gap-2">
                        <Badge tone="neutral">{formatCount(quiz.questions_count)} soal</Badge>
                        <Badge tone="yellow">{quiz.duration_minutes ? `${quiz.duration_minutes} menit` : "Tanpa batas waktu"}</Badge>
                        <Badge tone="blue">Percobaan: {quiz.max_attempts ? `${usedAttempts}/${quiz.max_attempts}` : formatCount(usedAttempts)}</Badge>
                        {quiz.attempt_limit_reached ? <Badge tone="orange">Batas percobaan tercapai</Badge> : null}
                      </div>
                      <div className="rounded-2xl border-2 border-ink bg-[var(--color-primary-muted)] p-3">
                        <p className="text-xs font-black uppercase text-slate-500">Status pengerjaan</p>
                        <p className="mt-1 text-2xl font-black text-ink">
                          {hasSubmittedScore ? `Nilai: ${formatScoreOutOf100(latestScore)}` : "Belum dikerjakan"}
                        </p>
                        <p className="mt-1 text-sm font-bold text-slate-600">
                          {quiz.has_active_attempt ? "Ada pengerjaan aktif." : quiz.can_start ? "Masih bisa dibuka dari halaman detail." : "Kuis tidak dapat dimulai."}
                        </p>
                      </div>
                      <Link className="inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-ink bg-blue-600 px-4 py-2 text-sm font-black text-white shadow-brutal hover:bg-blue-700" href={`/student/quizzes/${quiz.id}`}>
                        {hasSubmittedScore ? "Lihat Detail & Hasil" : "Mulai dari Detail Kuis"}
                      </Link>
                    </div>
                  </CardContent>
                </Card>
                );
              })}
            </div>
            <Pagination onPageChange={setPage} page={meta?.current_page ?? page} totalPages={meta?.last_page ?? 1} />
          </div>
        )
      ) : null}
    </div>
  );
}
