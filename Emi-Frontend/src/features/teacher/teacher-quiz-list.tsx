"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { BarChart3, LockKeyhole, Pencil, Plus, X } from "lucide-react";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, Input, LoadingState, PageHeader, StatsCard, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import type { TeacherClassQuiz } from "./types";
import { formatCount, formatDate, formatOptional, statusLabel } from "./teacher-utils";

const lockedMessage = "Konten kuis terkunci karena kuis sudah dipublikasikan atau sudah memiliki percobaan siswa. Buat kuis draft baru atau gunakan kuis yang belum dipublikasikan untuk mengubah soal.";

function isQuizLocked(quiz: TeacherClassQuiz) {
  return quiz.status !== "draft" || (quiz.attempts_count ?? 0) > 0;
}

export function TeacherQuizList() {
  const { token, user } = useAuth();
  const router = useRouter();
  const queryClient = useQueryClient();
  const [showCreate, setShowCreate] = useState(false);
  const quizzesQuery = useQuery({
    queryKey: ["teacher", "quizzes"],
    queryFn: () => teacherService.quizzes(token ?? ""),
    enabled: Boolean(token),
  });
  const classesQuery = useQuery({
    queryKey: ["teacher", "classes", "quiz-create"],
    queryFn: () => teacherService.classes(token ?? ""),
    enabled: Boolean(token && showCreate),
  });
  const createMutation = useMutation({
    mutationFn: (payload: Partial<TeacherClassQuiz>) => teacherService.createQuiz(token ?? "", payload),
    onSuccess: (quiz) => {
      queryClient.invalidateQueries({ queryKey: ["teacher", "quizzes"] });
      router.push(teacherRoutes.quizBuilder(quiz.id));
    },
  });

  const quizzes = quizzesQuery.data?.items ?? [];
  const publishedCount = quizzes.filter((quiz) => quiz.status === "published").length;
  const defaultClassId = user?.active_class?.id ?? classesQuery.data?.items[0]?.id ?? "";

  return (
    <div className="grid gap-8">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <PageHeader badge="Guru" description="Buat kuis draft, buka builder soal, dan pantau hasil attempt siswa." title="Kuis" />
        <Button className="gap-2" onClick={() => setShowCreate((value) => !value)} type="button">{showCreate ? <X className="size-5" /> : <Plus className="size-5" />}{showCreate ? "Tutup Form" : "Buat Kuis"}</Button>
      </div>

      {showCreate ? (
        <Card>
          <CardHeader><h2 className="text-xl font-black text-ink">Buat Kuis Draft</h2></CardHeader>
          <CardContent>
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
                <label className="grid gap-2 text-sm font-black text-ink">Judul<Input name="title" required /></label>
                <label className="grid gap-2 text-sm font-black text-ink">Durasi Menit<Input defaultValue={20} min={1} name="duration_minutes" required type="number" /></label>
                <label className="grid gap-2 text-sm font-black text-ink">Maks Attempt<Input defaultValue={1} min={1} name="max_attempts" required type="number" /></label>
                <label className="grid gap-2 text-sm font-black text-ink">Buka<Input name="open_at" type="datetime-local" /></label>
                <label className="grid gap-2 text-sm font-black text-ink">Tutup<Input name="close_at" type="datetime-local" /></label>
              </div>
              <label className="grid gap-2 text-sm font-black text-ink">Deskripsi<Textarea name="description" rows={2} /></label>
              <label className="grid gap-2 text-sm font-black text-ink">Instruksi<Textarea name="instructions" rows={2} /></label>
              <label className="flex items-center gap-2 text-sm font-black text-ink"><input defaultChecked name="show_result" type="checkbox" /> Tampilkan hasil ke siswa</label>
              <Button disabled={createMutation.isPending || !defaultClassId} type="submit">{createMutation.isPending ? "Membuat..." : "Buat dan Buka Builder"}</Button>
            </form>
          </CardContent>
        </Card>
      ) : null}

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
                          <div className="flex flex-wrap gap-2"><Badge tone={quiz.status === "published" ? "blue" : "neutral"}>{statusLabel(quiz.status)}</Badge>{locked ? <Badge tone="yellow"><LockKeyhole className="mr-1 size-3" />Terkunci</Badge> : <Badge tone="blue"><Pencil className="mr-1 size-3" />Draft bisa diedit</Badge>}</div>
                          <h2 className="mt-2 text-xl font-black text-ink">{quiz.title}</h2>
                          <p className="mt-1 text-sm font-bold text-muted">{quiz.class?.name ?? user?.active_class?.name ?? "Kelas aktif"}</p>
                        </div>
                        <div className="flex gap-2 sm:flex-col"><Link className="inline-flex min-h-11 flex-1 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition-transform hover:-translate-y-0.5" href={teacherRoutes.quizBuilder(quiz.id)}>{locked ? <LockKeyhole className="size-4" /> : <Pencil className="size-4" />}{locked ? "Lihat Detail" : "Builder"}</Link><Link className="inline-flex min-h-11 flex-1 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink transition-colors hover:bg-surface-muted" href={teacherRoutes.quizResults(quiz.id)}><BarChart3 className="size-4" />Hasil</Link></div>
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
