"use client";

import { type FormEvent, useMemo, useState } from "react";
import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Download, Eye, Pencil, Plus, Search, Trash2 } from "lucide-react";

import {
  Alert,
  AudioPlayer,
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  ConfirmDialog,
  EmptyState,
  ErrorState,
  FilterPanel,
  FormField,
  Input,
  LoadingState,
  Modal,
  Pagination,
  Select,
  Table,
  TableCell,
  TableHeader,
  Textarea,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { DictionaryEntryForm } from "./dictionary-form";
import { dictionaryService } from "./dictionary-service";
import {
  normalizeNullable,
  statusLabel,
  statusTone,
} from "./dictionary-utils";
import type {
  DictionaryCategory,
  DictionaryCategoryPayload,
  DictionaryEntryPayload,
  DictionaryStatus,
} from "./types";

const defaultCategoryForm = {
  name: "",
  description: "",
  status: "active" as DictionaryStatus,
};

function toCategoryForm(category?: DictionaryCategory | null) {
  return category
    ? {
        name: category.name,
        description: category.description ?? "",
        status: category.status,
      }
    : defaultCategoryForm;
}

export function DictionaryList() {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [status, setStatus] = useState<DictionaryStatus | "">("");
  const [hasAudio, setHasAudio] = useState<boolean | "">("");
  const [entryModalOpen, setEntryModalOpen] = useState(false);
  const [categoryModalOpen, setCategoryModalOpen] = useState(false);
  const [categoryForm, setCategoryForm] = useState(defaultCategoryForm);
  const [editingCategory, setEditingCategory] = useState<DictionaryCategory | null>(null);
  const [deleteCategoryTarget, setDeleteCategoryTarget] = useState<DictionaryCategory | null>(null);
  const [deleteCategoryConfirmStep, setDeleteCategoryConfirmStep] = useState<1 | 2>(1);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const entryFilters = useMemo(
    () => ({
      search,
      category_id: categoryId,
      status,
      has_audio: hasAudio,
      page,
      per_page: 15,
    }),
    [categoryId, hasAudio, page, search, status],
  );

  const entriesQuery = useQuery({
    queryKey: ["admin", "dictionary", "entries", entryFilters],
    queryFn: () => dictionaryService.listEntries(token ?? "", entryFilters),
    enabled: Boolean(token),
  });

  const categoriesQuery = useQuery({
    queryKey: ["admin", "dictionary", "categories"],
    queryFn: () => dictionaryService.listCategories(token ?? "", { per_page: 100 }),
    enabled: Boolean(token),
  });

  const createEntryMutation = useMutation({
    mutationFn: (payload: DictionaryEntryPayload) =>
      dictionaryService.createEntry(token ?? "", payload),
    onSuccess: async (entry) => {
      setSuccessMessage(`Kata ${entry.mekongga} berhasil dibuat.`);
      setEntryModalOpen(false);
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary"] });
    },
  });

  const createCategoryMutation = useMutation({
    mutationFn: (payload: DictionaryCategoryPayload) =>
      dictionaryService.createCategory(token ?? "", payload),
    onSuccess: async (category) => {
      setSuccessMessage(`Kategori ${category.name} berhasil dibuat.`);
      closeCategoryModal();
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary", "categories"] });
    },
  });

  const updateCategoryMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: DictionaryCategoryPayload }) =>
      dictionaryService.updateCategory(token ?? "", id, payload),
    onSuccess: async (category) => {
      setSuccessMessage(`Kategori ${category.name} berhasil diperbarui.`);
      closeCategoryModal();
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary", "categories"] });
    },
  });

  const deleteCategoryMutation = useMutation({
    mutationFn: (categoryId: string) => dictionaryService.deleteCategory(token ?? "", categoryId),
    onSuccess: async () => {
      setSuccessMessage(`Kategori ${deleteCategoryTarget?.name ?? ""} berhasil dihapus.`);
      setDeleteCategoryTarget(null);
      setDeleteCategoryConfirmStep(1);
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary", "categories"] });
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary", "entries"] });
    },
  });

  const deleteEntryMutation = useMutation({
    mutationFn: (entryId: string) => dictionaryService.deleteEntry(token ?? "", entryId),
    onSuccess: async () => {
      setSuccessMessage("Entri kamus berhasil dinonaktifkan atau dihapus sesuai aturan sistem.");
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary", "entries"] });
    },
  });

  const entries = entriesQuery.data?.items ?? [];
  const categories = categoriesQuery.data?.items ?? [];
  const meta = entriesQuery.data?.meta;
  const actionError =
    createEntryMutation.error ??
    createCategoryMutation.error ??
    updateCategoryMutation.error ??
    deleteCategoryMutation.error ??
    deleteEntryMutation.error;

  function applySearch() {
    setPage(1);
    setSearch(searchInput.trim());
  }

  function openCreateCategory() {
    setEditingCategory(null);
    setCategoryForm(defaultCategoryForm);
    setCategoryModalOpen(true);
  }

  function openEditCategory(category: DictionaryCategory) {
    setEditingCategory(category);
    setCategoryForm(toCategoryForm(category));
    setCategoryModalOpen(true);
  }

  function closeCategoryModal() {
    setCategoryModalOpen(false);
    setEditingCategory(null);
    setCategoryForm(defaultCategoryForm);
  }

  function submitCategory(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const payload: DictionaryCategoryPayload = {
      name: categoryForm.name.trim(),
      description: normalizeNullable(categoryForm.description),
      status: categoryForm.status,
    };

    if (editingCategory) {
      updateCategoryMutation.mutate({ id: editingCategory.id, payload });
      return;
    }

    createCategoryMutation.mutate(payload);
  }

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <Badge tone="blue">Admin</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Kelola Kamus Mekongga</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
            Kelola kosakata Mekongga beserta terjemahan, kategori, status, dan audio pendukung.
          </p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <Link
            className="inline-flex min-h-11 items-center justify-center rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-bold text-ink shadow-emi hover:bg-surface-muted"
            href="/admin/dictionary/import"
          >
            <Download aria-hidden="true" className="mr-2 size-4" />
            Impor Excel
          </Link>
          <Button onClick={openCreateCategory} variant="secondary">
            Tambah Kategori
          </Button>
          <Button onClick={() => setEntryModalOpen(true)}><Plus aria-hidden="true" className="mr-2 size-4" />Tambah Kata</Button>
        </div>
      </header>

      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}

      <FilterPanel className="md:grid-cols-5">
        <label className="grid gap-2 text-sm font-bold text-ink md:col-span-2">
          <span>Cari kata</span>
          <Input
            onChange={(event) => setSearchInput(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter") {
                applySearch();
              }
            }}
            placeholder="Cari Indonesia, Inggris, atau Mekongga"
            value={searchInput}
          />
        </label>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Kategori</span>
          <Select
            onChange={(event) => {
              setCategoryId(event.target.value);
              setPage(1);
            }}
            value={categoryId}
          >
            <option value="">Semua kategori</option>
            {categories.map((category) => (
              <option key={category.id} value={category.id}>
                {category.name}
              </option>
            ))}
          </Select>
        </label>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Status</span>
          <Select
            onChange={(event) => {
              setStatus(event.target.value as DictionaryStatus | "");
              setPage(1);
            }}
            value={status}
          >
            <option value="">Semua</option>
            <option value="active">Aktif</option>
            <option value="inactive">Nonaktif</option>
          </Select>
        </label>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Audio</span>
          <Select
            onChange={(event) => {
              const value = event.target.value;
              setHasAudio(value === "" ? "" : value === "true");
              setPage(1);
            }}
            value={hasAudio === "" ? "" : String(hasAudio)}
          >
            <option value="">Semua</option>
            <option value="true">Ada audio</option>
            <option value="false">Tanpa audio</option>
          </Select>
        </label>
        <div className="flex items-end md:col-span-5">
          <Button className="w-full md:w-fit" onClick={applySearch} variant="secondary">
            <Search aria-hidden="true" className="mr-2 size-4" />
            Terapkan Filter
          </Button>
        </div>
      </FilterPanel>

      <Card>
        <CardContent>
          {entriesQuery.isLoading ? <LoadingState title="Memuat kamus" /> : null}
          {entriesQuery.isError ? (
            <ErrorState
              description={getFirstApiError(entriesQuery.error)}
              onRetry={() => void entriesQuery.refetch()}
              title="Gagal memuat kamus"
            />
          ) : null}
          {!entriesQuery.isLoading && !entriesQuery.isError ? (
            entries.length === 0 ? (
              <EmptyState
                description="Belum ada kata sesuai filter saat ini."
                title="Kamus kosong"
              />
            ) : (
              <div className="grid gap-4">
                <Table>
                  <TableHeader>
                    <tr>
                      <th className="px-4 py-3">Mekongga</th>
                      <th className="px-4 py-3">Indonesia</th>
                      <th className="px-4 py-3">Inggris</th>
                      <th className="px-4 py-3">Kategori</th>
                      <th className="px-4 py-3">Audio</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3">Aksi</th>
                    </tr>
                  </TableHeader>
                  <tbody>
                    {entries.map((entry) => (
                      <tr key={entry.id}>
                        <TableCell className="font-black text-ink">{entry.mekongga}</TableCell>
                        <TableCell>{entry.indonesia}</TableCell>
                        <TableCell>{entry.english}</TableCell>
                        <TableCell>{entry.category?.name ?? "-"}</TableCell>
                        <TableCell>{entry.audio ? "Ada" : "Belum"}</TableCell>
                        <TableCell>
                          <Badge tone={statusTone(entry.status)}>{statusLabel(entry.status)}</Badge>
                        </TableCell>
                        <TableCell>
                          <div className="flex flex-wrap gap-2">
                            <Link
                              className="inline-flex min-h-9 items-center rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 py-1 text-xs font-black text-ink hover:bg-surface-muted"
                              href={`/admin/dictionary/${entry.id}`}
                            >
                              <Eye aria-hidden="true" className="mr-1 size-4" />
                              Detail
                            </Link>
                            <Button
                              className="min-h-9 px-3 py-1 text-xs"
                              disabled={deleteEntryMutation.isPending}
                              onClick={() => deleteEntryMutation.mutate(entry.id)}
                              variant="danger"
                            >
                              <Trash2 aria-hidden="true" className="mr-1 size-4" />
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

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between gap-3">
            <div>
              <h2 className="text-xl font-black text-ink">Kategori Kamus</h2>
              <p className="mt-1 text-sm text-muted">
                Kelola kategori yang dipakai untuk mengelompokkan kata kamus.
              </p>
            </div>
            <Badge tone="neutral">{categories.length} kategori</Badge>
          </div>
        </CardHeader>
        <CardContent>
          {categoriesQuery.isLoading ? <LoadingState title="Memuat kategori" /> : null}
          {categoriesQuery.isError ? (
            <ErrorState
              description={getFirstApiError(categoriesQuery.error)}
              onRetry={() => void categoriesQuery.refetch()}
              title="Gagal memuat kategori"
            />
          ) : null}
          {!categoriesQuery.isLoading && !categoriesQuery.isError ? (
            categories.length === 0 ? (
              <EmptyState
                description="Belum ada kategori kamus."
                title="Kategori kosong"
              />
            ) : (
              <Table>
                <TableHeader>
                  <tr>
                    <th className="px-4 py-3">Nama</th>
                    <th className="px-4 py-3">Deskripsi</th>
                    <th className="px-4 py-3">Jumlah Kata</th>
                    <th className="px-4 py-3">Status</th>
                    <th className="px-4 py-3">Aksi</th>
                  </tr>
                </TableHeader>
                <tbody>
                  {categories.map((category) => (
                    <tr key={category.id}>
                      <TableCell className="font-black text-ink">{category.name}</TableCell>
                      <TableCell>{category.description ?? "-"}</TableCell>
                      <TableCell>{category.entries_count ?? 0}</TableCell>
                      <TableCell>
                        <Badge tone={statusTone(category.status)}>{statusLabel(category.status)}</Badge>
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-wrap gap-2">
                          <Button
                            className="min-h-9 px-3 py-1 text-xs"
                            onClick={() => openEditCategory(category)}
                            variant="secondary"
                          >
                            <Pencil aria-hidden="true" className="mr-1 size-4" />
                            Edit
                          </Button>
                          <Button
                            className="min-h-9 px-3 py-1 text-xs"
                            disabled={deleteCategoryMutation.isPending}
                            onClick={() => {
                              setDeleteCategoryTarget(category);
                              setDeleteCategoryConfirmStep(1);
                            }}
                            variant="danger"
                          >
                            <Trash2 aria-hidden="true" className="mr-1 size-4" />
                            Hapus
                          </Button>
                        </div>
                      </TableCell>
                    </tr>
                  ))}
                </tbody>
              </Table>
            )
          ) : null}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Pratinjau Audio Kamus</h2>
        </CardHeader>
        <CardContent>
          <AudioPlayer
            src={entries.find((entry) => entry.audio)?.audio?.url}
            title="audio kamus"
          />
          <p className="mt-3 text-sm text-muted">
            Audio pertama yang tersedia dari hasil filter ditampilkan untuk pemeriksaan cepat.
          </p>
        </CardContent>
      </Card>

      <Modal onClose={() => setEntryModalOpen(false)} open={entryModalOpen} title="Tambah Kata Kamus">
        <DictionaryEntryForm
          categories={categories.filter((category) => category.status === "active")}
          isSubmitting={createEntryMutation.isPending}
          onCancel={() => setEntryModalOpen(false)}
          onSubmit={(payload) => createEntryMutation.mutate(payload)}
          token={token ?? ""}
        />
      </Modal>

      <Modal
        onClose={closeCategoryModal}
        open={categoryModalOpen}
        title={editingCategory ? "Edit Kategori Kamus" : "Tambah Kategori Kamus"}
      >
        <form className="grid gap-4" onSubmit={submitCategory}>
          <FormField label="Nama kategori">
            <Input
              onChange={(event) =>
                setCategoryForm((current) => ({ ...current, name: event.target.value }))
              }
              required
              value={categoryForm.name}
            />
          </FormField>
          <FormField label="Deskripsi">
            <Textarea
              onChange={(event) =>
                setCategoryForm((current) => ({ ...current, description: event.target.value }))
              }
              value={categoryForm.description}
            />
          </FormField>
          <FormField label="Status">
            <Select
              onChange={(event) =>
                setCategoryForm((current) => ({
                  ...current,
                  status: event.target.value as DictionaryStatus,
                }))
              }
              value={categoryForm.status}
            >
              <option value="active">Aktif</option>
              <option value="inactive">Nonaktif</option>
            </Select>
          </FormField>
          <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
            <Button onClick={closeCategoryModal} type="button" variant="ghost">
              Batal
            </Button>
            <Button
              disabled={createCategoryMutation.isPending || updateCategoryMutation.isPending}
              type="submit"
              variant="secondary"
            >
              Simpan Kategori
            </Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        confirmLabel="Ya, Lanjutkan"
        description={
          deleteCategoryTarget
            ? `Kategori "${deleteCategoryTarget.name}" memiliki ${deleteCategoryTarget.entries_count ?? 0} kata. Menghapus kategori ini akan membuat kata-kata tersebut kehilangan kategorinya. Lanjutkan?`
            : ""
        }
        onCancel={() => {
          setDeleteCategoryTarget(null);
          setDeleteCategoryConfirmStep(1);
        }}
        onConfirm={() => setDeleteCategoryConfirmStep(2)}
        open={Boolean(deleteCategoryTarget) && deleteCategoryConfirmStep === 1}
        title="Hapus kategori kamus?"
      />

      <ConfirmDialog
        confirmLabel={deleteCategoryMutation.isPending ? "Menghapus..." : "Ya, Hapus Permanen"}
        description={
          deleteCategoryTarget
            ? `Konfirmasi terakhir: kategori "${deleteCategoryTarget.name}" akan dihapus permanen dan tidak dapat dibatalkan.`
            : ""
        }
        onCancel={() => {
          setDeleteCategoryTarget(null);
          setDeleteCategoryConfirmStep(1);
        }}
        onConfirm={() => {
          if (deleteCategoryTarget) deleteCategoryMutation.mutate(deleteCategoryTarget.id);
        }}
        open={Boolean(deleteCategoryTarget) && deleteCategoryConfirmStep === 2}
        title="Konfirmasi sekali lagi"
      />
    </div>
  );
}
