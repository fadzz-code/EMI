"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

import { Alert, Badge, Card, CardContent, EmptyState, PageHeader, StatsCard } from "@/components/ui";
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

function score(value?: number | null) {
  return value === null || value === undefined ? "-" : `${value}/100`;
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
    <div className="grid gap-6">
      <PageHeader badge="AI-assisted" description="Riwayat skor awal AI, transkripsi AI, dan feedback guru." title="Hasil Speaking" />
      {error ? <Alert tone="error">{error}</Alert> : null}

      <section className="grid gap-4 md:grid-cols-3">
        <StatsCard helper="Total audio yang pernah dikirim" label="Percobaan" value={String(attempts.length)} />
        <StatsCard helper="Percobaan yang sudah ditinjau guru" label="Sudah Direview" value={String(reviewedCount)} />
        <StatsCard helper="Skor awal AI percobaan terbaru" label="Skor Awal AI" value={score(latest?.ai_score)} />
      </section>

      <Card>
        <CardContent>
          {isLoading ? <p className="text-sm font-bold text-slate-600">Memuat hasil speaking...</p> : null}
          {!isLoading && attempts.length === 0 ? <EmptyState description="Kirim latihan speaking pertama Anda untuk melihat hasil di sini." title="Belum ada hasil speaking." /> : null}
          <div className="grid gap-3">
            {attempts.map((attempt) => (
              <div key={attempt.id} className="rounded-xl border-2 border-ink bg-white p-4 shadow-brutal">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <h2 className="text-lg font-black text-ink">{attempt.exercise?.title ?? "Latihan Speaking"}</h2>
                    <p className="mt-1 text-sm font-bold text-slate-700">{attempt.target_text}</p>
                    <p className="mt-1 text-xs text-slate-500">Dikirim: {date(attempt.created_at)}</p>
                  </div>
                  <Badge tone={attempt.status === "failed" ? "orange" : attempt.status === "reviewed" ? "blue" : "yellow"}>{statusLabel(attempt.status)}</Badge>
                </div>
                <div className="mt-4 grid gap-3 md:grid-cols-3">
                  <p className="rounded-lg bg-slate-50 p-3 text-sm"><span className="font-black">Skor awal AI:</span> {score(attempt.ai_score)}</p>
                  <p className="rounded-lg bg-slate-50 p-3 text-sm"><span className="font-black">Skor guru:</span> {score(attempt.teacher_score)}</p>
                  <p className="rounded-lg bg-slate-50 p-3 text-sm"><span className="font-black">Transkripsi AI:</span> {attempt.ai_transcription ?? "-"}</p>
                </div>
                {attempt.teacher_feedback ? <Alert tone="success">Feedback guru: {attempt.teacher_feedback}</Alert> : <p className="mt-3 text-sm font-bold text-slate-600">Menunggu tinjauan guru.</p>}
              </div>
            ))}
          </div>
          <Link className="mt-5 inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-ink bg-white px-4 py-2 text-sm font-black text-ink shadow-brutal hover:bg-yellow-100" href="/student/speaking">Kembali ke Latihan Speaking</Link>
        </CardContent>
      </Card>
    </div>
  );
}
