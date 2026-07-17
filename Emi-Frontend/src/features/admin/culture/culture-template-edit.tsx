"use client";

import Link from "next/link";
import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft } from "lucide-react";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, Input, LoadingState, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { classService } from "@/features/admin/management/management-service";

import { adminCultureService } from "./culture-service";
import { CultureTemplateItemForm } from "./culture-template-item-form";
import type { AdminCultureTemplateItem } from "./types";

function statusLabel(status: string | null | undefined) {
  if (status === "draft") return "Draft";
  if (status === "published") return "Terbit";
  if (status === "archived") return "Arsip";
  return status ?? "Belum tersedia";
}

export function AdminCultureTemplateEdit({ templateId }: { templateId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [editingItem, setEditingItem] = useState<AdminCultureTemplateItem | null>(null);
  const [isAdding, setIsAdding] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const query = useQuery({
    queryKey: ["admin", "culture-templates", templateId],
    queryFn: () => adminCultureService.getTemplate(token ?? "", templateId),
    enabled: Boolean(token && templateId),
  });

  const classesQuery = useQuery({
    queryKey: ["admin", "classes"],
    queryFn: () => classService.list(token ?? "", { per_page: 100 }),
    enabled: Boolean(token),
  });

  const updateMutation = useMutation({
    mutationFn: (payload: { title: string; description: string }) => adminCultureService.updateTemplate(token ?? "", templateId, payload),
    onSuccess: () => {
      setSuccessMsg("Template berhasil disimpan. Terbitkan template saat siap, lalu terapkan ke kelas agar tampil untuk guru dan siswa.");
      queryClient.invalidateQueries({ queryKey: ["admin", "culture-templates", templateId] });
      queryClient.invalidateQueries({ queryKey: ["admin", "culture-templates"] });
    },
  });

  const publishMutation = useMutation({
    mutationFn: () => adminCultureService.publishTemplate(token ?? "", templateId),
    onSuccess: () => {
      setSuccessMsg("Template berhasil diterbitkan. Template belum tampil untuk guru/siswa sampai diterapkan ke kelas.");
      queryClient.invalidateQueries({ queryKey: ["admin", "culture-templates", templateId] });
      queryClient.invalidateQueries({ queryKey: ["admin", "culture-templates"] });
    },
  });

  const applyMutation = useMutation({
    mutationFn: (classIds: string[]) => adminCultureService.applyTemplate(token ?? "", templateId, classIds),
    onSuccess: (res) => setSuccessMsg(`Berhasil diterapkan ke ${res.applied.length} kelas. Dilewati: ${res.skipped.length}, Gagal: ${res.failed.length}.`),
  });

  const deleteItemMutation = useMutation({
    mutationFn: (itemId: string) => adminCultureService.deleteItem(token ?? "", itemId),
    onSuccess: () => {
      setSuccessMsg("Item berhasil dihapus.");
      queryClient.invalidateQueries({ queryKey: ["admin", "culture-templates", templateId] });
    },
  });

  const template = query.data;

  return (
    <div className="grid gap-6">
      <Link className="inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink transition hover:-translate-y-0.5 hover:bg-surface-muted hover:shadow-emi" href="/admin/culture/templates"><ArrowLeft className="size-4" strokeWidth={2.5} />Kembali ke Daftar Template</Link>
      <PageHeader badge="Admin" description="Simpan perubahan template, terbitkan saat siap, lalu terapkan ke kelas agar tampil untuk guru dan siswa." title="Edit Template Budaya" />

      {query.isLoading ? <LoadingState title="Memuat template" /> : null}
      {query.isError ? <ErrorState description={getFirstApiError(query.error)} onRetry={() => void query.refetch()} title="Gagal memuat template" /> : null}

      {template ? (
        <div className="grid gap-6 lg:grid-cols-[1fr_1fr]">
          <div className="grid gap-6">
            <Card>
              <CardHeader><div className="flex items-center justify-between"><h2 className="text-xl font-black text-ink">Informasi Template</h2><Badge tone={template.status === "published" ? "blue" : "neutral"}>{statusLabel(template.status)}</Badge></div></CardHeader>
              <CardContent>
                <form className="grid gap-4" onSubmit={(e) => {
                  e.preventDefault();
                  setSuccessMsg(null);
                  const formData = new FormData(e.currentTarget);
                  updateMutation.mutate({ title: String(formData.get("title") ?? ""), description: String(formData.get("description") ?? "") });
                }}>
                  {successMsg ? <Alert tone="success">{successMsg}</Alert> : null}
                  {updateMutation.error ? <Alert tone="error">{getFirstApiError(updateMutation.error)}</Alert> : null}
                  {publishMutation.error ? <Alert tone="error">{getFirstApiError(publishMutation.error)}</Alert> : null}
                  <label className="grid gap-2 text-sm font-black text-ink">Judul<Input defaultValue={template.title} name="title" required /></label>
                  <label className="grid gap-2 text-sm font-black text-ink">Deskripsi<Input defaultValue={template.description ?? ""} name="description" /></label>
                  <div className="flex flex-wrap gap-2">
                    <Button disabled={updateMutation.isPending || publishMutation.isPending} type="submit">{updateMutation.isPending ? "Menyimpan..." : "Simpan Template"}</Button>
                    {template.status !== "published" ? <Button disabled={publishMutation.isPending || updateMutation.isPending} onClick={() => publishMutation.mutate()} type="button" variant="secondary">{publishMutation.isPending ? "Menerbitkan..." : "Terbitkan Template"}</Button> : null}
                  </div>
                </form>
              </CardContent>
            </Card>

            <Card>
              <CardHeader><h2 className="text-xl font-black text-ink">Terapkan ke Kelas</h2></CardHeader>
              <CardContent>
                <p className="mb-4 text-sm font-semibold text-muted">Template yang diterbitkan belum tampil untuk guru/siswa sampai diterapkan ke kelas. Saat diterapkan, sistem membuat konten budaya kelas yang bisa dikelola guru.</p>
                {template.status !== "published" ? <Alert className="mb-4" tone="warning">Terbitkan template terlebih dahulu untuk membuka aksi Terapkan ke Kelas.</Alert> : <Alert className="mb-4" tone="info">Template siap diterapkan ke kelas.</Alert>}
                {applyMutation.error ? <Alert className="mb-4" tone="error">{getFirstApiError(applyMutation.error)}</Alert> : null}
                <form onSubmit={(e) => {
                  e.preventDefault();
                  setSuccessMsg(null);
                  const formData = new FormData(e.currentTarget);
                  const classIds = formData.getAll("class_ids").map(String);
                  if (classIds.length === 0) return alert("Pilih minimal satu kelas.");
                  applyMutation.mutate(classIds);
                }}>
                  <div className="mb-4 max-h-48 overflow-y-auto rounded-lg border border-border bg-surface-muted p-2">
                    {classesQuery.isLoading ? <p className="text-sm p-2 text-muted">Memuat kelas...</p> : null}
                    {classesQuery.data?.items.map((c) => (
                      <label className="flex items-center gap-2 p-2 text-sm font-bold text-ink hover:bg-surface" key={c.id}><input name="class_ids" type="checkbox" value={c.id} /> {c.name} {c.school ? `(${c.school.name})` : ""}</label>
                    ))}
                  </div>
                  <Button disabled={applyMutation.isPending || template.status !== "published" || classesQuery.isLoading} type="submit" variant="secondary">{applyMutation.isPending ? "Menerapkan..." : "Terapkan ke Kelas"}</Button>
                </form>
              </CardContent>
            </Card>
          </div>

          <div className="grid gap-6">
            <Card>
              <CardHeader><div className="flex items-center justify-between"><h2 className="text-xl font-black text-ink">Item Budaya</h2><Button onClick={() => { setIsAdding(true); setEditingItem(null); }} type="button" variant="ghost">Tambah Item</Button></div></CardHeader>
              <CardContent>
                {deleteItemMutation.error ? <Alert tone="error">{getFirstApiError(deleteItemMutation.error)}</Alert> : null}
                {!template.items?.length ? <EmptyState description="Belum ada item." title="Item kosong" /> : (
                  <div className="grid gap-3">
                    {template.items.map((item) => (
                      <div className="rounded-2xl border-2 border-border bg-surface-muted p-3" key={item.id}>
                        <div className="flex items-start justify-between gap-3"><div><p className="font-black text-ink">{item.display_order}. {item.title}</p><p className="text-xs font-bold text-muted">{item.content_type} | {statusLabel(item.status)}</p></div></div>
                        <p className="mt-2 text-sm font-semibold text-muted line-clamp-2">{item.description}</p>
                        {item.media_id ? <p className="mt-1 text-xs text-muted">Media: {item.media?.original_name ?? item.media_id}</p> : null}
                        {item.external_url ? <p className="mt-1 text-xs text-muted truncate">URL: <a className="text-info-foreground underline" href={item.external_url} rel="noreferrer" target="_blank">{item.external_url}</a></p> : null}
                        <div className="mt-3 flex gap-2"><Button onClick={() => { setEditingItem(item); setIsAdding(false); }} type="button" variant="secondary">Edit</Button><Button disabled={deleteItemMutation.isPending} onClick={() => { if (confirm("Hapus item ini?")) deleteItemMutation.mutate(item.id); }} type="button" variant="danger">Hapus</Button></div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>

            {isAdding || editingItem ? (
              <CultureTemplateItemForm editingItem={editingItem} onCancel={() => { setIsAdding(false); setEditingItem(null); }} onSaved={() => { setSuccessMsg("Item disimpan."); setIsAdding(false); setEditingItem(null); queryClient.invalidateQueries({ queryKey: ["admin", "culture-templates", templateId] }); }} templateId={templateId} token={token ?? ""} />
            ) : null}
          </div>
        </div>
      ) : null}
    </div>
  );
}
