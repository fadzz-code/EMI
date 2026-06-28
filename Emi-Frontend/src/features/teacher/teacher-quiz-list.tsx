"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { formatCount, formatDate, formatOptional, statusLabel } from "./teacher-utils";

export function TeacherQuizList() {
  const { token, user } = useAuth();
  const quizzesQuery = useQuery({
    queryKey: ["teacher", "quizzes"],
    queryFn: () => teacherService.quizzes(token ?? ""),
    enabled: Boolean(token),
  });

  const quizzes = quizzesQuery.data?.items ?? [];
  const publishedCount = quizzes.filter((quiz) => quiz.status === "published").length;

  return (
    <div className="grid gap-6">
      <PageHeader badge="Guru" description="Kelola kuis dari class_quizzes backend untuk kelas yang ditugaskan kepada Anda." title="Kuis" />

      {quizzesQuery.isLoading ? <LoadingState title="Memuat kuis" /> : null}
      {quizzesQuery.isError ? <ErrorState description={getFirstApiError(quizzesQuery.error)} onRetry={() => void quizzesQuery.refetch()} title="Gagal memuat kuis" /> : null}

      {!quizzesQuery.isLoading && !quizzesQuery.isError ? (
        quizzes.length === 0 ? (
          <Card><CardContent><EmptyState description="Belum ada kuis kelas dari backend." title="Kuis belum tersedia" /></CardContent></Card>
        ) : (
          <div className="grid gap-4">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard helper={user?.active_class?.name ?? "Kelas aktif"} label="Total kuis" value={formatCount(quizzes.length)} />
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
                        <p className="mt-1 text-sm font-bold text-slate-500">{quiz.class?.name ?? user?.active_class?.name ?? "Kelas aktif"}</p>
                      </div>
                      <Link className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-bold text-ink shadow-brutal hover:bg-yellow-200" href={teacherRoutes.quizBuilder(quiz.id)}>
                        Builder
                      </Link>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm leading-6 text-slate-600 line-clamp-2">{formatOptional(quiz.description)}</p>
                    <dl className="mt-4 grid gap-3 text-sm sm:grid-cols-2">
                      <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Durasi</dt><dd className="mt-1 font-bold text-ink">{formatCount(quiz.duration_minutes)} menit</dd></div>
                      <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Soal</dt><dd className="mt-1 font-bold text-ink">{formatCount(quiz.questions_count)}</dd></div>
                      <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Attempt</dt><dd className="mt-1 font-bold text-ink">{formatCount(quiz.attempts_count)}</dd></div>
                      <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Buka</dt><dd className="mt-1 font-bold text-ink">{formatDate(quiz.open_at)}</dd></div>
                    </dl>
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
