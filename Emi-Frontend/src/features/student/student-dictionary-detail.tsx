"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Headphones, Languages, MessageSquareText } from "lucide-react";

import { AudioPlayer, Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentDictionaryService } from "./student-dictionary-service";
import { formatOptional } from "./student-utils";

function DetailRow({ label, value }: { label: string; value?: string | null }) {
  return (
    <div className="h-full rounded-xl border-2 border-border bg-surface-muted p-4">
      <p className="text-xs font-black uppercase tracking-[0.08em] text-muted">{label}</p>
      <p className="mt-2 text-lg font-black text-ink">{formatOptional(value)}</p>
    </div>
  );
}

export function StudentDictionaryDetail({ entryId }: { entryId: string }) {
  const { token } = useAuth();
  const entryQuery = useQuery({
    queryKey: ["student", "dictionary", "entries", entryId],
    queryFn: () => studentDictionaryService.detail(token ?? "", entryId),
    enabled: Boolean(token && entryId),
  });

  const entry = entryQuery.data;

  return (
    <div className="grid gap-8">
      <Link className="inline-flex min-h-12 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink shadow-emi transition-transform hover:-translate-y-0.5 hover:bg-surface-muted" href="/student/dictionary">
        <ArrowLeft className="size-5" strokeWidth={2.5} />
        Kembali ke Kamus
      </Link>

      {entryQuery.isLoading ? <LoadingState title="Memuat detail kamus" /> : null}
      {entryQuery.isError ? (
        <ErrorState
          description={getFirstApiError(entryQuery.error)}
          onRetry={() => void entryQuery.refetch()}
          title="Kata kamus tidak dapat dibuka"
        />
      ) : null}

      {entry ? (
        <>
          <header className="grid gap-6 rounded-3xl border-2 border-border bg-[var(--color-primary-muted)] p-5 shadow-emi sm:p-8 lg:grid-cols-[1.3fr_0.7fr] lg:items-center">
            <div className="grid gap-4">
              <div className="flex flex-wrap gap-2">
                <Badge tone="blue">{entry.category?.name ?? "Tanpa kategori"}</Badge>
                <Badge tone={entry.audio ? "yellow" : "neutral"}>{entry.audio ? "Audio tersedia" : "Audio belum tersedia"}</Badge>
              </div>
              <div className="flex items-start gap-4">
                <div className="inline-flex size-12 shrink-0 items-center justify-center rounded-xl border-2 border-border bg-surface text-ink">
                  <Languages className="size-6" strokeWidth={2.5} />
                </div>
                <div>
                  <p className="text-xs font-black uppercase tracking-[0.08em] text-muted">Bahasa Mekongga</p>
                  <h1 className="mt-1 text-4xl font-black text-ink sm:text-5xl">{entry.mekongga}</h1>
                  <p className="mt-3 text-lg font-black text-muted">Indonesia: <span className="text-ink">{formatOptional(entry.indonesia)}</span></p>
                </div>
              </div>
            </div>
            <div className="rounded-2xl border-2 border-border bg-surface p-5 shadow-[4px_4px_0px_0px_var(--border)]">
              <div className="mb-3 flex items-center gap-3">
                <Headphones className="size-6 text-ink" strokeWidth={2.5} />
                <p className="text-xs font-black uppercase tracking-[0.08em] text-muted">Dengarkan kata</p>
              </div>
              <AudioPlayer src={entry.audio?.url} title="Mekongga" />
              <p className="mt-3 text-sm font-bold text-muted">
                {entry.audio ? "Audio membantu latihan pelafalan." : "Audio belum tersedia untuk kata ini."}
              </p>
            </div>
          </header>

          <section className="grid gap-4 md:grid-cols-3">
            <DetailRow label="Bahasa Indonesia" value={entry.indonesia} />
            <DetailRow label="Bahasa Inggris" value={entry.english} />
            <DetailRow label="Bahasa Mekongga" value={entry.mekongga} />
          </section>

          <Card>
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="inline-flex size-10 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-ink">
                  <MessageSquareText className="size-5" strokeWidth={2.5} />
                </div>
                <h2 className="text-xl font-black text-ink">Contoh Kalimat</h2>
              </div>
            </CardHeader>
            <CardContent>
              {entry.example_mekongga || entry.example_indonesia || (entry.sentence_examples ?? []).length > 0 ? (
                <div className="grid gap-4">
                  {entry.example_mekongga || entry.example_indonesia ? (
                    <div className="rounded-xl border-2 border-border bg-surface-muted p-4">
                      <p className="text-xs font-black uppercase tracking-[0.08em] text-muted">Contoh Kalimat</p>
                      <p className="mt-2 text-lg font-black text-ink">Mekongga: {entry.example_mekongga ?? "-"}</p>
                      <p className="mt-1 text-sm font-bold text-muted">Indonesia: {entry.example_indonesia ?? "-"}</p>
                    </div>
                  ) : null}
                  {entry.sentence_examples?.map((example, index) => (
                    <div key={example.id} className="rounded-xl border-2 border-border bg-surface-muted p-4">
                      <p className="text-xs font-black uppercase tracking-[0.08em] text-muted">Contoh Tambahan {index + 1}</p>
                      <p className="mt-2 text-lg font-black text-ink">Mekongga: {example.contoh_mekongga}</p>
                      <p className="mt-1 text-sm font-bold text-muted">Indonesia: {example.contoh_indonesia}</p>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="rounded-xl border-2 border-dashed border-border bg-surface-muted p-4 text-sm font-bold text-muted">Belum ada contoh kalimat.</p>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="inline-flex size-10 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-ink">
                  <Headphones className="size-5" strokeWidth={2.5} />
                </div>
                <div>
                  <h2 className="text-xl font-black text-ink">Audio Mekongga</h2>
                  <p className="mt-1 text-sm font-semibold text-muted">Gunakan audio ini sebagai pendamping saat membaca kosakata Mekongga.</p>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <AudioPlayer src={entry.audio?.url} title="Mekongga" />
              {entry.audio ? (
                <p className="mt-3 text-xs font-bold text-muted">MIME: {entry.audio.mime_type}</p>
              ) : null}
            </CardContent>
          </Card>
        </>
      ) : !entryQuery.isLoading && !entryQuery.isError ? (
        <EmptyState description="Kata ini belum tersedia di kamus." title="Kata tidak ditemukan" />
      ) : null}
    </div>
  );
}
