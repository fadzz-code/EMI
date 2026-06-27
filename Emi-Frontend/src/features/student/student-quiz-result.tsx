"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";

import { Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentQuizService } from "./student-quiz-service";
import { formatCount, formatDate, formatPercent } from "./student-utils";

export function StudentQuizResult() {
  const { token } = useAuth();
  const searchParams = useSearchParams();
  const attemptId = searchParams.get("attemptId");

  const attemptQuery = useQuery({
    queryKey: ["student", "quiz-attempts", attemptId],
    queryFn: () => studentQuizService.attemptDetail(token ?? "", attemptId ?? ""),
    enabled: Boolean(token && attemptId),
  });

  if (!attemptId) {
    return <ErrorState description="ID Attempt tidak ditemukan di URL." title="Data tidak lengkap" />;
  }

  const attempt = attemptQuery.data;
  const quiz = attempt?.class_quiz;

  return (
    <div className="grid gap-6">
      <Link className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100" href="/student/quizzes">
        Kembali ke Daftar Kuis
      </Link>

      {attemptQuery.isLoading ? <LoadingState title="Memuat hasil kuis" /> : null}
      {attemptQuery.isError ? (
        <ErrorState
          description={getFirstApiError(attemptQuery.error)}
          onRetry={() => void attemptQuery.refetch()}
          title="Gagal memuat hasil"
        />
      ) : null}

      {!attemptQuery.isLoading && !attemptQuery.isError && attempt ? (
        <>
          <header className="grid gap-4 rounded-3xl border-2 border-ink bg-white p-5 shadow-brutal">
            <div>
              <h1 className="text-3xl font-black text-ink">{quiz?.title ?? "Hasil Kuis"}</h1>
              <p className="mt-2 text-sm text-slate-600">Dikumpulkan pada: {formatDate(attempt.submitted_at) || "Belum dikumpulkan"}</p>
            </div>
          </header>

          <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <StatsCard label="Nilai (Skor)" value={attempt.score_percent !== null ? formatPercent(attempt.score_percent) : "Belum tersedia"} />
            <StatsCard label="Jawaban Benar" value={attempt.correct_count !== null ? formatCount(attempt.correct_count) : "-"} />
            <StatsCard label="Jawaban Salah" value={attempt.incorrect_count !== null ? formatCount(attempt.incorrect_count) : "-"} />
            <StatsCard label="Tidak Dijawab" value={attempt.unanswered_count !== null ? formatCount(attempt.unanswered_count) : "-"} />
          </section>

          <Card>
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Catatan Hasil</h2>
            </CardHeader>
            <CardContent>
              <div className="text-sm leading-6 text-slate-700">
                <p>
                  Jika nilai belum tersedia, guru mungkin mengatur agar nilai tidak langsung ditampilkan (pengaturan show_result) atau kuis belum selesai dinilai.
                </p>
                <p className="mt-2">
                  Untuk melihat percobaan lain atau kuis yang tersedia, silakan kembali ke halaman kuis.
                </p>
              </div>
            </CardContent>
          </Card>
        </>
      ) : !attemptQuery.isLoading && !attemptQuery.isError ? (
        <EmptyState description="Data hasil kuis tidak ditemukan." title="Hasil tidak tersedia" />
      ) : null}
    </div>
  );
}
