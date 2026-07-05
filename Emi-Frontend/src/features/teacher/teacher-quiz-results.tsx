"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, Input, LoadingState, PageHeader, Select, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import type { TeacherQuizAnswer, TeacherQuizAttempt, TeacherQuizQuestion } from "./types";
import { formatCount, formatDate, formatOptional, formatPercent, statusLabel } from "./teacher-utils";

function studentName(attempt: TeacherQuizAttempt) {
  return attempt.student?.full_name ?? attempt.student?.name ?? attempt.student?.email ?? attempt.student_id ?? "Siswa";
}

function selectedOptionLabel(question: TeacherQuizQuestion | undefined, optionId: string | null | undefined) {
  if (!optionId) {
    return "-";
  }
  const option = question?.options?.find((item) => item.id === optionId);
  return option ? `${option.order_number}. ${option.option_text}` : optionId;
}

function answerLabel(answer: TeacherQuizAnswer, question: TeacherQuizQuestion | undefined) {
  if (answer.answer_text) {
    return answer.answer_text;
  }
  return selectedOptionLabel(question, answer.selected_option_id);
}

export function TeacherQuizResults({ classQuizId }: { classQuizId: string }) {
  const { token } = useAuth();
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");
  const [selectedAttemptId, setSelectedAttemptId] = useState<string | null>(null);

  const quizQuery = useQuery({
    queryKey: ["teacher", "class-quizzes", classQuizId],
    queryFn: () => teacherService.quizDetail(token ?? "", classQuizId),
    enabled: Boolean(token && classQuizId),
  });
  const attemptsQuery = useQuery({
    queryKey: ["teacher", "class-quizzes", classQuizId, "attempts", status],
    queryFn: () => teacherService.quizAttempts(token ?? "", classQuizId, { status: status || undefined, per_page: 100 }),
    enabled: Boolean(token && classQuizId),
  });
  const reportQuery = useQuery({
    queryKey: ["teacher", "class-quizzes", classQuizId, "report"],
    queryFn: () => teacherService.quizReport(token ?? "", classQuizId),
    enabled: Boolean(token && classQuizId),
  });
  const detailQuery = useQuery({
    queryKey: ["teacher", "quiz-attempts", selectedAttemptId],
    queryFn: () => teacherService.quizAttemptDetail(token ?? "", selectedAttemptId ?? ""),
    enabled: Boolean(token && selectedAttemptId),
  });

  const attempts = useMemo(() => attemptsQuery.data?.items ?? [], [attemptsQuery.data?.items]);
  const filteredAttempts = useMemo(() => attempts.filter((attempt) => studentName(attempt).toLowerCase().includes(search.toLowerCase())), [attempts, search]);
  const questionsById = useMemo(() => new Map((quizQuery.data?.questions ?? []).map((question) => [question.id, question])), [quizQuery.data?.questions]);
  const selectedAttempt = detailQuery.data;

  return (
    <div className="grid gap-6">
      <div className="flex flex-wrap gap-3">
        <Link className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100" href={teacherRoutes.quizzes}>Kembali ke Kuis</Link>
        <Link className="w-fit rounded-lg border-2 border-ink bg-yellow-300 px-3 py-2 text-sm font-black text-ink shadow-brutal hover:bg-yellow-200" href={teacherRoutes.quizBuilder(classQuizId)}>Buka Builder</Link>
      </div>
      <PageHeader badge="Guru" description="Tinjau attempt siswa, cek skor, dan buka detail jawaban untuk kuis kelas." title="Hasil Kuis" />

      {quizQuery.isLoading || attemptsQuery.isLoading ? <LoadingState title="Memuat hasil kuis" /> : null}
      {quizQuery.isError ? <ErrorState description={getFirstApiError(quizQuery.error)} onRetry={() => void quizQuery.refetch()} title="Gagal memuat kuis" /> : null}
      {attemptsQuery.isError ? <ErrorState description={getFirstApiError(attemptsQuery.error)} onRetry={() => void attemptsQuery.refetch()} title="Gagal memuat attempt" /> : null}

      {quizQuery.data ? (
        <Card>
          <CardHeader>
            <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
              <div>
                <div className="flex flex-wrap gap-2"><Badge tone={quizQuery.data.status === "published" ? "blue" : "neutral"}>{statusLabel(quizQuery.data.status)}</Badge><Badge tone="yellow">{formatCount(quizQuery.data.questions_count)} soal</Badge></div>
                <h2 className="mt-3 text-2xl font-black text-ink">{quizQuery.data.title}</h2>
                <p className="mt-1 text-sm font-bold text-slate-500">Kelas: {quizQuery.data.class?.name ?? quizQuery.data.class_id}</p>
              </div>
              <p className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-bold text-slate-600">Show result: {quizQuery.data.show_result ? "Ya" : "Tidak"}</p>
            </div>
          </CardHeader>
          <CardContent><p className="text-sm leading-6 text-slate-600">{formatOptional(quizQuery.data.description)}</p></CardContent>
        </Card>
      ) : null}

      <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <StatsCard helper="Percobaan siswa" label="Total attempt" value={formatCount(reportQuery.data?.attempts_count ?? attemptsQuery.data?.meta?.total)} />
        <StatsCard helper="Submitted/expired" label="Selesai" value={formatCount(reportQuery.data?.submitted_count)} />
        <StatsCard helper="Rata-rata" label="Skor rata-rata" value={formatPercent(reportQuery.data?.average_score_percent)} />
        <StatsCard helper="Tertinggi" label="Skor tertinggi" value={formatPercent(reportQuery.data?.highest_score_percent)} />
        <StatsCard helper="Terendah" label="Skor terendah" value={formatPercent(reportQuery.data?.lowest_score_percent)} />
      </section>
      {reportQuery.isError ? <Alert tone="warning">Ringkasan report tidak dapat dimuat: {getFirstApiError(reportQuery.error)}</Alert> : null}

      <Card>
        <CardHeader><h2 className="text-xl font-black text-ink">Daftar Attempt</h2></CardHeader>
        <CardContent>
          <div className="mb-4 grid gap-3 sm:grid-cols-[1fr_220px]">
            <Input onChange={(event) => setSearch(event.target.value)} placeholder="Cari nama/email siswa" value={search} />
            <Select onChange={(event) => setStatus(event.target.value)} value={status}>
              <option value="">Semua status</option>
              <option value="in_progress">Sedang dikerjakan</option>
              <option value="submitted">Dikumpulkan</option>
              <option value="expired">Berakhir</option>
            </Select>
          </div>

          {!attemptsQuery.isLoading && !attemptsQuery.isError && filteredAttempts.length === 0 ? <EmptyState description="Belum ada attempt siswa untuk kuis ini." title="Attempt kosong" /> : null}

          {filteredAttempts.length > 0 ? (
            <div className="grid gap-3">
              {filteredAttempts.map((attempt) => (
                <div className="grid gap-3 rounded-xl border border-slate-200 bg-slate-50 p-4 lg:grid-cols-[1fr_auto]" key={attempt.id}>
                  <div>
                    <div className="flex flex-wrap items-center gap-2"><Badge tone={attempt.status === "submitted" ? "blue" : "neutral"}>{statusLabel(attempt.status)}</Badge><Badge tone="yellow">Attempt #{formatOptional(attempt.attempt_number)}</Badge></div>
                    <h3 className="mt-2 font-black text-ink">{studentName(attempt)}</h3>
                    <p className="text-sm text-slate-600">{formatOptional(attempt.student?.email)}</p>
                    <dl className="mt-3 grid gap-2 text-sm sm:grid-cols-4">
                      <div><dt className="font-black text-slate-500">Skor</dt><dd>{formatPercent(attempt.score_percent)}</dd></div>
                      <div><dt className="font-black text-slate-500">Poin</dt><dd>{formatOptional(attempt.score_points)} / {formatOptional(attempt.max_points)}</dd></div>
                      <div><dt className="font-black text-slate-500">Mulai</dt><dd>{formatDate(attempt.started_at)}</dd></div>
                      <div><dt className="font-black text-slate-500">Submit</dt><dd>{formatDate(attempt.submitted_at)}</dd></div>
                    </dl>
                  </div>
                  <Button onClick={() => setSelectedAttemptId((current) => current === attempt.id ? null : attempt.id)} type="button" variant="secondary">{selectedAttemptId === attempt.id ? "Tutup Detail" : "Lihat Detail"}</Button>
                </div>
              ))}
            </div>
          ) : null}
        </CardContent>
      </Card>

      {selectedAttemptId ? (
        <Card>
          <CardHeader><h2 className="text-xl font-black text-ink">Detail Attempt</h2></CardHeader>
          <CardContent>
            {detailQuery.isLoading ? <LoadingState title="Memuat detail attempt" /> : null}
            {detailQuery.isError ? <ErrorState description={getFirstApiError(detailQuery.error)} onRetry={() => void detailQuery.refetch()} title="Gagal memuat detail attempt" /> : null}
            {selectedAttempt ? (
              <div className="grid gap-4">
                <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
                  <h3 className="font-black text-ink">{studentName(selectedAttempt)}</h3>
                  <p className="text-sm text-slate-600">Status: {statusLabel(selectedAttempt.status)} | Skor: {formatPercent(selectedAttempt.score_percent)}</p>
                </div>
                {selectedAttempt.answers?.length ? selectedAttempt.answers.map((answer) => {
                  const question = questionsById.get(answer.quiz_question_id);
                  return (
                    <div className="rounded-xl border border-slate-200 bg-white p-4" key={answer.id}>
                      <div className="flex flex-wrap gap-2"><Badge tone="neutral">{formatOptional(question?.question_type)}</Badge>{typeof answer.is_correct === "boolean" ? <Badge tone={answer.is_correct ? "blue" : "orange"}>{answer.is_correct ? "Benar" : "Salah"}</Badge> : null}</div>
                      <h4 className="mt-2 font-black text-ink">{question?.order_number}. {question?.question_text ?? answer.quiz_question_id}</h4>
                      <p className="mt-2 text-sm text-slate-700"><span className="font-black">Jawaban siswa:</span> {answerLabel(answer, question)}</p>
                      <p className="mt-1 text-sm text-slate-600">Poin: {formatOptional(answer.awarded_points)} / {formatOptional(answer.max_points)}{typeof answer.similarity_score === "number" ? ` | Similarity: ${formatPercent(answer.similarity_score)}` : ""}</p>
                    </div>
                  );
                }) : <EmptyState description="Backend tidak mengembalikan detail jawaban untuk attempt ini." title="Detail jawaban kosong" />}
              </div>
            ) : null}
          </CardContent>
        </Card>
      ) : null}
    </div>
  );
}
