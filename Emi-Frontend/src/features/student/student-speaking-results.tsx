"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { ArrowLeft, MessageSquareText, Mic, Trash2, UploadCloud } from "lucide-react";

import { Alert, Badge, Button, Card, CardContent, ConfirmDialog, EmptyState, Pagination } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { ComparePlayer, referenceAudioUrl, SpeakingResultHero, speakingStatusTone } from "./speaking-result-hero";
import { studentService } from "./student-service";
import type { SpeakingAttempt, SpeakingExercise } from "./types";

function score(value?: number | null) {
  return value === null || value === undefined ? "-" : `${value}/100`;
}

function date(value?: string | null) {
  return value ? new Intl.DateTimeFormat("id-ID", { dateStyle: "medium", timeStyle: "short" }).format(new Date(value)) : "-";
}

function state(attempt: SpeakingAttempt) {
  if (attempt.review_status === "reviewed" || attempt.status === "reviewed") return { label: "Ditinjau", tone: "blue" as const };
  if (attempt.submitted_at) return { label: "Dikirim", tone: "yellow" as const };
  return { label: "Latihan privat", tone: speakingStatusTone(attempt.status) };
}

export function StudentSpeakingResults() {
  const { token } = useAuth();
  const [attempts, setAttempts] = useState<SpeakingAttempt[]>([]);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [exercises, setExercises] = useState<SpeakingExercise[]>([]);
  const [selected, setSelected] = useState<SpeakingAttempt | null>(null);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [confirm, setConfirm] = useState<{ action: "submit" | "delete" | "bulk"; attempt?: SpeakingAttempt; exerciseId?: string } | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isMutating, setIsMutating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!token) return;
    const [result, exerciseItems] = await Promise.all([studentService.speakingAttempts(token, page), studentService.speakingExercises(token).catch(() => [] as SpeakingExercise[])]);
    setAttempts(result.items);
    setTotalPages(result.meta?.last_page ?? 1);
    setExercises(exerciseItems);
  }, [page, token]);

  useEffect(() => {
    let ignore = false;
    void Promise.resolve().then(load).catch((err) => !ignore && setError(getFirstApiError(err))).finally(() => !ignore && setIsLoading(false));
    return () => { ignore = true; };
  }, [load]);

  async function selectAttempt(attempt: SpeakingAttempt) {
    if (!token) return;
    try {
      setAudioUrl(null);
      const detail = await studentService.speakingAttemptDetail(token, attempt.id);
      setSelected(detail);
      if (detail.audio_media_id) {
        try {
          setAudioUrl(await studentService.temporaryMediaUrl(token, detail.audio_media_id));
        } catch {
          setError("Audio riwayat belum dapat diputar. Detail hasil tetap tersedia.");
        }
      }
    } catch (err) { setError(getFirstApiError(err)); }
  }

  async function mutate() {
    if (!token || !confirm) return;
    setIsMutating(true);
    try {
      if (confirm.action === "submit" && confirm.attempt) await studentService.submitSpeakingResult(token, confirm.attempt.id);
      if (confirm.action === "delete" && confirm.attempt) await studentService.deleteSpeakingAttempt(token, confirm.attempt.id);
      if (confirm.action === "bulk" && confirm.exerciseId) await studentService.deletePrivateSpeakingHistory(token, confirm.exerciseId);
      setSelected(null);
      setAudioUrl(null);
      setConfirm(null);
      await load();
      setError(null);
    } catch (err) { setError(getFirstApiError(err)); } finally { setIsMutating(false); }
  }

  const latest = attempts[0];
  const latestExercise = latest ? (latest.exercise ?? exercises.find((exercise) => exercise.id === latest.exercise_id) ?? null) : null;

  return <div className="mx-auto grid max-w-6xl gap-8 pb-24 lg:pb-0">
    <section className="flex flex-wrap items-start justify-between gap-4"><div><p className="text-sm font-black uppercase tracking-[0.08em] text-muted">Hasil Evaluasi</p><h1 className="mt-2 text-3xl font-black text-ink md:text-4xl">Mari kita lihat bagaimana pelafalanmu.</h1></div><Link className="inline-flex min-h-11 items-center gap-2 rounded-xl border-2 border-border bg-surface px-4 py-2 text-sm font-black" href="/student/speaking"><ArrowLeft className="size-4" />Kembali</Link></section>
    {error ? <Alert tone="error">{error}</Alert> : null}
    {isLoading ? <p className="text-sm font-bold text-muted">Memuat hasil speaking...</p> : null}
    {!isLoading && attempts.length === 0 ? <Card><CardContent><EmptyState description="Buat latihan speaking pertama untuk melihat hasil di sini." title="Belum ada hasil speaking." /></CardContent></Card> : null}
    {latest ? <SpeakingResultHero attempt={latest} referenceAudioUrl={referenceAudioUrl(latestExercise)} /> : null}
    {selected ? <Card><CardContent><div className="grid gap-4"><div className="flex items-start justify-between gap-3"><div><h2 className="text-xl font-black">Detail percobaan</h2><p className="text-sm font-bold text-muted">{selected.target_text}</p></div><Badge tone={state(selected).tone}>{state(selected).label}</Badge></div><ComparePlayer icon={Mic} label="Rekaman Kamu" src={audioUrl} /><SpeakingResultHero attempt={selected} referenceAudioUrl={referenceAudioUrl(selected.exercise)} /></div></CardContent></Card> : null}
    {attempts.length ? <Card><CardContent><div className="mb-4"><h2 className="text-xl font-black">Riwayat percobaan</h2><p className="text-sm font-semibold text-muted">Latihan privat hanya terlihat olehmu. Kirim satu hasil selesai agar dapat ditinjau guru.</p></div><div className="grid gap-3">{attempts.map((attempt) => <div key={attempt.id} className="rounded-xl bg-surface-muted p-4"><div className="flex flex-wrap items-start justify-between gap-3"><button className="text-left" onClick={() => selectAttempt(attempt)} type="button"><span className="flex items-center gap-2 text-lg font-black"><Mic className="size-4 text-primary" />{attempt.exercise?.title ?? "Latihan Speaking"}</span><span className="mt-1 block text-xs font-bold text-muted">{attempt.submitted_at ? `Dikirim: ${date(attempt.submitted_at)}` : `Dibuat: ${date(attempt.created_at)}`}</span></button><Badge tone={state(attempt).tone}>{state(attempt).label}</Badge></div><div className="mt-3 grid gap-2 md:grid-cols-3"><p>Skor AI: <strong>{score(attempt.ai_score)}</strong></p><p>Skor guru: <strong>{score(attempt.teacher_score)}</strong></p><p className="flex gap-2"><MessageSquareText className="size-4" />{attempt.teacher_feedback ?? "Belum ada feedback."}</p></div><div className="mt-3 flex flex-wrap gap-2">{!attempt.submitted_at && attempt.analysis_status === "completed" ? <Button onClick={() => setConfirm({ action: "submit", attempt })} type="button"><UploadCloud className="mr-2 size-4" />Kirim ke guru</Button> : null}{!attempt.submitted_at ? <Button onClick={() => setConfirm({ action: "delete", attempt })} type="button" variant="danger"><Trash2 className="mr-2 size-4" />Hapus privat</Button> : null}{!attempt.submitted_at && attempts.filter((item) => item.exercise_id === attempt.exercise_id && !item.submitted_at).length > 1 ? <Button onClick={() => setConfirm({ action: "bulk", exerciseId: attempt.exercise_id })} type="button" variant="secondary">Hapus semua riwayat privat latihan ini</Button> : null}</div></div>)}</div>{totalPages > 1 ? <div className="mt-4"><Pagination onPageChange={setPage} page={page} totalPages={totalPages} /></div> : null}</CardContent></Card> : null}
    <ConfirmDialog description={confirm?.action === "submit" ? "Hasil ini akan dikirim ke guru. Jika sudah ada kiriman yang belum ditinjau, kiriman lama akan diganti dan dihapus." : confirm?.action === "bulk" ? "Semua percobaan privat latihan ini akan dihapus permanen." : "Percobaan privat ini akan dihapus permanen."} isConfirming={isMutating} onCancel={() => setConfirm(null)} onConfirm={mutate} open={Boolean(confirm)} title={confirm?.action === "submit" ? "Kirim hasil speaking?" : "Hapus riwayat speaking?"} />
  </div>;
}
