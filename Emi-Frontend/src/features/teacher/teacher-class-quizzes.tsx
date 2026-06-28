"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

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
      <Link className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100" href={teacherRoutes.classes}>
        Kembali ke Daftar Kelas
      </Link>
      <PageHeader badge="Guru" description="Kuis kelas dan attempt dibaca dari endpoint backend teacher-accessible." title="Kuis Kelas" />

      <TeacherClassNav classId={classId} />

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
              {quizzes.map((quiz) => {
                const locked = isQuizLocked(quiz);
                return (
                  <Card key={quiz.id}>
                    <CardHeader>
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <div className="flex flex-wrap gap-2"><Badge tone={quiz.status === "published" ? "blue" : "neutral"}>{statusLabel(quiz.status)}</Badge>{locked ? <Badge tone="yellow">Terkunci</Badge> : <Badge tone="blue">Draft bisa diedit</Badge>}</div>
                          <h2 className="mt-2 text-xl font-black text-ink">{quiz.title}</h2>
                        </div>
                        <span className="rounded-lg border border-slate-200 px-2 py-1 text-xs font-black text-slate-500">{formatCount(quiz.duration_minutes)} menit</span>
                      </div>
                    </CardHeader>
                    <CardContent>
                      <p className="text-sm leading-6 text-slate-600">{formatOptional(quiz.description)}</p>
                      <dl className="mt-4 grid gap-3 text-sm sm:grid-cols-2">
                        <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Soal</dt><dd className="mt-1 font-bold text-ink">{formatCount(quiz.questions_count)}</dd></div>
                        <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Attempt</dt><dd className="mt-1 font-bold text-ink">{formatCount(quiz.attempts_count)}</dd></div>
                        <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Buka</dt><dd className="mt-1 font-bold text-ink">{formatDate(quiz.open_at)}</dd></div>
                        <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Tutup</dt><dd className="mt-1 font-bold text-ink">{formatDate(quiz.close_at)}</dd></div>
                      </dl>
                      <div className="mt-4 flex flex-wrap gap-2"><Link className={`inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink px-4 py-2 text-sm font-bold text-ink shadow-brutal ${locked ? "bg-white hover:bg-slate-50" : "bg-yellow-300 hover:bg-yellow-200"}`} href={teacherRoutes.quizBuilder(quiz.id)}>{locked ? "Lihat Detail" : "Buka Builder"}</Link><Link className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-white px-4 py-2 text-sm font-bold text-ink shadow-brutal hover:bg-slate-50" href={teacherRoutes.quizResults(quiz.id)}>Hasil</Link></div>
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
