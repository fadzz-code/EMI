"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentService } from "./student-service";
import type { SpeakingAttempt, SpeakingExercise } from "./types";

const terminalStatuses = new Set(["completed", "failed", "reviewed"]);

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

export function StudentSpeaking() {
  const { token } = useAuth();
  const [exercises, setExercises] = useState<SpeakingExercise[]>([]);
  const [selectedExercise, setSelectedExercise] = useState<SpeakingExercise | null>(null);
  const [activeAttempt, setActiveAttempt] = useState<SpeakingAttempt | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRecording, setIsRecording] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [recordedFile, setRecordedFile] = useState<File | null>(null);
  const [recordedUrl, setRecordedUrl] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);

  useEffect(() => {
    if (!token) return;
    let ignore = false;
    studentService.speakingExercises(token)
      .then((items) => {
        if (ignore) return;
        setExercises(items);
        setSelectedExercise(items[0] ?? null);
      })
      .catch((err) => !ignore && setError(getFirstApiError(err)))
      .finally(() => !ignore && setIsLoading(false));
    return () => {
      ignore = true;
    };
  }, [token]);

  useEffect(() => {
    if (!token || !activeAttempt || terminalStatuses.has(activeAttempt.status)) return;
    const interval = window.setInterval(async () => {
      try {
        const detail = await studentService.speakingAttemptDetail(token, activeAttempt.id);
        setActiveAttempt(detail);
      } catch (err) {
        setError(getFirstApiError(err));
      }
    }, 2500);
    return () => window.clearInterval(interval);
  }, [activeAttempt, token]);

  useEffect(() => () => {
    if (recordedUrl) URL.revokeObjectURL(recordedUrl);
  }, [recordedUrl]);

  async function startRecording() {
    setError(null);
    if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === "undefined") {
      setError("Browser belum mendukung perekaman audio. Gunakan browser terbaru atau unggah dari perangkat lain.");
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mimeType = MediaRecorder.isTypeSupported("audio/webm") ? "audio/webm" : "";
      const recorder = new MediaRecorder(stream, mimeType ? { mimeType } : undefined);
      chunksRef.current = [];
      recorder.ondataavailable = (event) => {
        if (event.data.size > 0) chunksRef.current.push(event.data);
      };
      recorder.onstop = () => {
        const blob = new Blob(chunksRef.current, { type: recorder.mimeType || "audio/webm" });
        const file = new File([blob], `speaking-${Date.now()}.webm`, { type: blob.type || "audio/webm" });
        if (recordedUrl) URL.revokeObjectURL(recordedUrl);
        setRecordedFile(file);
        setRecordedUrl(URL.createObjectURL(blob));
        stream.getTracks().forEach((track) => track.stop());
      };
      mediaRecorderRef.current = recorder;
      recorder.start();
      setIsRecording(true);
    } catch {
      setError("Tidak dapat mengakses mikrofon. Periksa izin browser lalu coba lagi.");
    }
  }

  function stopRecording() {
    mediaRecorderRef.current?.stop();
    setIsRecording(false);
  }

  async function submitAttempt() {
    if (!token || !selectedExercise || !recordedFile) return;
    setIsSubmitting(true);
    setError(null);
    try {
      const attempt = await studentService.submitSpeakingAttempt(token, selectedExercise.id, recordedFile);
      setActiveAttempt(attempt);
    } catch (err) {
      setError(getFirstApiError(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="grid gap-6">
      <PageHeader badge="AI-assisted" description="Latih pelafalan Bahasa Mekongga dengan skor awal AI dan tinjauan guru." title="Latihan Speaking" />
      {error ? <Alert tone="error">{error}</Alert> : null}

      <section className="grid gap-4 lg:grid-cols-[1fr_1.2fr]">
        <Card>
          <CardHeader><h2 className="text-xl font-black text-ink">Pilih Latihan</h2></CardHeader>
          <CardContent>
            {isLoading ? <p className="text-sm font-bold text-slate-600">Memuat latihan...</p> : null}
            {!isLoading && exercises.length === 0 ? <EmptyState title="Belum ada latihan speaking" description="Latihan yang dipublish guru akan muncul di sini." /> : null}
            <div className="grid gap-3">
              {exercises.map((exercise) => (
                <button key={exercise.id} className={`rounded-xl border-2 border-ink p-4 text-left shadow-brutal ${selectedExercise?.id === exercise.id ? "bg-yellow-200" : "bg-white hover:bg-yellow-50"}`} onClick={() => setSelectedExercise(exercise)} type="button">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-black text-ink">{exercise.title}</p>
                      <p className="mt-1 text-sm font-bold text-slate-700">{exercise.target_text}</p>
                      {exercise.target_translation ? <p className="mt-1 text-xs text-slate-500">{exercise.target_translation}</p> : null}
                    </div>
                    <Badge tone="blue">{exercise.difficulty ?? "Latihan"}</Badge>
                  </div>
                </button>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><h2 className="text-xl font-black text-ink">Rekam dan Kirim</h2></CardHeader>
          <CardContent>
            {selectedExercise ? (
              <div className="grid gap-4">
                <div className="rounded-xl border-2 border-ink bg-blue-50 p-4">
                  <p className="text-xs font-black uppercase text-blue-700">Target bacaan</p>
                  <p className="mt-2 text-2xl font-black text-ink">{selectedExercise.target_text}</p>
                  {selectedExercise.prompt_text ? <p className="mt-2 text-sm text-slate-700">{selectedExercise.prompt_text}</p> : null}
                </div>
                <div className="flex flex-wrap gap-3">
                  <Button disabled={isRecording} onClick={startRecording} type="button">Mulai Rekam</Button>
                  <Button disabled={!isRecording} onClick={stopRecording} type="button" variant="secondary">Stop Rekam</Button>
                  <Button disabled={!recordedFile || isSubmitting || isRecording} onClick={submitAttempt} type="button" variant="secondary">{isSubmitting ? "Mengirim..." : "Kirim Audio"}</Button>
                </div>
                {recordedUrl ? <audio className="w-full" controls src={recordedUrl} /> : null}
                <Alert tone="info">Analisis AI sedang diproses. Pastikan queue worker berjalan pada mode database queue.</Alert>
              </div>
            ) : <EmptyState title="Pilih latihan dahulu" description="Pilih salah satu target bacaan untuk mulai merekam." />}
          </CardContent>
        </Card>
      </section>

      {activeAttempt ? (
        <Card>
          <CardHeader>
            <div className="flex flex-wrap items-center justify-between gap-3">
              <h2 className="text-xl font-black text-ink">Hasil Percobaan Terakhir</h2>
              <Badge tone={activeAttempt.status === "failed" ? "orange" : activeAttempt.status === "reviewed" ? "blue" : "yellow"}>{statusLabel(activeAttempt.status)}</Badge>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid gap-3 md:grid-cols-2">
              <div className="rounded-xl border border-slate-200 bg-slate-50 p-4"><p className="text-xs font-black uppercase text-slate-500">Skor awal AI</p><p className="mt-1 text-2xl font-black text-ink">{score(activeAttempt.ai_score)}</p></div>
              <div className="rounded-xl border border-slate-200 bg-slate-50 p-4"><p className="text-xs font-black uppercase text-slate-500">Skor guru</p><p className="mt-1 text-2xl font-black text-ink">{score(activeAttempt.teacher_score)}</p></div>
            </div>
            {activeAttempt.ai_transcription ? <p className="mt-4 text-sm leading-6"><span className="font-black">Transkripsi AI:</span> {activeAttempt.ai_transcription}</p> : null}
            {activeAttempt.ai_error ? <Alert tone="error">AI gagal menganalisis: {activeAttempt.ai_error}</Alert> : null}
            {activeAttempt.teacher_feedback ? <Alert tone="success">Feedback guru: {activeAttempt.teacher_feedback}</Alert> : <p className="mt-4 text-sm font-bold text-slate-600">Menunggu tinjauan guru.</p>}
          </CardContent>
        </Card>
      ) : null}

      <Card>
        <CardContent>
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div><h2 className="text-xl font-black text-ink">Riwayat latihan speaking</h2><p className="mt-2 text-sm text-slate-600">Lihat status, skor awal AI, dan feedback guru dari percobaan sebelumnya.</p></div>
            <Link className="inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-ink bg-blue-600 px-4 py-2 text-sm font-black text-white shadow-brutal hover:bg-blue-700" href="/student/speaking/results">Lihat Hasil Speaking</Link>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
