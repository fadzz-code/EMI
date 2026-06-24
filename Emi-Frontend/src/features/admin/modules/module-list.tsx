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

  const deleteMutation = useMutation({
    mutationFn: (moduleId: string) => moduleTemplateService.delete(token ?? "", moduleId),
    onSuccess: async () => {
      setSuccessMessage("Modul berhasil dihapus sesuai aturan soft delete backend.");
      setDeleteTarget(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "module-templates"] });
    },
  });

  const actionError =
    createMutation.error ??
    publishMutation.error ??
    archiveMutation.error ??
    deleteMutation.error;

  const modules = modulesQuery.data?.items ?? [];
  const meta = modulesQuery.data?.meta;

  function applySearch() {
    setPage(1);
    setSearch(searchInput.trim());
  }

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <Badge tone="yellow">ADMIN-13</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Modul Pembelajaran</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
            Kelola template modul default. Daftar ini memakai endpoint
            admin/module-templates dari backend.
          </p>
        </div>
        <Button onClick={() => setCreateModalOpen(true)}>Tambah Modul</Button>
      </header>

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
                            {module.status !== "archived" ? (
                              <Button
                                className="min-h-9 px-3 py-1 text-xs"
                                disabled={archiveMutation.isPending}
                                onClick={() => archiveMutation.mutate(module.id)}
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

      <ConfirmDialog
        confirmLabel={deleteMutation.isPending ? "Menghapus..." : "Hapus Modul"}
        description={
          deleteTarget
            ? `Modul "${deleteTarget.title}" akan dihapus dengan soft delete sesuai backend.`
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
