"use client";

import { type ChangeEvent, type FormEvent, useState } from "react";

import { Button, FilePreview, FormField, Input, MutationAlert, Select, Textarea, UploadComponent } from "@/components/ui";

import { acceptForLesson, INVALID_LESSON_MEDIA_MESSAGE, isValidLessonMedia, lessonPayload, mediaPurposeForLesson, validateLessonForm } from "./teacher-lesson-workflow";
import { teacherService } from "./teacher-service";
import type { TeacherLessonContentType, TeacherLessonForm, TeacherLessonPayload } from "./types";

const labels: Record<TeacherLessonContentType, string> = { text: "Teks", image: "Gambar", audio: "Audio", pdf: "PDF", video: "Video", link: "Link" };

function emptyForm(): TeacherLessonForm {
  return { title: "", description: "", content_type: "text", content_body: "", media_id: "", external_url: "", sort_order: "" };
}

export function TeacherLessonCreateForm({
  isSubmitting,
  onCancel,
  onSubmit,
  token,
}: {
  isSubmitting: boolean;
  onCancel: () => void;
  onSubmit: (payload: TeacherLessonPayload) => void;
  token: string;
}) {
  const [form, setForm] = useState<TeacherLessonForm>(emptyForm);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);
  const [localAttempt, setLocalAttempt] = useState(0);

  function changeType(type: TeacherLessonContentType) {
    setSelectedFile(null);
    setLocalError(null);
    setForm((current) => ({ ...current, content_type: type, content_body: "", external_url: "", media_id: "" }));
  }

  function chooseFile(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0] ?? null;
    setLocalError(null);
    if (file && !isValidLessonMedia(form.content_type, file)) {
      setSelectedFile(null);
      setLocalError(INVALID_LESSON_MEDIA_MESSAGE);
      event.target.value = "";
      return;
    }
    setSelectedFile(file);
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLocalAttempt((attempt) => attempt + 1);
    let mediaId = form.media_id;

    if (selectedFile) {
      const purpose = mediaPurposeForLesson(form.content_type);
      if (!purpose) {
        setLocalError(INVALID_LESSON_MEDIA_MESSAGE);
        return;
      }
      try {
        setIsUploading(true);
        const media = await teacherService.uploadMedia(token, selectedFile, purpose, "private");
        mediaId = media.id;
      } catch {
        setIsUploading(false);
        setLocalError("Gagal mengunggah file. Coba lagi.");
        return;
      }
      setIsUploading(false);
    }

    const nextForm: TeacherLessonForm = { ...form, media_id: mediaId };
    const validationError = validateLessonForm(nextForm);
    setLocalError(validationError);
    if (!validationError) onSubmit(lessonPayload(nextForm));
  }

  const busy = isSubmitting || isUploading;

  return (
    <form className="grid gap-4" onSubmit={(event) => void handleSubmit(event)}>
      <MutationAlert eventKey={localAttempt} tone="error" visible={Boolean(localError)}>{localError}</MutationAlert>
      <FormField label="Judul Materi">
        <Input disabled={busy} onChange={(event) => setForm({ ...form, title: event.target.value })} required value={form.title} />
      </FormField>
      <FormField label="Deskripsi Singkat">
        <Textarea disabled={busy} onChange={(event) => setForm({ ...form, description: event.target.value })} rows={2} value={form.description} />
      </FormField>
      <div className="grid gap-4 sm:grid-cols-[1fr_160px]">
        <FormField label="Jenis Materi">
          <Select disabled={busy} onChange={(event) => changeType(event.target.value as TeacherLessonContentType)} value={form.content_type}>
            {Object.entries(labels).map(([value, label]) => (
              <option key={value} value={value}>{label}</option>
            ))}
          </Select>
        </FormField>
        <FormField label="Urutan Tampil">
          <Input disabled={busy} min={1} onChange={(event) => setForm({ ...form, sort_order: event.target.value })} placeholder="Auto" type="number" value={form.sort_order} />
        </FormField>
      </div>
      {form.content_type === "text" ? (
        <FormField label="Isi Materi (Teks)">
          <Textarea disabled={busy} onChange={(event) => setForm({ ...form, content_body: event.target.value })} required rows={8} value={form.content_body} />
        </FormField>
      ) : null}
      {form.content_type === "video" || form.content_type === "link" ? (
        <FormField label="URL HTTPS">
          <Input disabled={busy} onChange={(event) => setForm({ ...form, external_url: event.target.value })} placeholder="https://..." required type="url" value={form.external_url} />
        </FormField>
      ) : null}
      {mediaPurposeForLesson(form.content_type) ? (
        <FormField label={`Unggah ${labels[form.content_type]}`}>
          <UploadComponent accept={acceptForLesson(form.content_type)} disabled={busy} onChange={chooseFile} />
          {selectedFile ? <FilePreview name={selectedFile.name} size={`${Math.ceil(selectedFile.size / 1024)} KB`} type={selectedFile.type || labels[form.content_type]} /> : null}
        </FormField>
      ) : null}
      <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
        <Button disabled={busy} onClick={onCancel} type="button" variant="ghost">Batal</Button>
        <Button disabled={busy} type="submit">{isUploading ? "Mengunggah..." : isSubmitting ? "Menyimpan..." : "Simpan Materi"}</Button>
      </div>
    </form>
  );
}
