"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Mic, Pencil } from "lucide-react";

import { Alert, AudioPlayer, Badge, Card, CardContent, CardHeader, ErrorState, LoadingState, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { formatCount, formatOptional } from "./teacher-utils";

function difficultyLabel(value?: string | null) {
  if (value === "beginner") return "Pemula";
  if (value === "intermediate") return "Menengah";
  if (value === "advanced") return "Lanjutan";
  return formatOptional(value);
}

function statusTone(status?: string | null): "yellow" | "blue" | "orange" {
  if (status === "published") return "blue";
  if (status === "archived") return "orange";
  return "yellow";
}

function statusLabel(status?: string | null) {
  return {
    draft: "Draft",
    published: "Terbit",
    archived: "Arsip",
  }[status ?? ""] ?? "Status";
}

export function TeacherSpeakingExercisePreview({ exerciseId }: { exerciseId: string }) {
  const { token } = useAuth();

  const exerciseQuery = useQuery({
    queryKey: ["teacher", "speaking-exercises", exerciseId],
    queryFn: () => teacherService.speakingExerciseDetail(token ?? "", exerciseId),
    enabled: Boolean(token && exerciseId),
  });

  const exercise = exerciseQuery.data;

  return (
    <div className="grid gap-8">
      <div className="flex flex-wrap gap-3">
        <Link className="inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-primary transition hover:-translate-y-0.5 hover:bg-[var(--color-primary-muted)] hover:shadow-emi" href={teacherRoutes.speakingExercises}>
          <ArrowLeft className="size-5" strokeWidth={2.5} /> Kembali ke Daftar Target Speaking
        </Link>
      </div>
      <PageHeader badge="Guru" description="Lihat target bacaan dan audio contoh persis seperti tampilan yang akan dilihat siswa." title="Lihat Target Speaking (Preview)" />

      {exerciseQuery.isLoading ? <LoadingState title="Memuat target speaking" /> : null}
      {exerciseQuery.isError ? (
        <ErrorState description={getFirstApiError(exerciseQuery.error)} onRetry={() => void exerciseQuery.refetch()} title="Gagal memuat target speaking" />
      ) : null}

      {exercise ? (
        <>
          <header className="grid gap-6 rounded-3xl border-2 border-border bg-[var(--color-primary-muted)] p-6 shadow-emi sm:p-8 lg:grid-cols-[1.2fr_auto] lg:items-center">
            <div className="grid gap-5">
              <div className="flex flex-wrap gap-2">
                <Badge tone={statusTone(exercise.status)}>{statusLabel(exercise.status)}</Badge>
                <Badge tone="yellow">{difficultyLabel(exercise.difficulty)}</Badge>
                <Badge tone="neutral">{formatCount(exercise.attempts_count)} percobaan siswa</Badge>
              </div>
              <div>
                <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">{exercise.title}</h1>
                <p className="mt-3 max-w-2xl text-sm font-semibold leading-6 text-muted">Kelas: {exercise.classroom?.name ?? "-"}</p>
              </div>
            </div>
            <div className="flex flex-col gap-3 sm:flex-row lg:flex-col">
              <Link className="inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5" href={teacherRoutes.speakingExercises}>
                <Pencil className="size-4" strokeWidth={2.5} /> Edit Target
              </Link>
            </div>
          </header>

          <Card>
            <CardHeader><h2 className="text-xl font-black text-ink">Target Bacaan</h2></CardHeader>
            <CardContent>
              <div className="rounded-2xl border-2 border-border bg-surface-muted p-5 sm:p-6">
                <p className="text-[10px] font-black uppercase tracking-widest text-muted">Bahasa Mekongga</p>
                <p className="mt-2 text-xl font-black text-ink">{exercise.target_text}</p>
                {exercise.target_translation ? (
                  <>
                    <p className="mt-4 text-[10px] font-black uppercase tracking-widest text-muted">Terjemahan</p>
                    <p className="mt-2 text-sm font-semibold text-muted">{exercise.target_translation}</p>
                  </>
                ) : null}
              </div>
              {exercise.prompt_text ? (
                <div className="prose prose-slate mt-4 max-w-none whitespace-pre-wrap rounded-2xl border-2 border-border bg-surface p-4 text-sm font-semibold leading-6 text-ink">
                  {exercise.prompt_text}
                </div>
              ) : null}
            </CardContent>
          </Card>

          <Card>
            <CardHeader><h2 className="text-xl font-black text-ink">Suara Asli (Contoh Audio)</h2></CardHeader>
            <CardContent>
              {exercise.reference_audio?.url ? (
                <AudioPlayer src={exercise.reference_audio.url} title={exercise.reference_audio.original_name ?? "Suara Asli"} />
              ) : (
                <div className="flex items-center gap-3 rounded-2xl border-2 border-dashed border-border bg-surface-muted p-5 text-sm font-bold text-muted">
                  <Mic className="size-5 shrink-0" strokeWidth={2.5} />
                  Belum ada audio contoh untuk target speaking ini.
                </div>
              )}
            </CardContent>
          </Card>
        </>
      ) : null}

      {!exerciseQuery.isLoading && !exerciseQuery.isError && !exercise ? <Alert tone="warning">Target speaking tidak ditemukan.</Alert> : null}
    </div>
  );
}
