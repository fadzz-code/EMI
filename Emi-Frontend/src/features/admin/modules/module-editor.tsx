"use client";

import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";

import {
  Alert,
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  ConfirmDialog,
  EmptyState,
  ErrorState,
  LoadingState,
  Modal,
  Table,
  TableCell,
  TableHeader,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { env } from "@/lib/env";

import { ModuleContentForm } from "./module-content-form";
import { ModuleTemplateForm } from "./module-form";
import { lessonTemplateService, moduleTemplateService } from "./module-service";
import {
  contentTypeLabel,
  formatDate,
  publicMediaContentUrl,
  statusLabel,
  statusTone,
} from "./module-utils";
import type { LessonTemplate, LessonTemplatePayload, ModuleTemplatePayload } from "./types";

function LessonPreview({ lesson }: { lesson: LessonTemplate }) {
  if (lesson.content_type === "text") {
    return (
      <div className="rounded-lg border-2 border-ink bg-white p-4">
        <p className="whitespace-pre-wrap text-sm leading-6 text-slate-700">
          {lesson.content_body ?? "Konten teks belum diisi."}
        </p>
      </div>
    );
  }

  if (lesson.content_type === "video" || lesson.content_type === "link") {
    return lesson.external_url ? (
      <a
        className="text-sm font-black text-blue-700 underline"
        href={lesson.external_url}
        rel="noreferrer"
        target="_blank"
      >
        Buka URL materi
      </a>
    ) : (
      <p className="text-sm text-slate-600">URL belum diisi.</p>
    );
  }

  if (!lesson.media) {
    return <p className="text-sm text-slate-600">Media belum dihubungkan.</p>;
  }

  if (lesson.media.visibility === "private") {
    return (
      <p className="text-sm text-slate-600">
        Media private terhubung dengan ID {lesson.media.id}. Preview langsung tidak tersedia di
        endpoint template.
      </p>
    );
  }

  const mediaUrl = publicMediaContentUrl(env.apiBaseUrl, lesson.media.id);

  if (lesson.content_type === "audio") {
    return <audio className="w-full" controls src={mediaUrl} />;
  }

  return (
    <a
      className="text-sm font-black text-blue-700 underline"
      href={mediaUrl}
      rel="noreferrer"
      target="_blank"
    >
      Buka media publik
    </a>
  );
}

export function ModuleEditor({ moduleId }: { moduleId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [createLessonOpen, setCreateLessonOpen] = useState(false);
  const [editingLesson, setEditingLesson] = useState<LessonTemplate | null>(null);
  const [deleteLessonTarget, setDeleteLessonTarget] = useState<LessonTemplate | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const moduleQuery = useQuery({
    queryKey: ["admin", "module-templates", moduleId],
    queryFn: () => moduleTemplateService.detail(token ?? "", moduleId),
    enabled: Boolean(token),
  });

  const lessonsQuery = useQuery({
    queryKey: ["admin", "module-templates", moduleId, "lessons"],
    queryFn: () => lessonTemplateService.list(token ?? "", moduleId),
    enabled: Boolean(token),
  });

  async function invalidateModule() {
    await queryClient.invalidateQueries({ queryKey: ["admin", "module-templates"] });
  }

  const updateModuleMutation = useMutation({
    mutationFn: (payload: ModuleTemplatePayload) =>
      moduleTemplateService.update(token ?? "", moduleId, payload),
    onSuccess: async (module) => {
      setSuccessMessage(`Metadata modul ${module.title} berhasil disimpan.`);
      await invalidateModule();
    },
  });

  const publishModuleMutation = useMutation({
    mutationFn: () => moduleTemplateService.publish(token ?? "", moduleId),
    onSuccess: async (module) => {
      setSuccessMessage(`Modul ${module.title} berhasil dipublish.`);
      await invalidateModule();
    },
  });

  const archiveModuleMutation = useMutation({
    mutationFn: () => moduleTemplateService.archive(token ?? "", moduleId),
    onSuccess: async (module) => {
      setSuccessMessage(`Modul ${module.title} berhasil diarsipkan.`);
      await invalidateModule();
    },
  });

  const createLessonMutation = useMutation({
    mutationFn: (payload: LessonTemplatePayload) =>
      lessonTemplateService.create(token ?? "", moduleId, payload),
    onSuccess: async (lesson) => {
      setSuccessMessage(`Materi ${lesson.title} berhasil dibuat.`);
      setCreateLessonOpen(false);
      await invalidateModule();
    },
  });

  const updateLessonMutation = useMutation({
    mutationFn: ({ lessonId, payload }: { lessonId: string; payload: LessonTemplatePayload }) =>
      lessonTemplateService.update(token ?? "", lessonId, payload),
    onSuccess: async (lesson) => {
      setSuccessMessage(`Materi ${lesson.title} berhasil diperbarui.`);
      setEditingLesson(null);
      await invalidateModule();
    },
  });

  const publishLessonMutation = useMutation({
    mutationFn: (lessonId: string) => lessonTemplateService.publish(token ?? "", lessonId),
    onSuccess: async (lesson) => {
      setSuccessMessage(`Materi ${lesson.title} berhasil dipublish.`);
      await invalidateModule();
    },
  });

  const archiveLessonMutation = useMutation({
    mutationFn: (lessonId: string) => lessonTemplateService.archive(token ?? "", lessonId),
    onSuccess: async (lesson) => {
      setSuccessMessage(`Materi ${lesson.title} berhasil diarsipkan.`);
      await invalidateModule();
    },
  });

  const deleteLessonMutation = useMutation({
    mutationFn: (lessonId: string) => lessonTemplateService.delete(token ?? "", lessonId),
    onSuccess: async () => {
      setSuccessMessage("Materi berhasil dihapus sesuai aturan soft delete backend.");
      setDeleteLessonTarget(null);
      await invalidateModule();
    },
  });

  const reorderLessonMutation = useMutation({
    mutationFn: (lessonIds: string[]) =>
      lessonTemplateService.reorder(token ?? "", moduleId, lessonIds),
    onSuccess: async () => {
      setSuccessMessage("Urutan materi berhasil diperbarui.");
      await invalidateModule();
    },
  });

  const moduleTemplate = moduleQuery.data;
  const lessons = lessonsQuery.data?.items ?? [];
  const actionError =
    updateModuleMutation.error ??
    publishModuleMutation.error ??
    archiveModuleMutation.error ??
    createLessonMutation.error ??
    updateLessonMutation.error ??
    publishLessonMutation.error ??
    archiveLessonMutation.error ??
    deleteLessonMutation.error ??
    reorderLessonMutation.error;

  function moveLesson(index: number, direction: -1 | 1) {
    const targetIndex = index + direction;

    if (targetIndex < 0 || targetIndex >= lessons.length) {
      return;
    }

    const ids = lessons.map((lesson) => lesson.id);
    const current = ids[index];
    ids[index] = ids[targetIndex] ?? ids[index];
    ids[targetIndex] = current;
    reorderLessonMutation.mutate(ids);
  }

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <Badge tone="yellow">ADMIN-14</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">
            {moduleTemplate?.title ?? "Editor Modul Default"}
          </h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
            Edit metadata dan materi template modul. Publish modul mengikuti validasi backend:
            minimal satu materi harus published dan valid.
          </p>
        </div>
        <Link
          className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-white px-4 py-2 text-sm font-bold text-ink hover:bg-slate-100"
          href="/admin/modules"
        >
          Kembali ke Daftar
        </Link>
      </header>

      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}

      {moduleQuery.isLoading ? <LoadingState title="Memuat modul" /> : null}
      {moduleQuery.isError ? (
        <ErrorState
          description={getFirstApiError(moduleQuery.error)}
          onRetry={() => void moduleQuery.refetch()}
          title="Gagal memuat modul"
        />
      ) : null}

      {moduleTemplate ? (
        <div className="grid gap-6 xl:grid-cols-[380px_1fr]">
          <Card>
            <CardHeader>
              <div className="flex flex-wrap items-center justify-between gap-3">
                <h2 className="text-xl font-black text-ink">Metadata Modul</h2>
                <Badge tone={statusTone(moduleTemplate.status)}>
                  {statusLabel(moduleTemplate.status)}
                </Badge>
              </div>
              <p className="text-xs text-slate-600">
                Diubah terakhir: {formatDate(moduleTemplate.updated_at)}
              </p>
            </CardHeader>
            <CardContent>
              <ModuleTemplateForm
                isSubmitting={updateModuleMutation.isPending}
                module={moduleTemplate}
                onCancel={() => void moduleQuery.refetch()}
                onSubmit={(payload) => updateModuleMutation.mutate(payload)}
              />
              <div className="mt-5 flex flex-col gap-2 border-t-2 border-ink pt-4 sm:flex-row">
                <Button
                  disabled={
                    publishModuleMutation.isPending || moduleTemplate.status === "published"
                  }
                  onClick={() => publishModuleMutation.mutate()}
                  variant="secondary"
                >
                  Publish Modul
                </Button>
                <Button
                  disabled={
                    archiveModuleMutation.isPending || moduleTemplate.status === "archived"
                  }
                  onClick={() => archiveModuleMutation.mutate()}
                  variant="ghost"
                >
                  Arsipkan Modul
                </Button>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
                <div>
                  <h2 className="text-xl font-black text-ink">Materi Modul</h2>
                  <p className="mt-1 text-sm text-slate-600">
                    Total materi aktif di halaman ini: {lessons.length}
                  </p>
                </div>
                <Button onClick={() => setCreateLessonOpen(true)}>Tambah Materi</Button>
              </div>
            </CardHeader>
            <CardContent>
              {lessonsQuery.isLoading ? <LoadingState title="Memuat materi" /> : null}
              {lessonsQuery.isError ? (
                <ErrorState
                  description={getFirstApiError(lessonsQuery.error)}
                  onRetry={() => void lessonsQuery.refetch()}
                  title="Gagal memuat materi"
                />
              ) : null}
              {!lessonsQuery.isLoading && !lessonsQuery.isError ? (
                lessons.length === 0 ? (
                  <EmptyState
                    description="Belum ada materi. Tambahkan minimal satu materi published sebelum publish modul."
                    title="Materi kosong"
                  />
                ) : (
                  <div className="grid gap-4">
                    <Table>
                      <TableHeader>
                        <tr>
                          <th className="px-4 py-3">Materi</th>
                          <th className="px-4 py-3">Jenis</th>
                          <th className="px-4 py-3">Status</th>
                          <th className="px-4 py-3">Urutan</th>
                          <th className="px-4 py-3">Aksi</th>
                        </tr>
                      </TableHeader>
                      <tbody>
                        {lessons.map((lesson, index) => (
                          <tr key={lesson.id}>
                            <TableCell>
                              <p className="font-black text-ink">{lesson.title}</p>
                              <p className="mt-1 line-clamp-2 text-xs leading-5 text-slate-600">
                                {lesson.description ?? "Tanpa deskripsi."}
                              </p>
                            </TableCell>
                            <TableCell>{contentTypeLabel(lesson.content_type)}</TableCell>
                            <TableCell>
                              <Badge tone={statusTone(lesson.status)}>
                                {statusLabel(lesson.status)}
                              </Badge>
                            </TableCell>
                            <TableCell>{lesson.sort_order}</TableCell>
                            <TableCell>
                              <div className="flex flex-wrap gap-2">
                                <Button
                                  className="min-h-9 px-3 py-1 text-xs"
                                  disabled={index === 0 || reorderLessonMutation.isPending}
                                  onClick={() => moveLesson(index, -1)}
                                  variant="ghost"
                                >
                                  Naik
                                </Button>
                                <Button
                                  className="min-h-9 px-3 py-1 text-xs"
                                  disabled={
                                    index === lessons.length - 1 || reorderLessonMutation.isPending
                                  }
                                  onClick={() => moveLesson(index, 1)}
                                  variant="ghost"
                                >
                                  Turun
                                </Button>
                                <Button
                                  className="min-h-9 px-3 py-1 text-xs"
                                  onClick={() => setEditingLesson(lesson)}
                                  variant="secondary"
                                >
                                  Edit
                                </Button>
                                {lesson.status !== "published" ? (
                                  <Button
                                    className="min-h-9 px-3 py-1 text-xs"
                                    disabled={publishLessonMutation.isPending}
                                    onClick={() => publishLessonMutation.mutate(lesson.id)}
                                    variant="secondary"
                                  >
                                    Publish
                                  </Button>
                                ) : null}
                                {lesson.status !== "archived" ? (
                                  <Button
                                    className="min-h-9 px-3 py-1 text-xs"
                                    disabled={archiveLessonMutation.isPending}
                                    onClick={() => archiveLessonMutation.mutate(lesson.id)}
                                    variant="ghost"
                                  >
                                    Arsipkan
                                  </Button>
                                ) : null}
                                <Button
                                  className="min-h-9 px-3 py-1 text-xs"
                                  disabled={deleteLessonMutation.isPending}
                                  onClick={() => setDeleteLessonTarget(lesson)}
                                  variant="danger"
                                >
                                  Hapus
                                </Button>
                              </div>
                            </TableCell>
                          </tr>
                        ))}
                      </tbody>
                    </Table>

                    <div className="grid gap-4">
                      {lessons.map((lesson) => (
                        <div
                          className="rounded-lg border-2 border-ink bg-yellow-50 p-4"
                          key={`preview-${lesson.id}`}
                        >
                          <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
                            <h3 className="text-base font-black text-ink">
                              Preview: {lesson.title}
                            </h3>
                            <Badge tone="neutral">{contentTypeLabel(lesson.content_type)}</Badge>
                          </div>
                          <LessonPreview lesson={lesson} />
                        </div>
                      ))}
                    </div>
                  </div>
                )
              ) : null}
            </CardContent>
          </Card>
        </div>
      ) : null}

      <Modal
        onClose={() => setCreateLessonOpen(false)}
        open={createLessonOpen}
        title="Tambah Materi Modul"
      >
        <ModuleContentForm
          isSubmitting={createLessonMutation.isPending}
          onCancel={() => setCreateLessonOpen(false)}
          onSubmit={(payload) => createLessonMutation.mutate(payload)}
          token={token ?? ""}
        />
      </Modal>

      <Modal
        onClose={() => setEditingLesson(null)}
        open={Boolean(editingLesson)}
        title="Edit Materi Modul"
      >
        {editingLesson ? (
          <ModuleContentForm
            isSubmitting={updateLessonMutation.isPending}
            lesson={editingLesson}
            onCancel={() => setEditingLesson(null)}
            onSubmit={(payload) =>
              updateLessonMutation.mutate({ lessonId: editingLesson.id, payload })
            }
            token={token ?? ""}
          />
        ) : null}
      </Modal>

      <ConfirmDialog
        confirmLabel={deleteLessonMutation.isPending ? "Menghapus..." : "Hapus Materi"}
        description={
          deleteLessonTarget
            ? `Materi "${deleteLessonTarget.title}" akan dihapus dengan soft delete sesuai backend.`
            : ""
        }
        onCancel={() => setDeleteLessonTarget(null)}
        onConfirm={() => {
          if (deleteLessonTarget) {
            deleteLessonMutation.mutate(deleteLessonTarget.id);
          }
        }}
        open={Boolean(deleteLessonTarget)}
        title="Hapus materi?"
      />
    </div>
  );
}
