"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Archive, Hammer, Send, Share2, Trash2 } from "lucide-react";

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

import { moduleTemplateService } from "./module-service";
import { newModuleDraft } from "./module-workflow";
import { formatDate, statusLabel, statusTone } from "./module-utils";
import type { ModuleTemplate, ModuleTemplateStatus } from "./types";

export function ModuleList() {
  const { token } = useAuth();
  const router = useRouter();
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<ModuleTemplateStatus | "">("");
  const [applyTarget, setApplyTarget] = useState<ModuleTemplate | null>(null);
  const [selectedClassIds, setSelectedClassIds] = useState<string[]>([]);
  const [publishAfterApply, setPublishAfterApply] = useState(true);
  const [syncExisting, setSyncExisting] = useState(false);
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
    queryFn: () => classService.list(token ?? "", { status: "active", per_page: 500 }),
    enabled: Boolean(token),
  });

  const createMutation = useMutation({
    mutationFn: () => moduleTemplateService.create(token ?? "", newModuleDraft()),
    onSuccess: (module) => router.push(`/admin/modules/${module.id}/edit`),
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
      syncExistingClasses,
    }: {
      moduleId: string;
      classIds: string[];
      publishClassContent: boolean;
      syncExistingClasses: boolean;
    }) => {
      const result = await moduleTemplateService.applyToClasses(token ?? "", moduleId, classIds, syncExistingClasses);
      let publishedCount = 0;

      if (publishClassContent) {
        const classModules = await Promise.all(
          classIds.map((classId) => moduleTemplateService.listClassModules(token ?? "", classId)),
        );
        const classModuleIds = new Set([
          ...result.applied
            .map((item) => item.class_module_id)
            .filter((id): id is string => Boolean(id)),
          ...result.synced
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
      const totalAffected = result.applied.length + result.synced.length;
      setSuccessMessage(
        totalAffected > 0
          ? `Template modul diterapkan ke ${result.applied.length} kelas baru, disinkronkan ke ${result.synced.length} kelas existing${publishedCount > 0 ? `, dan ${publishedCount} modul kelas langsung diterbitkan` : ""}. Modul terlihat untuk siswa yang terdaftar pada kelas tersebut.`
          : `Tidak ada kelas baru yang diterapkan. Dilewati: ${result.skipped.length} (sudah memiliki template), gagal: ${result.failed.length}. Centang "Sinkronkan" untuk memperbarui kelas yang sudah ada.`,
      );
      setApplyTarget(null);
      setSelectedClassIds([]);
      setPublishAfterApply(true);
      setSyncExisting(false);
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
          <Badge tone="blue">ADMIN-13</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Modul Pembelajaran</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 font-semibold text-muted">
            Kelola template modul, materi awal, status terbit, dan distribusi modul ke kelas aktif.
          </p>
        </div>
        <Button
          disabled={createMutation.isPending}
          onClick={() => createMutation.mutate()}
        >
          {createMutation.isPending ? "Membuat Modul..." : "Tambah Modul"}
        </Button>
      </header>

      <Alert tone="info">
        Alur tampil ke siswa: terbitkan template, terapkan ke kelas, lalu pastikan modul kelas ikut diterbitkan.
      </Alert>
      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {createMutation.isError ? (
        <Alert tone="error">Modul belum berhasil dibuat. Silakan coba lagi.</Alert>
      ) : null}
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
                <Table className="w-full table-fixed">
                  <TableHeader className="hidden md:table-header-group">
                    <tr>
                      <th className="px-4 py-3">Modul</th>
                      <th className="w-[110px] px-4 py-3">Status</th>
                      <th className="w-[130px] px-4 py-3">Dibuat</th>
                      <th className="w-[130px] px-4 py-3">Diubah</th>
                      <th className="w-[264px] px-4 py-3">Aksi</th>
                    </tr>
                  </TableHeader>
                  <tbody className="grid gap-4 md:table-row-group">
                    {modules.map((module) => (
                      <tr className="grid min-w-0 gap-3 rounded-xl border-2 border-border p-4 md:table-row md:rounded-none md:border-0 md:p-0" key={module.id}>
                        <TableCell className="min-w-0 border-0 p-0 md:border-t md:px-4 md:py-3">
                          <p className="truncate font-black text-ink">{module.title}</p>
                          <p className="mt-1 line-clamp-2 text-xs leading-5 font-semibold text-muted">
                            {module.description ?? "Tanpa deskripsi."}
                          </p>
                        </TableCell>
                        <TableCell className="border-0 p-0 md:border-t md:px-4 md:py-3">
                          <span className="mr-2 font-bold md:hidden">Status:</span>
                          <Badge tone={statusTone(module.status)}>
                            {statusLabel(module.status)}
                          </Badge>
                        </TableCell>
                        <TableCell className="border-0 p-0 md:border-t md:px-4 md:py-3"><span className="font-bold md:hidden">Dibuat: </span>{formatDate(module.created_at)}</TableCell>
                        <TableCell className="border-0 p-0 md:border-t md:px-4 md:py-3"><span className="font-bold md:hidden">Diubah: </span>{formatDate(module.updated_at)}</TableCell>
                        <TableCell className="border-0 p-0 md:border-t md:px-4 md:py-3">
                          <div className="grid w-full max-w-[232px] grid-cols-2 gap-2">
                            <Link className="inline-flex h-9 w-28 items-center justify-center gap-1.5 rounded-lg border-2 border-border text-xs font-bold text-ink hover:border-primary hover:text-primary" href={`/admin/modules/${module.id}/edit`}>
                              <Hammer aria-hidden="true" className="size-4 shrink-0" />
                              Builder
                            </Link>
                            {module.status !== "published" ? (
                              <button className="inline-flex h-9 w-28 items-center justify-center gap-1.5 rounded-lg border-2 border-border text-xs font-bold text-ink hover:border-primary hover:text-primary disabled:opacity-50" disabled={publishMutation.isPending} onClick={() => publishMutation.mutate(module.id)} type="button">
                                <Send aria-hidden="true" className="size-4 shrink-0" />
                                Terbitkan
                              </button>
                            ) : null}
                            {module.status === "published" ? (
                              <button className="inline-flex h-9 w-28 items-center justify-center gap-1.5 rounded-lg border-2 border-border text-xs font-bold text-ink hover:border-primary hover:text-primary disabled:opacity-50" disabled={applyMutation.isPending} onClick={() => { setApplyTarget(module); setSelectedClassIds([]); setPublishAfterApply(true); setSyncExisting(false); }} type="button">
                                <Share2 aria-hidden="true" className="size-4 shrink-0" />
                                Terapkan
                              </button>
                            ) : null}
                            {module.status !== "archived" ? (
                              <button className="inline-flex h-9 w-28 items-center justify-center gap-1.5 rounded-lg border-2 border-border text-xs font-bold text-ink hover:border-primary hover:text-primary disabled:opacity-50" disabled={archiveMutation.isPending} onClick={() => archiveMutation.mutate(module.id)} type="button">
                                <Archive aria-hidden="true" className="size-4 shrink-0" />
                                Arsipkan
                              </button>
                            ) : null}
                            <button className="inline-flex h-9 w-28 items-center justify-center gap-1.5 rounded-lg border-2 border-danger/40 text-xs font-bold text-danger hover:border-danger disabled:opacity-50" disabled={deleteMutation.isPending} onClick={() => setDeleteTarget(module)} type="button">
                              <Trash2 aria-hidden="true" className="size-4 shrink-0" />
                              Hapus
                            </button>
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
              <>
                <div className="flex items-center justify-between gap-2">
                  <span className="text-sm font-bold text-muted">{classes.length} kelas aktif tersedia</span>
                  <div className="flex gap-2">
                    <button className="rounded-lg border-2 border-border px-3 py-1.5 text-xs font-bold text-ink hover:border-primary hover:text-primary" onClick={() => setSelectedClassIds(classes.map((c) => c.id))} type="button">
                      Pilih Semua
                    </button>
                    <button className="rounded-lg border-2 border-border px-3 py-1.5 text-xs font-bold text-ink hover:border-primary hover:text-primary" onClick={() => setSelectedClassIds([])} type="button">
                      Kosongkan
                    </button>
                  </div>
                </div>
                <div className="grid max-h-80 gap-2 overflow-auto rounded-xl border border-border p-3">
                  {classes.map((schoolClass) => (
                    <label className="flex items-center gap-3 rounded-lg border border-border bg-surface p-3 text-sm font-bold text-ink" key={schoolClass.id}>
                      <input
                        checked={selectedClassIds.includes(schoolClass.id)}
                        onChange={() => toggleClass(schoolClass.id)}
                        type="checkbox"
                      />
                      <span>{schoolClass.name} - {schoolClass.school?.name ?? "Tanpa Sekolah"} ({schoolClass.academic_year})</span>
                    </label>
                  ))}
                </div>
              </>
            )
          ) : null}
          <label className="flex items-start gap-3 rounded-xl border-2 border-border bg-[var(--color-primary-muted)] p-3 text-sm font-bold text-ink">
            <input
              checked={publishAfterApply}
              className="mt-1"
              onChange={(event) => setPublishAfterApply(event.target.checked)}
              type="checkbox"
            />
            <span>Setelah diterapkan, langsung terbitkan modul kelas agar terlihat oleh guru dan siswa.</span>
          </label>
          <label className="flex items-start gap-3 rounded-xl border-2 border-border bg-surface p-3 text-sm font-bold text-ink">
            <input
              checked={syncExisting}
              className="mt-1"
              onChange={(event) => setSyncExisting(event.target.checked)}
              type="checkbox"
            />
            <span>Sinkronkan kelas yang sudah memiliki template ini. Memperbarui judul, deskripsi, dan materi modul kelas dengan versi terbaru dari template. Perubahan guru pada modul kelas akan ditimpa.</span>
          </label>
          {syncExisting ? (
            <Alert tone="warning">
              Mode sinkronisasi akan memperbarui modul kelas yang sudah ada. Materi yang dibuat guru sendiri (tanpa sumber template) tidak akan terpengaruh.
            </Alert>
          ) : null}
          <div className="flex flex-col gap-2 sm:flex-row sm:justify-end">
            <Button onClick={() => setApplyTarget(null)} type="button" variant="ghost">
              Batal
            </Button>
            <Button
              disabled={!applyTarget || selectedClassIds.length === 0 || applyMutation.isPending}
              onClick={() => {
                if (applyTarget) {
                  applyMutation.mutate({ moduleId: applyTarget.id, classIds: selectedClassIds, publishClassContent: publishAfterApply, syncExistingClasses: syncExisting });
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
