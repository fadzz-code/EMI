"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { Cable, LoaderCircle, Mic, Play, Square, UploadCloud } from "lucide-react";

import { Alert, Badge, Button, Card, CardContent, EmptyState } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { ApiError, getFirstApiError } from "@/lib/api-client";
import { cn } from "@/lib/utils";

import { studentService } from "./student-service";
import { useEsp32SerialCapture } from "./use-esp32-serial-capture";
import type { SpeakingAttempt, SpeakingExercise } from "./types";
import { createSpeakingPoller, SPEAKING_TERMINAL_STATUSES } from "./speaking-poller";
import { shouldUseMicrophone, studentAiWarnings } from "./speaking-result";

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

function speakingErrorMessage(error: unknown) {
  const message = getFirstApiError(error);

  if (message === "validation.mimetypes" || (error instanceof ApiError && error.status === 422 && message.toLowerCase().includes("format audio"))) {
    return "Format audio tidak didukung. Coba rekam ulang atau gunakan browser terbaru.";
  }

  return message;
}

function statusTone(status?: string): "yellow" | "blue" | "orange" {
  if (status === "failed") return "orange";
  if (status === "reviewed" || status === "completed") return "blue";
  return "yellow";
}

function referenceAudioUrl(exercise: SpeakingExercise | null) {
  return exercise?.reference_audio?.url
    ?? exercise?.reference_audio?.content_url
    ?? exercise?.reference_audio?.public_url
    ?? exercise?.reference_audio?.file_url
    ?? null;
}

function referenceAudioName(exercise: SpeakingExercise | null) {
  return exercise?.reference_audio?.original_name ?? exercise?.reference_audio?.file_name ?? exercise?.reference_audio?.name ?? "Audio contoh";
}

export function StudentSpeaking() {
  const { token } = useAuth();
  const [exercises, setExercises] = useState<SpeakingExercise[]>([]);
  const [selectedExercise, setSelectedExercise] = useState<SpeakingExercise | null>(null);
  const [activeAttempt, setActiveAttempt] = useState<SpeakingAttempt | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRecording, setIsRecording] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [captureSource, setCaptureSource] = useState<"microphone" | "esp32">("microphone");
  const [recordedFile, setRecordedFile] = useState<File | null>(null);
  const [recordedUrl, setRecordedUrl] = useState<string | null>(null);
  const [referenceAudioError, setReferenceAudioError] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const mediaStreamRef = useRef<MediaStream | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const submitGuardRef = useRef(false);
  const esp32 = useEsp32SerialCapture();

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
    if (!token || !activeAttempt || SPEAKING_TERMINAL_STATUSES.has(activeAttempt.status)) return;
    const poller = createSpeakingPoller({
      attempt: activeAttempt,
      fetch: (id) => studentService.speakingAttemptDetail(token, id),
      update: setActiveAttempt,
      fail: setError,
    });
    return poller.stop;
  }, [activeAttempt, token]);

  useEffect(() => () => {
    if (mediaRecorderRef.current?.state === "recording") mediaRecorderRef.current.stop();
    mediaStreamRef.current?.getTracks().forEach((track) => track.stop());
  }, []);

  useEffect(() => () => {
    if (recordedUrl) URL.revokeObjectURL(recordedUrl);
  }, [recordedUrl]);

  async function startRecording() {
    if (!shouldUseMicrophone(captureSource)) return;
    setError(null);
    if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === "undefined") {
      setError("Browser belum mendukung perekaman audio. Gunakan browser terbaru atau unggah dari perangkat lain.");
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      mediaStreamRef.current = stream;
      const mimeType = MediaRecorder.isTypeSupported("audio/webm") ? "audio/webm" : "";
      const recorder = new MediaRecorder(stream, mimeType ? { mimeType } : undefined);
      chunksRef.current = [];
      recorder.ondataavailable = (event) => {
        if (event.data.size > 0) chunksRef.current.push(event.data);
      };
      recorder.onstop = () => {
        const blobType = recorder.mimeType || "audio/webm";
        const blob = new Blob(chunksRef.current, { type: blobType });
        const fileType = blobType.startsWith("audio/") ? blobType : "audio/webm";
        const file = new File([blob], "speaking-attempt.webm", { type: fileType });
        if (recordedUrl) URL.revokeObjectURL(recordedUrl);
        setRecordedFile(file);
        setRecordedUrl(URL.createObjectURL(blob));
        stream.getTracks().forEach((track) => track.stop());
        mediaStreamRef.current = null;
        mediaRecorderRef.current = null;
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

  async function selectCaptureSource(source: "microphone" | "esp32") {
    if (isRecording || isSubmitting || esp32.state === "recording" || esp32.state === "finalizing") return;
    if (source === "microphone") await esp32.disconnect();
    setCaptureSource(source);
  }

  async function submitAttempt() {
    const file = captureSource === "esp32" ? esp32.capture?.file : recordedFile;
    if (!token || !selectedExercise || !file || submitGuardRef.current) return;
    submitGuardRef.current = true;
    setIsSubmitting(true);
    setError(null);
    try {
      const attempt = await studentService.submitSpeakingAttempt(token, selectedExercise.id, file, captureSource === "esp32" ? "web_esp32_serial" : "web_microphone", captureSource === "esp32" ? esp32.capture?.duration : undefined);
      setActiveAttempt(attempt);
    } catch (err) {
      setError(speakingErrorMessage(err));
    } finally {
      submitGuardRef.current = false;
      setIsSubmitting(false);
    }
  }

  return (
    <div className="mx-auto grid max-w-5xl gap-8 pb-24 lg:pb-0">
      <section className="flex flex-col gap-2">
        <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">Latihan Speaking</p>
        <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">Latih pelafalan Mekongga</h1>
        <p className="max-w-3xl text-sm font-semibold leading-6 text-muted">
          Rekam bacaanmu, kirim ke EMI, lalu lihat skor awal AI dan tinjauan guru saat tersedia.
        </p>
      </section>

      {error ? <Alert tone="error">{error}</Alert> : null}

      <section className="grid gap-6 lg:grid-cols-[0.8fr_1.2fr]">
        <Card className="h-fit">
          <CardContent>
            <div className="mb-4 flex items-center justify-between gap-3">
              <div>
                <h2 className="text-xl font-black text-ink">Pilih latihan</h2>
                <p className="mt-1 text-sm font-semibold text-muted">Target bacaan dari guru.</p>
              </div>
              <Badge tone="yellow">AI-assisted</Badge>
            </div>
            {isLoading ? <p className="text-sm font-bold text-muted">Memuat latihan...</p> : null}
            {!isLoading && exercises.length === 0 ? <EmptyState title="Belum ada latihan speaking" description="Latihan yang dipublish guru akan muncul di sini." /> : null}
            <div className="grid gap-3">
              {exercises.map((exercise) => (
                <button
                  key={exercise.id}
                  className={cn(
                    "rounded-[var(--radius-card)] border-2 p-4 text-left transition-all",
                    selectedExercise?.id === exercise.id
                      ? "border-border bg-accent text-accent-foreground shadow-[2px_2px_0_var(--border)]"
                      : "border-transparent bg-surface-muted text-ink hover:border-border hover:shadow-[2px_2px_0_var(--border)]",
                  )}
                  onClick={() => {
                    setSelectedExercise(exercise);
                    setReferenceAudioError(false);
                  }}
                  type="button"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-black">{exercise.title}</p>
                      <p className="mt-1 text-sm font-bold">{exercise.target_text}</p>
                      {exercise.target_translation ? <p className="mt-1 text-xs opacity-80">{exercise.target_translation}</p> : null}
                    </div>
                    <Badge tone="yellow">{exercise.difficulty ?? "Latihan"}</Badge>
                  </div>
                </button>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card className="overflow-hidden bg-[var(--color-primary-muted)]">
          <CardContent>
            {selectedExercise ? (
              <div className="grid gap-5">
                <div className="rounded-[var(--radius-card)] border-2 border-border bg-surface p-5 text-center shadow-[2px_2px_0_var(--border)]">
                  <p className="text-[10px] font-black uppercase tracking-widest text-muted">Target bacaan</p>
                  <p className="mt-3 text-3xl font-black leading-tight text-ink md:text-4xl">{selectedExercise.target_text}</p>
                  {selectedExercise.target_translation ? <p className="mt-2 text-sm font-bold text-muted">{selectedExercise.target_translation}</p> : null}
                  {selectedExercise.prompt_text ? <p className="mt-3 text-sm font-semibold leading-6 text-muted">{selectedExercise.prompt_text}</p> : null}
                </div>

                <div className="grid gap-3 sm:grid-cols-3">
                  <div className="rounded-2xl border-2 border-transparent bg-surface p-4">
                    <p className="text-sm font-black text-ink">1. Baca</p>
                    <p className="mt-1 text-xs font-semibold text-muted">Pahami target kalimat.</p>
                  </div>
                  <div className="rounded-2xl border-2 border-transparent bg-surface p-4">
                    <p className="text-sm font-black text-ink">2. Dengarkan</p>
                    <p className="mt-1 text-xs font-semibold text-muted">Ikuti contoh Suara Asli.</p>
                  </div>
                  <div className="rounded-2xl border-2 border-transparent bg-surface p-4">
                    <p className="text-sm font-black text-ink">3. Rekam</p>
                    <p className="mt-1 text-xs font-semibold text-muted">Ucapkan dengan jelas.</p>
                  </div>
                </div>

                <div className="rounded-[var(--radius-card)] border-2 border-border bg-surface p-4 shadow-[2px_2px_0_var(--border)]">
                  <div className="mb-3 flex items-start justify-between gap-3">
                    <div>
                      <p className="text-lg font-black text-ink">Suara Asli</p>
                      <p className="mt-1 text-sm font-semibold text-muted">Dengarkan contoh pengucapan sebelum merekam suaramu.</p>
                    </div>
                    <Badge tone="blue">Contoh</Badge>
                  </div>
                  {referenceAudioUrl(selectedExercise) ? (
                    <div className="grid gap-2">
                      <audio className="w-full" controls onError={() => setReferenceAudioError(true)} src={referenceAudioUrl(selectedExercise) ?? undefined}>Audio belum dapat diputar. Coba muat ulang halaman.</audio>
                      <p className="text-xs font-bold text-muted">{referenceAudioName(selectedExercise)}</p>
                      {referenceAudioError ? <p className="text-xs font-black text-danger">Audio belum dapat diputar. Coba muat ulang halaman.</p> : null}
                      {esp32.state !== "unsupported" ? <p className="text-xs font-semibold text-muted">Pilih &quot;EMI_KOLAKA&quot; sebagai output audio Windows agar suara keluar dari speaker alat.</p> : null}
                    </div>
                  ) : (
                    <p className="rounded-2xl bg-surface-muted p-3 text-sm font-semibold leading-6 text-muted">
                      Audio contoh belum tersedia untuk latihan ini. Kamu tetap bisa membaca target bacaan lalu merekam suaramu.
                    </p>
                  )}
                </div>

                <div className="grid grid-cols-2 gap-3" aria-label="Sumber rekaman">
                  <Button disabled={isRecording || isSubmitting || esp32.state === "recording" || esp32.state === "finalizing"} onClick={() => selectCaptureSource("microphone")} type="button" variant={captureSource === "microphone" ? "primary" : "secondary"}><Mic className="mr-2 size-4" />Gunakan mikrofon perangkat</Button>
                  <Button disabled={!esp32.supported || isRecording || isSubmitting || esp32.state === "recording" || esp32.state === "finalizing"} onClick={() => selectCaptureSource("esp32")} type="button" variant={captureSource === "esp32" ? "primary" : "secondary"}><Cable className="mr-2 size-4" />Gunakan Alat Speaking EMI</Button>
                </div>

                {captureSource === "microphone" ? <div className="flex flex-col items-center gap-4 rounded-[var(--radius-card)] border-2 border-border bg-surface p-6 shadow-[2px_2px_0_var(--border)]">
                  <button
                    aria-label={isRecording ? "Stop rekaman" : "Mulai rekaman"}
                    className={cn(
                      "flex size-28 items-center justify-center rounded-full border-4 border-border text-ink shadow-emi transition-transform hover:-translate-y-1 disabled:cursor-not-allowed disabled:opacity-50",
                      isRecording ? "bg-danger-muted text-danger" : "bg-accent text-accent-foreground",
                    )}
                    disabled={isSubmitting}
                    onClick={isRecording ? stopRecording : startRecording}
                    type="button"
                  >
                    {isRecording ? <Square className="size-10" strokeWidth={3} /> : <Mic className="size-12" strokeWidth={3} />}
                  </button>
                  <div className="text-center">
                    <p className="text-lg font-black text-ink">{isRecording ? "Sedang merekam..." : recordedFile ? "Rekaman siap dikirim" : "Tekan untuk mulai rekam"}</p>
                    <p className="mt-1 text-xs font-bold text-muted">Pastikan mikrofon aktif dan suara terdengar jelas.</p>
                  </div>
                  <div className="flex h-10 w-full max-w-sm items-center justify-center gap-1 rounded-full bg-surface px-4">
                    {Array.from({ length: 18 }).map((_, index) => (
                      <span
                        className={cn("w-1 rounded-full bg-primary", isRecording ? "animate-pulse" : "opacity-40")}
                        key={index}
                        style={{ height: `${8 + (index % 5) * 5}px` }}
                      />
                    ))}
                  </div>
                </div> : (
                  <div className="grid gap-4 rounded-[var(--radius-card)] border-2 border-border bg-surface p-6 shadow-[2px_2px_0_var(--border)]">
                    <div className="flex items-start gap-3">
                      <span className="flex size-12 shrink-0 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-ink">
                        <Mic className="size-6" strokeWidth={2.5} />
                      </span>
                      <div>
                        <p className="text-lg font-black text-ink">Alat Speaking EMI</p>
                        <p className="mt-1 text-sm font-semibold text-muted">Tekan tombol pada alat untuk mulai.</p>
                      </div>
                    </div>
                    {esp32.notice ? <Alert tone="info">{esp32.notice}</Alert> : null}
                    {esp32.error ? <Alert tone="error">{esp32.error}</Alert> : null}
                    <p className="text-sm font-bold text-muted">Status: {{ unsupported: "Alat belum didukung", disconnected: "Alat mati atau belum pernah dipilih", permitted: "Alat tersimpan, belum terhubung", connecting: "Sedang menghubungkan alat...", ready: "Alat siap digunakan", recording: "Sedang merekam...", finalizing: "Menyiapkan rekaman...", captured: "Rekaman siap dikirim", error: "Terjadi masalah pada alat" }[esp32.state]}</p>
                    <div className="flex flex-wrap gap-3">
                      <Button disabled={!esp32.supported || esp32.state === "connecting" || esp32.state === "recording" || esp32.state === "finalizing" || isSubmitting} onClick={() => esp32.connect(false)} type="button"><Cable className="mr-2 size-4" />Sambungkan ulang</Button>
                      <Button disabled={!esp32.supported || esp32.state === "connecting" || esp32.state === "recording" || esp32.state === "finalizing" || isSubmitting} onClick={() => esp32.connect(true)} type="button" variant="secondary">Pilih alat lain</Button>
                      {esp32.state !== "disconnected" && esp32.state !== "permitted" && esp32.state !== "unsupported" ? <Button disabled={esp32.state === "finalizing" || isSubmitting} onClick={esp32.disconnect} type="button" variant="secondary">Putuskan alat</Button> : null}
                    </div>
                  </div>
                )}

                {(captureSource === "microphone" ? recordedUrl : esp32.capture?.url) ? (
                  <div className="rounded-[var(--radius-card)] border-2 border-border bg-surface p-4 shadow-[2px_2px_0_var(--border)]">
                    <div className="mb-3 flex items-center gap-2">
                      <Play className="size-5 text-primary" strokeWidth={3} />
                      <p className="font-black text-ink">Preview audio</p>
                    </div>
                    <audio className="w-full" controls src={captureSource === "microphone" ? recordedUrl ?? undefined : esp32.capture?.url} />
                  </div>
                ) : null}

                <div className="grid gap-3 rounded-[var(--radius-card)] border-2 border-border bg-surface p-4 shadow-[2px_2px_0_var(--border)]">
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <div>
                      <p className="font-black text-ink">Kirim untuk dianalisis</p>
                      <p className="mt-1 text-xs font-bold text-muted">Skor AI adalah penilaian awal. Guru tetap dapat meninjau dan memberi umpan balik.</p>
                    </div>
                    <Button disabled={!(captureSource === "microphone" ? recordedFile : esp32.capture?.file) || isSubmitting || isRecording || esp32.state === "recording"} onClick={submitAttempt} type="button">
                      {isSubmitting ? <LoaderCircle className="mr-2 size-4 animate-spin" /> : <UploadCloud className="mr-2 size-4" />}
                      {isSubmitting ? "Mengirim" : "Kirim audio"}
                    </Button>
                  </div>
                </div>
              </div>
            ) : <EmptyState title="Pilih latihan dahulu" description="Pilih salah satu target bacaan untuk mulai merekam." />}
          </CardContent>
        </Card>
      </section>

      {activeAttempt ? (
        <Card>
          <CardContent>
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h2 className="text-xl font-black text-ink">Hasil Percobaan Terakhir</h2>
                <p className="mt-1 text-xs font-bold text-muted">Hasil AI adalah perkiraan awal. Penilaian akhir akan diberikan oleh guru.</p>
              </div>
              <Badge tone={statusTone(activeAttempt.status)}>{statusLabel(activeAttempt.status)}</Badge>
            </div>
            <div className="mt-4 grid gap-3 md:grid-cols-2">
              <div className="rounded-xl border-2 border-transparent bg-surface-muted p-4"><p className="text-xs font-black uppercase text-muted">Skor awal AI</p><p className="mt-1 text-2xl font-black text-ink">{score(activeAttempt.ai_score)}</p></div>
              <div className="rounded-xl border-2 border-transparent bg-surface-muted p-4"><p className="text-xs font-black uppercase text-muted">Skor guru</p><p className="mt-1 text-2xl font-black text-ink">{score(activeAttempt.teacher_score)}</p></div>
            </div>
            {activeAttempt.ai_transcription ? <p className="mt-4 text-sm leading-6"><span className="font-black">Transkripsi AI:</span> {activeAttempt.ai_transcription}</p> : null}
            {activeAttempt.ai_alignment ? <p className="mt-2 text-sm font-bold text-muted">Alignment AI tersedia untuk membantu tinjauan pengucapan.</p> : null}
            {studentAiWarnings(activeAttempt.ai_warnings).map((warning) => <Alert key={warning} tone="info">{warning}</Alert>)}
            {activeAttempt.status === "failed" ? <div className="grid gap-3"><Alert tone="error">{activeAttempt.ai_error || "Analisis belum berhasil. Audio tetap tersimpan dan dapat dicoba lagi."}</Alert><Button onClick={() => { setError(null); setActiveAttempt(null); }} type="button" variant="secondary">Coba lagi</Button></div> : null}
            {activeAttempt.teacher_feedback ? <Alert tone="success">Feedback guru: {activeAttempt.teacher_feedback}</Alert> : <p className="mt-4 text-sm font-bold text-muted">Menunggu tinjauan guru.</p>}
          </CardContent>
        </Card>
      ) : null}

      <Card>
        <CardContent>
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div><h2 className="text-xl font-black text-ink">Riwayat latihan speaking</h2><p className="mt-2 text-sm font-semibold text-muted">Lihat status, skor awal AI, dan feedback guru dari percobaan sebelumnya.</p></div>
            <Link className="inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi hover:-translate-y-0.5" href="/student/speaking/results">Lihat Hasil Speaking</Link>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
