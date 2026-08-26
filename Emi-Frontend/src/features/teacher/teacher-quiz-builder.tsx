"use client";

import Link from "next/link";
import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, BarChart3, Eye, LockKeyhole } from "lucide-react";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, Input, LoadingState, MutationAlert, PageHeader, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { TeacherQuizQuestionForm } from "./teacher-quiz-question-form";
import { teacherService } from "./teacher-service";
import type { TeacherClassQuiz, TeacherQuizQuestion } from "./types";
import { questionTypeLabel, statusLabel } from "./teacher-utils";
import { quizHasAttempts, quizPublished } from "./teacher-workflow";

const publishedMessage = "Kuis terbit terkunci. Arsipkan kuis sebelum mengubahnya.";
const attemptsMessage = "Kuis sudah memiliki percobaan siswa. Soal tidak dapat ditambah, diedit, atau dihapus.";

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
    mutationFn: (payload: Partial<TeacherClassQuiz>) => teacherService.updateQuiz(token ?? "", classQuizId, payload),
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
  const published = quiz ? quizPublished(quiz) : false;
  const hasAttempts = quiz ? quizHasAttempts(quiz) : false;
  const metadataLocked = published || hasAttempts;
  const questionsLocked = published || hasAttempts;
  const canPublish = quiz ? quiz.status === "draft" || quiz.status === "archived" : false;

  return (
    <div className="grid gap-6">
      <div className="flex flex-wrap gap-3"><Link className="inline-flex w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 py-2 text-sm font-black text-ink transition-colors hover:bg-surface-muted" href={teacherRoutes.quizzes}><ArrowLeft className="size-4" />Kembali ke Daftar Kuis</Link><Link className="inline-flex w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 py-2 text-sm font-black text-ink transition-colors hover:bg-surface-muted" href={teacherRoutes.quizPreview(classQuizId)}><Eye className="size-4" />Preview Kuis</Link><Link className="inline-flex w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-3 py-2 text-sm font-black text-primary-foreground shadow-emi transition-transform hover:-translate-y-0.5" href={teacherRoutes.quizResults(classQuizId)}><BarChart3 className="size-4" />Lihat Hasil</Link></div>
      <PageHeader badge="Guru" description="Atur informasi kuis, jadwal pengerjaan, visibilitas hasil, dan daftar soal kelas." title="Quiz Builder" />

      {quizQuery.isLoading ? <LoadingState title="Memuat detail kuis" /> : null}
      {quizQuery.isError ? <ErrorState description={getFirstApiError(quizQuery.error)} onRetry={() => void quizQuery.refetch()} title="Gagal memuat kuis" /> : null}

      {quiz ? (
        <div className="grid items-start gap-6 lg:grid-cols-2">
          <Card>
            <CardHeader><div className="flex items-center justify-between"><h2 className="text-xl font-black text-ink">Metadata Kuis</h2><div className="flex gap-2"><Badge tone={published ? "blue" : "neutral"}>{statusLabel(quiz.status)}</Badge>{published ? <Badge tone="yellow"><LockKeyhole className="mr-1 size-3" />Terkunci</Badge> : <Badge tone="blue">Bisa diedit</Badge>}{hasAttempts ? <Badge tone="yellow">Sudah ada attempt</Badge> : null}</div></div></CardHeader>
            <CardContent>
              <form className="grid gap-4" onSubmit={(event) => {
                event.preventDefault();
                setSuccessMsg(null);
                const formData = new FormData(event.currentTarget);
                 const payload = metadataLocked ? {
                  show_result: formData.get("show_result") === "on",
                } : {
                  title: String(formData.get("title") ?? ""),
                  description: String(formData.get("description") ?? ""),
                  instructions: String(formData.get("instructions") ?? ""),
                  duration_minutes: Number(formData.get("duration_minutes") ?? 1),
                  max_attempts: Number(formData.get("max_attempts") ?? 1),
                  show_result: formData.get("show_result") === "on",
                  open_at: String(formData.get("open_at") ?? "") || null,
                  close_at: String(formData.get("close_at") ?? "") || null,
                };
                updateMutation.mutate(payload);
              }}>
                <MutationAlert eventKey={Math.max(updateMutation.submittedAt, publishMutation.submittedAt, deleteMutation.submittedAt)} tone="success" visible={Boolean(successMsg)}>{successMsg}</MutationAlert>
                <MutationAlert eventKey={updateMutation.submittedAt} tone="error" visible={Boolean(updateMutation.error)}>{getFirstApiError(updateMutation.error)}</MutationAlert>
                <MutationAlert eventKey={publishMutation.submittedAt} tone="error" visible={Boolean(publishMutation.error)}>{getFirstApiError(publishMutation.error)}</MutationAlert>
                 {published ? <Alert tone="warning">{publishedMessage}</Alert> : null}
                 {hasAttempts ? <Alert tone="warning">{attemptsMessage}</Alert> : null}
                 <p className="text-sm font-bold text-muted">Kelas: {quiz.class?.name ?? quiz.class_id}</p>
                 <label className="grid gap-2 text-sm font-black text-ink">Judul<Input defaultValue={quiz.title} disabled={metadataLocked} name="title" required /></label>
                 <label className="grid gap-2 text-sm font-black text-ink">Deskripsi<Textarea defaultValue={quiz.description ?? ""} disabled={metadataLocked} name="description" rows={3} /></label>
                 <label className="grid gap-2 text-sm font-black text-ink">Instruksi<Textarea defaultValue={quiz.instructions ?? ""} disabled={metadataLocked} name="instructions" rows={3} /></label>
                <div className="grid gap-4 sm:grid-cols-2">
                  <label className="grid gap-2 text-sm font-black text-ink">Durasi Menit<Input defaultValue={quiz.duration_minutes ?? 1} disabled={metadataLocked} min={1} name="duration_minutes" type="number" required /></label>
                  <label className="grid gap-2 text-sm font-black text-ink">Maks Attempt<Input defaultValue={quiz.max_attempts ?? 1} disabled={metadataLocked} min={1} name="max_attempts" type="number" required /></label>
                  <label className="grid gap-2 text-sm font-black text-ink">Buka<Input defaultValue={quiz.open_at?.slice(0, 16) ?? ""} disabled={metadataLocked} name="open_at" type="datetime-local" /></label>
                  <label className="grid gap-2 text-sm font-black text-ink">Tutup<Input defaultValue={quiz.close_at?.slice(0, 16) ?? ""} disabled={metadataLocked} name="close_at" type="datetime-local" /></label>
                </div>
                <label className="flex items-center gap-2 text-sm font-black text-ink"><input defaultChecked={quiz.show_result} name="show_result" type="checkbox" /> Tampilkan hasil ke siswa</label>
                <div className="flex flex-col gap-3 sm:flex-row">
                  <Button disabled={updateMutation.isPending || publishMutation.isPending} type="submit">{updateMutation.isPending ? "Menyimpan..." : metadataLocked ? "Simpan Visibilitas Hasil" : "Simpan"}</Button>
                  {canPublish ? <Button disabled={publishMutation.isPending || updateMutation.isPending} onClick={() => { setSuccessMsg(null); publishMutation.mutate(); }} type="button" variant="secondary">{publishMutation.isPending ? "Menerbitkan..." : quiz?.status === "archived" ? "Terbitkan Ulang" : "Publish"}</Button> : null}
                </div>
              </form>
            </CardContent>
          </Card>

          <Card>
            <CardHeader><h2 className="text-xl font-black text-ink">Soal</h2></CardHeader>
            <CardContent>
              <MutationAlert eventKey={deleteMutation.submittedAt} tone="error" visible={Boolean(deleteMutation.error)}>{getFirstApiError(deleteMutation.error)}</MutationAlert>
              {questions.length === 0 ? <EmptyState description="Belum ada soal." title="Soal kosong" /> : (
                <div className="grid gap-3">
                  {questions.map((question) => (
                    <div className="rounded-xl border-2 border-border bg-surface-muted p-4" key={question.id}>
                      <div className="flex items-start justify-between gap-3"><div><p className="font-black text-ink">{question.order_number}. {question.question_text}</p><p className="text-xs font-bold text-muted">{questionTypeLabel(question.question_type)} · {question.points ?? 0} poin</p></div><Badge>{question.options?.length ?? 0} opsi</Badge></div>
                      {question.options?.length ? <ol className="mt-2 grid gap-1 text-sm text-muted">{question.options.map((option) => <li key={`${question.id}-${option.order_number}`}>{option.order_number}. {option.option_text}{option.is_correct ? " (benar)" : ""}</li>)}</ol> : null}
                      {question.image_media?.url ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img alt="Gambar soal" className="mt-3 max-h-48 w-fit rounded-lg border-2 border-border bg-surface object-contain" src={question.image_media.url} />
                      ) : question.image_media_id ? <p className="mt-3 rounded-lg border-2 border-border bg-surface p-2 text-xs text-muted">Gambar terhubung: {question.image_media_id}</p> : null}
                      <div className="mt-3 flex gap-2"><Button disabled={questionsLocked} onClick={() => setEditingQuestion(question)} type="button" variant="secondary">Edit</Button><Button disabled={questionsLocked || deleteMutation.isPending} onClick={() => { if (confirm("Hapus soal ini?")) { deleteMutation.mutate(question.id); } }} type="button" variant="danger">Hapus</Button></div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {questionsLocked ? (
            <Card className="lg:col-span-2"><CardContent><Alert tone="warning">{hasAttempts ? attemptsMessage : publishedMessage}</Alert><Link className="mt-4 inline-flex min-h-11 items-center justify-center rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition-transform hover:-translate-y-0.5" href={teacherRoutes.quizzes}>Buat Kuis Baru</Link></CardContent></Card>
          ) : (
            <TeacherQuizQuestionForm classQuizId={classQuizId} defaultOrder={questions.length + 1} editingQuestion={editingQuestion} key={editingQuestion?.id ?? `new-${questions.length + 1}`} onCancelEdit={() => setEditingQuestion(null)} onSaved={() => { setSuccessMsg(editingQuestion ? "Soal berhasil diperbarui." : "Soal berhasil ditambahkan."); setEditingQuestion(null); queryClient.invalidateQueries({ queryKey: ["teacher", "class-quizzes", classQuizId] }); queryClient.invalidateQueries({ queryKey: ["teacher", "quizzes"] }); }} token={token ?? ""} />
          )}
        </div>
      ) : null}
    </div>
  );
}
