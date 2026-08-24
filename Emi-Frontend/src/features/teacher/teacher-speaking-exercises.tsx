"use client";

import { type ChangeEvent, type FormEvent, useEffect, useMemo, useState } from "react";
import { Archive, ListChecks, Pencil, Plus, Send, Trash2 } from "lucide-react";

import { Alert, AudioPlayer, Badge, Button, Card, CardContent, ConfirmDialog, EmptyState, ErrorState, FormField, Input, LoadingState, Modal, Select, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { teacherService } from "./teacher-service";
import { speakingExerciseLifecycle } from "./teacher-workflow";
import type { TeacherClass, TeacherSpeakingExercise, TeacherSpeakingExercisePayload, TeacherSpeakingTemplate } from "./types";

type FormState = {
  template_exercise_id: string;
  classroom_id: string;
  title: string;
  target_text: string;
  target_translation: string;
  prompt_text: string;
  difficulty: string;
  status: "draft" | "published";
  reference_audio_media_id: string;
};

const defaultForm: FormState = {
  template_exercise_id: "",
  classroom_id: "",
  title: "",
  target_text: "",
  target_translation: "",
  prompt_text: "",
  difficulty: "beginner",
  status: "draft",
  reference_audio_media_id: "",
};

function statusTone(status?: string | null): "yellow" | "blue" | "orange" {
  if (status === "published") return "blue";
  if (status === "archived") return "orange";
  return "yellow";
}

function statusLabel(status?: string | null) {
  return {
    draft: "Draft",
    published: "Published",
    archived: "Archived",
  }[status ?? ""] ?? "Status";
}

function toForm(exercise: TeacherSpeakingExercise, fallbackClassId: string): FormState {
  return {
    template_exercise_id: "",
    classroom_id: exercise.classroom_id ?? fallbackClassId,
    title: exercise.title ?? "",
    target_text: exercise.target_text ?? "",
    target_translation: exercise.target_translation ?? "",
    prompt_text: exercise.prompt_text ?? "",
    difficulty: exercise.difficulty ?? "beginner",
    status: exercise.status === "published" ? "published" : "draft",
    reference_audio_media_id: exercise.reference_audio_media_id ?? "",
  };
}

function toPayload(form: FormState, includeTemplate = false): TeacherSpeakingExercisePayload {
  return {
    ...(includeTemplate && form.template_exercise_id ? { template_exercise_id: form.template_exercise_id } : {}),
    classroom_id: form.classroom_id,
    title: form.title.trim(),
    target_text: form.target_text.trim(),
    target_translation: form.target_translation.trim() || null,
    prompt_text: form.prompt_text.trim() || null,
    reference_audio_media_id: form.reference_audio_media_id || null,
    difficulty: form.difficulty || null,
    language_code: "mekongga",
    status: form.status,
  };
}

export function TeacherSpeakingExercises() {
  const { token } = useAuth();
  const [classes, setClasses] = useState<TeacherClass[]>([]);
  const [exercises, setExercises] = useState<TeacherSpeakingExercise[]>([]);
  const [templates, setTemplates] = useState<TeacherSpeakingTemplate[]>([]);
  const [selectedClassId, setSelectedClassId] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [editingExercise, setEditingExercise] = useState<TeacherSpeakingExercise | null>(null);
  const [form, setForm] = useState<FormState>(defaultForm);
  const [audioName, setAudioName] = useState("");
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [audioError, setAudioError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isTemplateLoading, setIsTemplateLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [templateError, setTemplateError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<TeacherSpeakingExercise | null>(null);
  const [archiveTarget, setArchiveTarget] = useState<TeacherSpeakingExercise | null>(null);
  const [publishTarget, setPublishTarget] = useState<TeacherSpeakingExercise | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);
  const [isArchiving, setIsArchiving] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);

  const classNameById = useMemo(() => new Map(classes.map((item) => [item.id, item.name])), [classes]);
  const selectedTemplate = useMemo(() => templates.find((item) => item.id === form.template_exercise_id) ?? null, [form.template_exercise_id, templates]);
  const previewAudio = selectedTemplate?.reference_audio ?? editingExercise?.reference_audio ?? null;
  const onlyClass = classes.length === 1 ? classes[0] : null;
  const hasNoClass = !isLoading && classes.length === 0;

  useEffect(() => {
    if (!token) return;
    let ignore = false;
    Promise.all([
      teacherService.classes(token),
      teacherService.speakingExercises(token),
      teacherService.speakingTemplates(token),
    ]).then(([classResult, exerciseResult, templateResult]) => {
      if (ignore) return;
      const classItems = classResult.items;
      setClasses(classItems);
      setExercises(exerciseResult.items);
      setTemplates(templateResult.items);
      setSelectedClassId((current) => current || classItems[0]?.id || "");
      setForm((current) => ({ ...current, classroom_id: current.classroom_id || classItems[0]?.id || "" }));
      setError(null);
      setTemplateError(null);
    }).catch((err) => {
      if (!ignore) {
        const message = getFirstApiError(err);
        setError(message);
        setTemplateError(message);
      }
    }).finally(() => {
      if (!ignore) {
        setIsLoading(false);
        setIsTemplateLoading(false);
      }
    });

    return () => {
      ignore = true;
    };
  }, [token]);

  async function loadInitial() {
    if (!token) return;
    setIsLoading(true);
    try {
      setIsTemplateLoading(true);
      const [classResult, exerciseResult, templateResult] = await Promise.all([
        teacherService.classes(token),
        teacherService.speakingExercises(token),
        teacherService.speakingTemplates(token),
      ]);
      const classItems = classResult.items;
      setClasses(classItems);
      setExercises(exerciseResult.items);
      setTemplates(templateResult.items);
      setSelectedClassId((current) => current || classItems[0]?.id || "");
      setForm((current) => ({ ...current, classroom_id: current.classroom_id || classItems[0]?.id || "" }));
      setError(null);
      setTemplateError(null);
    } catch (err) {
      const message = getFirstApiError(err);
      setError(message);
      setTemplateError(message);
    } finally {
      setIsLoading(false);
      setIsTemplateLoading(false);
    }
  }

  async function reloadExercises(filters: { classroom_id?: string; status?: string } = {}) {
    if (!token) return;
    try {
      const result = await teacherService.speakingExercises(token, filters);
      setExercises(result.items);
      setError(null);
    } catch (err) {
      setError(getFirstApiError(err));
    }
  }

  function openCreate() {
    setEditingExercise(null);
    setForm({ ...defaultForm, classroom_id: selectedClassId || classes[0]?.id || "" });
    setAudioName("");
    setAudioFile(null);
    setAudioError(null);
    setModalOpen(true);
  }

  function openEdit(exercise: TeacherSpeakingExercise) {
    setEditingExercise(exercise);
    setForm(toForm(exercise, selectedClassId || classes[0]?.id || ""));
    setAudioName(exercise.reference_audio?.original_name ?? "");
    setAudioFile(null);
    setAudioError(null);
    setModalOpen(true);
  }

  function selectTemplate(templateId: string) {
    const template = templates.find((item) => item.id === templateId);

    if (!template) {
      setForm((current) => ({ ...current, template_exercise_id: "" }));
      return;
    }

    setForm((current) => ({
      ...current,
      template_exercise_id: template.id,
      title: template.title ?? "",
      target_text: template.target_text ?? "",
      target_translation: template.target_translation ?? "",
      prompt_text: template.prompt_text ?? "",
      difficulty: template.difficulty ?? "beginner",
      status: current.status || "draft",
    }));
  }

  function chooseAudio(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0] ?? null;
    setAudioFile(file);
    setAudioName(file?.name ?? editingExercise?.reference_audio?.original_name ?? "");
    setAudioError(null);
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token) return;
    setIsSubmitting(true);
    setAudioError(null);
    try {
      let payload = toPayload(form, true);
      if (audioFile) {
        setIsUploading(true);
        try {
          const media = await teacherService.uploadSpeakingReferenceAudio(token, audioFile);
          payload = { ...payload, reference_audio_media_id: media.id };
        } catch (err) {
          setAudioError(getFirstApiError(err));
          setError("Audio penutur asli gagal diunggah. Target belum disimpan.");
          return;
        } finally {
          setIsUploading(false);
        }
      }

      if (editingExercise) {
        await teacherService.updateSpeakingExercise(token, editingExercise.id, payload);
        setMessage("Target speaking berhasil diperbarui.");
      } else {
        await teacherService.createSpeakingExercise(token, payload);
        setMessage("Target speaking berhasil dibuat.");
      }
      setModalOpen(false);
      await reloadExercises({ classroom_id: selectedClassId || undefined, status: statusFilter || undefined });
    } catch (err) {
      setError(getFirstApiError(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function confirmPublishExercise() {
    if (!token || !publishTarget) return;
    setIsSubmitting(true);
    try {
      await teacherService.updateSpeakingExercise(token, publishTarget.id, {
        classroom_id: publishTarget.classroom_id ?? "",
        title: publishTarget.title,
        target_text: publishTarget.target_text,
        status: "published",
      });
      setMessage("Target speaking berhasil diterbitkan.");
      setPublishTarget(null);
      await reloadExercises({ classroom_id: selectedClassId || undefined, status: statusFilter || undefined });
    } catch (err) {
      setError(getFirstApiError(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function confirmArchiveExercise() {
    if (!token || !archiveTarget) return;
    setIsArchiving(true);
    try {
      await teacherService.archiveSpeakingExercise(token, archiveTarget.id);
      setMessage("Target speaking berhasil diarsipkan.");
      setArchiveTarget(null);
      await reloadExercises({ classroom_id: selectedClassId || undefined, status: statusFilter || undefined });
    } catch (err) {
      setError(getFirstApiError(err));
    } finally {
      setIsArchiving(false);
    }
  }

  async function confirmDeleteExercise() {
    if (!token || !deleteTarget) return;
    setIsDeleting(true);
    try {
      await teacherService.deleteSpeakingExercise(token, deleteTarget.id);
      setMessage("Target speaking berhasil dihapus.");
      setDeleteTarget(null);
      await reloadExercises({ classroom_id: selectedClassId || undefined, status: statusFilter || undefined });
    } catch (err) {
      setError(getFirstApiError(err));
    } finally {
      setIsDeleting(false);
    }
  }

  async function applyFilters(classroom_id: string, status: string) {
    setSelectedClassId(classroom_id);
    setStatusFilter(status);
    await reloadExercises({ classroom_id: classroom_id || undefined, status: status || undefined });
  }

  return (
    <div className="grid gap-8">
      <section className="flex flex-col gap-2">
        <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">Kelola Target Speaking</p>
        <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">Target bacaan per kelas</h1>
        <p className="max-w-3xl text-base font-semibold leading-6 text-muted">
          Guru mengelola target bacaan untuk kelas aktifnya sendiri. Target yang dipublikasikan akan muncul di latihan speaking siswa kelas Anda.
        </p>
      </section>

      {error ? <ErrorState description={error} onRetry={loadInitial} title="Gagal memuat target speaking" /> : null}
      {message ? <Alert tone="success">{message}</Alert> : null}

      <Card>
        <CardContent>
          <div className="grid gap-4 lg:grid-cols-[1fr_auto] lg:items-end">
            <div className="grid gap-3 md:grid-cols-2">
              <FormField label={onlyClass ? "Kelas Anda" : "Kelas yang Anda ajar"}>
                {onlyClass ? (
                  <div className="min-h-11 rounded-[var(--radius-control)] border-2 border-border bg-surface-muted px-3 py-2 text-sm font-black text-ink">
                    {onlyClass.name}
                  </div>
                ) : (
                  <Select onChange={(event) => void applyFilters(event.target.value, statusFilter)} value={selectedClassId}>
                    <option value="">Semua kelas</option>
                    {classes.map((item) => (
                      <option key={item.id} value={item.id}>{item.name}</option>
                    ))}
                  </Select>
                )}
              </FormField>
              <FormField label="Filter status">
                <Select onChange={(event) => void applyFilters(selectedClassId, event.target.value)} value={statusFilter}>
                  <option value="">Semua status</option>
                  <option value="draft">Draft</option>
                  <option value="published">Published</option>
                  <option value="archived">Archived</option>
                </Select>
              </FormField>
            </div>
            <Button disabled={hasNoClass} onClick={openCreate} type="button">
              <Plus className="mr-2 size-4" /> Tambah Target
            </Button>
          </div>
        </CardContent>
      </Card>

      {isLoading ? <LoadingState title="Memuat target speaking" /> : null}
      {hasNoClass ? (
        <EmptyState description="Anda belum memiliki kelas aktif. Hubungi admin agar dapat membuat target speaking." title="Belum ada kelas aktif" />
      ) : null}
      {!isLoading && !hasNoClass && exercises.length === 0 ? (
        <EmptyState description="Buat target speaking pertama untuk kelas Anda." title="Belum ada target speaking" />
      ) : null}

      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {exercises.map((exercise) => (
          <Card key={exercise.id} className="group flex h-full flex-col overflow-hidden transition hover:-translate-y-1 hover:shadow-emi">
            <CardContent className="flex flex-1 flex-col">
              <div className="flex items-start justify-between gap-3">
                <span className="flex size-12 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-ink transition-colors group-hover:bg-primary group-hover:text-primary-foreground">
                  <ListChecks className="size-5" strokeWidth={3} />
                </span>
                <Badge tone={statusTone(exercise.status)}>{statusLabel(exercise.status)}</Badge>
              </div>
              <h2 className="mt-4 text-xl font-black text-ink">{exercise.title}</h2>
              <p className="mt-2 text-sm font-bold text-muted">Kelas: {exercise.classroom?.name ?? classNameById.get(exercise.classroom_id ?? "") ?? "-"}</p>
              <div className="mt-4 rounded-xl border-2 border-transparent bg-surface-muted p-4">
                <p className="text-[10px] font-black uppercase tracking-widest text-muted">Target bacaan</p>
                <p className="mt-2 text-lg font-black text-ink">{exercise.target_text}</p>
                {exercise.target_translation ? <p className="mt-1 text-sm font-semibold text-muted">{exercise.target_translation}</p> : null}
              </div>
              {exercise.prompt_text ? <p className="mt-3 text-sm font-semibold leading-6 text-muted">{exercise.prompt_text}</p> : null}
              <div className="mt-auto flex flex-wrap gap-2 pt-5">
                {exercise.status !== "published" ? <Button onClick={() => setPublishTarget(exercise)} type="button" variant="secondary">
                  <Send className="mr-2 size-4" /> Terbitkan
                </Button> : null}
                <Button onClick={() => openEdit(exercise)} type="button" variant="secondary">
                  <Pencil className="mr-2 size-4" /> Edit
                </Button>
                {exercise.status !== "archived" ? (
                  <Button onClick={() => setArchiveTarget(exercise)} type="button" variant="ghost">
                    <Archive className="mr-2 size-4" /> Arsipkan
                  </Button>
                ) : null}
                <Button
                  disabled={speakingExerciseLifecycle(exercise) !== "delete"}
                  onClick={() => setDeleteTarget(exercise)}
                  title={speakingExerciseLifecycle(exercise) !== "delete" ? "Target yang sudah memiliki hasil siswa harus diarsipkan, tidak bisa dihapus." : undefined}
                  type="button"
                  variant="danger"
                >
                  <Trash2 className="mr-2 size-4" /> Hapus
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </section>

      <Modal className="max-w-2xl" onClose={() => setModalOpen(false)} open={modalOpen} title={editingExercise ? "Edit Target Speaking" : "Tambah Target Speaking"}>
        <form className="flex flex-col gap-4" onSubmit={submit}>
          <Alert tone="info">Target ini akan muncul untuk siswa di kelas {onlyClass ? "Anda" : "yang Anda ajar"} setelah dipublikasikan.</Alert>
          {onlyClass ? (
            <FormField label="Kelas Anda">
              <div className="min-h-11 rounded-[var(--radius-control)] border-2 border-border bg-surface-muted px-3 py-2 text-sm font-black text-ink">
                {onlyClass.name}
              </div>
            </FormField>
          ) : (
            <FormField label="Kelas yang Anda ajar">
              <Select onChange={(event) => setForm((current) => ({ ...current, classroom_id: event.target.value }))} required value={form.classroom_id}>
                <option value="">Pilih kelas</option>
                {classes.map((item) => (
                  <option key={item.id} value={item.id}>{item.name}</option>
                ))}
              </Select>
            </FormField>
          )}
          {!editingExercise ? (
            <section className="rounded-2xl border-2 border-border bg-surface-muted p-4">
              <FormField label="Gunakan Template Admin">
                <Select disabled={isTemplateLoading || Boolean(templateError)} onChange={(event) => selectTemplate(event.target.value)} value={form.template_exercise_id}>
                  <option value="">Buat manual tanpa template</option>
                  {templates.map((template) => (
                    <option key={template.id} value={template.id}>{template.title}</option>
                  ))}
                </Select>
              </FormField>
              {isTemplateLoading ? <p className="mt-2 text-sm font-bold text-muted">Memuat template admin...</p> : null}
              {!isTemplateLoading && !templateError && templates.length === 0 ? (
                <p className="mt-2 text-sm font-bold text-muted">Belum ada template admin yang dipublikasikan. Guru tetap bisa membuat target manual.</p>
              ) : null}
              {templateError ? <Alert tone="error">Template admin gagal dimuat: {templateError}</Alert> : null}
              {selectedTemplate ? (
                <div className="mt-3 rounded-xl border-2 border-border bg-surface p-3">
                  <p className="text-[10px] font-black uppercase tracking-widest text-muted">Preview template</p>
                  <p className="mt-1 text-sm font-black text-ink">{selectedTemplate.target_text}</p>
                  {selectedTemplate.target_translation ? <p className="mt-1 text-xs font-semibold text-muted">{selectedTemplate.target_translation}</p> : null}
                </div>
              ) : null}
            </section>
          ) : null}
          {previewAudio && !audioFile ? (
            <section className="rounded-2xl border-2 border-border bg-surface-muted p-4">
              <p className="text-sm font-black text-ink">Suara Asli tersedia dari {selectedTemplate ? "template admin" : "target speaking ini"}.</p>
              {previewAudio.url ? <div className="mt-3"><AudioPlayer src={previewAudio.url} title="Suara Asli" /></div> : null}
            </section>
          ) : null}
          <FormField label="Upload audio Suara Asli (opsional)">
            <Input accept="audio/*" disabled={isUploading || isSubmitting} onChange={chooseAudio} type="file" />
            <p className="mt-2 text-xs font-bold text-muted">Guru juga bisa mengunggah audio penutur sendiri sebagai contoh untuk siswa.</p>
            {audioName ? (
              <div className="mt-3 rounded-xl border-2 border-border bg-surface-muted p-3">
                <p className="text-sm font-black text-ink">{audioName}</p>
                <p className="mt-1 text-xs font-bold text-muted">Boleh unggah ulang untuk mengganti audio.</p>
              </div>
            ) : null}
            {audioError ? <p className="mt-2 text-sm font-black text-danger">{audioError}</p> : null}
            {isUploading ? <p className="mt-2 text-sm font-bold text-muted">Mengunggah audio...</p> : null}
          </FormField>
          <FormField label="Judul latihan">
            <Input onChange={(event) => setForm((current) => ({ ...current, title: event.target.value }))} required value={form.title} />
          </FormField>
          <FormField label="Target bacaan Mekongga">
            <Textarea className="min-h-24" onChange={(event) => setForm((current) => ({ ...current, target_text: event.target.value }))} required value={form.target_text} />
          </FormField>
          <FormField label="Terjemahan (opsional)">
            <Textarea className="min-h-20" onChange={(event) => setForm((current) => ({ ...current, target_translation: event.target.value }))} value={form.target_translation} />
          </FormField>
          <FormField label="Petunjuk untuk siswa (opsional)">
            <Textarea className="min-h-20" onChange={(event) => setForm((current) => ({ ...current, prompt_text: event.target.value }))} value={form.prompt_text} />
          </FormField>
          <div className="grid gap-3 sm:grid-cols-2">
            <FormField label="Tingkat kesulitan">
              <Select onChange={(event) => setForm((current) => ({ ...current, difficulty: event.target.value }))} value={form.difficulty}>
                <option value="beginner">Beginner</option>
                <option value="intermediate">Intermediate</option>
                <option value="advanced">Advanced</option>
              </Select>
            </FormField>
            <FormField label="Status">
              <Select onChange={(event) => setForm((current) => ({ ...current, status: event.target.value as FormState["status"] }))} value={form.status}>
                <option value="draft">Draft</option>
                <option value="published">Published</option>
              </Select>
            </FormField>
          </div>
          <div className="sticky bottom-0 mt-2 bg-surface pt-2">
            <Button className="w-full" disabled={isSubmitting || isUploading} type="submit">{isSubmitting ? "Menyimpan..." : editingExercise ? "Simpan Perubahan" : "Buat Target"}</Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        confirmLabel={isArchiving ? "Mengarsipkan..." : "Arsipkan Target"}
        confirmVariant="secondary"
        description={archiveTarget ? `Arsipkan target speaking "${archiveTarget.title}"? Target tidak akan tampil lagi untuk siswa.` : ""}
        isConfirming={isArchiving}
        onCancel={() => setArchiveTarget(null)}
        onConfirm={() => void confirmArchiveExercise()}
        open={Boolean(archiveTarget)}
        title="Arsipkan target speaking?"
      />

      <ConfirmDialog
        confirmLabel={isSubmitting ? "Menerbitkan..." : "Terbitkan Target"}
        description={publishTarget ? `Terbitkan target speaking "${publishTarget.title}"? Target akan terlihat oleh siswa.` : ""}
        isConfirming={isSubmitting}
        onCancel={() => setPublishTarget(null)}
        onConfirm={() => void confirmPublishExercise()}
        open={Boolean(publishTarget)}
        title="Terbitkan target speaking?"
      />

      <ConfirmDialog
        confirmLabel={isDeleting ? "Menghapus..." : "Hapus Target"}
        description={deleteTarget ? `Target speaking "${deleteTarget.title}" akan dihapus secara permanen.` : ""}
        isConfirming={isDeleting}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => void confirmDeleteExercise()}
        open={Boolean(deleteTarget)}
        title="Hapus target speaking?"
      />
    </div>
  );
}
