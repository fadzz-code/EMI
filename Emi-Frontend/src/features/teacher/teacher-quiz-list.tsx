"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Archive, BarChart3, Eye, LockKeyhole, Pencil, Plus, Send, Trash2 } from "lucide-react";

import { Alert, Badge, Button, Card, CardContent, CardHeader, ConfirmDialog, EmptyState, ErrorState, Input, LoadingState, Modal, PageHeader, StatsCard, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { quizLifecycle } from "./teacher-workflow";
import type { TeacherClassQuiz } from "./types";
import { formatCount, formatDate, formatOptional, statusLabel } from "./teacher-utils";

const lockedMessage = "Konten kuis terkunci saat sedang diterbitkan atau sudah memiliki percobaan siswa. Arsipkan kuis sebelum mengubahnya.";

function isQuizLocked(quiz: TeacherClassQuiz) {
  return quiz.status === "published" || (quiz.attempts_count ?? 0) > 0;
}

export function TeacherQuizList() {
  const { token, user } = useAuth();
  const router = useRouter();
  const queryClient = useQueryClient();
  const [createOpen, setCreateOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<TeacherClassQuiz | null>(null);
  const [archiveTarget, setArchiveTarget] = useState<TeacherClassQuiz | null>(null);
  const [publishTarget, setPublishTarget] = useState<TeacherClassQuiz | null>(null);

  const quizzesQuery = useQuery({
    queryKey: ["teacher", "quizzes"],
    queryFn: () => teacherService.quizzes(token ?? ""),
    enabled: Boolean(token),
  });
  const classesQuery = useQuery({
    queryKey: ["teacher", "classes", "quiz-create"],
    queryFn: () => teacherService.classes(token ?? ""),
    enabled: Boolean(token && createOpen),
  });

  async function invalidateQuizzes() {
    await queryClient.invalidateQueries({ queryKey: ["teacher", "quizzes"] });
  }

  const createMutation = useMutation({
    mutationFn: (payload: Partial<TeacherClassQuiz>) => teacherService.createQuiz(token ?? "", payload),
    onSuccess: (quiz) => {
      setCreateOpen(false);
      queryClient.invalidateQueries({ queryKey: ["teacher", "quizzes"] });
      router.push(teacherRoutes.quizBuilder(quiz.id));
    },
  });

  const archiveMutation = useMutation({
    mutationFn: (quizId: string) => teacherService.archiveQuiz(token ?? "", quizId),
    onSuccess: async () => {
      setArchiveTarget(null);
      await invalidateQuizzes();
    },
  });

  const publishMutation = useMutation({
    mutationFn: (quizId: string) => teacherService.publishQuiz(token ?? "", quizId),
    onSuccess: async () => {
      setPublishTarget(null);
      await invalidateQuizzes();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (quizId: string) => teacherService.deleteQuiz(token ?? "", quizId),
    onSuccess: async () => {
      setDeleteTarget(null);
      await invalidateQuizzes();
    },
  });

  const quizzes = quizzesQuery.data?.items ?? [];
  const publishedCount = quizzes.filter((quiz) => quiz.status === "published").length;
  const defaultClassId = user?.active_class?.id ?? classesQuery.data?.items[0]?.id ?? "";
  const actionError = archiveMutation.error ?? publishMutation.error ?? deleteMutation.error;

  return (
    <div className="grid gap-8">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <PageHeader badge="Guru" description="Kelola kuis kelas Anda: tambah, ubah, arsipkan, atau hapus sesuai kebutuhan siswa di kelas ini." title="Kuis" />
        <Button onClick={() => setCreateOpen(true)} type="button">
          <Plus className="size-4" strokeWidth={2.5} />
          Buat Kuis
        </Button>
      </div>

      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}
      {quizzesQuery.isLoading ? <LoadingState title="Memuat kuis" /> : null}
      {quizzesQuery.isError ? <ErrorState description={getFirstApiError(quizzesQuery.error)} onRetry={() => void quizzesQuery.refetch()} title="Gagal memuat kuis" /> : null}

      {!quizzesQuery.isLoading && !quizzesQuery.isError ? (
        quizzes.length === 0 ? (
          <Card><CardContent><EmptyState description="Belum ada kuis kelas yang bisa dikelola." title="Kuis belum tersedia" /></CardContent></Card>
        ) : (
          <div className="grid gap-4">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard helper={user?.active_class?.name ?? "Kelas aktif"} label="Total kuis" value={formatCount(quizzes.length)} />
              <StatsCard helper="Status published" label="Kuis terbit" value={formatCount(publishedCount)} />
              <StatsCard helper="Percobaan siswa yang tercatat" label="Attempt" value={formatCount(quizzes.reduce((sum, quiz) => sum + (quiz.attempts_count ?? 0), 0))} />
            </section>
            <div className="grid auto-rows-fr gap-4 md:grid-cols-2">
              {quizzes.map((quiz) => {
                const locked = isQuizLocked(quiz);
                return (
                  <Card className="flex h-full flex-col transition hover:-translate-y-1 hover:shadow-emi" key={quiz.id}>
                    <CardHeader>
                      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                        <div>
                          <div className="flex flex-wrap gap-2"><Badge tone={quiz.status === "published" ? "blue" : "neutral"}>{statusLabel(quiz.status)}</Badge>{locked ? <Badge tone="yellow"><LockKeyhole className="mr-1 size-3" />Terkunci</Badge> : <Badge tone="blue"><Pencil className="mr-1 size-3" />Bisa diedit</Badge>}</div>
                          <h2 className="mt-2 text-xl font-black text-ink">{quiz.title}</h2>
                          <p className="mt-1 text-sm font-bold text-muted">{quiz.class?.name ?? user?.active_class?.name ?? "Kelas aktif"}</p>
                        </div>
                        <Link className="inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5" href={teacherRoutes.quizBuilder(quiz.id)}>
                          <Pencil className="size-4" strokeWidth={2.5} />
                          Edit Kuis
                        </Link>
                      </div>
                    </CardHeader>
                    <CardContent className="flex flex-1 flex-col">
                      {locked ? <Alert tone="warning">{lockedMessage}</Alert> : null}
                      <p className="line-clamp-2 text-sm font-semibold leading-6 text-muted">{formatOptional(quiz.description)}</p>
                      <dl className="mt-auto grid gap-3 pt-4 text-sm sm:grid-cols-2">
                        <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Durasi</dt><dd className="mt-1 font-bold text-ink">{formatCount(quiz.duration_minutes)} menit</dd></div>
                        <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Soal</dt><dd className="mt-1 font-bold text-ink">{formatCount(quiz.questions_count)}</dd></div>
                        <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Attempt</dt><dd className="mt-1 font-bold text-ink">{formatCount(quiz.attempts_count)}</dd></div>
                        <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Buka</dt><dd className="mt-1 font-bold text-ink">{formatDate(quiz.open_at)}</dd></div>
                      </dl>
                      <div className="mt-4 flex flex-wrap gap-2">
                        <Link className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 text-xs font-black text-ink transition hover:-translate-y-0.5 hover:bg-surface-muted" href={teacherRoutes.quizPreview(quiz.id)}>
                          <Eye className="size-4" strokeWidth={2.5} /> Preview
                        </Link>
                        <Link className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 text-xs font-black text-ink transition hover:-translate-y-0.5 hover:bg-surface-muted" href={teacherRoutes.quizResults(quiz.id)}>
                          <BarChart3 className="size-4" strokeWidth={2.5} /> Hasil
                        </Link>
                        {quiz.status === "archived" ? (
                          <button
                            className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 text-xs font-black text-ink transition hover:-translate-y-0.5 hover:bg-surface-muted disabled:opacity-50"
                            disabled={publishMutation.isPending}
                            onClick={() => setPublishTarget(quiz)}
                            type="button"
                          >
                            <Send className="size-4" strokeWidth={2.5} /> Terbitkan
                          </button>
                        ) : (
                          <button
                            className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 text-xs font-black text-ink transition hover:-translate-y-0.5 hover:bg-surface-muted disabled:opacity-50"
                            disabled={archiveMutation.isPending}
                            onClick={() => setArchiveTarget(quiz)}
                            type="button"
                          >
                            <Archive className="size-4" strokeWidth={2.5} /> Arsipkan
                          </button>
                        )}
                        <button
                          className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-danger/40 bg-surface px-3 text-xs font-black text-danger transition hover:-translate-y-0.5 hover:border-danger disabled:opacity-50"
                          disabled={deleteMutation.isPending || quizLifecycle(quiz) !== "delete"}
                          onClick={() => setDeleteTarget(quiz)}
                          title={quizLifecycle(quiz) !== "delete" ? "Kuis yang masih published harus diarsipkan terlebih dahulu sebelum dihapus." : undefined}
                          type="button"
                        >
                          <Trash2 className="size-4" strokeWidth={2.5} /> Hapus
                        </button>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          </div>
        )
      ) : null}

      <Modal onClose={() => setCreateOpen(false)} open={createOpen} title="Buat Kuis Draft">
        <form className="grid gap-4" onSubmit={(event) => {
          event.preventDefault();
          const formData = new FormData(event.currentTarget);
          createMutation.mutate({
            class_id: String(formData.get("class_id") ?? defaultClassId),
            title: String(formData.get("title") ?? ""),
            description: String(formData.get("description") ?? ""),
            instructions: String(formData.get("instructions") ?? ""),
            duration_minutes: Number(formData.get("duration_minutes") ?? 20),
            max_attempts: Number(formData.get("max_attempts") ?? 1),
            show_result: formData.get("show_result") === "on",
            open_at: String(formData.get("open_at") ?? "") || null,
            close_at: String(formData.get("close_at") ?? "") || null,
            status: "draft",
          });
        }}>
          {createMutation.error ? <Alert tone="error">{getFirstApiError(createMutation.error)}</Alert> : null}
          <div className="grid gap-4 sm:grid-cols-2">
            <label className="grid gap-2 text-sm font-black text-ink">Kelas<select className="min-h-11 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 py-2 text-sm font-semibold text-ink" defaultValue={defaultClassId} name="class_id" required>{user?.active_class?.id ? <option value={user.active_class.id}>{user.active_class.name ?? "Kelas aktif"}</option> : null}{classesQuery.data?.items.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
            <label className="grid gap-2 text-sm font-black text-ink">Judul<Input autoFocus name="title" required /></label>
            <label className="grid gap-2 text-sm font-black text-ink">Durasi Menit<Input defaultValue={20} min={1} name="duration_minutes" required type="number" /></label>
            <label className="grid gap-2 text-sm font-black text-ink">Maks Attempt<Input defaultValue={1} min={1} name="max_attempts" required type="number" /></label>
            <label className="grid gap-2 text-sm font-black text-ink">Buka<Input name="open_at" type="datetime-local" /></label>
            <label className="grid gap-2 text-sm font-black text-ink">Tutup<Input name="close_at" type="datetime-local" /></label>
          </div>
          <label className="grid gap-2 text-sm font-black text-ink">Deskripsi<Textarea name="description" rows={2} /></label>
          <label className="grid gap-2 text-sm font-black text-ink">Instruksi<Textarea name="instructions" rows={2} /></label>
          <label className="flex items-center gap-2 text-sm font-black text-ink"><input defaultChecked name="show_result" type="checkbox" /> Tampilkan hasil ke siswa</label>
          <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
            <Button disabled={createMutation.isPending} onClick={() => setCreateOpen(false)} type="button" variant="ghost">Batal</Button>
            <Button disabled={createMutation.isPending || !defaultClassId} type="submit">{createMutation.isPending ? "Membuat..." : "Buat dan Buka Builder"}</Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        confirmLabel={deleteMutation.isPending ? "Menghapus..." : "Hapus Kuis"}
        description={deleteTarget ? `Kuis "${deleteTarget.title}" akan dihapus secara permanen dan hanya berlaku untuk kelas ini.` : ""}
        isConfirming={deleteMutation.isPending}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => {
          if (deleteTarget) deleteMutation.mutate(deleteTarget.id);
        }}
        open={Boolean(deleteTarget)}
        title="Hapus kuis?"
      />

      <ConfirmDialog
        confirmLabel={archiveMutation.isPending ? "Mengarsipkan..." : "Arsipkan Kuis"}
        confirmVariant="secondary"
        description={archiveTarget ? `Arsipkan kuis "${archiveTarget.title}"? Kuis tidak akan terlihat oleh siswa.` : ""}
        isConfirming={archiveMutation.isPending}
        onCancel={() => setArchiveTarget(null)}
        onConfirm={() => {
          if (archiveTarget) archiveMutation.mutate(archiveTarget.id);
        }}
        open={Boolean(archiveTarget)}
        title="Arsipkan kuis?"
      />

      <ConfirmDialog
        confirmLabel={publishMutation.isPending ? "Menerbitkan..." : "Terbitkan Kuis"}
        confirmVariant="primary"
        description={publishTarget ? `Terbitkan kembali kuis "${publishTarget.title}"? Kuis akan terlihat oleh siswa lagi.` : ""}
        isConfirming={publishMutation.isPending}
        onCancel={() => setPublishTarget(null)}
        onConfirm={() => {
          if (publishTarget) publishMutation.mutate(publishTarget.id);
        }}
        open={Boolean(publishTarget)}
        title="Terbitkan kuis?"
      />
    </div>
  );
}
