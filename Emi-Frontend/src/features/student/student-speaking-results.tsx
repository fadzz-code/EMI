"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { ArrowLeft, MessageSquareText, Mic } from "lucide-react";

import { Alert, Badge, Card, CardContent, EmptyState } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { latestSpeakingAttempt } from "./speaking-result";
import { referenceAudioUrl, SpeakingResultHero, speakingStatusLabel, speakingStatusTone } from "./speaking-result-hero";
import { studentService } from "./student-service";
import type { SpeakingAttempt, SpeakingExercise } from "./types";

function score(value?: number | null) {
  return value === null || value === undefined ? "-" : `${value}/100`;
}

function date(value?: string | null) {
  return value ? new Intl.DateTimeFormat("id-ID", { dateStyle: "medium", timeStyle: "short" }).format(new Date(value)) : "-";
}

export function StudentSpeakingResults() {
  const { token } = useAuth();
  const [attempts, setAttempts] = useState<SpeakingAttempt[]>([]);
  const [exercises, setExercises] = useState<SpeakingExercise[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!token) return;
    let ignore = false;
    Promise.all([
      studentService.speakingAttempts(token),
      studentService.speakingExercises(token).catch(() => [] as SpeakingExercise[]),
    ])
      .then(([items, exerciseItems]) => {
        if (ignore) return;
        setAttempts(items);
        setExercises(exerciseItems);
      })
      .catch((err) => !ignore && setError(getFirstApiError(err)))
      .finally(() => !ignore && setIsLoading(false));
    return () => {
      ignore = true;
    };
  }, [token]);

  const latest = latestSpeakingAttempt(attempts);
  const latestExercise = latest ? (latest.exercise ?? exercises.find((exercise) => exercise.id === latest.exercise_id) ?? null) : null;

  return (
    <div className="mx-auto grid max-w-6xl gap-8 pb-24 lg:pb-0">
      <section className="flex flex-wrap items-start justify-between gap-4">
        <div className="flex flex-col gap-2">
          <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">Hasil Evaluasi</p>
          <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">Mari kita lihat bagaimana pelafalanmu.</h1>
        </div>
        <Link className="inline-flex min-h-11 items-center gap-2 rounded-xl border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink shadow-[2px_2px_0_var(--border)] transition hover:-translate-y-0.5 hover:bg-accent/30" href="/student/speaking">
          <ArrowLeft className="size-4" strokeWidth={3} />Kembali
        </Link>
      </section>

      {error ? <Alert tone="error">{error}</Alert> : null}
      {isLoading ? <p className="text-sm font-bold text-muted">Memuat hasil speaking...</p> : null}

      {!isLoading && attempts.length === 0 ? (
        <Card>
          <CardContent>
            <EmptyState description="Kirim latihan speaking pertama Anda untuk melihat hasil di sini." title="Belum ada hasil speaking." />
            <Link className="mt-5 inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi hover:-translate-y-0.5" href="/student/speaking">Mulai Latihan Speaking</Link>
          </CardContent>
        </Card>
      ) : null}

      {latest ? <SpeakingResultHero attempt={latest} referenceAudioUrl={referenceAudioUrl(latestExercise)} /> : null}

      {attempts.length > 0 ? (
        <Card>
          <CardContent>
            <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
              <div>
                <h2 className="text-xl font-black text-ink">Riwayat percobaan</h2>
                <p className="mt-1 text-sm font-semibold text-muted">Semua skor awal AI dan tinjauan guru.</p>
              </div>
              <Link className="inline-flex min-h-11 items-center justify-center rounded-xl border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink shadow-[2px_2px_0_var(--border)] hover:bg-accent/30" href="/student/speaking">Latihan lagi</Link>
            </div>
            <div className="grid gap-3">
              {attempts.map((attempt) => (
                <div key={attempt.id} className="rounded-xl border-2 border-transparent bg-surface-muted p-4 transition-colors hover:border-border hover:shadow-[2px_2px_0_var(--border)]">
                  <div className="flex flex-wrap items-start justify-between gap-3">
                    <div>
                      <div className="flex items-center gap-2">
                        <Mic className="size-4 text-primary" strokeWidth={3} />
                        <h3 className="text-lg font-black text-ink">{attempt.exercise?.title ?? "Latihan Speaking"}</h3>
                      </div>
                      <p className="mt-1 text-sm font-bold text-muted">{attempt.target_text}</p>
                      <p className="mt-1 text-xs font-bold text-muted">Dikirim: {date(attempt.created_at)}</p>
                    </div>
                    <Badge tone={speakingStatusTone(attempt.status)}>{speakingStatusLabel(attempt.status)}</Badge>
                  </div>
                  <div className="mt-4 grid gap-3 md:grid-cols-3">
                    <p className="rounded-lg bg-surface p-3 text-sm"><span className="font-black">Skor awal AI:</span> {score(attempt.ai_score)}</p>
                    <p className="rounded-lg bg-surface p-3 text-sm"><span className="font-black">Skor guru:</span> {score(attempt.teacher_score)}</p>
                    <p className="rounded-lg bg-surface p-3 text-sm"><span className="font-black">Transkripsi AI:</span> {attempt.ai_transcription ?? "-"}</p>
                  </div>
                  <div className="mt-3 flex items-start gap-2 text-sm font-bold text-muted">
                    <MessageSquareText className="mt-0.5 size-4 shrink-0 text-primary" strokeWidth={3} />
                    <p>{attempt.teacher_feedback ? `Feedback guru: ${attempt.teacher_feedback}` : "Menunggu tinjauan guru."}</p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      ) : null}
    </div>
  );
}
