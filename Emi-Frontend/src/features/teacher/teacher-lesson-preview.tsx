"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, ExternalLink, Pencil } from "lucide-react";

import { Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { contentTypeLabel, formatOptional, statusLabel } from "./teacher-utils";
import type { TeacherLessonContent } from "./types";

export function LessonBody({ content }: { content?: TeacherLessonContent }) {
  if (!content) {
    return <EmptyState description="Konten materi belum tersedia untuk dilihat." title="Konten belum tersedia" />;
  }

  if (content.type === "text") {
    return (
      <div className="prose prose-slate max-w-none whitespace-pre-wrap rounded-2xl border-2 border-border bg-surface-muted p-5 text-sm font-semibold leading-7 text-ink sm:p-6">
        {content.content_body || "Belum tersedia"}
      </div>
    );
  }

  if (!content.url) {
    return <EmptyState description="Media untuk materi ini belum tersedia." title="Media belum tersedia" />;
  }

  if (content.type === "image") {
    return (
      <a className="inline-flex min-h-12 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-5 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5" href={content.url} rel="noreferrer" target="_blank">
        Buka Gambar
        <ExternalLink className="size-4" strokeWidth={2.5} />
      </a>
    );
  }

  if (content.type === "audio") {
    return <audio className="w-full" controls src={content.url} />;
  }

  return (
    <a className="inline-flex min-h-12 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-5 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5" href={content.url} rel="noreferrer" target="_blank">
      Buka {contentTypeLabel(content.type)}
      <ExternalLink className="size-4" strokeWidth={2.5} />
    </a>
  );
}

export function TeacherLessonPreview({ moduleId, lessonId }: { moduleId: string; lessonId: string }) {
  const { token } = useAuth();
  const lessonQuery = useQuery({
    queryKey: ["teacher", "class-lessons", lessonId],
    queryFn: () => teacherService.classLessonDetail(token ?? "", lessonId),
    enabled: Boolean(token && lessonId),
  });
  const contentQuery = useQuery({
    queryKey: ["teacher", "class-lessons", lessonId, "content"],
    queryFn: () => teacherService.classLessonContent(token ?? "", lessonId),
    enabled: Boolean(token && lessonId),
  });

  const lesson = lessonQuery.data;

  return (
    <div className="grid gap-8">
      <Link className="inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-primary transition hover:-translate-y-0.5 hover:bg-[var(--color-primary-muted)] hover:shadow-emi" href={teacherRoutes.moduleEdit(moduleId)}>
        <ArrowLeft className="size-5" strokeWidth={2.5} />
        Kembali ke Modul
      </Link>
      <PageHeader badge="Guru" description="Lihat materi kelas persis seperti tampilan siswa." title="Lihat Materi (Preview)" />

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
          <header className="grid gap-6 rounded-3xl border-2 border-border bg-[var(--color-primary-muted)] p-6 shadow-emi sm:p-8 lg:grid-cols-[1.2fr_auto] lg:items-center">
            <div className="grid gap-5">
              <Badge tone="blue">{contentTypeLabel(lesson.content_type)}</Badge>
              <div>
                <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">{lesson.title}</h1>
                <p className="mt-3 max-w-2xl text-sm font-semibold leading-6 text-muted">{formatOptional(lesson.description)}</p>
              </div>
            </div>
            <div className="flex flex-col gap-3 sm:flex-row lg:flex-col">
              <Link className="inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5" href={teacherRoutes.lessonEdit(moduleId, lessonId)}>
                <Pencil className="size-4" strokeWidth={2.5} />
                Edit Materi
              </Link>
              <Link className="inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink shadow-emi transition hover:-translate-y-0.5 hover:bg-surface-muted" href={teacherRoutes.moduleEdit(moduleId)}>
                <ArrowLeft className="size-4 text-primary" strokeWidth={2.5} />
                Kembali ke Modul
              </Link>
            </div>
          </header>

          <Card className="bg-surface">
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Konten Materi</h2>
              <p className="mt-1 text-sm font-semibold text-muted">Status materi: {statusLabel(lesson.status)}</p>
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
