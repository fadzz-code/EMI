"use client";

import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentService } from "./student-service";
import { contentTypeLabel, formatOptional, statusLabel } from "./student-utils";
import type { LessonContent } from "./types";

function LessonBody({ content }: { content?: LessonContent }) {
  if (!content) {
    return <EmptyState description="Konten materi belum tersedia untuk dibaca." title="Konten belum tersedia" />;
  }

  if (content.type === "text") {
    return (
      <div className="prose prose-slate max-w-none whitespace-pre-wrap rounded-2xl border border-slate-200 bg-white p-4 text-sm leading-7 text-slate-800">
        {content.content_body || "Belum tersedia"}
      </div>
    );
  }

  if (!content.url) {
    return <EmptyState description="Media untuk materi ini belum tersedia." title="Media belum tersedia" />;
  }

  if (content.type === "image") {
    return (
      <a className="inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-ink bg-blue-600 px-4 py-2 text-sm font-black text-white shadow-brutal hover:bg-blue-700" href={content.url} rel="noreferrer" target="_blank">
        Buka Gambar
      </a>
    );
  }

  if (content.type === "audio") {
    return <audio className="w-full" controls src={content.url} />;
  }

  return (
    <a className="inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-ink bg-blue-600 px-4 py-2 text-sm font-black text-white shadow-brutal hover:bg-blue-700" href={content.url} rel="noreferrer" target="_blank">
      Buka {contentTypeLabel(content.type)}
    </a>
  );
}

export function StudentLessonDetail({ lessonId }: { lessonId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const lessonQuery = useQuery({
    queryKey: ["student", "lessons", lessonId],
    queryFn: () => studentService.lessonDetail(token ?? "", lessonId),
    enabled: Boolean(token && lessonId),
  });
  const contentQuery = useQuery({
    queryKey: ["student", "lessons", lessonId, "content"],
    queryFn: () => studentService.lessonContent(token ?? "", lessonId),
    enabled: Boolean(token && lessonId),
  });
  const completeMutation = useMutation({
    mutationFn: () => studentService.completeLesson(token ?? "", lessonId),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["student", "modules"] });
      await queryClient.invalidateQueries({ queryKey: ["student", "lessons", lessonId] });
    },
  });

  const lesson = lessonQuery.data;

  return (
    <div className="grid gap-6">
      <Link className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100" href="/student/modules">
        Kembali ke Modul Saya
      </Link>

      {lessonQuery.isLoading ? <LoadingState title="Memuat materi" /> : null}
      {lessonQuery.isError ? (
        <ErrorState
          description={getFirstApiError(lessonQuery.error)}
          onRetry={() => void lessonQuery.refetch()}
          title="Gagal memuat materi"
        />
      ) : null}

      {lesson ? (
        <>
          {completeMutation.isSuccess ? <Alert tone="success">Materi ditandai selesai.</Alert> : null}
          {completeMutation.error ? <Alert tone="error">{getFirstApiError(completeMutation.error)}</Alert> : null}

          <header className="grid gap-5 rounded-3xl border-2 border-ink bg-[var(--color-primary-muted)] p-5 shadow-brutal lg:grid-cols-[1.2fr_auto] lg:items-center">
            <div className="grid gap-4">
              <Badge tone="blue">{contentTypeLabel(lesson.content_type)}</Badge>
              <div>
                <h1 className="text-3xl font-black text-ink">{lesson.title}</h1>
                <p className="mt-2 text-sm leading-6 text-slate-700">{formatOptional(lesson.description)}</p>
              </div>
            </div>
            <div className="flex flex-col gap-3 sm:flex-row lg:flex-col">
              <Button disabled={completeMutation.isPending} onClick={() => completeMutation.mutate()}>
                Tandai Selesai
              </Button>
              <Link className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-bold text-ink shadow-brutal hover:bg-yellow-200" href={`/student/modules/${lesson.class_module_id}`}>
                Kembali ke Modul
              </Link>
            </div>
          </header>

          <Card>
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Konten Materi</h2>
              <p className="mt-1 text-sm text-slate-600">Status materi: {statusLabel(lesson.status)}</p>
            </CardHeader>
            <CardContent>
              {contentQuery.isLoading ? <LoadingState title="Memuat konten materi" /> : null}
              {contentQuery.isError ? (
                <ErrorState
                  description={getFirstApiError(contentQuery.error)}
                  onRetry={() => void contentQuery.refetch()}
                  title="Gagal memuat konten materi"
                />
              ) : null}
              {!contentQuery.isLoading && !contentQuery.isError ? <LessonBody content={contentQuery.data} /> : null}
            </CardContent>
          </Card>
        </>
      ) : null}
    </div>
  );
}
