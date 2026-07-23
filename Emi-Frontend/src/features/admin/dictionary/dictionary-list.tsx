"use client";

import { type FormEvent, useMemo, useState } from "react";
import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

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
  const [categoryForm, setCategoryForm] = useState({
    name: "",
    description: "",
    status: "active" as DictionaryStatus,
  });
  const [editingCategory, setEditingCategory] = useState<DictionaryCategory | null>(null);
  const [categoryToDelete, setCategoryToDelete] = useState<DictionaryCategory | null>(null);
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
      setCategoryModalOpen(false);
      setCategoryForm({ name: "", description: "", status: "active" });
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary", "categories"] });
    },
  });

  const updateCategoryMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: DictionaryCategoryPayload }) => dictionaryService.updateCategory(token ?? "", id, payload),
    onSuccess: async (category) => {
      setSuccessMessage(`Kategori ${category.name} berhasil diperbarui.`);
      setCategoryModalOpen(false);
      setEditingCategory(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary"] });
    },
  });

  const deleteCategoryMutation = useMutation({
    mutationFn: (id: string) => dictionaryService.deleteCategory(token ?? "", id),
    onSuccess: async () => {
      setSuccessMessage("Kategori kamus berhasil dihapus.");
      setCategoryToDelete(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary"] });
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
    createEntryMutation.error ?? createCategoryMutation.error ?? updateCategoryMutation.error ?? deleteCategoryMutation.error ?? deleteEntryMutation.error;

  function applySearch() {
    setPage(1);
    setSearch(searchInput.trim());
  }

  function submitCategory(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const payload = {
      name: categoryForm.name.trim(),
      description: normalizeNullable(categoryForm.description),
      status: categoryForm.status,
    };
    if (editingCategory) updateCategoryMutation.mutate({ id: editingCategory.id, payload });
    else createCategoryMutation.mutate(payload);
  }

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <Badge tone="yellow">Admin</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Kelola Kamus Mekongga</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
            Kelola kosakata Mekongga beserta terjemahan, kategori, status, dan audio pendukung.
          </p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <Link
            className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-white px-4 py-2 text-sm font-bold text-ink shadow-brutal hover:bg-yellow-100"
            href="/admin/dictionary/import"
          >
            Impor CSV/ZIP
          </Link>
          <Button onClick={() => { setEditingCategory(null); setCategoryForm({ name: "", description: "", status: "active" }); setCategoryModalOpen(true); }} variant="secondary">
            Tambah Kategori
          </Button>
          <Button onClick={() => setEntryModalOpen(true)}>Tambah Kata</Button>
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
                              className="inline-flex min-h-9 items-center rounded-lg border-2 border-ink bg-white px-3 py-1 text-xs font-black text-ink hover:bg-yellow-100"
                              href={`/admin/dictionary/${entry.id}`}
                            >
                              Detail
                            </Link>
                            <Button
                              className="min-h-9 px-3 py-1 text-xs"
                              disabled={deleteEntryMutation.isPending}
                              onClick={() => { if (confirm(`Hapus entri "${entry.mekongga}"? Tindakan ini tidak dapat dibatalkan.`)) deleteEntryMutation.mutate(entry.id); }}
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

      <Card>
        <CardHeader><h2 className="text-xl font-black text-ink">Kategori Kamus</h2></CardHeader>
        <CardContent><div className="grid gap-2">{categories.map((category) => <div className="flex flex-col gap-2 rounded-lg border-2 border-ink p-3 sm:flex-row sm:items-center sm:justify-between" key={category.id}><div><p className="font-black">{category.name}</p><p className="text-sm text-slate-600">{category.description ?? "Tanpa deskripsi"} · {statusLabel(category.status)}</p></div><div className="flex gap-2"><Button className="min-h-9 px-3 py-1 text-xs" onClick={() => { setEditingCategory(category); setCategoryForm({ name: category.name, description: category.description ?? "", status: category.status }); setCategoryModalOpen(true); }} variant="secondary">Edit</Button><Button className="min-h-9 px-3 py-1 text-xs" onClick={() => setCategoryToDelete(category)} variant="danger">Hapus</Button></div></div>)}</div></CardContent>
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
          <p className="mt-3 text-sm text-slate-600">
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
        onClose={() => { setCategoryModalOpen(false); setEditingCategory(null); setCategoryForm({ name: "", description: "", status: "active" }); }}
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
            <Button onClick={() => setCategoryModalOpen(false)} type="button" variant="ghost">
              Batal
            </Button>
            <Button disabled={createCategoryMutation.isPending || updateCategoryMutation.isPending} type="submit" variant="secondary">
              Simpan Kategori
            </Button>
          </div>
        </form>
      </Modal>
      <ConfirmDialog confirmLabel={deleteCategoryMutation.isPending ? "Menghapus..." : "Ya, hapus"} description={`Kategori ${categoryToDelete?.name ?? "ini"} akan dihapus. Kategori yang masih digunakan entri dapat ditolak backend.`} onCancel={() => setCategoryToDelete(null)} onConfirm={() => categoryToDelete && deleteCategoryMutation.mutate(categoryToDelete.id)} open={Boolean(categoryToDelete)} title="Hapus Kategori Kamus?" />
    </div>
  );
}
