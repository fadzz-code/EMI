"use client";

import { type FormEvent, useEffect, useMemo, useState } from "react";
import { Bot, CheckCheck, ListChecks, Mic, TriangleAlert, Volume2 } from "lucide-react";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, FormField, Input, LoadingState, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { ComparePlayer, referenceAudioUrl } from "@/features/student/speaking-result-hero";
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
  const [tab, setTab] = useState<"pending" | "reviewed">("pending");
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
        const initialAttempt = items.find((item) => item.status !== "reviewed" && item.teacher_score === null) ?? items[0] ?? null;
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

  const isReviewed = (attempt: TeacherSpeakingAttempt) => attempt.status === "reviewed" || attempt.teacher_score !== null;

  const filteredAttempts = useMemo(() => {
    const byTab = attempts.filter((attempt) => tab === "reviewed" ? isReviewed(attempt) : !isReviewed(attempt));
    const keyword = search.trim().toLowerCase();
    if (!keyword) return byTab;
    return byTab.filter((attempt) => [
      attempt.student?.full_name,
      attempt.student?.email,
      attempt.exercise?.title,
      attempt.target_text,
      attempt.status,
    ].filter(Boolean).join(" ").toLowerCase().includes(keyword));
  }, [attempts, search, tab]);

  const alignmentRows = (Array.isArray(selectedAttempt?.ai_alignment) ? [] : Object.entries(selectedAttempt?.ai_alignment ?? {}))
    .filter(([key, value]) => typeof value === "number" && /^\d+_/.test(key))
    .map(([key, value]) => {
      const word = key.replace(/^\d+_/, "");
      return { word, value: Math.round(value as number) };
    })
    .slice(0, 8);
  const reviewedCount = attempts.filter((attempt) => attempt.status === "reviewed" || attempt.teacher_score !== null).length;
  const pendingReviewCount = attempts.filter((attempt) => attempt.status === "completed" && attempt.teacher_score === null).length;
  const failedCount = attempts.filter((attempt) => attempt.status === "failed").length;

  return (
    <div className="grid gap-8">
      <section className="flex flex-col gap-2">
        <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">AI-assisted</p>
        <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">Hasil Speaking</h1>
        <p className="max-w-3xl text-base font-semibold leading-6 text-muted">Dengarkan audio siswa, baca skor awal AI, lalu simpan skor dan feedback guru sebagai tinjauan manual.</p>
      </section>
      {error ? <Alert tone="error">{error}</Alert> : null}
      {message ? <Alert tone="success">{message}</Alert> : null}
      <Alert tone="info">
        Analisis AI merupakan penilaian awal. Guru tetap menentukan nilai akhir.
      </Alert>

      <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {[
          { label: "Total", value: attempts.length, helper: "Percobaan yang masuk", icon: ListChecks },
          { label: "Siap Ditinjau", value: pendingReviewCount, helper: "Perlu feedback guru", icon: Bot },
          { label: "Ditinjau", value: reviewedCount, helper: "Sudah diberi skor guru", icon: CheckCheck },
          { label: "Analisis Gagal", value: failedCount, helper: "Perlu cek ulang", icon: TriangleAlert },
        ].map((stat) => (
          <Card className="group h-full transition hover:-translate-y-1 hover:shadow-emi" key={stat.label}>
            <CardContent className="flex h-full items-center gap-4">
              <span className="flex size-12 shrink-0 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-ink transition-colors group-hover:bg-primary group-hover:text-primary-foreground">
                <stat.icon className="size-6" strokeWidth={2.5} />
              </span>
              <div>
                <p className="text-sm font-black text-muted">{stat.label}</p>
                <p className="text-3xl font-black text-ink">{stat.value}</p>
                <p className="text-xs font-semibold text-muted">{stat.helper}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </section>

      <section className="grid gap-4 lg:grid-cols-[1fr_1.3fr]">
        <Card className="flex flex-col lg:h-[42rem]">
          <CardHeader>
            <div className="grid gap-3">
              <h2 className="text-xl font-black text-ink">Percobaan Siswa</h2>
              <div className="grid grid-cols-2 gap-2">
                {([
                  { key: "pending", label: `Perlu Ditinjau (${attempts.filter((attempt) => !isReviewed(attempt)).length})` },
                  { key: "reviewed", label: `Sudah Ditinjau (${attempts.filter(isReviewed).length})` },
                ] as const).map((item) => (
                  <button
                    className={`rounded-xl border-2 border-border px-3 py-2 text-sm font-black transition ${tab === item.key ? "bg-primary text-primary-foreground" : "bg-surface text-ink hover:bg-surface-muted"}`}
                    key={item.key}
                    onClick={() => setTab(item.key)}
                    type="button"
                  >
                    {item.label}
                  </button>
                ))}
              </div>
              <Input onChange={(event) => setSearch(event.target.value)} placeholder="Cari siswa, latihan, status..." value={search} />
            </div>
          </CardHeader>
          <CardContent className="flex min-h-0 flex-1 flex-col">
            {isLoading ? <LoadingState title="Memuat hasil speaking" /> : null}
            {!isLoading && filteredAttempts.length === 0 ? <EmptyState description={tab === "pending" ? "Tidak ada percobaan yang menunggu tinjauan. Percobaan baru akan muncul setelah siswa mengirim audio." : "Belum ada percobaan yang selesai ditinjau. Buka tab Perlu Ditinjau untuk memberi feedback."} title={tab === "pending" ? "Tidak ada yang perlu ditinjau" : "Belum ada yang ditinjau"} /> : null}
            <div className="grid max-h-[34rem] content-start gap-3 overflow-y-auto pr-1 lg:max-h-none lg:min-h-0 lg:flex-1">
              {filteredAttempts.map((attempt) => (
                <button key={attempt.id} className={`rounded-xl border-2 border-border p-4 text-left transition hover:-translate-y-0.5 hover:shadow-emi ${selectedAttempt?.id === attempt.id ? "bg-[var(--color-primary-muted)]" : "bg-surface hover:bg-surface-muted"}`} onClick={() => selectAttempt(attempt)} type="button">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-black text-ink">{attempt.student?.full_name ?? "Siswa"}</p>
                      <p className="mt-1 text-sm font-bold text-muted">{attempt.exercise?.title ?? "Latihan Speaking"}</p>
                      <p className="mt-1 text-xs text-muted">{date(attempt.created_at)}</p>
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

        <Card className="flex flex-col lg:h-[42rem]">
          <CardHeader><h2 className="text-xl font-black text-ink">Detail dan Feedback</h2></CardHeader>
          <CardContent className="min-h-0 flex-1 overflow-y-auto">
            {!selectedAttempt ? <EmptyState description="Pilih percobaan siswa untuk meninjau audio dan memberi feedback." title="Pilih percobaan" /> : (
              <div className="grid gap-4">
                <div className="rounded-xl border-2 border-border bg-[var(--color-primary-muted)] p-4">
                  <p className="text-xs font-black uppercase text-primary">Target teks</p>
                  <p className="mt-2 text-2xl font-black text-ink">{selectedAttempt.target_text}</p>
                  <p className="mt-2 text-sm text-muted">Siswa: {selectedAttempt.student?.full_name ?? "-"} | Status: {statusLabel(selectedAttempt.status)}</p>
                </div>
                <div className="grid gap-3 md:grid-cols-2">
                  <p className="rounded-xl border-2 border-border bg-surface-muted p-3 text-sm"><span className="font-black">Skor awal AI:</span> {score(selectedAttempt.ai_score)}</p>
                  <p className="rounded-xl border-2 border-border bg-surface-muted p-3 text-sm"><span className="font-black">Skor guru:</span> {score(selectedAttempt.teacher_score)}</p>
                </div>
                {selectedAttempt.ai_error ? <Alert tone="error">AI gagal menganalisis: {selectedAttempt.ai_error}</Alert> : null}
                <div className="grid gap-3 rounded-xl border-2 border-border bg-surface p-4">
                  <p className="text-xs font-black uppercase tracking-[0.12em] text-muted">Bandingkan Suara</p>
                  <ComparePlayer icon={Volume2} label="Penutur Asli" src={referenceAudioUrl(selectedAttempt.exercise)} />
                  <ComparePlayer icon={Mic} label="Suara Siswa" src={audioUrl} />
                  {!audioUrl ? <p className="text-xs font-bold text-muted">Audio siswa akan diputar setelah URL sementara tersedia untuk guru.</p> : null}
                </div>
                <div className="rounded-xl border-2 border-border bg-surface p-4">
                  <h3 className="font-black text-ink">Perbandingan ucapan</h3>
                  <p className="mt-1 text-xs font-semibold text-muted">Bandingkan hasil ucapan siswa yang dikenali AI dengan target teks per kata.</p>
                  <p className="mt-3 text-sm"><span className="font-black">Transkripsi AI:</span> {selectedAttempt.ai_transcription ?? "-"}</p>
                  {alignmentRows.length > 0 ? (
                    <div className="mt-3 flex flex-wrap gap-2">
                      {alignmentRows.map(({ word, value }) => (
                        <Badge key={word} tone={value >= 80 ? "blue" : value >= 50 ? "yellow" : "orange"}>
                          {word}: {value}%
                        </Badge>
                      ))}
                    </div>
                  ) : null}
                </div>
                <form className="grid gap-4" onSubmit={submitFeedback}>
                  <FormField label="Skor guru (0-100)"><Input max={100} min={0} onChange={(event) => setTeacherScore(event.target.value)} required type="number" value={teacherScore} /></FormField>
                  <p className="rounded-xl border border-border bg-surface-muted p-3 text-sm text-muted">
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
