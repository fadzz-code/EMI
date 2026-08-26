"use client";

import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Archive, Eye, Pencil, Plus, Send, Trash2 } from "lucide-react";
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
  MutationAlert,
  PageHeader,
  StatsCard,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { TeacherModuleCreateForm } from "./teacher-module-create";
import { teacherService } from "./teacher-service";
import {
  formatCount,
  formatDate,
  formatOptional,
  statusLabel,
  teacherStatusTone,
} from "./teacher-utils";
import { moduleLifecycle } from "./teacher-workflow";
import type { TeacherClassModule } from "./types";

export function TeacherModuleList() {
  const { token, user } = useAuth();
  const classId = user?.active_class?.id;
  const queryClient = useQueryClient();
  const [createOpen, setCreateOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<TeacherClassModule | null>(
    null,
  );
  const [archiveTarget, setArchiveTarget] = useState<TeacherClassModule | null>(
    null,
  );
  const [publishTarget, setPublishTarget] = useState<TeacherClassModule | null>(
    null,
  );

  const modulesQuery = useQuery({
    queryKey: ["teacher", "classes", classId, "modules", "page"],
    queryFn: () => teacherService.classModules(token ?? "", classId!),
    enabled: Boolean(token && classId),
  });

  async function invalidateModules() {
    await queryClient.invalidateQueries({
      queryKey: ["teacher", "classes", classId, "modules"],
    });
  }

  const createMutation = useMutation({
    mutationFn: (payload: {
      title: string;
      description?: string | null;
      sort_order?: number;
    }) => teacherService.createClassModule(token ?? "", classId ?? "", payload),
    onSuccess: async () => {
      setCreateOpen(false);
      await invalidateModules();
    },
  });

  const archiveMutation = useMutation({
    mutationFn: (moduleId: string) =>
      teacherService.archiveClassModule(token ?? "", moduleId),
    onSuccess: async () => {
      setArchiveTarget(null);
      await invalidateModules();
    },
  });

  const publishMutation = useMutation({
    mutationFn: (moduleId: string) =>
      teacherService.publishClassModule(token ?? "", moduleId),
    onSuccess: async () => {
      setPublishTarget(null);
      await invalidateModules();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (moduleId: string) =>
      teacherService.deleteClassModule(token ?? "", moduleId),
    onSuccess: async () => {
      setDeleteTarget(null);
      await invalidateModules();
    },
  });

  const modules = modulesQuery.data?.items ?? [];
  const publishedCount = modules.filter(
    (module) => module.status === "published",
  ).length;
  const actionError =
    archiveMutation.error ?? publishMutation.error ?? deleteMutation.error;

  return (
    <div className="grid gap-8">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <PageHeader
          badge="Guru"
          description="Kelola modul pembelajaran kelas Anda: tambah, ubah, arsipkan, atau hapus sesuai kebutuhan siswa di kelas ini."
          title="Modul Kelas"
        />
        <Button
          disabled={!classId}
          onClick={() => setCreateOpen(true)}
          type="button"
        >
          <Plus className="size-4" strokeWidth={2.5} />
          Tambah Modul
        </Button>
      </div>

      {!classId ? (
        <Alert tone="warning">
          Anda belum memiliki kelas aktif. Minta Admin untuk menetapkan Anda ke
          sebuah kelas.
        </Alert>
      ) : null}
      <MutationAlert eventKey={Math.max(archiveMutation.submittedAt, publishMutation.submittedAt, deleteMutation.submittedAt)} tone="error" visible={Boolean(actionError)}>{getFirstApiError(actionError)}</MutationAlert>

      {modulesQuery.isLoading ? (
        <LoadingState title="Memuat modul kelas" />
      ) : null}
      {modulesQuery.isError ? (
        <ErrorState
          description={getFirstApiError(modulesQuery.error)}
          onRetry={() => void modulesQuery.refetch()}
          title="Gagal memuat modul"
        />
      ) : null}

      {!modulesQuery.isLoading && !modulesQuery.isError && classId ? (
        modules.length === 0 ? (
          <Card>
            <CardContent>
              <EmptyState
                description="Belum ada modul kelas yang bisa dikelola."
                title="Modul belum tersedia"
              />
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-4">
            <section className="grid gap-4 sm:grid-cols-3">
              <StatsCard
                helper={user?.active_class?.name ?? "Kelas aktif"}
                label="Total modul"
                value={formatCount(modules.length)}
              />
              <StatsCard
                helper="Status published"
                label="Modul terbit"
                value={formatCount(publishedCount)}
              />
              <StatsCard
                helper="Buka editor untuk mengatur materi"
                label="Aksi"
                value="Kelola"
              />
            </section>
            <div className="grid auto-rows-fr gap-6 md:grid-cols-2">
              {modules.map((module) => (
                <Card
                  className="flex h-full flex-col transition hover:-translate-y-1 hover:shadow-emi"
                  key={module.id}
                >
                  <CardHeader>
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <h2 className="text-xl font-black text-ink">
                          {module.title}
                        </h2>
                        <div className="mt-2 flex items-center gap-2">
                          <Badge tone={teacherStatusTone(module.status)}>
                            {statusLabel(module.status)}
                          </Badge>
                          <span className="rounded-lg border border-border px-2 py-0.5 text-xs font-black text-muted">
                            Urutan: {formatOptional(module.sort_order)}
                          </span>
                        </div>
                      </div>
                      <Link
                        className="group inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5"
                        href={teacherRoutes.moduleEdit(module.id)}
                      >
                        <Pencil className="size-5" strokeWidth={2.5} /> Edit
                        Modul
                      </Link>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm leading-6 text-muted line-clamp-2">
                      {formatOptional(module.description)}
                    </p>
                    <dl className="mt-4 grid gap-3 text-sm sm:grid-cols-2">
                      <div className="rounded-xl bg-surface-muted p-3">
                        <dt className="font-black uppercase text-muted">
                          Terbit
                        </dt>
                        <dd className="mt-1 font-bold text-primary">
                          {formatDate(module.published_at)}
                        </dd>
                      </div>
                      <div className="rounded-xl bg-surface-muted p-3">
                        <dt className="font-black uppercase text-muted">
                          Lesson
                        </dt>
                        <dd className="mt-1 font-bold text-primary">
                          {module.lessons
                            ? formatCount(module.lessons.length)
                            : "Lihat di edit"}
                        </dd>
                      </div>
                    </dl>
                    <div className="mt-4 flex flex-wrap gap-2">
                      <Link
                        className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 text-xs font-black text-ink transition hover:-translate-y-0.5 hover:bg-surface-muted"
                        href={teacherRoutes.modulePreview(module.id)}
                      >
                        <Eye className="size-4" strokeWidth={2.5} /> Preview
                      </Link>
                      {module.status === "archived" ? (
                        <button
                          className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 text-xs font-black text-ink transition hover:-translate-y-0.5 hover:bg-surface-muted disabled:opacity-50"
                          disabled={publishMutation.isPending}
                          onClick={() => setPublishTarget(module)}
                          type="button"
                        >
                          <Send className="size-4" strokeWidth={2.5} />{" "}
                          Terbitkan
                        </button>
                      ) : (
                        <button
                          className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 text-xs font-black text-ink transition hover:-translate-y-0.5 hover:bg-surface-muted disabled:opacity-50"
                          disabled={archiveMutation.isPending}
                          onClick={() => setArchiveTarget(module)}
                          type="button"
                        >
                          <Archive className="size-4" strokeWidth={2.5} />{" "}
                          Arsipkan
                        </button>
                      )}
                      <button
                        className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-danger/40 bg-surface px-3 text-xs font-black text-danger transition hover:-translate-y-0.5 hover:border-danger disabled:opacity-50"
                        disabled={
                          deleteMutation.isPending ||
                          moduleLifecycle(module) !== "delete"
                        }
                        onClick={() => setDeleteTarget(module)}
                        title={
                          moduleLifecycle(module) !== "delete"
                            ? "Modul yang masih published harus diarsipkan terlebih dahulu sebelum dihapus."
                            : undefined
                        }
                        type="button"
                      >
                        <Trash2 className="size-4" strokeWidth={2.5} /> Hapus
                      </button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>
        )
      ) : null}

      <Modal
        onClose={() => setCreateOpen(false)}
        open={createOpen}
        title="Tambah Modul Kelas"
      >
        <TeacherModuleCreateForm
          error={createMutation.error}
          isSubmitting={createMutation.isPending}
          submittedAt={createMutation.submittedAt}
          onCancel={() => setCreateOpen(false)}
          onSubmit={(payload) => createMutation.mutate(payload)}
        />
      </Modal>

      <ConfirmDialog
        confirmLabel={deleteMutation.isPending ? "Menghapus..." : "Hapus Modul"}
        description={
          deleteTarget
            ? `Modul "${deleteTarget.title}" akan dihapus secara permanen dan hanya berlaku untuk kelas ini.`
            : ""
        }
        isConfirming={deleteMutation.isPending}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => {
          if (deleteTarget) deleteMutation.mutate(deleteTarget.id);
        }}
        open={Boolean(deleteTarget)}
        title="Hapus modul?"
      />

      <ConfirmDialog
        confirmLabel={
          archiveMutation.isPending ? "Mengarsipkan..." : "Arsipkan Modul"
        }
        confirmVariant="secondary"
        description={
          archiveTarget
            ? `Arsipkan modul "${archiveTarget.title}"? Modul tidak akan terlihat oleh siswa.`
            : ""
        }
        isConfirming={archiveMutation.isPending}
        onCancel={() => setArchiveTarget(null)}
        onConfirm={() => {
          if (archiveTarget) archiveMutation.mutate(archiveTarget.id);
        }}
        open={Boolean(archiveTarget)}
        title="Arsipkan modul?"
      />

      <ConfirmDialog
        confirmLabel={
          publishMutation.isPending ? "Menerbitkan..." : "Terbitkan Modul"
        }
        confirmVariant="primary"
        description={
          publishTarget
            ? `Terbitkan kembali modul "${publishTarget.title}"? Modul akan terlihat oleh siswa lagi.`
            : ""
        }
        isConfirming={publishMutation.isPending}
        onCancel={() => setPublishTarget(null)}
        onConfirm={() => {
          if (publishTarget) publishMutation.mutate(publishTarget.id);
        }}
        open={Boolean(publishTarget)}
        title="Terbitkan modul?"
      />
    </div>
  );
}
