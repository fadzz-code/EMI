"use client";

import { type ChangeEvent, type FormEvent, useEffect, useState } from "react";
import { Archive, Headphones, Pencil, Plus } from "lucide-react";

import { Alert, Badge, Button, Card, CardContent, EmptyState, ErrorState, FormField, Input, LoadingState, Modal, Select, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { adminSpeakingService } from "./speaking-service";
import type { AdminSpeakingExercise, AdminSpeakingExercisePayload } from "./types";

type FormState = {
  title: string;
  target_text: string;
  target_translation: string;
  prompt_text: string;
  difficulty: string;
  status: "draft" | "published";
  reference_audio_media_id: string;
};

const defaultForm: FormState = {
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

function toForm(exercise: AdminSpeakingExercise): FormState {
  return {
    title: exercise.title ?? "",
    target_text: exercise.target_text ?? "",
    target_translation: exercise.target_translation ?? "",
    prompt_text: exercise.prompt_text ?? "",
    difficulty: exercise.difficulty ?? "beginner",
    status: exercise.status === "published" ? "published" : "draft",
    reference_audio_media_id: exercise.reference_audio_media_id ?? "",
  };
}

function toPayload(form: FormState): AdminSpeakingExercisePayload {
  return {
    title: form.title.trim(),
    target_text: form.target_text.trim(),
    target_translation: form.target_translation.trim() || null,
    prompt_text: form.prompt_text.trim() || null,
    difficulty: form.difficulty || null,
    status: form.status,
    reference_audio_media_id: form.reference_audio_media_id || null,
  };
}

export function AdminSpeakingExercises() {
  const { token } = useAuth();
  const [exercises, setExercises] = useState<AdminSpeakingExercise[]>([]);
  const [statusFilter, setStatusFilter] = useState("");
  const [editingExercise, setEditingExercise] = useState<AdminSpeakingExercise | null>(null);
  const [form, setForm] = useState<FormState>(defaultForm);
  const [audioName, setAudioName] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [modalOpen, setModalOpen] = useState(false);

  useEffect(() => {
    if (!token) return;
    let ignore = false;
    adminSpeakingService.exercises(token).then((result) => {
      if (ignore) return;
      setExercises(result.items);
      setError(null);
    }).catch((err) => {
      if (!ignore) setError(getFirstApiError(err));
    }).finally(() => {
      if (!ignore) setIsLoading(false);
    });

    return () => {
      ignore = true;
    };
  }, [token]);

  async function loadExercises(status = statusFilter) {
    if (!token) return;
    setIsLoading(true);
    try {
      const result = await adminSpeakingService.exercises(token, { status: status || undefined });
      setExercises(result.items);
      setError(null);
    } catch (err) {
      setError(getFirstApiError(err));
    } finally {
      setIsLoading(false);
    }
  }

  function openCreate() {
    setEditingExercise(null);
    setForm(defaultForm);
    setAudioName("");
    setModalOpen(true);
  }

  function openEdit(exercise: AdminSpeakingExercise) {
    setEditingExercise(exercise);
    setForm(toForm(exercise));
    setAudioName(exercise.reference_audio?.original_name ?? "");
    setModalOpen(true);
  }

  async function uploadAudio(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!token || !file) return;
    setIsUploading(true);
    try {
      const media = await adminSpeakingService.uploadReferenceAudio(token, file);
      setForm((current) => ({ ...current, reference_audio_media_id: media.id }));
      setAudioName(media.original_name ?? file.name);
      setMessage("Audio penutur asli berhasil diunggah.");
    } catch (err) {
      setError(getFirstApiError(err));
    } finally {
      setIsUploading(false);
    }
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token) return;
    setIsSubmitting(true);
    try {
      if (editingExercise) {
        await adminSpeakingService.updateExercise(token, editingExercise.id, toPayload(form));
        setMessage("Template speaking berhasil diperbarui.");
      } else {
        await adminSpeakingService.createExercise(token, toPayload(form));
        setMessage("Template speaking berhasil dibuat.");
      }
      setModalOpen(false);
      await loadExercises();
    } catch (err) {
      setError(getFirstApiError(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function archiveExercise(exercise: AdminSpeakingExercise) {
    if (!token) return;
    if (!window.confirm(`Arsipkan template speaking "${exercise.title}"?`)) return;
    try {
      await adminSpeakingService.archiveExercise(token, exercise.id);
      setMessage("Template speaking berhasil diarsipkan.");
      await loadExercises();
    } catch (err) {
      setError(getFirstApiError(err));
    }
  }

  async function applyStatus(status: string) {
    setStatusFilter(status);
    await loadExercises(status);
  }

  return (
    <div className="grid gap-6">
      <section className="flex flex-col gap-2">
        <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">Template Speaking</p>
        <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">Kelola Template Speaking</h1>
        <p className="max-w-3xl text-sm font-semibold leading-6 text-muted">
          Template global dapat dipakai sebagai acuan latihan speaking. Guru tetap dapat menyesuaikan target untuk kelasnya masing-masing.
        </p>
      </section>

      {error ? <ErrorState description={error} onRetry={() => void loadExercises()} title="Gagal memuat template speaking" /> : null}
      {message ? <Alert tone="success">{message}</Alert> : null}

      <Card>
        <CardContent>
          <div className="grid gap-4 lg:grid-cols-[1fr_auto] lg:items-end">
            <FormField label="Filter status">
              <Select onChange={(event) => void applyStatus(event.target.value)} value={statusFilter}>
                <option value="">Semua status</option>
                <option value="draft">Draft</option>
                <option value="published">Published</option>
                <option value="archived">Archived</option>
              </Select>
            </FormField>
            <Button onClick={openCreate} type="button">
              <Plus className="mr-2 size-4" /> Tambah Template
            </Button>
          </div>
        </CardContent>
      </Card>

      {isLoading ? <LoadingState title="Memuat template speaking" /> : null}
      {!isLoading && exercises.length === 0 ? (
        <EmptyState description="Buat template global pertama untuk latihan speaking." title="Belum ada template speaking" />
      ) : null}

      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {exercises.map((exercise) => (
          <Card key={exercise.id} className="overflow-hidden">
            <CardContent>
              <div className="flex items-start justify-between gap-3">
                <span className="flex size-11 items-center justify-center rounded-full border-2 border-border bg-accent text-accent-foreground shadow-[2px_2px_0_var(--border)]">
                  <Headphones className="size-5" strokeWidth={3} />
                </span>
                <Badge tone={statusTone(exercise.status)}>{statusLabel(exercise.status)}</Badge>
              </div>
              <h2 className="mt-4 text-xl font-black text-ink">{exercise.title}</h2>
              <div className="mt-4 rounded-xl border-2 border-transparent bg-surface-muted p-4">
                <p className="text-[10px] font-black uppercase tracking-widest text-muted">Target bacaan</p>
                <p className="mt-2 text-lg font-black text-ink">{exercise.target_text}</p>
                {exercise.target_translation ? <p className="mt-1 text-sm font-semibold text-muted">{exercise.target_translation}</p> : null}
              </div>
              {exercise.prompt_text ? <p className="mt-3 text-sm font-semibold leading-6 text-muted">{exercise.prompt_text}</p> : null}
              <div className="mt-4 rounded-xl border-2 border-border bg-surface p-3">
                <p className="text-xs font-black text-muted">Suara Asli</p>
                {exercise.reference_audio?.url ? (
                  <audio className="mt-2 w-full" controls src={exercise.reference_audio.url} />
                ) : exercise.reference_audio_media_id ? (
                  <p className="mt-1 text-sm font-bold text-ink">Audio tersedia</p>
                ) : (
                  <p className="mt-1 text-sm font-semibold text-muted">Belum ada audio</p>
                )}
              </div>
              <div className="mt-5 flex flex-wrap gap-2">
                <Button onClick={() => openEdit(exercise)} type="button" variant="secondary">
                  <Pencil className="mr-2 size-4" /> Edit
                </Button>
                {exercise.status !== "archived" ? (
                  <Button onClick={() => void archiveExercise(exercise)} type="button" variant="ghost">
                    <Archive className="mr-2 size-4" /> Arsipkan
                  </Button>
                ) : null}
              </div>
            </CardContent>
          </Card>
        ))}
      </section>

      <Modal className="max-w-2xl" onClose={() => setModalOpen(false)} open={modalOpen} title={editingExercise ? "Edit Template Speaking" : "Tambah Template Speaking"}>
        <form className="flex min-h-0 flex-col gap-4" onSubmit={submit}>
          <Alert tone="info">Audio ini akan digunakan sebagai contoh Suara Asli untuk siswa.</Alert>
          <FormField label="Judul latihan">
            <Input onChange={(event) => setForm((current) => ({ ...current, title: event.target.value }))} required value={form.title} />
          </FormField>
          <FormField label="Target bacaan Mekongga">
            <Textarea className="min-h-24" onChange={(event) => setForm((current) => ({ ...current, target_text: event.target.value }))} required value={form.target_text} />
          </FormField>
          <FormField label="Terjemahan opsional">
            <Textarea className="min-h-20" onChange={(event) => setForm((current) => ({ ...current, target_translation: event.target.value }))} value={form.target_translation} />
          </FormField>
          <FormField label="Petunjuk untuk siswa opsional">
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
          <FormField label="Upload audio penutur asli">
            <Input accept="audio/*" disabled={isUploading} onChange={(event) => void uploadAudio(event)} type="file" />
            {audioName || editingExercise?.reference_audio?.url ? (
              <div className="mt-3 rounded-xl border-2 border-border bg-surface-muted p-3">
                <p className="text-sm font-black text-ink">{audioName || "Audio lama"}</p>
                {editingExercise?.reference_audio?.url && !audioName ? <audio className="mt-2 w-full" controls src={editingExercise.reference_audio.url} /> : null}
                <p className="mt-1 text-xs font-bold text-muted">Boleh unggah ulang untuk mengganti audio.</p>
              </div>
            ) : null}
            {isUploading ? <p className="mt-2 text-sm font-bold text-muted">Mengunggah audio...</p> : null}
          </FormField>
          <div className="sticky bottom-0 mt-2 flex gap-2 border-t-2 border-border bg-surface pt-3">
            <Button className="flex-1" disabled={isSubmitting || isUploading} type="submit">{isSubmitting ? "Menyimpan..." : editingExercise ? "Simpan Perubahan" : "Buat Template"}</Button>
            <Button disabled={isSubmitting} onClick={() => setModalOpen(false)} type="button" variant="ghost">Batal</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
