"use client";

import Link from "next/link";
import { type CSSProperties, useEffect, useMemo, useRef, useState } from "react";
import { ArrowRight, Award, Lightbulb, Mic, Pause, Play, RotateCcw, Volume2 } from "lucide-react";

import { Alert, Badge } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { cn } from "@/lib/utils";

import { aiConfidence, scoreLevel, speakingTips, wordPairs, type WordPair } from "./speaking-feedback";
import { studentService } from "./student-service";
import type { SpeakingAttempt, SpeakingExercise } from "./types";

export function speakingStatusLabel(status?: string) {
  return {
    pending: "Menunggu analisis",
    processing: "Diproses AI",
    completed: "Selesai dianalisis",
    failed: "Analisis gagal",
    reviewed: "Sudah ditinjau guru",
  }[status ?? ""] ?? "Status tidak dikenal";
}

export function speakingStatusTone(status?: string): "yellow" | "blue" | "orange" {
  if (status === "failed") return "orange";
  if (status === "reviewed" || status === "completed") return "blue";
  return "yellow";
}

export function referenceAudioUrl(exercise?: SpeakingExercise | null) {
  return exercise?.reference_audio?.url
    ?? exercise?.reference_audio?.content_url
    ?? exercise?.reference_audio?.public_url
    ?? exercise?.reference_audio?.file_url
    ?? null;
}

function formatDuration(seconds?: number | null) {
  if (!seconds || !Number.isFinite(seconds)) return "--:--";
  const mins = Math.floor(seconds / 60);
  const secs = Math.round(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, "0")}`;
}

function useCountUp(target: number, duration = 1100) {
  const [value, setValue] = useState(0);
  useEffect(() => {
    let raf = 0;
    const start = performance.now();
    const tick = (now: number) => {
      const progress = Math.min(1, (now - start) / duration);
      setValue(Math.round(target * (1 - Math.pow(1 - progress, 3))));
      if (progress < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [target, duration]);
  return value;
}

function ScoreCard({ attempt }: { attempt: SpeakingAttempt }) {
  const finalScore = attempt.teacher_score ?? attempt.ai_score;
  const level = scoreLevel(finalScore);
  const display = useCountUp(finalScore ?? 0);
  const radius = 66;
  const circumference = 2 * Math.PI * radius;

  return (
    <div className={cn("relative flex h-full flex-col items-center justify-center gap-4 rounded-[var(--radius-card)] border-2 border-border p-8 text-center shadow-emi", level.cardBg)}>
      <span className="absolute right-4 top-4 inline-flex size-10 items-center justify-center rounded-full border-2 border-border bg-surface text-primary shadow-[2px_2px_0_var(--border)]">
        <Award className="size-5" strokeWidth={2.5} />
      </span>
      <Badge tone={speakingStatusTone(attempt.status)}>{speakingStatusLabel(attempt.status)}</Badge>
      <div className="relative size-48">
        <svg className="size-full -rotate-90" viewBox="0 0 160 160">
          <circle cx="80" cy="80" fill="var(--surface)" r={radius} stroke="var(--border)" strokeOpacity="0.15" strokeWidth="10" />
          <circle
            cx="80"
            cy="80"
            fill="none"
            r={radius}
            stroke="var(--border)"
            strokeLinecap="round"
            strokeWidth="10"
            strokeDasharray={circumference}
            strokeDashoffset={circumference * (1 - display / 100)}
          />
        </svg>
        <div className="absolute inset-0 grid place-items-center">
          <div>
            <p className="text-6xl font-black leading-none text-ink">{finalScore === null || finalScore === undefined ? "-" : display}</p>
            <p className="mt-1 text-sm font-black text-muted">/100</p>
          </div>
        </div>
      </div>
      <div>
        <p className="text-2xl font-black text-ink">{level.label}</p>
        <p className="mt-1 text-sm font-bold leading-6 text-muted">{level.hint}</p>
      </div>
      <p className="rounded-full border-2 border-border bg-surface px-3 py-1 text-xs font-black uppercase tracking-wide text-muted">
        {attempt.teacher_score !== null && attempt.teacher_score !== undefined ? "Skor akhir dari guru" : "Skor awal AI · penilaian akhir oleh guru"}
      </p>
    </div>
  );
}

function DiffChars({ pair, side }: { pair: WordPair; side: "target" | "detected" }) {
  const items = pair[side];
  if (items.length === 0) return null;
  return (
    <span className="whitespace-nowrap">
      {items.map((item, index) => (
        <span key={index} className={item.ok ? "text-ink" : "rounded bg-danger-muted px-0.5 text-danger"}>
          {item.char}
        </span>
      ))}
    </span>
  );
}

function WordDetailCard({ attempt, pairs }: { attempt: SpeakingAttempt; pairs: WordPair[] }) {
  const confidence = aiConfidence(attempt.ai_alignment);
  return (
    <section className="rounded-[var(--radius-card)] border-2 border-border bg-surface p-6 shadow-emi transition hover:-translate-y-0.5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <p className="text-xs font-black uppercase tracking-[0.12em] text-muted">Detail Kata</p>
        <Badge tone="blue">Target: {attempt.target_text}</Badge>
      </div>
      <div className="mt-4 grid gap-4 sm:grid-cols-2">
        <div className="rounded-xl border-2 border-border bg-surface-muted p-4">
          <p className="text-xs font-black uppercase text-muted">Target</p>
          <p className="mt-2 flex flex-wrap gap-x-3 gap-y-1 text-2xl font-black leading-9">
            {pairs.length > 0
              ? pairs.map((pair, index) => <DiffChars key={index} pair={pair} side="target" />)
              : <span className="text-ink">{attempt.target_text}</span>}
          </p>
        </div>
        <div className="rounded-xl border-2 border-border bg-surface p-4">
          <p className="text-xs font-black uppercase text-muted">Terdeteksi</p>
          <p className="mt-2 flex flex-wrap gap-x-3 gap-y-1 text-2xl font-black leading-9">
            {pairs.length > 0
              ? pairs.map((pair, index) => <DiffChars key={index} pair={pair} side="detected" />)
              : <span className="text-base font-bold text-muted">Belum terdeteksi — analisis belum selesai.</span>}
          </p>
        </div>
      </div>
      <div className="mt-4 flex flex-wrap items-center gap-x-5 gap-y-2 text-xs font-bold text-muted">
        <span className="flex items-center gap-1.5"><span className="inline-block size-3 rounded-sm border border-border bg-success" />Bunyi benar</span>
        <span className="flex items-center gap-1.5"><span className="inline-block size-3 rounded-sm border border-border bg-danger-muted" />Perlu diperbaiki</span>
        {confidence !== null ? <span className="ml-auto rounded-full border-2 border-border bg-surface-muted px-3 py-1 font-black text-ink">Keyakinan AI: {confidence}%</span> : null}
      </div>
    </section>
  );
}

export function ComparePlayer({ src, label, icon: Icon, onError }: { src?: string | null; label: string; icon: typeof Volume2; onError?: () => void }) {
  const audioRef = useRef<HTMLAudioElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [duration, setDuration] = useState<number | null>(null);
  const bars = useMemo(() => Array.from({ length: 26 }, (_, index) => 8 + ((index * 29) % 18)), []);

  if (!src) {
    return (
      <div className="rounded-xl border-2 border-dashed border-border bg-surface-muted p-4 text-sm font-bold text-muted">
        Audio {label.toLowerCase()} belum tersedia.
      </div>
    );
  }

  const toggle = () => {
    const audio = audioRef.current;
    if (!audio) return;
    if (isPlaying) audio.pause();
    else void audio.play().catch(() => setIsPlaying(false));
  };

  return (
    <div className={cn("flex items-center gap-4 rounded-xl border-2 border-border bg-surface p-4 shadow-[2px_2px_0_var(--border)]", isPlaying && "wave-playing")}>
      <audio
        className="hidden"
        onEnded={() => setIsPlaying(false)}
        onError={onError}
        onLoadedMetadata={(event) => setDuration(event.currentTarget.duration)}
        onPause={() => setIsPlaying(false)}
        onPlay={() => setIsPlaying(true)}
        ref={audioRef}
        src={src}
      />
      <button
        aria-label={isPlaying ? `Jeda ${label}` : `Putar ${label}`}
        className="flex size-12 shrink-0 items-center justify-center rounded-full border-2 border-border bg-primary text-primary-foreground shadow-emi transition hover:-translate-y-0.5"
        onClick={toggle}
        type="button"
      >
        {isPlaying ? <Pause className="size-5" strokeWidth={3} /> : <Play className="ml-0.5 size-5" strokeWidth={3} />}
      </button>
      <div className="min-w-0 shrink-0">
        <p className="flex items-center gap-1.5 text-sm font-black text-ink"><Icon className="size-4 text-primary" strokeWidth={3} />{label}</p>
        <p className="mt-0.5 text-xs font-bold text-muted">{formatDuration(duration)}</p>
      </div>
      <div aria-hidden="true" className="flex h-9 min-w-0 flex-1 items-center justify-end gap-[3px]">
        {bars.map((height, index) => (
          <span
            className={cn("wave-bar w-1 shrink-0 rounded-full", isPlaying ? "bg-primary" : "bg-primary/35")}
            key={index}
            style={{ height: `${height}px`, animationDelay: `${index * 60}ms` }}
          />
        ))}
      </div>
    </div>
  );
}

type SpeakingResultHeroProps = {
  attempt: SpeakingAttempt;
  referenceAudioUrl?: string | null;
  onRetry?: () => void;
  onNext?: () => void;
};

export function SpeakingResultHero({ attempt, referenceAudioUrl: referenceUrl, onRetry, onNext }: SpeakingResultHeroProps) {
  const { token } = useAuth();
  const [studentAudio, setStudentAudio] = useState<{ id: string; url: string } | null>(null);
  const pairs = wordPairs(attempt);
  const tips = speakingTips(pairs, attempt.teacher_feedback);
  const studentAudioUrl = studentAudio && studentAudio.id === attempt.audio_media_id ? studentAudio.url : null;

  useEffect(() => {
    const mediaId = attempt.audio_media_id;
    if (!token || !mediaId) return;
    let ignore = false;
    studentService.temporaryMediaUrl(token, mediaId)
      .then((url) => !ignore && setStudentAudio({ id: mediaId, url }))
      .catch(() => {});
    return () => {
      ignore = true;
    };
  }, [attempt.audio_media_id, token]);

  return (
    <div className="grid gap-6">
      {attempt.status === "failed" ? <Alert tone="error">{attempt.ai_error || "Analisis belum berhasil. Audio tetap tersimpan dan dapat dicoba lagi."}</Alert> : null}

      <section className="grid gap-6 lg:grid-cols-[3fr_7fr]">
        <div className="animate-fade-up" style={{ "--stagger": "0ms" } as CSSProperties}>
          <ScoreCard attempt={attempt} />
        </div>
        <div className="grid content-start gap-6">
          <div className="animate-fade-up" style={{ "--stagger": "120ms" } as CSSProperties}>
            <WordDetailCard attempt={attempt} pairs={pairs} />
          </div>
          <section className="animate-fade-up rounded-[var(--radius-card)] border-2 border-border bg-surface p-6 shadow-emi transition hover:-translate-y-0.5" style={{ "--stagger": "240ms" } as CSSProperties}>
            <p className="text-xs font-black uppercase tracking-[0.12em] text-muted">Bandingkan Suara</p>
            <div className="mt-4 grid gap-3">
              <ComparePlayer icon={Volume2} label="Penutur Asli" src={referenceUrl} />
              <ComparePlayer icon={Mic} label="Suara Kamu" src={studentAudioUrl} />
            </div>
          </section>
        </div>
      </section>

      <section className="animate-fade-up rounded-[var(--radius-card)] border-2 border-border bg-surface p-6 shadow-emi" style={{ "--stagger": "360ms" } as CSSProperties}>
        <div className="flex items-center gap-3">
          <span className="inline-flex size-11 items-center justify-center rounded-xl border-2 border-border bg-accent text-accent-foreground shadow-[2px_2px_0_var(--border)]">
            <Lightbulb className="size-5" strokeWidth={2.5} />
          </span>
          <h2 className="text-xl font-black text-ink">Tips Pelafalan</h2>
        </div>
        <ul className="mt-4 grid gap-3">
          {tips.map((tip) => (
            <li className="flex items-start gap-3 rounded-xl bg-surface-muted p-4 text-base font-semibold leading-7 text-ink" key={tip}>
              <span className="mt-2.5 size-2 shrink-0 rounded-full bg-primary" />
              {tip}
            </li>
          ))}
        </ul>
      </section>

      <section className="animate-fade-up grid gap-4 sm:grid-cols-2" style={{ "--stagger": "480ms" } as CSSProperties}>
        {onRetry ? (
          <button className="inline-flex min-h-14 items-center justify-center gap-2 rounded-xl border-2 border-border bg-surface px-6 text-base font-black text-ink shadow-emi transition hover:-translate-y-0.5 hover:bg-accent/30" onClick={onRetry} type="button">
            <RotateCcw className="size-5" strokeWidth={3} />Coba Lagi
          </button>
        ) : (
          <Link className="inline-flex min-h-14 items-center justify-center gap-2 rounded-xl border-2 border-border bg-surface px-6 text-base font-black text-ink shadow-emi transition hover:-translate-y-0.5 hover:bg-accent/30" href="/student/speaking">
            <RotateCcw className="size-5" strokeWidth={3} />Coba Lagi
          </Link>
        )}
        {onNext ? (
          <button className="inline-flex min-h-14 items-center justify-center gap-2 rounded-xl border-2 border-border bg-primary px-6 text-base font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5" onClick={onNext} type="button">
            Latihan Kata Berikutnya<ArrowRight className="size-5" strokeWidth={3} />
          </button>
        ) : (
          <Link className="inline-flex min-h-14 items-center justify-center gap-2 rounded-xl border-2 border-border bg-primary px-6 text-base font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5" href="/student/speaking">
            Latihan Kata Berikutnya<ArrowRight className="size-5" strokeWidth={3} />
          </Link>
        )}
      </section>
    </div>
  );
}
