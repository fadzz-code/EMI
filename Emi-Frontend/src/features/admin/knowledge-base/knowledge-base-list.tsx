"use client";

import { type FormEvent, useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Archive, Eye, FilePenLine, Plus, Send, Trash2 } from "lucide-react";

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

import { KnowledgeBaseForm } from "./knowledge-base-form";
import { knowledgeBaseService } from "./knowledge-base-service";
import type { AiKnowledgeItem, AiKnowledgePayload, AiKnowledgeStatus } from "./types";

const statusOptions: Array<{ value: AiKnowledgeStatus; label: string; description: string }> = [
  { value: "draft", label: "Draft", description: "Belum digunakan chatbot." },
  { value: "published", label: "Terbit", description: "Digunakan chatbot siswa." },
  { value: "archived", label: "Arsip", description: "Disimpan, tetapi tidak digunakan chatbot." },
];

const sourceTypeLabel = {
  manual: "Teks Manual",
  link: "Link",
  pdf: "PDF / Dokumen",
} as const;

function statusLabel(status: AiKnowledgeStatus) {
  return statusOptions.find((option) => option.value === status)?.label ?? status;
}

function statusTone(status: AiKnowledgeStatus) {
  if (status === "published") {
    return "blue";
  }

  if (status === "archived") {
    return "orange";
  }

  return "neutral";
}

function formatDate(value?: string | null) {
  if (!value) {
    return "-";
  }

  return new Intl.DateTimeFormat("id-ID", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(value));
}

function countByStatus(items: AiKnowledgeItem[], status: AiKnowledgeStatus) {
  return items.filter((item) => item.status === status).length;
}

export function KnowledgeBaseList() {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("");
  const [status, setStatus] = useState<AiKnowledgeStatus | "">("");
  const [formOpen, setFormOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<AiKnowledgeItem | null>(null);
  const [previewItem, setPreviewItem] = useState<AiKnowledgeItem | null>(null);
  const [itemToDelete, setItemToDelete] = useState<AiKnowledgeItem | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const filters = useMemo(
    () => ({
      search,
      category,
      status,
      page,
      per_page: 15,
    }),
    [category, page, search, status],
  );

  const knowledgeQuery = useQuery({
    queryKey: ["admin", "knowledge-base", filters],
    queryFn: () => knowledgeBaseService.list(token ?? "", filters),
    enabled: Boolean(token),
  });

  const createMutation = useMutation({
    mutationFn: (payload: AiKnowledgePayload) => knowledgeBaseService.create(token ?? "", payload),
    onSuccess: async (item) => {
      setSuccessMessage(`Pengetahuan ${item.title} berhasil dibuat.`);
      closeForm();
      await queryClient.invalidateQueries({ queryKey: ["admin", "knowledge-base"] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ itemId, payload }: { itemId: string; payload: AiKnowledgePayload }) =>
      knowledgeBaseService.update(token ?? "", itemId, payload),
    onSuccess: async (item) => {
      setSuccessMessage(`Pengetahuan ${item.title} berhasil diperbarui.`);
      closeForm();
      await queryClient.invalidateQueries({ queryKey: ["admin", "knowledge-base"] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (itemId: string) => knowledgeBaseService.delete(token ?? "", itemId),
    onSuccess: async () => {
      setSuccessMessage("Pengetahuan Basis AI berhasil dihapus.");
      setItemToDelete(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "knowledge-base"] });
    },
  });

  const publishMutation = useMutation({
    mutationFn: (itemId: string) => knowledgeBaseService.publish(token ?? "", itemId),
    onSuccess: async (item) => {
      setSuccessMessage(`Pengetahuan ${item.title} berhasil diterbitkan.`);
      await queryClient.invalidateQueries({ queryKey: ["admin", "knowledge-base"] });
    },
  });

  const archiveMutation = useMutation({
    mutationFn: (itemId: string) => knowledgeBaseService.archive(token ?? "", itemId),
    onSuccess: async (item) => {
      setSuccessMessage(`Pengetahuan ${item.title} berhasil diarsipkan.`);
      await queryClient.invalidateQueries({ queryKey: ["admin", "knowledge-base"] });
    },
  });

  const items = knowledgeQuery.data?.items ?? [];
  const meta = knowledgeQuery.data?.meta;
  const actionError =
    createMutation.error ??
    updateMutation.error ??
    deleteMutation.error ??
    publishMutation.error ??
    archiveMutation.error;
  const isSubmitting = createMutation.isPending || updateMutation.isPending;

  function applySearch() {
    setPage(1);
    setSearch(searchInput.trim());
  }

  function openCreateForm() {
    setEditingItem(null);
    setFormOpen(true);
  }

  function openEditForm(item: AiKnowledgeItem) {
    setEditingItem(item);
    setFormOpen(true);
  }

  function closeForm() {
    setFormOpen(false);
    setEditingItem(null);
  }

  function submitForm(payload: AiKnowledgePayload) {
    if (editingItem) {
      updateMutation.mutate({ itemId: editingItem.id, payload });
      return;
    }

    createMutation.mutate(payload);
  }

  function submitFilters(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    applySearch();
  }

  function confirmDelete() {
    if (!itemToDelete) {
      return;
    }

    deleteMutation.mutate(itemToDelete.id);
  }

  function renderActions(item: AiKnowledgeItem) {
    return (
      <div className="grid w-fit grid-cols-2 gap-2">
        <Button className="h-9 w-28 gap-1.5 text-xs" onClick={() => setPreviewItem(item)} variant="ghost">
          <Eye className="size-4" />Lihat
        </Button>
        <Button className="h-9 w-28 gap-1.5 text-xs" onClick={() => openEditForm(item)} variant="secondary">
          <FilePenLine className="size-4" />Edit
        </Button>
        {item.status !== "published" ? (
          <Button
            className="h-9 w-28 gap-1.5 text-xs"
            disabled={publishMutation.isPending}
            onClick={() => publishMutation.mutate(item.id)}
          >
            <Send className="size-4" />Terbitkan
          </Button>
        ) : (
          <Button
            className="h-9 w-28 gap-1.5 text-xs"
            disabled={archiveMutation.isPending}
            onClick={() => archiveMutation.mutate(item.id)}
            variant="ghost"
          >
            <Archive className="size-4" />Arsipkan
          </Button>
        )}
        <Button
          className="h-9 w-28 gap-1.5 text-xs"
          disabled={deleteMutation.isPending}
          onClick={() => setItemToDelete(item)}
          variant="danger"
        >
          <Trash2 className="size-4" />Hapus
        </Button>
      </div>
    );
  }

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <Badge tone="blue">ADMIN-11</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Basis AI</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 font-semibold text-muted">
            Kelola sumber pengetahuan Chatbot AI siswa. Hanya item berstatus terbit
            yang dipakai sebagai rujukan jawaban.
          </p>
        </div>
        <Button className="gap-2" onClick={openCreateForm}><Plus className="size-5" strokeWidth={2.5} />Tambah Pengetahuan</Button>
      </header>

      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}

      <section className="grid gap-3 md:grid-cols-4">
        <Card>
          <CardContent>
            <p className="text-xs font-black uppercase text-muted">Total</p>
            <p className="mt-2 text-2xl font-black text-ink">{meta?.total ?? items.length}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <p className="text-xs font-black uppercase text-muted">Draft</p>
            <p className="mt-2 text-2xl font-black text-ink">{countByStatus(items, "draft")}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <p className="text-xs font-black uppercase text-muted">Terbit</p>
            <p className="mt-2 text-2xl font-black text-ink">{countByStatus(items, "published")}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <p className="text-xs font-black uppercase text-muted">Arsip</p>
            <p className="mt-2 text-2xl font-black text-ink">{countByStatus(items, "archived")}</p>
          </CardContent>
        </Card>
      </section>

      <form onSubmit={submitFilters}>
        <FilterPanel className="md:grid-cols-4">
          <label className="grid gap-2 text-sm font-bold text-ink md:col-span-2">
            <span>Cari judul/konten</span>
            <Input
              onChange={(event) => setSearchInput(event.target.value)}
              placeholder="Cari judul, kategori, atau konten"
              value={searchInput}
            />
          </label>
          <label className="grid gap-2 text-sm font-bold text-ink">
            <span>Status</span>
            <Select
              onChange={(event) => {
                setStatus(event.target.value as AiKnowledgeStatus | "");
                setPage(1);
              }}
              value={status}
            >
              <option value="">Semua status</option>
              {statusOptions.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </Select>
          </label>
          <label className="grid gap-2 text-sm font-bold text-ink">
            <span>Kategori</span>
            <Input
              onChange={(event) => {
                setCategory(event.target.value);
                setPage(1);
              }}
              placeholder="Filter kategori"
              value={category}
            />
          </label>
          <div className="flex items-end md:col-span-4">
            <Button className="w-full md:w-fit" type="submit" variant="secondary">
              Terapkan Filter
            </Button>
          </div>
        </FilterPanel>
      </form>

      <Card>
        <CardHeader>
          <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <h2 className="text-xl font-black text-ink">Daftar Pengetahuan</h2>
              <p className="mt-1 text-sm leading-6 font-semibold text-muted">
                Draft belum digunakan chatbot. Terbit digunakan chatbot siswa. Arsip tetap tersimpan, tetapi tidak digunakan.
              </p>
            </div>
            <Badge tone="blue">Aktif untuk chatbot</Badge>
          </div>
        </CardHeader>
        <CardContent>
          {knowledgeQuery.isLoading ? <LoadingState title="Memuat Basis AI" /> : null}
          {knowledgeQuery.isError ? (
            <ErrorState
              description={getFirstApiError(knowledgeQuery.error)}
              onRetry={() => void knowledgeQuery.refetch()}
              title="Gagal memuat Basis AI"
            />
          ) : null}
          {!knowledgeQuery.isLoading && !knowledgeQuery.isError ? (
            items.length === 0 ? (
              <EmptyState
                description="Belum ada pengetahuan sesuai filter saat ini. Tambahkan pengetahuan pertama agar dapat digunakan Chatbot AI siswa setelah diterbitkan."
                title="Basis AI kosong"
              />
            ) : (
              <div className="grid gap-4">
                <div className="grid grid-cols-1 gap-3 md:hidden">
                  {items.map((item) => (
                    <div className="min-w-0 rounded-[var(--radius-card)] border-2 border-border bg-surface p-4" key={item.id}>
                      <div className="min-w-0">
                        <p className="break-words font-black text-ink">{item.title}</p>
                        <p className="mt-1 line-clamp-3 break-words text-xs leading-5 font-semibold text-muted">{item.content}</p>
                      </div>
                      <div className="mt-3 grid grid-cols-2 gap-3 text-sm">
                        <div className="min-w-0">
                          <p className="text-xs font-black uppercase text-muted">Kategori</p>
                          <p className="break-words font-semibold text-ink">{item.category ?? "-"}</p>
                        </div>
                        <div>
                          <p className="text-xs font-black uppercase text-muted">Sumber</p>
                          <p className="font-semibold text-ink">{sourceTypeLabel[item.source_type]}</p>
                        </div>
                        <Badge tone={statusTone(item.status)}>{statusLabel(item.status)}</Badge>
                        <p className="text-xs font-semibold text-muted">{formatDate(item.updated_at)}</p>
                      </div>
                      <div className="mt-4 overflow-hidden">{renderActions(item)}</div>
                    </div>
                  ))}
                </div>
                <div className="hidden md:block">
                <Table className="table-fixed">
                  <TableHeader>
                    <tr>
                      <th className="w-[30%] px-4 py-3">Judul</th>
                      <th className="w-[14%] px-4 py-3">Kategori</th>
                      <th className="w-[13%] px-4 py-3">Jenis Sumber</th>
                      <th className="w-[11%] px-4 py-3">Status</th>
                      <th className="w-[14%] px-4 py-3">Diubah</th>
                      <th className="w-64 px-4 py-3">Aksi</th>
                    </tr>
                  </TableHeader>
                  <tbody>
                    {items.map((item) => (
                      <tr key={item.id}>
                        <TableCell className="min-w-0">
                           <p className="break-words font-black text-ink">{item.title}</p>
                           <p className="mt-1 line-clamp-2 break-words text-xs leading-5 font-semibold text-muted">{item.content}</p>
                         </TableCell>
                         <TableCell className="break-words">{item.category ?? "-"}</TableCell>
                        <TableCell>{sourceTypeLabel[item.source_type]}</TableCell>
                        <TableCell>
                          <Badge tone={statusTone(item.status)}>{statusLabel(item.status)}</Badge>
                        </TableCell>
                        <TableCell>{formatDate(item.updated_at)}</TableCell>
                        <TableCell>{renderActions(item)}</TableCell>
                      </tr>
                    ))}
                  </tbody>
                </Table>
                </div>
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
        onClose={closeForm}
        open={formOpen}
        title={editingItem ? "Edit Pengetahuan Basis AI" : "Tambah Pengetahuan Basis AI"}
      >
        <KnowledgeBaseForm
          isSubmitting={isSubmitting}
          item={editingItem}
          key={editingItem?.id ?? "create"}
          onCancel={closeForm}
          onSubmit={submitForm}
          token={token}
        />
      </Modal>

      <ConfirmDialog
        confirmLabel={deleteMutation.isPending ? "Menghapus..." : "Ya, hapus"}
        description={`Pengetahuan ${itemToDelete?.title ?? "ini"} akan dihapus dari Basis AI. Aksi ini tidak langsung menghapus data siswa, tetapi item tidak akan muncul lagi di daftar admin.`}
        onCancel={() => setItemToDelete(null)}
        onConfirm={confirmDelete}
        open={Boolean(itemToDelete)}
        title="Hapus Pengetahuan Basis AI?"
      />

      <Modal onClose={() => setPreviewItem(null)} open={Boolean(previewItem)} title="Preview Pengetahuan Basis AI">
        {previewItem ? (
          <div className="grid gap-4">
            <div className="flex flex-wrap gap-2">
              <Badge tone={statusTone(previewItem.status)}>{statusLabel(previewItem.status)}</Badge>
              <Badge tone="neutral">{sourceTypeLabel[previewItem.source_type]}</Badge>
              {previewItem.category ? <Badge tone="blue">{previewItem.category}</Badge> : null}
            </div>
            <div>
              <p className="text-xs font-black uppercase text-muted">Judul</p>
              <h2 className="mt-1 text-xl font-black text-ink">{previewItem.title}</h2>
            </div>
            {previewItem.source_url ? (
              <div>
                <p className="text-xs font-black uppercase text-muted">URL Sumber</p>
                <a className="mt-1 block break-all text-sm font-bold text-info-foreground underline" href={previewItem.source_url} rel="noreferrer noopener" target="_blank">
                  {previewItem.source_url}
                </a>
              </div>
            ) : null}
            <div>
              <p className="text-xs font-black uppercase text-muted">Konten Pengetahuan</p>
              <div className="mt-2 max-h-96 overflow-y-auto whitespace-pre-wrap rounded-lg border-2 border-border bg-surface-muted p-4 text-sm leading-6 text-foreground">
                {previewItem.content}
              </div>
            </div>
          </div>
        ) : null}
      </Modal>
    </div>
  );
}
