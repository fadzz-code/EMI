"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { AudioPlayer, Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentDictionaryService } from "./student-dictionary-service";
import { formatOptional } from "./student-utils";

function DetailRow({ label, value }: { label: string; value?: string | null }) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-4">
      <p className="text-xs font-black uppercase text-slate-500">{label}</p>
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
    <div className="grid gap-6">
      <Link className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100" href="/student/dictionary">
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
          <header className="grid gap-5 rounded-3xl border-2 border-ink bg-[var(--color-primary-muted)] p-5 shadow-brutal lg:grid-cols-[1.3fr_0.7fr] lg:items-center">
            <div className="grid gap-4">
              <div className="flex flex-wrap gap-2">
                <Badge tone="blue">{entry.category?.name ?? "Tanpa kategori"}</Badge>
                <Badge tone={entry.audio ? "yellow" : "neutral"}>{entry.audio ? "Audio tersedia" : "Audio belum tersedia"}</Badge>
              </div>
              <div>
                <p className="text-xs font-black uppercase text-slate-500">Bahasa Mekongga</p>
                <h1 className="mt-2 text-5xl font-black text-ink">{entry.mekongga}</h1>
                <p className="mt-3 text-lg font-black text-slate-700">Indonesia: {formatOptional(entry.indonesia)}</p>
              </div>
            </div>
            <div className="rounded-2xl border-2 border-ink bg-white p-4 shadow-brutal">
              <p className="text-xs font-black uppercase text-slate-500">Dengarkan kata</p>
              <AudioPlayer src={entry.audio?.url} title="Mekongga" />
              <p className="mt-3 text-sm font-bold text-slate-600">
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
              <h2 className="text-xl font-black text-ink">Contoh Kalimat</h2>
            </CardHeader>
            <CardContent>
              {(entry.sentence_examples ?? []).length > 0 ? (
                <div className="grid gap-4">
                  {entry.sentence_examples?.map((example, index) => (
                    <div key={example.id} className="rounded-xl border border-slate-200 bg-white p-4">
                      <p className="text-xs font-black uppercase text-slate-500">Contoh {index + 1}</p>
                      <p className="mt-2 text-lg font-black text-ink">Mekongga: {example.contoh_mekongga}</p>
                      <p className="mt-1 text-sm font-bold text-slate-600">Indonesia: {example.contoh_indonesia}</p>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="rounded-xl border border-dashed border-slate-300 bg-white p-4 text-sm font-bold text-slate-600">Belum ada contoh kalimat.</p>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Audio Mekongga</h2>
              <p className="mt-1 text-sm text-slate-600">Gunakan audio ini sebagai pendamping saat membaca kosakata Mekongga.</p>
            </CardHeader>
            <CardContent>
              <AudioPlayer src={entry.audio?.url} title="Mekongga" />
              {entry.audio ? (
                <p className="mt-3 text-xs font-bold text-slate-500">MIME: {entry.audio.mime_type}</p>
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
