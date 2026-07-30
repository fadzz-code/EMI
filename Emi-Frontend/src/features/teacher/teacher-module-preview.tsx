"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, BookOpen, ChevronDown, ChevronUp, Pencil } from "lucide-react";
import { useState } from "react";

import { Alert, Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { LessonBody } from "./teacher-lesson-preview";
import { teacherService } from "./teacher-service";
import { contentTypeLabel, formatCount, formatDate, formatOptional, statusLabel } from "./teacher-utils";
import type { TeacherClassLesson } from "./types";

function LessonPreviewRow({ lesson, index, token }: { lesson: TeacherClassLesson; index: number; token: string }) {
  const [open, setOpen] = useState(false);

  const contentQuery = useQuery({
    queryKey: ["teacher", "class-lessons", lesson.id, "content"],
    queryFn: () => teacherService.classLessonContent(token, lesson.id),
    enabled: Boolean(token && lesson.id && open),
  });

  return (
    <div className="rounded-xl border-2 border-border bg-surface-muted p-4">
      <button
        aria-expanded={open}
        className="flex w-full items-start gap-4 text-left"
        onClick={() => setOpen((current) => !current)}
        type="button"
      >
        <div className="flex size-11 shrink-0 items-center justify-center rounded-xl border-2 border-border bg-surface text-primary">
          <BookOpen className="size-5" strokeWidth={2.5} />
        </div>
        <div className="flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <Badge tone={lesson.status === "published" ? "blue" : "neutral"}>{statusLabel(lesson.status)}</Badge>
            <span className="text-xs font-black uppercase text-muted">Materi {index + 1} · {contentTypeLabel(lesson.content_type)}</span>
          </div>
          <h3 className="mt-1 font-black text-ink">{lesson.title}</h3>
          <p className="mt-1 text-sm font-semibold leading-6 text-muted">{formatOptional(lesson.description)}</p>
        </div>
        <div className="flex size-9 shrink-0 items-center justify-center rounded-lg border-2 border-border bg-surface text-ink">
          {open ? <ChevronUp className="size-4" strokeWidth={2.5} /> : <ChevronDown className="size-4" strokeWidth={2.5} />}
        </div>
      </button>

      {open ? (
        <div className="mt-4 border-t-2 border-border pt-4">
          {contentQuery.isLoading ? <LoadingState title="Memuat isi materi" /> : null}
          {contentQuery.isError ? (
            <ErrorState description={getFirstApiError(contentQuery.error)} onRetry={() => void contentQuery.refetch()} title="Gagal memuat isi materi" />
          ) : null}
          {!contentQuery.isLoading && !contentQuery.isError ? <LessonBody content={contentQuery.data} /> : null}
        </div>
      ) : null}
    </div>
  );
}

export function TeacherModulePreview({ moduleId }: { moduleId: string }) {
  const { token } = useAuth();

  const moduleQuery = useQuery({
    queryKey: ["teacher", "class-modules", moduleId],
    queryFn: () => teacherService.classModuleDetail(token ?? "", moduleId),
    enabled: Boolean(token && moduleId),
  });

  const moduleData = moduleQuery.data;
  const lessons = moduleData?.lessons ?? [];

  return (
    <div className="grid gap-8">
      <div className="flex flex-wrap gap-3">
        <Link className="inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-primary transition hover:-translate-y-0.5 hover:bg-[var(--color-primary-muted)] hover:shadow-emi" href={teacherRoutes.modules}>
          <ArrowLeft className="size-5" strokeWidth={2.5} /> Kembali ke Daftar Modul
        </Link>
        <Link className="inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5" href={teacherRoutes.moduleEdit(moduleId)}>
          <Pencil className="size-4" strokeWidth={2.5} /> Edit Modul
        </Link>
      </div>
      <PageHeader badge="Guru" description="Lihat modul persis seperti tampilan yang akan dilihat siswa." title="Lihat Modul (Preview)" />

      {moduleQuery.isLoading ? <LoadingState title="Memuat modul" /> : null}
      {moduleQuery.isError ? (
        <ErrorState description={getFirstApiError(moduleQuery.error)} onRetry={() => void moduleQuery.refetch()} title="Gagal memuat modul" />
      ) : null}

      {moduleData ? (
        <>
          <header className="grid gap-6 rounded-3xl border-2 border-border bg-[var(--color-primary-muted)] p-6 shadow-emi sm:p-8 lg:grid-cols-[1.2fr_auto] lg:items-center">
            <div className="grid gap-5">
              <div className="flex flex-wrap gap-2">
                <Badge tone={moduleData.status === "published" ? "blue" : "neutral"}>{statusLabel(moduleData.status)}</Badge>
                <Badge tone="yellow">{formatCount(lessons.length)} materi</Badge>
              </div>
              <div>
                <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">{moduleData.title}</h1>
                <p className="mt-3 max-w-2xl text-sm font-semibold leading-6 text-muted">{formatOptional(moduleData.description)}</p>
              </div>
            </div>
          </header>

          <Card>
            <CardHeader><h2 className="text-xl font-black text-ink">Detail Modul</h2></CardHeader>
            <CardContent>
              <dl className="grid gap-3 text-sm sm:grid-cols-2">
                <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Urutan Tampil</dt><dd className="mt-1 font-bold text-ink">{formatOptional(moduleData.sort_order)}</dd></div>
                <div className="rounded-xl border-2 border-border bg-surface-muted p-3"><dt className="font-black uppercase text-muted">Terbit</dt><dd className="mt-1 font-bold text-ink">{formatDate(moduleData.published_at)}</dd></div>
              </dl>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Materi ({formatCount(lessons.length)})</h2>
              <p className="mt-1 text-sm font-semibold text-muted">Klik salah satu materi untuk membuka dan melihat isinya (teks, gambar, audio, PDF, atau video).</p>
            </CardHeader>
            <CardContent>
              {lessons.length === 0 ? (
                <EmptyState description="Modul ini belum memiliki materi." title="Materi kosong" />
              ) : (
                <div className="grid gap-3">
                  {lessons.map((lesson, index) => (
                    <LessonPreviewRow index={index} key={lesson.id} lesson={lesson} token={token ?? ""} />
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </>
      ) : null}

      {!moduleQuery.isLoading && !moduleQuery.isError && !moduleData ? <Alert tone="warning">Modul tidak ditemukan.</Alert> : null}
    </div>
  );
}
