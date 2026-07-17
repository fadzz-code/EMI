"use client";

import { useState } from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ClipboardList } from "lucide-react";

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
  const openCount = quizzes.filter((quiz) => !quiz.attempt_limit_reached).length;

  return (
    <div className="grid gap-8">
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
          <div className="grid gap-8">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard helper="Total evaluasi yang tersedia" label="Total Kuis" value={formatCount(quizzes.length)} />
              <StatsCard helper="Sudah punya nilai terakhir" label="Sudah Dikerjakan" value={formatCount(completedCount)} />
              <StatsCard helper="Masih bisa dibuka" label="Bisa Dikerjakan" value={formatCount(openCount)} />
            </section>
            <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
              {quizzes.map((quiz) => {
                const usedAttempts = quiz.used_attempts ?? quiz.attempts_count ?? 0;
                const hasSubmittedScore = typeof quiz.latest_score_normalized === "number";

                return (
                <Card className="flex h-full flex-col overflow-hidden border-2 border-border bg-surface shadow-emi" key={quiz.id}>
                  <CardHeader>
                    <div className="grid gap-3">
                      <div className="inline-flex size-12 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-primary">
                        <ClipboardList className="size-6" strokeWidth={2.5} />
                      </div>
                      {quiz.open_at || quiz.close_at ? (
                        <div className="flex flex-wrap gap-2 text-xs font-bold text-muted">
                          {quiz.open_at ? <span>Buka: {formatDate(quiz.open_at)}</span> : null}
                          {quiz.close_at ? <span>Tutup: {formatDate(quiz.close_at)}</span> : null}
                        </div>
                      ) : (
                        <span className="text-xs font-bold text-muted">Jadwal terbuka</span>
                      )}
                      <h2 className="text-xl font-black text-ink">{quiz.title}</h2>
                      <p className="line-clamp-2 text-sm font-semibold leading-6 text-muted">{formatOptional(quiz.description)}</p>
                    </div>
                  </CardHeader>
                  <CardContent className="flex flex-1 flex-col">
                    <div className="flex flex-1 flex-col gap-4">
                      <div className="flex flex-wrap gap-2">
                        <Badge tone="neutral">{formatCount(quiz.questions_count)} soal</Badge>
                        <Badge tone="yellow">{quiz.duration_minutes ? `${quiz.duration_minutes} menit` : "Tanpa batas waktu"}</Badge>
                        <Badge tone="blue">Percobaan: {quiz.max_attempts ? `${usedAttempts}/${quiz.max_attempts}` : formatCount(usedAttempts)}</Badge>
                        {quiz.attempt_limit_reached ? <Badge tone="orange">Batas percobaan tercapai</Badge> : null}
                      </div>
                      <div className="rounded-2xl border-2 border-border bg-surface-muted p-3">
                        <p className="text-xs font-black uppercase text-muted">Status pengerjaan</p>
                        <p className="mt-1 text-2xl font-black text-ink">
                          {hasSubmittedScore ? `Nilai: ${formatScoreOutOf100(quiz.latest_score_normalized)}` : "Belum dikerjakan"}
                        </p>
                        <p className="mt-1 text-sm font-bold text-muted">
                          {quiz.attempt_limit_reached ? "Percobaan sudah habis." : "Masih bisa dibuka dari halaman detail."}
                        </p>
                      </div>
                      <Link className="mt-auto inline-flex min-h-12 items-center justify-center rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-center text-sm font-black text-primary-foreground shadow-emi transition-transform hover:-translate-y-0.5" href={`/student/quizzes/${quiz.id}`}>
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
