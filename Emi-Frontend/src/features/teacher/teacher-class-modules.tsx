"use client";

import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Archive, ArrowLeft, Pencil, Plus, Trash2 } from "lucide-react";
import { useState } from "react";

import {
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

import { TeacherClassNav } from "./teacher-class-nav";
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

export function TeacherClassModules({ classId }: { classId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [createOpen, setCreateOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<TeacherClassModule | null>(
    null,
  );

  const modulesQuery = useQuery({
    queryKey: ["teacher", "classes", classId, "modules", "page"],
    queryFn: () => teacherService.classModules(token ?? "", classId),
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
    }) => teacherService.createClassModule(token ?? "", classId, payload),
    onSuccess: async () => {
      setCreateOpen(false);
      await invalidateModules();
    },
  });

  const archiveMutation = useMutation({
    mutationFn: (moduleId: string) =>
      teacherService.archiveClassModule(token ?? "", moduleId),
    onSuccess: async () => {
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
  const actionError = archiveMutation.error ?? deleteMutation.error;

  return (
    <div className="grid gap-8">
      <Link
        className="group inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-primary transition hover:-translate-y-0.5 hover:bg-[var(--color-primary-muted)] hover:shadow-emi"
        href={teacherRoutes.classDetail(classId)}
      >
        <ArrowLeft className="size-5" strokeWidth={2.5} /> Kembali ke Detail
        Kelas
      </Link>
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <PageHeader
          badge="Guru"
          description="Kelola modul pembelajaran untuk kelas ini. Perubahan hanya berlaku untuk kelas ini."
          title="Modul Kelas"
        />
        <Button onClick={() => setCreateOpen(true)} type="button">
          <Plus className="size-4" strokeWidth={2.5} />
          Tambah Modul
        </Button>
      </div>

      <TeacherClassNav classId={classId} />

      <MutationAlert eventKey={Math.max(archiveMutation.submittedAt, deleteMutation.submittedAt)} tone="error" visible={Boolean(actionError)}>{getFirstApiError(actionError)}</MutationAlert>
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

      {!modulesQuery.isLoading && !modulesQuery.isError ? (
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
                helper="Semua status"
                label="Total modul"
                value={formatCount(modules.length)}
              />
              <StatsCard
                helper="Status published"
                label="Modul terbit"
                value={formatCount(publishedCount)}
              />
              <StatsCard
                helper="Buka kartu modul untuk melihat materi"
                label="Materi"
                value="Tersedia"
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
                        <Badge tone={teacherStatusTone(module.status)}>
                          {statusLabel(module.status)}
                        </Badge>
                        <h2 className="mt-2 text-xl font-black text-primary">
                          {module.title}
                        </h2>
                      </div>
                      <Link
                        className="inline-flex min-h-11 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition hover:-translate-y-0.5"
                        href={teacherRoutes.moduleEdit(module.id)}
                      >
                        <Pencil className="size-5" strokeWidth={2.5} /> Edit
                        Modul
                      </Link>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm leading-6 text-muted">
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
                          {formatCount(module.lessons?.length)}
                        </dd>
                      </div>
                    </dl>
                    <ModuleLessons token={token ?? ""} moduleId={module.id} />
                    <div className="mt-4 flex flex-wrap gap-2">
                      {module.status !== "archived" ? (
                        <button
                          className="inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 text-xs font-black text-ink transition hover:-translate-y-0.5 hover:bg-surface-muted disabled:opacity-50"
                          disabled={archiveMutation.isPending}
                          onClick={() => {
                            if (
                              confirm(
                                `Arsipkan modul "${module.title}"? Modul tidak akan terlihat oleh siswa.`,
                              )
                            )
                              archiveMutation.mutate(module.id);
                          }}
                          type="button"
                        >
                          <Archive className="size-4" strokeWidth={2.5} />{" "}
                          Arsipkan
                        </button>
                      ) : null}
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
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => {
          if (deleteTarget) deleteMutation.mutate(deleteTarget.id);
        }}
        open={Boolean(deleteTarget)}
        title="Hapus modul?"
      />
    </div>
  );
}

function ModuleLessons({
  token,
  moduleId,
}: {
  token: string;
  moduleId: string;
}) {
  const detailQuery = useQuery({
    queryKey: ["teacher", "class-modules", moduleId],
    queryFn: () => teacherService.classModuleDetail(token, moduleId),
    enabled: Boolean(token && moduleId),
  });
  const lessons = detailQuery.data?.lessons ?? [];

  if (detailQuery.isLoading) {
    return (
      <p className="mt-4 text-sm font-bold text-muted">Memuat lesson...</p>
    );
  }

  if (detailQuery.isError) {
    return (
      <p className="mt-4 text-sm font-bold text-orange-600">
        Lesson tidak dapat dimuat: {getFirstApiError(detailQuery.error)}
      </p>
    );
  }

  if (lessons.length === 0) {
    return (
      <p className="mt-4 text-sm font-bold text-muted">
        Materi belum tersedia untuk modul ini.
      </p>
    );
  }

  return (
    <div className="mt-4 grid gap-2">
      {lessons.map((lesson) => (
        <details
          className="rounded-xl border border-border bg-surface p-3"
          key={lesson.id}
        >
          <summary className="cursor-pointer font-black text-primary">
            {lesson.title}
          </summary>
          <p className="mt-2 text-sm text-muted">
            {formatOptional(lesson.description)}
          </p>
          {lesson.content_body ? (
            <p className="mt-2 rounded-lg bg-surface-muted p-3 text-sm text-muted">
              {lesson.content_body}
            </p>
          ) : null}
        </details>
      ))}
    </div>
  );
}
