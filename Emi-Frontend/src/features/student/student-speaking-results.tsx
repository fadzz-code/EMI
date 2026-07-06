"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { Bot, CheckCircle2, MessageSquareText, Mic } from "lucide-react";

import { Alert, Badge, Card, CardContent, EmptyState } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentService } from "./student-service";
import type { SpeakingAttempt } from "./types";

function statusLabel(status?: string) {
  return {
    pending: "Menunggu analisis",
    processing: "Diproses AI",
    completed: "Selesai dianalisis",
    failed: "Analisis gagal",
    reviewed: "Sudah ditinjau guru",
  }[status ?? ""] ?? "Status tidak dikenal";
}

function statusTone(status?: string): "yellow" | "blue" | "orange" {
  if (status === "failed") return "orange";
  if (status === "reviewed" || status === "completed") return "blue";
  return "yellow";
}

function score(value?: number | null) {
  return value === null || value === undefined ? "-" : `${value}/100`;
}

function scoreNumber(value?: number | null) {
  return value === null || value === undefined ? "-" : String(value);
}

function date(value?: string | null) {
  return value ? new Intl.DateTimeFormat("id-ID", { dateStyle: "medium", timeStyle: "short" }).format(new Date(value)) : "-";
}

export function StudentSpeakingResults() {
  const { token } = useAuth();
  const [attempts, setAttempts] = useState<SpeakingAttempt[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!token) return;
    let ignore = false;
    studentService.speakingAttempts(token)
      .then((items) => !ignore && setAttempts(items))
      .catch((err) => !ignore && setError(getFirstApiError(err)))
      .finally(() => !ignore && setIsLoading(false));
    return () => {
      ignore = true;
    };
  }, [token]);

  const reviewedCount = attempts.filter((attempt) => attempt.status === "reviewed").length;
  const latest = attempts[0];

  return (
    <div className="mx-auto grid max-w-5xl gap-6 pb-24 lg:pb-0">
      <section className="flex flex-col gap-2">
        <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">Hasil Speaking</p>
        <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">Lihat hasil latihanmu</h1>
        <p className="max-w-3xl text-sm font-semibold leading-6 text-muted">
          Skor AI adalah penilaian awal. Tinjauan guru tetap menjadi umpan balik utama untuk memperbaiki pelafalan.
        </p>
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

      {latest ? (
        <Card className="overflow-hidden bg-[var(--color-primary-muted)]">
          <CardContent>
            <div className="grid gap-6 lg:grid-cols-[0.8fr_1.2fr] lg:items-center">
              <div className="rounded-[var(--radius-card)] border-2 border-border bg-surface p-6 text-center shadow-[2px_2px_0_var(--border)]">
                <Badge tone={statusTone(latest.status)}>{statusLabel(latest.status)}</Badge>
                <p className="mt-4 text-[10px] font-black uppercase tracking-widest text-muted">Skor awal AI</p>
                <p className="mt-2 text-6xl font-black text-ink">{scoreNumber(latest.ai_score)}</p>
                <p className="text-sm font-black text-muted">/100</p>
                <p className="mt-4 text-sm font-bold leading-6 text-muted">{latest.exercise?.title ?? "Latihan Speaking"}</p>
                <p className="mt-1 text-lg font-black text-ink">{latest.target_text}</p>
              </div>

              <div className="grid gap-4">
                <div className="rounded-[var(--radius-card)] border-2 border-transparent bg-surface p-4">
                  <div className="mb-3 flex items-center gap-2">
                    <Bot className="size-5 text-primary" strokeWidth={3} />
                    <h2 className="font-black text-ink">Analisis AI</h2>
                  </div>
                  <p className="text-sm leading-6 text-muted"><span className="font-black text-ink">Skor awal AI:</span> {score(latest.ai_score)}</p>
                  <p className="mt-2 text-sm leading-6 text-muted"><span className="font-black text-ink">Transkripsi AI:</span> {latest.ai_transcription ?? "Belum tersedia"}</p>
                  {latest.ai_error ? <Alert tone="error">AI gagal menganalisis: {latest.ai_error}</Alert> : null}
                </div>

                <div className="rounded-[var(--radius-card)] border-2 border-border bg-surface p-4 shadow-[2px_2px_0_var(--border)]">
                  <div className="mb-3 flex items-center gap-2">
                    <CheckCircle2 className="size-5 text-primary" strokeWidth={3} />
                    <h2 className="font-black text-ink">Tinjauan Guru</h2>
                  </div>
                  <p className="text-sm leading-6 text-muted"><span className="font-black text-ink">Skor guru:</span> {score(latest.teacher_score)}</p>
                  {latest.teacher_feedback ? (
                    <p className="mt-2 text-sm leading-6 text-muted"><span className="font-black text-ink">Feedback:</span> {latest.teacher_feedback}</p>
                  ) : (
                    <p className="mt-2 rounded-xl bg-yellow-50 p-3 text-sm font-bold leading-6 text-muted">Menunggu tinjauan guru.</p>
                  )}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      ) : null}

      {attempts.length > 0 ? (
        <section className="grid gap-4 md:grid-cols-3">
          <div className="rounded-[var(--radius-card)] border-2 border-border bg-surface p-4 shadow-[2px_2px_0_var(--border)]"><p className="text-xs font-black uppercase text-muted">Percobaan</p><p className="mt-2 text-3xl font-black text-ink">{attempts.length}</p></div>
          <div className="rounded-[var(--radius-card)] border-2 border-transparent bg-surface-muted p-4"><p className="text-xs font-black uppercase text-muted">Sudah direview</p><p className="mt-2 text-3xl font-black text-ink">{reviewedCount}</p></div>
          <div className="rounded-[var(--radius-card)] border-2 border-transparent bg-surface-muted p-4"><p className="text-xs font-black uppercase text-muted">Skor terbaru</p><p className="mt-2 text-3xl font-black text-ink">{score(latest?.ai_score)}</p></div>
        </section>
      ) : null}

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
                    <Badge tone={statusTone(attempt.status)}>{statusLabel(attempt.status)}</Badge>
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
