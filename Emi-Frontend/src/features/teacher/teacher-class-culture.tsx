"use client";

import { type FormEvent, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { LibraryBig } from "lucide-react";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, FormField, Input, LoadingState, Select, Textarea, UploadComponent } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { TeacherClassNav } from "./teacher-class-nav";
import { teacherService } from "./teacher-service";
import { statusLabel } from "./teacher-utils";
import type { TeacherCultureContentType, TeacherCultureItem, TeacherCulturePayload } from "./types";

const fileTypes = ["image", "audio", "pdf", "video"];
const contentTypes: TeacherCultureContentType[] = ["image", "audio", "pdf", "video", "youtube", "article", "link"];

export function TeacherClassCulture({ classId }: { classId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [editing, setEditing] = useState<TeacherCultureItem | null>(null);
  const query = useQuery({ queryKey: ["teacher", "classes", classId, "culture"], queryFn: () => teacherService.classCulture(token ?? "", classId), enabled: Boolean(token && classId) });
  const invalidate = () => queryClient.invalidateQueries({ queryKey: ["teacher", "classes", classId, "culture"] });
  const deleteMutation = useMutation({ mutationFn: (itemId: string) => teacherService.deleteClassCulture(token ?? "", itemId), onSuccess: invalidate });
  const publishMutation = useMutation({ mutationFn: (itemId: string) => teacherService.publishClassCulture(token ?? "", itemId), onSuccess: invalidate });
  const archiveMutation = useMutation({ mutationFn: (itemId: string) => teacherService.archiveClassCulture(token ?? "", itemId), onSuccess: invalidate });
  const items = query.data?.items ?? [];

  return (
    <div className="grid gap-8">
      <section className="flex flex-col gap-2">
        <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">Guru</p>
        <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">Konten Budaya Kelas</h1>
        <p className="max-w-3xl text-base font-semibold leading-6 text-muted">Kelola konten budaya untuk kelas ini, termasuk media, artikel, tautan, dan status terbit.</p>
      </section>
      <TeacherClassNav classId={classId} />
      <CultureForm classId={classId} item={editing} key={editing?.id ?? "new"} onDone={() => { setEditing(null); void invalidate(); }} />
      {query.isLoading ? <LoadingState title="Memuat Budaya Mekongga" /> : null}
      {query.isError ? <ErrorState description={getFirstApiError(query.error)} onRetry={() => void query.refetch()} title="Gagal memuat Budaya Mekongga" /> : null}
      {!query.isLoading && !query.isError ? items.length === 0 ? <Card><CardContent><EmptyState description="Belum ada konten budaya untuk kelas ini." title="Budaya Mekongga kosong" /></CardContent></Card> : (
        <div className="grid gap-4 md:grid-cols-2">
          {items.map((item) => (
            <Card className="group flex h-full flex-col transition hover:-translate-y-1 hover:shadow-emi" key={item.id}>
              <CardHeader><div className="flex items-start justify-between gap-3"><span className="flex size-12 shrink-0 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-ink transition-colors group-hover:bg-primary group-hover:text-primary-foreground"><LibraryBig className="size-6" strokeWidth={2.5} /></span><div className="flex flex-wrap justify-end gap-2"><Badge tone={item.status === "published" ? "blue" : item.status === "archived" ? "neutral" : "yellow"}>{statusLabel(item.status)}</Badge><Badge tone="neutral">{item.content_type}</Badge></div></div><h2 className="mt-2 text-xl font-black text-ink">{item.title}</h2></CardHeader>
              <CardContent className="flex flex-1 flex-col">
                <p className="text-sm font-semibold text-muted">{item.description ?? "Tanpa deskripsi"}</p>
                {item.source_template_item_id ? <p className="mt-2 text-xs font-black uppercase text-muted">Salinan dari template admin</p> : <p className="mt-2 text-xs font-black uppercase text-muted">Dibuat guru untuk kelas ini</p>}
                <CultureLink item={item} />
                <div className="mt-auto flex flex-wrap gap-2 pt-4">
                  <Button type="button" variant="secondary" onClick={() => setEditing(item)}>Edit</Button>
                  {item.status !== "published" ? <Button type="button" onClick={() => publishMutation.mutate(item.id)}>Publish</Button> : null}
                  {item.status !== "archived" ? <Button type="button" variant="secondary" onClick={() => archiveMutation.mutate(item.id)}>Arsipkan</Button> : null}
                  <Button type="button" variant="danger" onClick={() => deleteMutation.mutate(item.id)}>Hapus</Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : null}
    </div>
  );
}

function CultureForm({ classId, item, onDone }: { classId: string; item: TeacherCultureItem | null; onDone: () => void }) {
  const { token } = useAuth();
  const [type, setType] = useState<TeacherCultureContentType>(item?.content_type ?? "image");
  const [file, setFile] = useState<File | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const mutation = useMutation({
    mutationFn: async (payload: TeacherCulturePayload) => {
      return item ? teacherService.updateClassCulture(token ?? "", item.id, payload) : teacherService.createClassCulture(token ?? "", classId, payload);
    },
    onSuccess: onDone,
  });

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setFormError(null);
    const formData = new FormData(event.currentTarget);
    let mediaId = item?.media_id ?? null;

    try {
      if (fileTypes.includes(type) && file) {
        mediaId = (await teacherService.uploadCultureMedia(token ?? "", file)).id;
      }

      mutation.mutate({
        title: String(formData.get("title") ?? ""),
        description: String(formData.get("description") ?? ""),
        content_type: type,
        media_id: fileTypes.includes(type) ? mediaId : null,
        external_url: fileTypes.includes(type) ? null : String(formData.get("external_url") ?? ""),
        display_order: Number(formData.get("display_order") ?? 1),
        status: String(formData.get("status") ?? "draft"),
      });
    } catch (error) {
      setFormError(getFirstApiError(error));
    }
  }

  return <Card><CardHeader><h2 className="text-xl font-black text-ink">{item ? "Edit Konten Budaya" : "Tambah Konten Budaya"}</h2></CardHeader><CardContent><form className="grid gap-4" onSubmit={submit}>{formError ? <Alert tone="error">{formError}</Alert> : null}{mutation.error ? <Alert tone="error">{getFirstApiError(mutation.error)}</Alert> : null}{mutation.isSuccess ? <Alert tone="success">Tersimpan.</Alert> : null}<FormField label="Judul"><Input name="title" defaultValue={item?.title ?? ""} required /></FormField><FormField label="Deskripsi"><Textarea name="description" defaultValue={item?.description ?? ""} /></FormField><FormField label="Tipe konten"><Select name="content_type" value={type} onChange={(event) => setType(event.target.value as TeacherCultureContentType)}>{contentTypes.map((contentType) => <option key={contentType} value={contentType}>{contentType}</option>)}</Select></FormField>{fileTypes.includes(type) ? <FormField label="File"><UploadComponent onChange={(event) => setFile(event.target.files?.[0] ?? null)} /></FormField> : <FormField label="URL"><Input name="external_url" type="url" defaultValue={item?.external_url ?? ""} required /></FormField>}<div className="grid gap-4 md:grid-cols-2"><FormField label="Urutan"><Input name="display_order" type="number" min="1" defaultValue={item?.display_order ?? 1} /></FormField><FormField label="Status"><Select name="status" defaultValue={item?.status ?? "draft"}><option value="draft">Draft</option><option value="published">Terbit</option><option value="archived">Arsip</option></Select></FormField></div><div className="flex gap-2"><Button disabled={mutation.isPending} type="submit">{mutation.isPending ? "Menyimpan..." : "Simpan"}</Button></div></form></CardContent></Card>;
}

function CultureLink({ item }: { item: TeacherCultureItem }) {
  const url = item.media?.url ?? item.external_url;
  if (!url) return <p className="mt-3 text-sm font-bold text-muted">Konten belum memiliki URL publik.</p>;
  if (item.content_type === "image") return <img alt={item.title} className="mt-3 max-h-64 rounded-xl border-2 border-border object-cover" src={url} />;
  if (item.content_type === "audio") return <audio className="mt-3 w-full" controls src={url} />;
  if (item.content_type === "video") return <video className="mt-3 w-full rounded-xl border-2 border-border" controls src={url} />;
  return <a className="mt-3 inline-flex font-black text-primary underline" href={url} rel="noreferrer" target="_blank">Buka konten</a>;
}
