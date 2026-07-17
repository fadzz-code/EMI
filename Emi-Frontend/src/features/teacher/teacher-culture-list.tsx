"use client";

import { type FormEvent, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { LibraryBig } from "lucide-react";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, FormField, Input, LoadingState, Select, Textarea, UploadComponent } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { CultureMediaPreview } from "@/features/culture/culture-media-preview";
import { getFirstApiError } from "@/lib/api-client";

import { teacherService } from "./teacher-service";
import { statusLabel } from "./teacher-utils";
import type { TeacherCultureContentType, TeacherCultureItem, TeacherCulturePayload } from "./types";

const fileTypes = ["image", "audio", "pdf", "video"];
const contentTypes: TeacherCultureContentType[] = ["image", "audio", "pdf", "video", "youtube", "article", "link"];

export function TeacherCultureList() {
  const { token } = useAuth();
  const searchParams = useSearchParams();
  const queryClient = useQueryClient();
  const requestedClassId = searchParams.get("class_id");
  const [selectedClassOverride, setSelectedClassOverride] = useState<string>("");
  const [showBuilder, setShowBuilder] = useState(false);
  const [editing, setEditing] = useState<TeacherCultureItem | null>(null);

  const classesQuery = useQuery({ queryKey: ["teacher", "culture", "classes"], queryFn: () => teacherService.classes(token ?? ""), enabled: Boolean(token) });
  const classes = useMemo(() => classesQuery.data?.items ?? [], [classesQuery.data?.items]);
  const requestedClassExists = requestedClassId ? classes.some((classItem) => classItem.id === requestedClassId) : false;
  const selectedClassId = selectedClassOverride || (requestedClassExists ? requestedClassId ?? "" : classes[0]?.id ?? "");
  const selectedClass = useMemo(() => classes.find((classItem) => classItem.id === selectedClassId) ?? null, [classes, selectedClassId]);
  const cultureQuery = useQuery({ queryKey: ["teacher", "classes", selectedClassId, "culture"], queryFn: () => teacherService.classCulture(token ?? "", selectedClassId), enabled: Boolean(token && selectedClassId) });
  const items = cultureQuery.data?.items ?? [];
  const publishedCount = items.filter((item) => item.status === "published").length;
  const isLoading = classesQuery.isLoading || cultureQuery.isLoading;
  const error = classesQuery.error ?? cultureQuery.error;
  const invalidate = () => queryClient.invalidateQueries({ queryKey: ["teacher", "classes", selectedClassId, "culture"] });
  const deleteMutation = useMutation({ mutationFn: (itemId: string) => teacherService.deleteClassCulture(token ?? "", itemId), onSuccess: invalidate });
  const publishMutation = useMutation({ mutationFn: (itemId: string) => teacherService.publishClassCulture(token ?? "", itemId), onSuccess: invalidate });
  const archiveMutation = useMutation({ mutationFn: (itemId: string) => teacherService.archiveClassCulture(token ?? "", itemId), onSuccess: invalidate });

  function openBuilder(item: TeacherCultureItem | null = null) {
    setEditing(item);
    setShowBuilder(true);
  }

  return (
    <div className="grid gap-8">
      <section className="flex flex-col gap-2">
        <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">Guru</p>
        <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">Budaya Mekongga</h1>
        <p className="max-w-3xl text-base font-semibold leading-6 text-muted">Kelola konten budaya untuk kelas, termasuk media, artikel, tautan, dan status terbit.</p>
      </section>

      {isLoading ? <LoadingState title="Memuat Budaya Mekongga" /> : null}
      {error ? <ErrorState description={getFirstApiError(error)} onRetry={() => { void classesQuery.refetch(); void cultureQuery.refetch(); }} title="Gagal memuat Budaya Mekongga" /> : null}

      {!isLoading && !error ? classes.length === 0 ? <Card><CardContent><EmptyState description="Belum ada kelas yang ditugaskan kepada Anda." title="Kelas kosong" /></CardContent></Card> : (
        <div className="grid gap-6">
          {classes.length > 1 ? (
            <Card>
              <CardContent>
                <FormField label="Pilih kelas"><Select value={selectedClassId} onChange={(event) => { setSelectedClassOverride(event.target.value); setEditing(null); setShowBuilder(false); }}>{classes.map((classItem) => <option key={classItem.id} value={classItem.id}>{classItem.name}</option>)}</Select></FormField>
              </CardContent>
            </Card>
          ) : null}

          <Card>
            <CardContent>
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <h2 className="text-2xl font-black text-ink">{selectedClass?.name ?? "Kelas"}</h2>
                  <p className="mt-2 text-sm font-bold text-muted">{items.length} konten · {publishedCount} konten terbit</p>
                </div>
                <Button onClick={() => openBuilder()} type="button" variant="secondary">Kelola Media</Button>
              </div>
            </CardContent>
          </Card>

          {showBuilder ? <CultureForm classId={selectedClassId} item={editing} key={editing?.id ?? `new-${selectedClassId}`} onDone={() => { setEditing(null); setShowBuilder(false); void invalidate(); }} /> : null}

          {items.length === 0 ? <Card><CardContent><EmptyState description="Belum ada konten budaya untuk kelas ini. Klik Kelola Media untuk menambah konten." title="Budaya Mekongga kosong" /></CardContent></Card> : (
            <div className="grid gap-4 md:grid-cols-2">
              {items.map((item) => (
                <Card className="group flex h-full flex-col transition hover:-translate-y-1 hover:shadow-emi" key={item.id}>
                  <CardHeader><div className="flex items-start justify-between gap-3"><span className="flex size-12 shrink-0 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-ink transition-colors group-hover:bg-primary group-hover:text-primary-foreground"><LibraryBig className="size-6" strokeWidth={2.5} /></span><div className="flex flex-wrap justify-end gap-2"><Badge tone={item.status === "published" ? "blue" : item.status === "archived" ? "neutral" : "yellow"}>{statusLabel(item.status)}</Badge><Badge tone="neutral">{item.content_type}</Badge></div></div><h2 className="mt-2 text-xl font-black text-ink">{item.title}</h2></CardHeader>
                  <CardContent className="flex flex-1 flex-col">
                    <p className="text-sm font-semibold text-muted">{item.description ?? "Tanpa deskripsi"}</p>
                    {item.created_scope === "admin" || item.admin_group_id ? <p className="mt-2 text-xs font-black uppercase text-muted">Salinan konten admin untuk kelas ini</p> : item.source_template_item_id ? <p className="mt-2 text-xs font-black uppercase text-muted">Salinan dari template admin</p> : <p className="mt-2 text-xs font-black uppercase text-muted">Dibuat guru untuk kelas ini</p>}
                    <CultureMediaPreview item={item} />
                    <div className="mt-auto flex flex-wrap gap-2 pt-4">
                      <Button type="button" variant="secondary" onClick={() => openBuilder(item)}>Edit</Button>
                      {item.status !== "published" ? <Button type="button" onClick={() => publishMutation.mutate(item.id)}>Publish</Button> : null}
                      {item.status !== "archived" ? <Button type="button" variant="secondary" onClick={() => archiveMutation.mutate(item.id)}>Arsipkan</Button> : null}
                      <Button type="button" variant="danger" onClick={() => deleteMutation.mutate(item.id)}>Hapus dari Kelas Ini</Button>
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

function CultureForm({ classId, item, onDone }: { classId: string; item: TeacherCultureItem | null; onDone: () => void }) {
  const { token } = useAuth();
  const [type, setType] = useState<TeacherCultureContentType>(item?.content_type ?? "image");
  const [file, setFile] = useState<File | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const mutation = useMutation({
    mutationFn: async (payload: TeacherCulturePayload) => item ? teacherService.updateClassCulture(token ?? "", item.id, payload) : teacherService.createClassCulture(token ?? "", classId, payload),
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
