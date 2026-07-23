"use client";

import { type FormEvent, useState } from "react";
import { useMutation } from "@tanstack/react-query";

import { Alert, Button, Card, CardContent, CardHeader, FilePreview, FormField, Input, Select, Textarea, UploadComponent } from "@/components/ui";
import { getFirstApiError } from "@/lib/api-client";
import { cultureFileMatches, cultureFields, cultureMediaAccept, isCultureFileType } from "@/features/culture/culture-content";

import { adminCultureService } from "./culture-service";
import type { AdminCultureTemplateItem } from "./types";

export function CultureTemplateItemForm({ editingItem, onCancel, onSaved, templateId, token }: { editingItem: AdminCultureTemplateItem | null; onCancel: () => void; onSaved: () => void; templateId: string; token: string }) {
  const [contentType, setContentType] = useState(editingItem?.content_type ?? "image");
  const [mediaId, setMediaId] = useState(editingItem?.media_id ?? "");
  const [file, setFile] = useState<File | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [uploadSuccess, setUploadSuccess] = useState<string | null>(null);

  const saveMutation = useMutation({
    mutationFn: (payload: Partial<AdminCultureTemplateItem>) => editingItem ? adminCultureService.updateItem(token, editingItem.id, payload) : adminCultureService.createItem(token, templateId, payload),
    onSuccess: onSaved,
  });

  const isFileBased = isCultureFileType(contentType);
  const isLinkBased = !isFileBased;

  async function uploadMedia() {
    if (!file) return;
    if (!cultureFileMatches(contentType, file)) {
      setUploadError("Jenis file tidak sesuai tipe konten.");
      return;
    }
    setIsUploading(true);
    setUploadError(null);
    setUploadSuccess(null);
    try {
      const media = await adminCultureService.uploadMedia(token, file);
      setMediaId(media.id);
      setUploadSuccess(`Media ${media.original_name ?? file.name} diunggah.`);
    } catch (e) {
      setUploadError(getFirstApiError(e));
    } finally {
      setIsUploading(false);
    }
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    saveMutation.mutate({
      title: String(formData.get("title") ?? ""),
      description: String(formData.get("description") ?? "") || null,
      content_type: contentType,
      ...cultureFields(contentType, mediaId || null, String(formData.get("external_url") ?? "") || null),
      display_order: Number(formData.get("display_order") ?? 1),
      status: String(formData.get("status") ?? "draft"),
    });
  }

  return (
    <Card>
      <CardHeader><h2 className="text-xl font-black text-ink">{editingItem ? "Edit Konten Template" : "Tambah Konten Template"}</h2></CardHeader>
      <CardContent>
        <form className="grid gap-4" onSubmit={submit}>
          {saveMutation.error ? <Alert tone="error">{getFirstApiError(saveMutation.error)}</Alert> : null}

          <div className="grid gap-4 sm:grid-cols-2">
            <FormField label="Tipe Konten"><Select onChange={(e) => { setContentType(e.target.value); setFile(null); setMediaId(e.target.value === editingItem?.content_type ? editingItem?.media_id ?? "" : ""); setUploadError(null); setUploadSuccess(null); }} value={contentType}><option value="image">Gambar</option><option value="audio">Audio</option><option value="pdf">PDF</option><option value="video">Video Lokal</option><option value="youtube">YouTube</option><option value="article">Artikel Teks</option><option value="link">Tautan Eksternal</option></Select></FormField>
            <FormField label="Status"><Select defaultValue={editingItem?.status ?? "draft"} name="status"><option value="draft">Draft</option><option value="published">Terbit</option></Select></FormField>
          </div>

          <FormField label="Judul"><Input defaultValue={editingItem?.title ?? ""} name="title" required /></FormField>
          <FormField label="Deskripsi (Opsional)"><Textarea defaultValue={editingItem?.description ?? ""} name="description" rows={3} /></FormField>
          <FormField label="Urutan Tampil"><Input defaultValue={editingItem?.display_order ?? 1} min={1} name="display_order" required type="number" /></FormField>

          {isFileBased ? (
            <div className="grid gap-4 rounded-2xl border-2 border-border bg-surface-muted p-4">
              <h3 className="font-black text-ink">Upload Media</h3>
              {uploadError ? <Alert tone="error">{uploadError}</Alert> : null}
              {uploadSuccess ? <Alert tone="success">{uploadSuccess}</Alert> : null}
              <UploadComponent accept={cultureMediaAccept(contentType)} onChange={(e) => setFile(e.target.files?.[0] ?? null)} />
              <div className="grid gap-2 sm:grid-cols-[1fr_auto] sm:items-end">
                <FormField label="Media"><Input onChange={(e) => setMediaId(e.target.value)} placeholder="Otomatis terisi setelah upload" required value={mediaId} /></FormField>
                <div className="flex gap-2"><Button disabled={!file || isUploading} onClick={uploadMedia} type="button" variant="secondary">{isUploading ? "Upload..." : "Upload"}</Button></div>
              </div>
              {file ? <FilePreview name={file.name} size={`${Math.ceil(file.size / 1024)} KB`} type={file.type || "File"} /> : null}
            </div>
          ) : null}

          {isLinkBased ? (
            <div className="grid gap-4 rounded-2xl border-2 border-border bg-surface-muted p-4">
              <FormField label="URL Eksternal"><Input defaultValue={editingItem?.external_url ?? ""} name="external_url" required type="url" /></FormField>
            </div>
          ) : null}

          <div className="flex gap-3 pt-2"><Button disabled={saveMutation.isPending || isUploading} type="submit">{saveMutation.isPending ? "Menyimpan..." : "Simpan Item"}</Button><Button onClick={onCancel} type="button" variant="ghost">Batal</Button></div>
        </form>
      </CardContent>
    </Card>
  );
}
