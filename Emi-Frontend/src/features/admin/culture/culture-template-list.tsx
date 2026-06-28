"use client";

import { type FormEvent, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, FormField, Input, LoadingState, PageHeader, Select, Textarea } from "@/components/ui";
import { classService } from "@/features/admin/management/management-service";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { adminCultureService } from "./culture-service";
import { CultureTemplateItemForm } from "./culture-template-item-form";
import type { AdminCultureTemplateItem } from "./types";

function statusLabel(status: string | null | undefined) {
  if (status === "draft") return "Draft";
  if (status === "published") return "Terbit";
  if (status === "archived") return "Arsip";
  return status ?? "Belum tersedia";
}

export function AdminCultureTemplateList() {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const searchParams = useSearchParams();
  const requestedTemplateId = searchParams.get("template_id");
  const [search, setSearch] = useState("");
  const [selectedTemplateOverride, setSelectedTemplateOverride] = useState("");
  const [showCreate, setShowCreate] = useState(false);
  const [showItemBuilder, setShowItemBuilder] = useState(false);
  const [showApplyPanel, setShowApplyPanel] = useState(false);
  const [editingItem, setEditingItem] = useState<AdminCultureTemplateItem | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const templatesQuery = useQuery({
    queryKey: ["admin", "culture-templates", search],
    queryFn: () => adminCultureService.getTemplates(token ?? "", search),
    enabled: Boolean(token),
  });
  const templates = useMemo(() => templatesQuery.data?.items ?? [], [templatesQuery.data?.items]);
  const requestedTemplateExists = requestedTemplateId ? templates.some((template) => template.id === requestedTemplateId) : false;
  const selectedTemplateId = selectedTemplateOverride || (requestedTemplateExists ? requestedTemplateId ?? "" : templates[0]?.id ?? "");
  const templateQuery = useQuery({
    queryKey: ["admin", "culture-templates", selectedTemplateId],
    queryFn: () => adminCultureService.getTemplate(token ?? "", selectedTemplateId),
    enabled: Boolean(token && selectedTemplateId),
  });
  const classesQuery = useQuery({
    queryKey: ["admin", "classes"],
    queryFn: () => classService.list(token ?? "", { per_page: 100 }),
    enabled: Boolean(token),
  });

  const template = templateQuery.data;
  const items = template?.items ?? [];
  const publishedItems = items.filter((item) => item.status === "published").length;

  const createMutation = useMutation({
    mutationFn: (payload: { title: string; description: string }) => adminCultureService.createTemplate(token ?? "", payload),
    onSuccess: (created) => {
      setSuccessMsg("Template berhasil dibuat. Tambahkan konten, publish, lalu terapkan ke kelas.");
      setSelectedTemplateOverride(created.id);
      setShowCreate(false);
      queryClient.invalidateQueries({ queryKey: ["admin", "culture-templates"] });
    },
  });
  const updateMutation = useMutation({
    mutationFn: (payload: { title: string; description: string }) => adminCultureService.updateTemplate(token ?? "", selectedTemplateId, payload),
    onSuccess: () => {
      setSuccessMsg("Template berhasil disimpan.");
      invalidateTemplate();
    },
  });
  const publishMutation = useMutation({
    mutationFn: () => adminCultureService.publishTemplate(token ?? "", selectedTemplateId),
    onSuccess: () => {
      setSuccessMsg("Template berhasil dipublish. Template belum tampil untuk guru/siswa sampai diterapkan ke kelas.");
      setShowApplyPanel(true);
      invalidateTemplate();
    },
  });
  const applyMutation = useMutation({
    mutationFn: (classIds: string[]) => adminCultureService.applyTemplate(token ?? "", selectedTemplateId, classIds),
    onSuccess: (res) => setSuccessMsg(`Berhasil diterapkan ke ${res.applied.length} kelas. Dilewati: ${res.skipped.length}, Gagal: ${res.failed.length}.`),
  });
  const deleteItemMutation = useMutation({
    mutationFn: (itemId: string) => adminCultureService.deleteItem(token ?? "", itemId),
    onSuccess: () => {
      setSuccessMsg("Konten template berhasil dihapus.");
      invalidateTemplate();
    },
  });

  function invalidateTemplate() {
    queryClient.invalidateQueries({ queryKey: ["admin", "culture-templates", selectedTemplateId] });
    queryClient.invalidateQueries({ queryKey: ["admin", "culture-templates"] });
  }

  function openItemBuilder(item: AdminCultureTemplateItem | null = null) {
    setEditingItem(item);
    setShowItemBuilder(true);
  }

  function createTemplate(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    createMutation.mutate({ title: String(formData.get("title") ?? ""), description: String(formData.get("description") ?? "") });
  }

  function updateTemplate(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSuccessMsg(null);
    const formData = new FormData(event.currentTarget);
    updateMutation.mutate({ title: String(formData.get("title") ?? ""), description: String(formData.get("description") ?? "") });
  }

  function applyTemplate(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSuccessMsg(null);
    const formData = new FormData(event.currentTarget);
    const classIds = formData.get("apply_all") === "on" ? (classesQuery.data?.items ?? []).map((classItem) => classItem.id) : formData.getAll("class_ids").map(String);
    if (classIds.length === 0) {
      alert("Pilih minimal satu kelas.");
      return;
    }
    applyMutation.mutate(classIds);
  }

  return (
    <div className="grid gap-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <PageHeader badge="Admin" description="Template Budaya Mekongga" title="Budaya Mekongga" />
        <div className="flex flex-wrap gap-2">
          <Button onClick={() => setShowCreate((value) => !value)} type="button">Buat Template</Button>
          <Button disabled={!selectedTemplateId} onClick={() => openItemBuilder()} type="button" variant="secondary">Kelola Konten Template</Button>
          <Button disabled={!selectedTemplateId} onClick={() => setShowApplyPanel((value) => !value)} type="button" variant="secondary">Terapkan ke Kelas</Button>
        </div>
      </div>
      <p className="text-sm leading-6 text-slate-600">Kelola template Budaya Mekongga yang bisa diterapkan ke kelas.</p>
      {successMsg ? <Alert tone="success">{successMsg}</Alert> : null}

      {showCreate ? (
        <Card>
          <CardHeader><h2 className="text-xl font-black text-ink">Buat Template Budaya</h2></CardHeader>
          <CardContent>
            <form className="grid gap-4 sm:max-w-xl" onSubmit={createTemplate}>
              {createMutation.error ? <Alert tone="error">{getFirstApiError(createMutation.error)}</Alert> : null}
              <FormField label="Judul"><Input name="title" required /></FormField>
              <FormField label="Deskripsi"><Textarea name="description" /></FormField>
              <Button disabled={createMutation.isPending} type="submit">{createMutation.isPending ? "Menyimpan..." : "Simpan Template"}</Button>
            </form>
          </CardContent>
        </Card>
      ) : null}

      <Card>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-[1fr_1fr]">
            <FormField label="Cari template"><Input onChange={(event) => setSearch(event.target.value)} placeholder="Cari template..." value={search} /></FormField>
            {templates.length > 1 ? <FormField label="Pilih template"><Select value={selectedTemplateId} onChange={(event) => { setSelectedTemplateOverride(event.target.value); setShowItemBuilder(false); setShowApplyPanel(false); setEditingItem(null); }}>{templates.map((templateItem) => <option key={templateItem.id} value={templateItem.id}>{templateItem.title}</option>)}</Select></FormField> : null}
          </div>
        </CardContent>
      </Card>

      {templatesQuery.isLoading || templateQuery.isLoading ? <LoadingState title="Memuat template budaya" /> : null}
      {templatesQuery.isError ? <ErrorState description={getFirstApiError(templatesQuery.error)} onRetry={() => void templatesQuery.refetch()} title="Gagal memuat template" /> : null}
      {templateQuery.isError ? <ErrorState description={getFirstApiError(templateQuery.error)} onRetry={() => void templateQuery.refetch()} title="Gagal memuat detail template" /> : null}
      {!templatesQuery.isLoading && !templatesQuery.isError && templates.length === 0 ? <Card><CardContent><EmptyState description="Belum ada template budaya. Klik Buat Template untuk memulai." title="Template kosong" /></CardContent></Card> : null}

      {template ? (
        <div className="grid gap-6">
          <Card>
            <CardContent>
              <div className="flex flex-wrap items-start justify-between gap-4">
                <div>
                  <div className="flex flex-wrap gap-2"><Badge tone={template.status === "published" ? "blue" : "neutral"}>{statusLabel(template.status)}</Badge><Badge tone="neutral">Template admin</Badge></div>
                  <h2 className="mt-3 text-2xl font-black text-ink">{template.title}</h2>
                  <p className="mt-2 text-sm text-slate-600">{template.description ?? "Tanpa deskripsi"}</p>
                  <p className="mt-3 text-sm font-bold text-slate-500">{items.length} konten · {publishedItems} konten terbit</p>
                </div>
                <div className="flex flex-wrap gap-2">
                  <Button disabled={publishMutation.isPending || template.status === "published"} onClick={() => publishMutation.mutate()} type="button">{publishMutation.isPending ? "Publishing..." : "Publish Template"}</Button>
                  <Button onClick={() => setShowApplyPanel(true)} type="button" variant="secondary">Terapkan ke Kelas</Button>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader><h2 className="text-xl font-black text-ink">Informasi Template</h2></CardHeader>
            <CardContent>
              <form className="grid gap-4" onSubmit={updateTemplate}>
                {updateMutation.error ? <Alert tone="error">{getFirstApiError(updateMutation.error)}</Alert> : null}
                {publishMutation.error ? <Alert tone="error">{getFirstApiError(publishMutation.error)}</Alert> : null}
                <FormField label="Judul"><Input defaultValue={template.title} key={`${template.id}-title`} name="title" required /></FormField>
                <FormField label="Deskripsi"><Textarea defaultValue={template.description ?? ""} key={`${template.id}-description`} name="description" /></FormField>
                <Button disabled={updateMutation.isPending} type="submit">{updateMutation.isPending ? "Menyimpan..." : "Simpan Template"}</Button>
              </form>
            </CardContent>
          </Card>

          {showItemBuilder ? <CultureTemplateItemForm editingItem={editingItem} key={editingItem?.id ?? `new-${template.id}`} onCancel={() => { setShowItemBuilder(false); setEditingItem(null); }} onSaved={() => { setSuccessMsg("Konten template berhasil disimpan."); setShowItemBuilder(false); setEditingItem(null); invalidateTemplate(); }} templateId={template.id} token={token ?? ""} /> : null}

          <Card>
            <CardHeader><div className="flex flex-wrap items-center justify-between gap-3"><h2 className="text-xl font-black text-ink">Konten Template</h2><Button onClick={() => openItemBuilder()} type="button" variant="secondary">Tambah Konten Template</Button></div></CardHeader>
            <CardContent>
              {deleteItemMutation.error ? <Alert tone="error">{getFirstApiError(deleteItemMutation.error)}</Alert> : null}
              {items.length === 0 ? <EmptyState description="Belum ada konten template." title="Konten kosong" /> : (
                <div className="grid gap-4 md:grid-cols-2">
                  {items.map((item) => <TemplateItemCard item={item} key={item.id} onDelete={() => { if (confirm("Hapus konten template ini?")) deleteItemMutation.mutate(item.id); }} onEdit={() => openItemBuilder(item)} />)}
                </div>
              )}
            </CardContent>
          </Card>

          {showApplyPanel ? (
            <Card>
              <CardHeader><h2 className="text-xl font-black text-ink">Terapkan ke Kelas</h2></CardHeader>
              <CardContent>
                <p className="mb-4 text-sm text-slate-600">Template yang dipublish belum tampil untuk guru/siswa sampai diterapkan ke kelas. Saat diterapkan, sistem membuat konten budaya kelas sebagai salinan class-scoped.</p>
                {template.status !== "published" ? <Alert className="mb-4" tone="warning">Publish template terlebih dahulu untuk membuka aksi Terapkan ke Kelas.</Alert> : <Alert className="mb-4" tone="info">Template siap diterapkan ke kelas.</Alert>}
                {applyMutation.error ? <Alert className="mb-4" tone="error">{getFirstApiError(applyMutation.error)}</Alert> : null}
                <form onSubmit={applyTemplate}>
                  <label className="mb-3 flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 p-3 text-sm font-black text-ink"><input name="apply_all" type="checkbox" /> Terapkan ke Semua Kelas</label>
                  <div className="mb-4 max-h-48 overflow-y-auto rounded-lg border border-slate-200 bg-slate-50 p-2">
                    {classesQuery.isLoading ? <p className="p-2 text-sm text-slate-500">Memuat kelas...</p> : null}
                    {classesQuery.data?.items.map((classItem) => <label className="flex items-center gap-2 p-2 text-sm font-bold text-ink hover:bg-white" key={classItem.id}><input name="class_ids" type="checkbox" value={classItem.id} /> {classItem.name} {classItem.school ? `(${classItem.school.name})` : ""}</label>)}
                  </div>
                  <Button disabled={applyMutation.isPending || template.status !== "published" || classesQuery.isLoading} type="submit" variant="secondary">{applyMutation.isPending ? "Menerapkan..." : "Terapkan ke Kelas"}</Button>
                </form>
              </CardContent>
            </Card>
          ) : null}
        </div>
      ) : null}
    </div>
  );
}

function TemplateItemCard({ item, onDelete, onEdit }: { item: AdminCultureTemplateItem; onDelete: () => void; onEdit: () => void }) {
  const url = item.media?.url ?? item.external_url;

  return <Card><CardHeader><div className="flex flex-wrap gap-2"><Badge tone={item.status === "published" ? "blue" : item.status === "archived" ? "neutral" : "yellow"}>{statusLabel(item.status)}</Badge><Badge tone="neutral">{item.content_type}</Badge></div><h3 className="mt-2 text-xl font-black text-ink">{item.title}</h3></CardHeader><CardContent><p className="text-sm text-slate-600">{item.description ?? "Tanpa deskripsi"}</p><p className="mt-2 text-xs font-black uppercase text-slate-500">Template admin</p>{url ? <a className="mt-3 inline-flex font-black text-blue-700 underline" href={url} rel="noreferrer" target="_blank">Buka konten</a> : <p className="mt-3 text-sm font-bold text-slate-500">Konten belum memiliki URL publik.</p>}<div className="mt-4 flex flex-wrap gap-2"><Button onClick={onEdit} type="button" variant="secondary">Edit</Button><Button onClick={onDelete} type="button" variant="danger">Hapus</Button></div></CardContent></Card>;
}
