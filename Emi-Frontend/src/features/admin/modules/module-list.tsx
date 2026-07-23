"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  Alert,
  Badge,
  Button,
  Card,
  CardContent,
  ConfirmDialog,
  EmptyState,
  ErrorState,
  FilterPanel,
  Input,
  LoadingState,
  Modal,
  Pagination,
  Select,
  Table,
  TableCell,
  TableHeader,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { classService } from "@/features/admin/management/management-service";
import { getFirstApiError } from "@/lib/api-client";

import { ModuleTemplateForm } from "./module-form";
import { moduleTemplateService } from "./module-service";
import { formatDate, statusLabel, statusTone } from "./module-utils";
import type { ModuleTemplate, ModuleTemplatePayload, ModuleTemplateStatus } from "./types";

export function ModuleList() {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<ModuleTemplateStatus | "">("");
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [applyTarget, setApplyTarget] = useState<ModuleTemplate | null>(null);
  const [selectedClassIds, setSelectedClassIds] = useState<string[]>([]);
  const [publishAfterApply, setPublishAfterApply] = useState(true);
  const [deleteTarget, setDeleteTarget] = useState<ModuleTemplate | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const filters = useMemo(
    () => ({
      search,
      status,
      page,
      per_page: 12,
    }),
    [page, search, status],
  );

  const modulesQuery = useQuery({
    queryKey: ["admin", "module-templates", filters],
    queryFn: () => moduleTemplateService.list(token ?? "", filters),
    enabled: Boolean(token),
  });

  const classesQuery = useQuery({
    queryKey: ["admin", "classes", "apply-targets"],
    queryFn: () => classService.list(token ?? "", { status: "active", per_page: 100 }),
    enabled: Boolean(token),
  });

  const createMutation = useMutation({
    mutationFn: (payload: ModuleTemplatePayload) =>
      moduleTemplateService.create(token ?? "", payload),
    onSuccess: async (module) => {
      setSuccessMessage(`Modul ${module.title} berhasil dibuat.`);
      setCreateModalOpen(false);
      await queryClient.invalidateQueries({ queryKey: ["admin", "module-templates"] });
    },
  });

  const publishMutation = useMutation({
    mutationFn: (moduleId: string) => moduleTemplateService.publish(token ?? "", moduleId),
    onSuccess: async (module) => {
      setSuccessMessage(`Modul ${module.title} berhasil diterbitkan.`);
      await queryClient.invalidateQueries({ queryKey: ["admin", "module-templates"] });
    },
  });

  const archiveMutation = useMutation({
    mutationFn: (moduleId: string) => moduleTemplateService.archive(token ?? "", moduleId),
    onSuccess: async (module) => {
      setSuccessMessage(`Modul ${module.title} berhasil diarsipkan.`);
      await queryClient.invalidateQueries({ queryKey: ["admin", "module-templates"] });
    },
  });

  const applyMutation = useMutation({
    mutationFn: async ({
      moduleId,
      classIds,
      publishClassContent,
    }: {
      moduleId: string;
      classIds: string[];
      publishClassContent: boolean;
    }) => {
      const result = await moduleTemplateService.applyToClasses(token ?? "", moduleId, classIds);
      let publishedCount = 0;

      if (publishClassContent) {
        const classModules = await Promise.all(
          classIds.map((classId) => moduleTemplateService.listClassModules(token ?? "", classId)),
        );
        const classModuleIds = new Set([
          ...result.applied
            .map((item) => item.class_module_id)
            .filter((id): id is string => Boolean(id)),
          ...classModules
            .flat()
            .filter((classModule) => classModule.source_module_template_id === moduleId && classModule.status !== "published")
            .map((classModule) => classModule.id),
        ]);

        for (const classModuleId of classModuleIds) {
          await moduleTemplateService.publishClassModule(token ?? "", classModuleId);
          publishedCount += 1;
        }
      }

      return { result, publishedCount };
    },
    onSuccess: ({ result, publishedCount }) => {
      setSuccessMessage(
        publishedCount > 0
          ? `Template modul diterapkan ke ${result.applied.length} kelas dan ${publishedCount} modul kelas langsung diterbitkan. Modul terlihat untuk siswa yang terdaftar pada kelas tersebut.`
          : `Template modul diterapkan: ${result.applied.length} kelas, dilewati: ${result.skipped.length}, gagal: ${result.failed.length}. Modul kelas masih draft dan perlu diterbitkan agar terlihat siswa.`,
      );
      setApplyTarget(null);
      setSelectedClassIds([]);
      setPublishAfterApply(true);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (moduleId: string) => moduleTemplateService.delete(token ?? "", moduleId),
    onSuccess: async () => {
      setSuccessMessage("Modul berhasil dihapus dari daftar aktif.");
      setDeleteTarget(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "module-templates"] });
    },
  });

  const actionError =
    createMutation.error ??
    publishMutation.error ??
    archiveMutation.error ??
    applyMutation.error ??
    deleteMutation.error;

  const modules = modulesQuery.data?.items ?? [];
  const meta = modulesQuery.data?.meta;
  const classes = classesQuery.data?.items ?? [];

  function applySearch() {
    setPage(1);
    setSearch(searchInput.trim());
  }

  function toggleClass(classId: string) {
    setSelectedClassIds((current) =>
      current.includes(classId)
        ? current.filter((id) => id !== classId)
        : [...current, classId],
    );
  }

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <Badge tone="yellow">ADMIN-13</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Modul Pembelajaran</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
            Kelola template modul, materi awal, status terbit, dan distribusi modul ke kelas aktif.
          </p>
        </div>
        <Button onClick={() => setCreateModalOpen(true)}>Tambah Modul</Button>
      </header>

      <Alert tone="info">
        Alur tampil ke siswa: terbitkan template, terapkan ke kelas, lalu pastikan modul kelas ikut diterbitkan.
      </Alert>
      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}

      <FilterPanel className="md:grid-cols-[2fr_1fr_auto]">
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Cari modul</span>
          <Input
            onChange={(event) => setSearchInput(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter") {
                applySearch();
              }
            }}
            placeholder="Judul atau deskripsi modul"
            value={searchInput}
          />
        </label>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Status</span>
          <Select
            onChange={(event) => {
              setStatus(event.target.value as ModuleTemplateStatus | "");
              setPage(1);
            }}
            value={status}
          >
            <option value="">Semua status</option>
            <option value="draft">Draft</option>
            <option value="published">Terbit</option>
            <option value="archived">Diarsipkan</option>
          </Select>
        </label>
        <div className="flex items-end">
          <Button className="w-full" onClick={applySearch} variant="secondary">
            Terapkan
          </Button>
        </div>
      </FilterPanel>

      <Card>
        <CardContent>
          {modulesQuery.isLoading ? <LoadingState title="Memuat modul" /> : null}
          {modulesQuery.isError ? (
            <ErrorState
              description={getFirstApiError(modulesQuery.error)}
              onRetry={() => void modulesQuery.refetch()}
              title="Gagal memuat modul"
            />
          ) : null}
          {!modulesQuery.isLoading && !modulesQuery.isError ? (
            modules.length === 0 ? (
              <EmptyState
                description="Belum ada modul default sesuai filter saat ini."
                title="Modul kosong"
              />
            ) : (
              <div className="grid gap-4">
                <Table>
                  <TableHeader>
                    <tr>
                      <th className="px-4 py-3">Modul</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3">Dibuat</th>
                      <th className="px-4 py-3">Diubah</th>
                      <th className="px-4 py-3">Aksi</th>
                    </tr>
                  </TableHeader>
                  <tbody>
                    {modules.map((module) => (
                      <tr key={module.id}>
                        <TableCell>
                          <p className="font-black text-ink">{module.title}</p>
                          <p className="mt-1 line-clamp-2 text-xs leading-5 text-slate-600">
                            {module.description ?? "Tanpa deskripsi."}
                          </p>
                        </TableCell>
                        <TableCell>
                          <Badge tone={statusTone(module.status)}>
                            {statusLabel(module.status)}
                          </Badge>
                        </TableCell>
                        <TableCell>{formatDate(module.created_at)}</TableCell>
                        <TableCell>{formatDate(module.updated_at)}</TableCell>
                        <TableCell>
                          <div className="flex flex-wrap gap-2">
                            <Link
                              className="inline-flex min-h-9 items-center rounded-lg border-2 border-ink bg-white px-3 py-1 text-xs font-black text-ink hover:bg-yellow-100"
                              href={`/admin/modules/${module.id}/edit`}
                            >
                              Editor
                            </Link>
                            {module.status !== "published" ? (
                              <Button
                                className="min-h-9 px-3 py-1 text-xs"
                                disabled={publishMutation.isPending}
                                onClick={() => publishMutation.mutate(module.id)}
                                variant="secondary"
                              >
                                Terbitkan
                              </Button>
                            ) : null}
                            {module.status === "published" ? (
                              <Button
                                className="min-h-9 px-3 py-1 text-xs"
                                onClick={() => {
                                  setApplyTarget(module);
                                  setSelectedClassIds([]);
                                  setPublishAfterApply(true);
                                }}
                                variant="secondary"
                              >
                                Terapkan ke Kelas
                              </Button>
                            ) : null}
                            {module.status !== "archived" ? (
                              <Button
                                className="min-h-9 px-3 py-1 text-xs"
                                disabled={archiveMutation.isPending}
                                onClick={() => { if (confirm(`Arsipkan modul "${module.title}"?`)) archiveMutation.mutate(module.id); }}
                                variant="ghost"
                              >
                                Arsipkan
                              </Button>
                            ) : null}
                            <Button
                              className="min-h-9 px-3 py-1 text-xs"
                              disabled={deleteMutation.isPending}
                              onClick={() => setDeleteTarget(module)}
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
                <Pagination
                  onPageChange={setPage}
                  page={meta?.current_page ?? page}
                  totalPages={meta?.last_page ?? 1}
                />
              </div>
            )
          ) : null}
        </CardContent>
      </Card>

      <Modal
        onClose={() => setCreateModalOpen(false)}
        open={createModalOpen}
        title="Tambah Modul Default"
      >
        <ModuleTemplateForm
          isSubmitting={createMutation.isPending}
          onCancel={() => setCreateModalOpen(false)}
          onSubmit={(payload) => createMutation.mutate(payload)}
        />
      </Modal>

      <Modal
        onClose={() => setApplyTarget(null)}
        open={Boolean(applyTarget)}
        title="Terapkan Modul ke Kelas"
      >
        <div className="grid gap-4">
          <Alert tone="info">
            Menerapkan template akan membuat modul kelas. Aktifkan opsi terbitkan di bawah agar modul langsung terlihat oleh guru dan siswa yang terhubung ke kelas.
          </Alert>
          {classesQuery.isLoading ? <LoadingState title="Memuat kelas" /> : null}
          {classesQuery.isError ? <ErrorState description={getFirstApiError(classesQuery.error)} title="Gagal memuat kelas" /> : null}
          {!classesQuery.isLoading && !classesQuery.isError ? (
            classes.length === 0 ? (
              <EmptyState description="Belum ada kelas aktif untuk menerima template modul." title="Kelas aktif kosong" />
            ) : (
              <div className="grid max-h-80 gap-2 overflow-auto rounded-xl border border-slate-200 p-3">
                {classes.map((schoolClass) => (
                  <label className="flex items-center gap-3 rounded-lg border border-slate-200 bg-white p-3 text-sm font-bold text-ink" key={schoolClass.id}>
                    <input
                      checked={selectedClassIds.includes(schoolClass.id)}
                      onChange={() => toggleClass(schoolClass.id)}
                      type="checkbox"
                    />
                    <span>{schoolClass.name} - {schoolClass.academic_year}</span>
                  </label>
                ))}
              </div>
            )
          ) : null}
          <label className="flex items-start gap-3 rounded-xl border-2 border-ink bg-yellow-50 p-3 text-sm font-bold text-ink">
            <input
              checked={publishAfterApply}
              className="mt-1"
              onChange={(event) => setPublishAfterApply(event.target.checked)}
              type="checkbox"
            />
            <span>Setelah diterapkan, langsung terbitkan modul kelas agar terlihat oleh guru dan siswa.</span>
          </label>
          <div className="flex flex-col gap-2 sm:flex-row sm:justify-end">
            <Button onClick={() => setApplyTarget(null)} type="button" variant="ghost">
              Batal
            </Button>
            <Button
              disabled={!applyTarget || selectedClassIds.length === 0 || applyMutation.isPending}
              onClick={() => {
                if (applyTarget) {
                  applyMutation.mutate({ moduleId: applyTarget.id, classIds: selectedClassIds, publishClassContent: publishAfterApply });
                }
              }}
              type="button"
            >
              {applyMutation.isPending ? "Menerapkan..." : "Terapkan"}
            </Button>
          </div>
        </div>
      </Modal>

      <ConfirmDialog
        confirmLabel={deleteMutation.isPending ? "Menghapus..." : "Hapus Modul"}
        description={
          deleteTarget
            ? `Modul "${deleteTarget.title}" akan dihapus dari daftar aktif.`
            : ""
        }
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => {
          if (deleteTarget) {
            deleteMutation.mutate(deleteTarget.id);
          }
        }}
        open={Boolean(deleteTarget)}
        title="Hapus modul?"
      />
    </div>
  );
}
