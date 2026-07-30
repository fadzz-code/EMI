"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Archive, ArrowLeft, Eye, Pencil, Plus, Trash2 } from "lucide-react";
import { useState } from "react";

import { Alert, Badge, Button, Card, CardContent, CardHeader, ConfirmDialog, EmptyState, ErrorState, Input, LoadingState, Modal, PageHeader, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { TeacherLessonCreateForm } from "./teacher-lesson-create";
import { teacherService } from "./teacher-service";
import { statusLabel } from "./teacher-utils";
import { lessonLifecycle, moduleLifecycle } from "./teacher-workflow";
import type { TeacherClassLesson, TeacherLessonPayload } from "./types";

export function TeacherModuleEdit({ moduleId }: { moduleId: string }) {
  const { token } = useAuth();
  const router = useRouter();
  const queryClient = useQueryClient();
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [createLessonOpen, setCreateLessonOpen] = useState(false);
  const [deleteModuleOpen, setDeleteModuleOpen] = useState(false);
  const [archiveModuleOpen, setArchiveModuleOpen] = useState(false);
  const [publishModuleOpen, setPublishModuleOpen] = useState(false);
  const [deleteLessonTarget, setDeleteLessonTarget] = useState<TeacherClassLesson | null>(null);
  const [archiveLessonTarget, setArchiveLessonTarget] = useState<TeacherClassLesson | null>(null);

  const moduleQuery = useQuery({
    queryKey: ["teacher", "class-modules", moduleId],
    queryFn: () => teacherService.classModuleDetail(token ?? "", moduleId),
    enabled: Boolean(token && moduleId),
  });

  async function invalidateModule() {
    await queryClient.invalidateQueries({ queryKey: ["teacher", "class-modules", moduleId] });
    await queryClient.invalidateQueries({ queryKey: ["teacher", "classes"] });
  }

  const updateMutation = useMutation({
    mutationFn: (payload: { title: string; description?: string; sort_order?: number }) =>
      teacherService.updateClassModule(token ?? "", moduleId, payload),
    onSuccess: async () => {
      setSuccessMsg("Modul berhasil disimpan.");
      await invalidateModule();
    },
  });

  const publishMutation = useMutation({
    mutationFn: () => teacherService.publishClassModule(token ?? "", moduleId),
    onSuccess: async () => {
      setSuccessMsg("Modul berhasil dipublikasikan.");
      setPublishModuleOpen(false);
      await invalidateModule();
    },
  });

  const archiveModuleMutation = useMutation({
    mutationFn: () => teacherService.archiveClassModule(token ?? "", moduleId),
    onSuccess: async () => {
      setSuccessMsg("Modul berhasil diarsipkan.");
      setArchiveModuleOpen(false);
      await invalidateModule();
    },
  });

  const deleteModuleMutation = useMutation({
    mutationFn: () => teacherService.deleteClassModule(token ?? "", moduleId),
    onSuccess: () => {
      setDeleteModuleOpen(false);
      router.push(teacherRoutes.modules);
    },
  });

  const createLessonMutation = useMutation({
    mutationFn: (payload: TeacherLessonPayload) => teacherService.createClassLesson(token ?? "", moduleId, payload),
    onSuccess: async (lesson) => {
      setSuccessMsg(`Materi ${lesson.title} berhasil dibuat.`);
      setCreateLessonOpen(false);
      await invalidateModule();
    },
  });

  const archiveLessonMutation = useMutation({
    mutationFn: (lessonId: string) => teacherService.archiveClassLesson(token ?? "", lessonId),
    onSuccess: async (lesson) => {
      setSuccessMsg(`Materi ${lesson.title} berhasil diarsipkan.`);
      setArchiveLessonTarget(null);
      await invalidateModule();
    },
  });

  const deleteLessonMutation = useMutation({
    mutationFn: (lessonId: string) => teacherService.deleteClassLesson(token ?? "", lessonId),
    onSuccess: async () => {
      setSuccessMsg("Materi berhasil dihapus.");
      setDeleteLessonTarget(null);
      await invalidateModule();
    },
  });

  const moduleData = moduleQuery.data;
  const moduleAction = moduleData ? moduleLifecycle(moduleData) : "archive";
  const actionError =
    updateMutation.error ??
    publishMutation.error ??
    archiveModuleMutation.error ??
    deleteModuleMutation.error ??
    createLessonMutation.error ??
    archiveLessonMutation.error ??
    deleteLessonMutation.error;

  return (
    <div className="grid gap-8">
      <div className="flex flex-wrap gap-3">
        <Link className="inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-primary transition hover:-translate-y-0.5 hover:bg-[var(--color-primary-muted)] hover:shadow-emi" href={teacherRoutes.modules}>
          <ArrowLeft className="size-5" strokeWidth={2.5} /> Kembali ke Daftar Modul
        </Link>
        <Link className="inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink transition hover:-translate-y-0.5 hover:bg-surface-muted" href={teacherRoutes.modulePreview(moduleId)}>
          <Eye className="size-5" strokeWidth={2.5} /> Preview Modul
        </Link>
      </div>
      <PageHeader badge="Guru" description="Ubah judul, deskripsi, atau urutan modul kelas Anda." title="Edit Modul" />

      {moduleQuery.isLoading ? <LoadingState title="Memuat detail modul" /> : null}
      {moduleQuery.isError ? <ErrorState description={getFirstApiError(moduleQuery.error)} onRetry={() => void moduleQuery.refetch()} title="Gagal memuat modul" /> : null}

      {moduleData ? (
        <div className="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-black text-primary">Form Edit Modul</h2>
                <Badge tone={moduleData.status === "published" ? "blue" : "neutral"}>{statusLabel(moduleData.status)}</Badge>
              </div>
            </CardHeader>
            <CardContent>
              <form
                className="grid gap-4"
                key={moduleData.id}
                onSubmit={(e) => {
                  e.preventDefault();
                  setSuccessMsg(null);
                  const formData = new FormData(e.currentTarget);
                  updateMutation.mutate({
                    title: String(formData.get("title") ?? ""),
                    description: String(formData.get("description") ?? ""),
                    sort_order: Number(formData.get("sort_order") ?? 1),
                  });
                }}
              >
                {successMsg ? <Alert tone="success">{successMsg}</Alert> : null}
                {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}
                
                <label className="grid gap-2 text-sm font-black text-primary">
                  Judul Modul
                  <Input defaultValue={moduleData.title} name="title" required />
                </label>
                <label className="grid gap-2 text-sm font-black text-primary">
                  Deskripsi Modul
                  <Textarea defaultValue={moduleData.description ?? ""} name="description" rows={4} />
                </label>
                <label className="grid gap-2 text-sm font-black text-primary">
                  Urutan Tampil (Sort Order)
                  <Input defaultValue={moduleData.sort_order ?? 1} min={1} name="sort_order" type="number" required />
                </label>
                
                <div className="mt-2 flex flex-col gap-3 sm:flex-row">
                  <Button disabled={updateMutation.isPending || publishMutation.isPending} type="submit">
                    {updateMutation.isPending ? "Menyimpan..." : "Simpan Perubahan"}
                  </Button>
                  {moduleData.status !== "published" ? (
                    <Button
                      disabled={publishMutation.isPending || updateMutation.isPending}
                      onClick={() => {
                        setSuccessMsg(null);
                        setPublishModuleOpen(true);
                      }}
                      type="button"
                      variant="secondary"
                    >
                      {publishMutation.isPending ? "Menerbitkan..." : moduleData.status === "archived" ? "Terbitkan Ulang" : "Terbitkan Modul"}
                    </Button>
                  ) : null}
                </div>
              </form>
              <div className="mt-5 flex flex-col gap-3 border-t-2 border-border pt-4 sm:flex-row">
                <Button
                  disabled={archiveModuleMutation.isPending || moduleData.status === "archived"}
                  onClick={() => {
                    setSuccessMsg(null);
                    setArchiveModuleOpen(true);
                  }}
                  type="button"
                  variant="ghost"
                >
                  <Archive className="size-4" strokeWidth={2.5} />
                  {archiveModuleMutation.isPending ? "Mengarsipkan..." : "Arsipkan Modul"}
                </Button>
                <Button
                  disabled={deleteModuleMutation.isPending || moduleAction !== "delete"}
                  onClick={() => setDeleteModuleOpen(true)}
                  type="button"
                  variant="danger"
                >
                  <Trash2 className="size-4" strokeWidth={2.5} />
                  Hapus Modul
                </Button>
              </div>
              {moduleAction !== "delete" ? (
                <p className="mt-2 text-xs font-semibold text-muted">Modul yang masih published harus diarsipkan terlebih dahulu sebelum bisa dihapus permanen.</p>
              ) : null}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <div className="flex items-center justify-between gap-3">
                <h2 className="text-xl font-black text-primary">Daftar Materi (Lessons)</h2>
                <Button onClick={() => setCreateLessonOpen(true)} type="button">
                  <Plus className="size-4" strokeWidth={2.5} />
                  Tambah Materi
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              {moduleData.lessons && moduleData.lessons.length > 0 ? (
                <div className="grid gap-3">
                  {moduleData.lessons.map((lesson) => (
                    <div className="flex flex-col gap-2 rounded-xl border border-border bg-surface-muted p-3" key={lesson.id}>
                      <div className="flex items-start justify-between gap-3">
                        <div className="font-bold text-primary">{lesson.title}</div>
                        <Badge tone={lesson.status === "published" ? "blue" : "neutral"}>{statusLabel(lesson.status)}</Badge>
                      </div>
                      <div className="text-xs text-muted">Tipe: {lesson.content_type || "-"} | Urutan: {lesson.sort_order}</div>
                      <div className="mt-2 flex flex-wrap gap-2">
                        <Link
                          className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 text-xs font-black text-primary transition hover:-translate-y-0.5 hover:bg-primary hover:text-primary-foreground hover:shadow-emi"
                          href={teacherRoutes.lessonPreview(moduleId, lesson.id)}
                        >
                          <Eye className="size-4" strokeWidth={2.5} /> Lihat Materi
                        </Link>
                        <Link
                          className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 text-xs font-black text-primary transition hover:-translate-y-0.5 hover:bg-primary hover:text-primary-foreground hover:shadow-emi"
                          href={teacherRoutes.lessonEdit(moduleId, lesson.id)}
                        >
                          <Pencil className="size-4" strokeWidth={2.5} /> Edit Materi
                        </Link>
                        {lesson.status !== "archived" ? (
                          <button
                            className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 text-xs font-black text-ink transition hover:-translate-y-0.5 hover:bg-surface-muted disabled:opacity-50"
                            disabled={archiveLessonMutation.isPending}
                            onClick={() => {
                              setSuccessMsg(null);
                              setArchiveLessonTarget(lesson);
                            }}
                            type="button"
                          >
                            <Archive className="size-4" strokeWidth={2.5} /> Arsipkan
                          </button>
                        ) : null}
                        <button
                          className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-danger/40 bg-surface px-3 text-xs font-black text-danger transition hover:-translate-y-0.5 hover:border-danger disabled:opacity-50"
                          disabled={deleteLessonMutation.isPending || lessonLifecycle(lesson) !== "delete"}
                          onClick={() => {
                            setSuccessMsg(null);
                            setDeleteLessonTarget(lesson);
                          }}
                          title={lessonLifecycle(lesson) !== "delete" ? "Materi yang masih published harus diarsipkan terlebih dahulu sebelum dihapus." : undefined}
                          type="button"
                        >
                          <Trash2 className="size-4" strokeWidth={2.5} /> Hapus
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyState description="Modul ini tidak memiliki materi (lessons)." title="Materi kosong" />
              )}
            </CardContent>
          </Card>
        </div>
      ) : null}

      <Modal onClose={() => setCreateLessonOpen(false)} open={createLessonOpen} title="Tambah Materi Modul">
        <TeacherLessonCreateForm
          isSubmitting={createLessonMutation.isPending}
          onCancel={() => setCreateLessonOpen(false)}
          onSubmit={(payload) => createLessonMutation.mutate(payload)}
          token={token ?? ""}
        />
      </Modal>

      <ConfirmDialog
        confirmLabel={deleteModuleMutation.isPending ? "Menghapus..." : "Hapus Modul"}
        description={moduleData ? `Modul "${moduleData.title}" akan dihapus secara permanen dan hanya berlaku untuk kelas ini.` : ""}
        isConfirming={deleteModuleMutation.isPending}
        onCancel={() => setDeleteModuleOpen(false)}
        onConfirm={() => deleteModuleMutation.mutate()}
        open={deleteModuleOpen}
        title="Hapus modul?"
      />

      <ConfirmDialog
        confirmLabel={archiveModuleMutation.isPending ? "Mengarsipkan..." : "Arsipkan Modul"}
        confirmVariant="secondary"
        description={moduleData ? `Arsipkan modul "${moduleData.title}"? Modul tidak akan terlihat oleh siswa.` : ""}
        isConfirming={archiveModuleMutation.isPending}
        onCancel={() => setArchiveModuleOpen(false)}
        onConfirm={() => archiveModuleMutation.mutate()}
        open={archiveModuleOpen}
        title="Arsipkan modul?"
      />

      <ConfirmDialog
        confirmLabel={publishMutation.isPending ? "Menerbitkan..." : "Terbitkan Modul"}
        confirmVariant="primary"
        description={moduleData ? `Terbitkan modul "${moduleData.title}"? Modul akan terlihat oleh siswa.` : ""}
        isConfirming={publishMutation.isPending}
        onCancel={() => setPublishModuleOpen(false)}
        onConfirm={() => publishMutation.mutate()}
        open={publishModuleOpen}
        title="Terbitkan modul?"
      />

      <ConfirmDialog
        confirmLabel={deleteLessonMutation.isPending ? "Menghapus..." : "Hapus Materi"}
        description={deleteLessonTarget ? `Materi "${deleteLessonTarget.title}" akan dihapus secara permanen dari modul ini.` : ""}
        isConfirming={deleteLessonMutation.isPending}
        onCancel={() => setDeleteLessonTarget(null)}
        onConfirm={() => {
          if (deleteLessonTarget) deleteLessonMutation.mutate(deleteLessonTarget.id);
        }}
        open={Boolean(deleteLessonTarget)}
        title="Hapus materi?"
      />

      <ConfirmDialog
        confirmLabel={archiveLessonMutation.isPending ? "Mengarsipkan..." : "Arsipkan Materi"}
        confirmVariant="secondary"
        description={archiveLessonTarget ? `Arsipkan materi "${archiveLessonTarget.title}"? Materi tidak akan terlihat oleh siswa.` : ""}
        isConfirming={archiveLessonMutation.isPending}
        onCancel={() => setArchiveLessonTarget(null)}
        onConfirm={() => {
          if (archiveLessonTarget) archiveLessonMutation.mutate(archiveLessonTarget.id);
        }}
        open={Boolean(archiveLessonTarget)}
        title="Arsipkan materi?"
      />
    </div>
  );
}
