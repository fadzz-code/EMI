"use client";

import { type FormEvent, useEffect, useMemo, useState } from "react";

import { Alert, AudioPlayer, Badge, Button, Card, CardContent, CardHeader, EmptyState, FormField, Input, LoadingState, PageHeader, StatsCard, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { teacherService } from "./teacher-service";
import type { TeacherSpeakingAttempt } from "./types";

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

export function TeacherSpeakingResults() {
  const { token } = useAuth();
  const [attempts, setAttempts] = useState<TeacherSpeakingAttempt[]>([]);
  const [selectedAttempt, setSelectedAttempt] = useState<TeacherSpeakingAttempt | null>(null);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [teacherScore, setTeacherScore] = useState("");
  const [teacherFeedback, setTeacherFeedback] = useState("");
  const [search, setSearch] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!token) return;
    let ignore = false;
    teacherService.speakingAttempts(token)
      .then((items) => {
        if (ignore) return;
        const initialAttempt = items[0] ?? null;
        setAttempts(items);
        setSelectedAttempt(initialAttempt);
        setTeacherScore(initialAttempt?.teacher_score?.toString() ?? "");
        setTeacherFeedback(initialAttempt?.teacher_feedback ?? "");
        setError(null);
      })
      .catch((err) => !ignore && setError(getFirstApiError(err)))
      .finally(() => !ignore && setIsLoading(false));
    return () => {
      ignore = true;
    };
  }, [token]);

  useEffect(() => {
    if (!token || !selectedAttempt?.audio_media_id) {
      return;
    }
    let ignore = false;
    teacherService.temporaryMediaUrl(token, selectedAttempt.audio_media_id)
      .then((url) => !ignore && setAudioUrl(url))
      .catch(() => !ignore && setAudioUrl(null));
    return () => {
      ignore = true;
      setAudioUrl(null);
    };
  }, [selectedAttempt?.audio_media_id, token]);

  async function selectAttempt(attempt: TeacherSpeakingAttempt) {
    if (!token) return;
    try {
      setAudioUrl(null);
      const detail = await teacherService.speakingAttemptDetail(token, attempt.id);
      setSelectedAttempt(detail);
      setTeacherScore(detail.teacher_score?.toString() ?? "");
      setTeacherFeedback(detail.teacher_feedback ?? "");
      setMessage(null);
    } catch (err) {
      setError(getFirstApiError(err));
    }
  }

  async function submitFeedback(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token || !selectedAttempt) return;
    setIsSubmitting(true);
    try {
      const updated = await teacherService.submitSpeakingFeedback(token, selectedAttempt.id, {
        teacher_score: Number(teacherScore),
        teacher_feedback: teacherFeedback.trim() || null,
      });
      setSelectedAttempt(updated);
      setAttempts((current) => current.map((item) => item.id === updated.id ? updated : item));
      setMessage("Feedback speaking berhasil disimpan.");
      setError(null);
    } catch (err) {
      setError(getFirstApiError(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  const filteredAttempts = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return attempts;
    return attempts.filter((attempt) => [
      attempt.student?.full_name,
      attempt.student?.email,
      attempt.exercise?.title,
      attempt.target_text,
      attempt.status,
    ].filter(Boolean).join(" ").toLowerCase().includes(keyword));
  }, [attempts, search]);

  const alignmentRows = Object.entries(selectedAttempt?.ai_alignment ?? {}).slice(0, 8);
  const reviewedCount = attempts.filter((attempt) => attempt.status === "reviewed" || attempt.teacher_score !== null).length;
  const pendingReviewCount = attempts.filter((attempt) => attempt.status === "completed" && attempt.teacher_score === null).length;
  const failedCount = attempts.filter((attempt) => attempt.status === "failed").length;

  return (
    <div className="grid gap-6">
      <PageHeader badge="AI-assisted" description="Dengarkan audio siswa, baca skor awal AI, lalu simpan skor dan feedback guru sebagai tinjauan manual." title="Hasil Speaking" />
      {error ? <Alert tone="error">{error}</Alert> : null}
      {message ? <Alert tone="success">{message}</Alert> : null}
      <Alert tone="info">
        Skor AI adalah bantuan awal. Keputusan pembelajaran tetap memakai tinjauan guru setelah mendengar audio siswa.
      </Alert>

      <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatsCard helper="Percobaan yang masuk" label="Total" value={String(attempts.length)} />
        <StatsCard helper="Perlu feedback guru" label="Siap Ditinjau" value={String(pendingReviewCount)} />
        <StatsCard helper="Sudah diberi skor guru" label="Ditinjau" value={String(reviewedCount)} />
        <StatsCard helper="Perlu cek ulang" label="Analisis Gagal" value={String(failedCount)} />
      </section>

      <section className="grid gap-4 lg:grid-cols-[1fr_1.3fr]">
        <Card>
          <CardHeader>
            <div className="grid gap-3">
              <h2 className="text-xl font-black text-ink">Percobaan Siswa</h2>
              <Input onChange={(event) => setSearch(event.target.value)} placeholder="Cari siswa, latihan, status..." value={search} />
            </div>
          </CardHeader>
          <CardContent>
            {isLoading ? <LoadingState title="Memuat hasil speaking" /> : null}
            {!isLoading && filteredAttempts.length === 0 ? <EmptyState description="Percobaan speaking siswa akan muncul setelah siswa mengirim audio." title="Belum ada hasil speaking" /> : null}
            <div className="grid gap-3">
              {filteredAttempts.map((attempt) => (
                <button key={attempt.id} className={`rounded-xl border-2 border-ink p-4 text-left shadow-brutal ${selectedAttempt?.id === attempt.id ? "bg-yellow-200" : "bg-white hover:bg-yellow-50"}`} onClick={() => selectAttempt(attempt)} type="button">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-black text-ink">{attempt.student?.full_name ?? "Siswa"}</p>
                      <p className="mt-1 text-sm font-bold text-slate-700">{attempt.exercise?.title ?? "Latihan Speaking"}</p>
                      <p className="mt-1 text-xs text-slate-500">{date(attempt.created_at)}</p>
                    </div>
                    <Badge tone={attempt.status === "failed" ? "orange" : attempt.status === "reviewed" ? "blue" : "yellow"}>{statusLabel(attempt.status)}</Badge>
                  </div>
                  <div className="mt-3 grid gap-2 text-sm md:grid-cols-2">
                    <span>Skor awal AI: <strong>{score(attempt.ai_score)}</strong></span>
                    <span>Skor guru: <strong>{score(attempt.teacher_score)}</strong></span>
                  </div>
                </button>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><h2 className="text-xl font-black text-ink">Detail dan Feedback</h2></CardHeader>
          <CardContent>
            {!selectedAttempt ? <EmptyState description="Pilih percobaan siswa untuk meninjau audio dan memberi feedback." title="Pilih percobaan" /> : (
              <div className="grid gap-4">
                <div className="rounded-xl border-2 border-ink bg-blue-50 p-4">
                  <p className="text-xs font-black uppercase text-blue-700">Target teks</p>
                  <p className="mt-2 text-2xl font-black text-ink">{selectedAttempt.target_text}</p>
                  <p className="mt-2 text-sm text-slate-700">Siswa: {selectedAttempt.student?.full_name ?? "-"} | Status: {statusLabel(selectedAttempt.status)}</p>
                </div>
                <div className="grid gap-3 md:grid-cols-2">
                  <p className="rounded-lg bg-slate-50 p-3 text-sm"><span className="font-black">Skor awal AI:</span> {score(selectedAttempt.ai_score)}</p>
                  <p className="rounded-lg bg-slate-50 p-3 text-sm"><span className="font-black">Skor guru:</span> {score(selectedAttempt.teacher_score)}</p>
                  <p className="rounded-lg bg-slate-50 p-3 text-sm md:col-span-2"><span className="font-black">Transkripsi AI:</span> {selectedAttempt.ai_transcription ?? "-"}</p>
                </div>
                {selectedAttempt.ai_error ? <Alert tone="error">AI gagal menganalisis: {selectedAttempt.ai_error}</Alert> : null}
                <AudioPlayer src={audioUrl ?? undefined} title="Audio asli siswa" />
                {!audioUrl ? <p className="text-sm font-bold text-muted">Audio private akan diputar setelah URL sementara tersedia untuk guru.</p> : null}
                {alignmentRows.length > 0 ? (
                  <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
                    <h3 className="font-black text-ink">Ringkasan alignment AI</h3>
                    <div className="mt-2 flex flex-wrap gap-2">
                      {alignmentRows.map(([key, value]) => <Badge key={key} tone={value >= 80 ? "blue" : "yellow"}>{key}: {value}</Badge>)}
                    </div>
                  </div>
                ) : null}
                <form className="grid gap-4" onSubmit={submitFeedback}>
                  <FormField label="Skor guru (0-100)"><Input max={100} min={0} onChange={(event) => setTeacherScore(event.target.value)} required type="number" value={teacherScore} /></FormField>
                  <p className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-sm text-muted">
                    Isi skor setelah mendengar audio siswa. Feedback akan tampil untuk siswa sebagai arahan latihan berikutnya.
                  </p>
                  <FormField label="Feedback guru"><Textarea className="min-h-32" onChange={(event) => setTeacherFeedback(event.target.value)} placeholder="Contoh: Pengucapan sudah cukup jelas, ulangi bagian akhir." value={teacherFeedback} /></FormField>
                  <Button disabled={isSubmitting} type="submit">{isSubmitting ? "Menyimpan..." : "Simpan Feedback Guru"}</Button>
                </form>
              </div>
            )}
          </CardContent>
        </Card>
      </section>
    </div>
  );
}
