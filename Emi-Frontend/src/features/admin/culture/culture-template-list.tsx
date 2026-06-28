"use client";

import { type FormEvent, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, FilePreview, FormField, Input, LoadingState, PageHeader, Select, Textarea, UploadComponent } from "@/components/ui";
import { classService } from "@/features/admin/management/management-service";
import { useAuth } from "@/features/auth/auth-provider";
import { CultureMediaPreview } from "@/features/culture/culture-media-preview";
import { getFirstApiError } from "@/lib/api-client";

import { adminCultureService } from "./culture-service";
import type { AdminGlobalCultureItem } from "./types";

const fileTypes = ["image", "audio", "pdf", "video"];
const contentTypes = ["image", "audio", "pdf", "video", "youtube", "article", "link"];

function statusLabel(status: string | null | undefined) {
  if (status === "draft") return "Draft";
  if (status === "published") return "Terbit";
  if (status === "archived") return "Arsip";
  return status ?? "Belum tersedia";
}

export function AdminCultureTemplateList() {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [showBuilder, setShowBuilder] = useState(false);
  const [editingItem, setEditingItem] = useState<AdminGlobalCultureItem | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const itemsQuery = useQuery({ queryKey: ["admin", "culture", "global-items"], queryFn: () => adminCultureService.globalItems(token ?? ""), enabled: Boolean(token) });
  const classesQuery = useQuery({ queryKey: ["admin", "classes"], queryFn: () => classService.list(token ?? "", { per_page: 100 }), enabled: Boolean(token) });
  const items = itemsQuery.data ?? [];
  const publishedCount = items.filter((item) => item.status === "published").length;
  const classCount = classesQuery.data?.items.length ?? 0;
  const invalidate = () => queryClient.invalidateQueries({ queryKey: ["admin", "culture", "global-items"] });

  const deleteMutation = useMutation({
    mutationFn: (itemId: string) => adminCultureService.deleteGlobalItem(token ?? "", itemId),
    onSuccess: () => {
      setSuccessMsg("Konten budaya berhasil dihapus dari semua kelas.");
      invalidate();
    },
  });
  const publishMutation = useMutation({
    mutationFn: (itemId: string) => adminCultureService.publishGlobalItem(token ?? "", itemId),
    onSuccess: () => {
      setSuccessMsg("Konten budaya berhasil dipublish untuk semua kelas.");
      invalidate();
    },
  });
  const archiveMutation = useMutation({
    mutationFn: (itemId: string) => adminCultureService.archiveGlobalItem(token ?? "", itemId),
    onSuccess: () => {
      setSuccessMsg("Konten budaya berhasil diarsipkan dari semua kelas.");
      invalidate();
    },
  });

  function openBuilder(item: AdminGlobalCultureItem | null = null) {
    setEditingItem(item);
    setShowBuilder(true);
  }

  return (
    <div className="grid gap-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <PageHeader badge="Admin" description="Konten Budaya Kelas" title="Budaya Mekongga" />
        <Button onClick={() => openBuilder()} type="button">Tambah Konten Budaya</Button>
      </div>
      <p className="text-sm leading-6 text-slate-600">Kelola konten budaya untuk semua kelas. Konten yang disimpan oleh admin akan ditambahkan ke semua kelas.</p>
      {successMsg ? <Alert tone="success">{successMsg}</Alert> : null}

      {itemsQuery.isLoading || classesQuery.isLoading ? <LoadingState title="Memuat Budaya Mekongga" /> : null}
      {itemsQuery.isError ? <ErrorState description={getFirstApiError(itemsQuery.error)} onRetry={() => void itemsQuery.refetch()} title="Gagal memuat konten budaya" /> : null}
      {classesQuery.isError ? <ErrorState description={getFirstApiError(classesQuery.error)} onRetry={() => void classesQuery.refetch()} title="Gagal memuat kelas" /> : null}

      {!itemsQuery.isLoading && !itemsQuery.isError ? (
        <div className="grid gap-6">
          <Card>
            <CardContent>
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <h2 className="text-2xl font-black text-ink">Semua Kelas</h2>
                  <p className="mt-2 text-sm font-bold text-slate-500">{items.length} konten · {publishedCount} konten terbit · {classCount} kelas</p>
                </div>
                <Badge tone="neutral">Dibuat admin untuk semua kelas</Badge>
              </div>
            </CardContent>
          </Card>

          {showBuilder ? <AdminGlobalCultureForm item={editingItem} key={editingItem?.id ?? "new"} onDone={() => { setSuccessMsg(editingItem ? "Konten budaya berhasil diperbarui untuk semua kelas." : "Konten budaya berhasil dibuat untuk semua kelas."); setEditingItem(null); setShowBuilder(false); void invalidate(); }} token={token ?? ""} /> : null}

          {items.length === 0 ? <Card><CardContent><EmptyState description="Belum ada konten budaya. Klik Tambah Konten Budaya untuk menambah konten ke semua kelas." title="Konten budaya kosong" /></CardContent></Card> : (
            <div className="grid gap-4 md:grid-cols-2">
              {items.map((item) => (
                <Card key={item.id}>
                  <CardHeader><div className="flex flex-wrap gap-2"><Badge tone={item.status === "published" ? "blue" : item.status === "archived" ? "neutral" : "yellow"}>{statusLabel(item.status)}</Badge><Badge tone="neutral">{item.content_type}</Badge></div><h2 className="mt-2 text-xl font-black text-ink">{item.title}</h2></CardHeader>
                  <CardContent>
                    <p className="text-sm text-slate-600">{item.description ?? "Tanpa deskripsi"}</p>
                    <p className="mt-2 text-xs font-black uppercase text-slate-500">Dibuat admin untuk semua kelas</p>
                    <p className="mt-2 text-sm font-bold text-slate-500">{item.classes_count ?? 0} kelas · {item.published_classes_count ?? 0} kelas terbit</p>
                    <CultureMediaPreview item={item} />
                    <div className="mt-4 flex flex-wrap gap-2">
                      <Button type="button" variant="secondary" onClick={() => openBuilder(item)}>Edit</Button>
                      {item.status !== "published" ? <Button type="button" onClick={() => publishMutation.mutate(item.id)}>Publish</Button> : null}
                      {item.status !== "archived" ? <Button type="button" variant="secondary" onClick={() => archiveMutation.mutate(item.id)}>Archive</Button> : null}
                      <Button type="button" variant="danger" onClick={() => { if (confirm("Hapus konten budaya ini dari semua kelas?")) deleteMutation.mutate(item.id); }}>Hapus</Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>
      ) : null}
    </div>
  );
}

function AdminGlobalCultureForm({ item, onDone, token }: { item: AdminGlobalCultureItem | null; onDone: () => void; token: string }) {
  const [type, setType] = useState(String(item?.content_type ?? "image"));
  const [file, setFile] = useState<File | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const mutation = useMutation({
    mutationFn: (payload: Partial<AdminGlobalCultureItem>) => item ? adminCultureService.updateGlobalItem(token, item.id, payload) : adminCultureService.createGlobalItem(token, payload),
    onSuccess: onDone,
  });
  const isFileBased = fileTypes.includes(type);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setFormError(null);
    const formData = new FormData(event.currentTarget);
    let mediaId = item?.media_id ?? null;

    try {
      if (isFileBased && file) {
        mediaId = (await adminCultureService.uploadMedia(token, file)).id;
      }

      mutation.mutate({
        title: String(formData.get("title") ?? ""),
        description: String(formData.get("description") ?? ""),
        content_type: type,
        media_id: isFileBased ? mediaId : null,
        external_url: isFileBased ? null : String(formData.get("external_url") ?? ""),
        display_order: Number(formData.get("display_order") ?? 1),
        status: String(formData.get("status") ?? "draft"),
      });
    } catch (error) {
      setFormError(getFirstApiError(error));
    }
  }

  return <Card><CardHeader><h2 className="text-xl font-black text-ink">{item ? "Edit Konten Budaya" : "Tambah Konten Budaya"}</h2></CardHeader><CardContent><form className="grid gap-4" onSubmit={submit}>{formError ? <Alert tone="error">{formError}</Alert> : null}{mutation.error ? <Alert tone="error">{getFirstApiError(mutation.error)}</Alert> : null}<FormField label="Judul"><Input name="title" defaultValue={item?.title ?? ""} required /></FormField><FormField label="Deskripsi"><Textarea name="description" defaultValue={item?.description ?? ""} /></FormField><FormField label="Tipe konten"><Select name="content_type" value={type} onChange={(event) => setType(event.target.value)}>{contentTypes.map((contentType) => <option key={contentType} value={contentType}>{contentType}</option>)}</Select></FormField>{isFileBased ? <div className="grid gap-3"><FormField label="File"><UploadComponent onChange={(event) => setFile(event.target.files?.[0] ?? null)} /></FormField>{file ? <FilePreview name={file.name} size={`${Math.ceil(file.size / 1024)} KB`} type={file.type || "File"} /> : null}{item?.media_id && !file ? <p className="text-sm font-bold text-slate-500">Media saat ini tetap dipakai jika tidak upload file baru.</p> : null}</div> : <FormField label="URL"><Input name="external_url" type="url" defaultValue={item?.external_url ?? ""} required /></FormField>}<div className="grid gap-4 md:grid-cols-2"><FormField label="Urutan"><Input name="display_order" type="number" min="1" defaultValue={item?.display_order ?? 1} /></FormField><FormField label="Status"><Select name="status" defaultValue={item?.status ?? "draft"}><option value="draft">Draft</option><option value="published">Published</option><option value="archived">Archived</option></Select></FormField></div><Button disabled={mutation.isPending} type="submit">{mutation.isPending ? "Menyimpan..." : "Simpan"}</Button></form></CardContent></Card>;
}
