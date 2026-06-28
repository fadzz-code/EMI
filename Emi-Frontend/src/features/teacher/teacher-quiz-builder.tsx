"use client";

import Link from "next/link";
import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, Input, LoadingState, PageHeader, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { TeacherQuizQuestionForm } from "./teacher-quiz-question-form";
import { teacherService } from "./teacher-service";
import type { TeacherQuizQuestion } from "./types";
import { statusLabel } from "./teacher-utils";

export function TeacherQuizBuilder({ classQuizId }: { classQuizId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [editingQuestion, setEditingQuestion] = useState<TeacherQuizQuestion | null>(null);

  const quizQuery = useQuery({
    queryKey: ["teacher", "class-quizzes", classQuizId],
    queryFn: () => teacherService.quizDetail(token ?? "", classQuizId),
    enabled: Boolean(token && classQuizId),
  });

  const updateMutation = useMutation({
    mutationFn: (payload: { title: string; description: string; instructions: string; duration_minutes: number; max_attempts: number; show_result: boolean; open_at: string | null; close_at: string | null }) => teacherService.updateQuiz(token ?? "", classQuizId, payload),
    onSuccess: () => {
      setSuccessMsg("Kuis berhasil disimpan.");
      queryClient.invalidateQueries({ queryKey: ["teacher", "class-quizzes", classQuizId] });
      queryClient.invalidateQueries({ queryKey: ["teacher", "quizzes"] });
    },
  });

  const publishMutation = useMutation({
    mutationFn: () => teacherService.publishQuiz(token ?? "", classQuizId),
    onSuccess: () => {
      setSuccessMsg("Kuis berhasil dipublikasikan.");
      queryClient.invalidateQueries({ queryKey: ["teacher", "class-quizzes", classQuizId] });
      queryClient.invalidateQueries({ queryKey: ["teacher", "quizzes"] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (questionId: string) => teacherService.deleteQuizQuestion(token ?? "", questionId),
    onSuccess: () => {
      setSuccessMsg("Soal berhasil dihapus.");
      queryClient.invalidateQueries({ queryKey: ["teacher", "class-quizzes", classQuizId] });
    },
  });

  const quiz = quizQuery.data;
  const questions = quiz?.questions ?? [];

  return (
    <div className="grid gap-6">
      <Link className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100" href={teacherRoutes.quizzes}>Kembali ke Daftar Kuis</Link>
      <PageHeader badge="Guru" description="Ubah metadata dan soal kuis kelas memakai endpoint class_quizzes dan quiz_questions." title="Quiz Builder" />

      {quizQuery.isLoading ? <LoadingState title="Memuat detail kuis" /> : null}
      {quizQuery.isError ? <ErrorState description={getFirstApiError(quizQuery.error)} onRetry={() => void quizQuery.refetch()} title="Gagal memuat kuis" /> : null}

      {quiz ? (
        <div className="grid gap-6 lg:grid-cols-[1fr_1fr]">
          <Card>
            <CardHeader><div className="flex items-center justify-between"><h2 className="text-xl font-black text-ink">Metadata Kuis</h2><Badge tone={quiz.status === "published" ? "blue" : "neutral"}>{statusLabel(quiz.status)}</Badge></div></CardHeader>
            <CardContent>
              <form className="grid gap-4" onSubmit={(event) => {
                event.preventDefault();
                setSuccessMsg(null);
                const formData = new FormData(event.currentTarget);
                updateMutation.mutate({
                  title: String(formData.get("title") ?? ""),
                  description: String(formData.get("description") ?? ""),
                  instructions: String(formData.get("instructions") ?? ""),
                  duration_minutes: Number(formData.get("duration_minutes") ?? 1),
                  max_attempts: Number(formData.get("max_attempts") ?? 1),
                  show_result: formData.get("show_result") === "on",
                  open_at: String(formData.get("open_at") ?? "") || null,
                  close_at: String(formData.get("close_at") ?? "") || null,
                });
              }}>
                {successMsg ? <Alert tone="success">{successMsg}</Alert> : null}
                {updateMutation.error ? <Alert tone="error">{getFirstApiError(updateMutation.error)}</Alert> : null}
                {publishMutation.error ? <Alert tone="error">{getFirstApiError(publishMutation.error)}</Alert> : null}
                <p className="text-sm font-bold text-slate-500">Kelas: {quiz.class?.name ?? quiz.class_id}</p>
                <label className="grid gap-2 text-sm font-black text-ink">Judul<Input defaultValue={quiz.title} name="title" required /></label>
                <label className="grid gap-2 text-sm font-black text-ink">Deskripsi<Textarea defaultValue={quiz.description ?? ""} name="description" rows={3} /></label>
                <label className="grid gap-2 text-sm font-black text-ink">Instruksi<Textarea defaultValue={quiz.instructions ?? ""} name="instructions" rows={3} /></label>
                <div className="grid gap-4 sm:grid-cols-2">
                  <label className="grid gap-2 text-sm font-black text-ink">Durasi Menit<Input defaultValue={quiz.duration_minutes ?? 1} min={1} name="duration_minutes" type="number" required /></label>
                  <label className="grid gap-2 text-sm font-black text-ink">Maks Attempt<Input defaultValue={quiz.max_attempts ?? 1} min={1} name="max_attempts" type="number" required /></label>
                  <label className="grid gap-2 text-sm font-black text-ink">Buka<Input defaultValue={quiz.open_at?.slice(0, 16) ?? ""} name="open_at" type="datetime-local" /></label>
                  <label className="grid gap-2 text-sm font-black text-ink">Tutup<Input defaultValue={quiz.close_at?.slice(0, 16) ?? ""} name="close_at" type="datetime-local" /></label>
                </div>
                <label className="flex items-center gap-2 text-sm font-black text-ink"><input defaultChecked={quiz.show_result} name="show_result" type="checkbox" /> Tampilkan hasil ke siswa</label>
                <div className="flex flex-col gap-3 sm:flex-row">
                  <Button disabled={updateMutation.isPending || publishMutation.isPending} type="submit">{updateMutation.isPending ? "Menyimpan..." : "Simpan"}</Button>
                  {quiz.status !== "published" ? <Button disabled={publishMutation.isPending || updateMutation.isPending} onClick={() => { setSuccessMsg(null); publishMutation.mutate(); }} type="button" variant="secondary">{publishMutation.isPending ? "Menerbitkan..." : "Publish"}</Button> : null}
                </div>
              </form>
            </CardContent>
          </Card>

          <Card>
            <CardHeader><h2 className="text-xl font-black text-ink">Soal</h2></CardHeader>
            <CardContent>
              {deleteMutation.error ? <Alert tone="error">{getFirstApiError(deleteMutation.error)}</Alert> : null}
              {questions.length === 0 ? <EmptyState description="Belum ada soal." title="Soal kosong" /> : (
                <div className="grid gap-3">
                  {questions.map((question) => (
                    <div className="rounded-xl border border-slate-200 bg-slate-50 p-3" key={question.id}>
                      <div className="flex items-start justify-between gap-3"><div><p className="font-black text-ink">{question.order_number}. {question.question_text}</p><p className="text-xs font-bold text-slate-500">{question.question_type} | {question.points ?? 0} poin</p></div><Badge>{question.options?.length ?? 0} opsi</Badge></div>
                      {question.options?.length ? <ol className="mt-2 grid gap-1 text-sm text-slate-600">{question.options.map((option) => <li key={`${question.id}-${option.order_number}`}>{option.order_number}. {option.option_text}{option.is_correct ? " (benar)" : ""}</li>)}</ol> : null}
                      <div className="mt-3 flex gap-2"><Button onClick={() => setEditingQuestion(question)} type="button" variant="secondary">Edit</Button><Button disabled={deleteMutation.isPending} onClick={() => deleteMutation.mutate(question.id)} type="button" variant="secondary">Hapus</Button></div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          <TeacherQuizQuestionForm classQuizId={classQuizId} editingQuestion={editingQuestion} onCancelEdit={() => setEditingQuestion(null)} onSaved={() => { setSuccessMsg(editingQuestion ? "Soal berhasil diperbarui." : "Soal berhasil ditambahkan."); setEditingQuestion(null); queryClient.invalidateQueries({ queryKey: ["teacher", "class-quizzes", classQuizId] }); }} token={token ?? ""} />
        </div>
      ) : null}
    </div>
  );
}
