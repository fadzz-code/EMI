"use client";

import { type ChangeEvent, type FormEvent, useEffect, useState } from "react";
import { Headphones, Pencil, Plus, Trash2, Users } from "lucide-react";

import { Alert, Badge, Button, Card, CardContent, EmptyState, ErrorState, FormField, Input, LoadingState, Modal, Select, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { classService } from "@/features/admin/management/management-service";
import type { SchoolClass } from "@/features/admin/management/types";
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

function statusTone(status?: string | null): "neutral" | "blue" | "orange" {
  if (status === "published") return "blue";
  if (status === "archived") return "orange";
  return "neutral";
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
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [modalError, setModalError] = useState<string | null>(null);
  const [audioError, setAudioError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [applyTarget, setApplyTarget] = useState<AdminSpeakingExercise | null>(null);
  const [classes, setClasses] = useState<SchoolClass[]>([]);
  const [applyClassIds, setApplyClassIds] = useState<string[]>([]);
  const [applySync, setApplySync] = useState(false);
  const [applyLoading, setApplyLoading] = useState(false);
  const [applySubmitting, setApplySubmitting] = useState(false);
  const [applyError, setApplyError] = useState<string | null>(null);

  useEffect(() => {
    if (!token) return;
    let ignore = false;
    adminSpeakingService.exercises(token).then((result) => {
      if (ignore) return;
      setExercises(result.items.filter((item) => item.status !== "archived"));
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
      setExercises(status ? result.items : result.items.filter((item) => item.status !== "archived"));
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
    setAudioFile(null);
    setModalError(null);
    setAudioError(null);
    setModalOpen(true);
  }

  function openEdit(exercise: AdminSpeakingExercise) {
    setEditingExercise(exercise);
    setForm(toForm(exercise));
    setAudioName(exercise.reference_audio?.original_name ?? "");
    setAudioFile(null);
    setModalError(null);
    setAudioError(null);
    setModalOpen(true);
  }

  function chooseAudio(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0] ?? null;
    setAudioFile(file);
    setAudioName(file?.name ?? editingExercise?.reference_audio?.original_name ?? "");
    setAudioError(null);
    setModalError(null);
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token) return;
    setIsSubmitting(true);
    setModalError(null);
    setAudioError(null);
    try {
      let payload = toPayload(form);
      if (audioFile) {
        setIsUploading(true);
        try {
          const media = await adminSpeakingService.uploadReferenceAudio(token, audioFile);
          payload = { ...payload, reference_audio_media_id: media.id };
        } catch (err) {
          const message = getFirstApiError(err);
          setAudioError(message);
          setModalError("Audio penutur asli gagal diunggah. Template belum disimpan.");
          return;
        } finally {
          setIsUploading(false);
        }
      }

      if (editingExercise) {
        await adminSpeakingService.updateExercise(token, editingExercise.id, payload);
        setMessage("Template speaking berhasil diperbarui.");
      } else {
        await adminSpeakingService.createExercise(token, payload);
        setMessage("Template speaking berhasil dibuat.");
      }
      setModalOpen(false);
      await loadExercises();
    } catch (err) {
      setModalError(getFirstApiError(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function archiveExercise(exercise: AdminSpeakingExercise) {
    if (!token) return;
    if (!window.confirm("Hapus template ini dari daftar? Data akan diarsipkan dan tidak tampil untuk siswa.")) return;
    try {
      await adminSpeakingService.archiveExercise(token, exercise.id);
      setMessage("Template speaking berhasil dihapus dari daftar.");
      await loadExercises();
    } catch (err) {
      setError(getFirstApiError(err));
    }
  }

  async function applyStatus(status: string) {
    setStatusFilter(status);
    await loadExercises(status);
  }

  async function openApply(exercise: AdminSpeakingExercise) {
    if (!token) return;
    setApplyTarget(exercise);
    setApplyClassIds([]);
    setApplySync(false);
    setApplyError(null);
    setApplyLoading(true);
    try {
      const result = await classService.list(token, { per_page: 100, status: "active" });
      setClasses(result.items);
    } catch (err) {
      setApplyError(getFirstApiError(err));
      setClasses([]);
    } finally {
      setApplyLoading(false);
    }
  }

  function toggleClass(classId: string) {
    setApplyClassIds((current) =>
      current.includes(classId) ? current.filter((id) => id !== classId) : [...current, classId],
    );
  }

  async function submitApply(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token || !applyTarget) return;
    if (applyClassIds.length === 0) {
      setApplyError("Pilih minimal satu kelas.");
      return;
    }
    setApplySubmitting(true);
    setApplyError(null);
    try {
      const result = await adminSpeakingService.applyTemplate(token, applyTarget.id, applyClassIds, applySync);
      const appliedCount = (result?.applied ?? []).length + (result?.synced ?? []).length;
      const skippedCount = (result?.skipped ?? []).length;
      setMessage(`Template berhasil diterapkan ke ${appliedCount} kelas${skippedCount > 0 ? ` (${skippedCount} dilewati)` : ""}.`);
      setApplyTarget(null);
    } catch (err) {
      setApplyError(getFirstApiError(err));
    } finally {
      setApplySubmitting(false);
    }
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

      {error && !modalOpen ? <ErrorState description={error} onRetry={() => void loadExercises()} title="Gagal memuat template speaking" /> : null}
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

      <section className="grid auto-rows-fr gap-4 md:grid-cols-2 xl:grid-cols-3">
        {exercises.map((exercise) => (
          <Card key={exercise.id} className="flex h-full overflow-hidden transition-transform hover:-translate-y-1 hover:shadow-emi">
            <CardContent className="flex w-full flex-col">
              <div className="flex items-start justify-between gap-3">
                <span className="flex size-11 items-center justify-center rounded-full border-2 border-border bg-[var(--color-primary-muted)] text-ink shadow-[2px_2px_0_var(--border)]">
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
              <div className="mt-auto flex flex-wrap gap-2 pt-5">
                <Button onClick={() => openEdit(exercise)} type="button" variant="secondary">
                  <Pencil className="mr-2 size-4" /> Edit
                </Button>
                {exercise.status === "published" ? (
                  <Button onClick={() => void openApply(exercise)} type="button" variant="secondary">
                    <Users className="mr-2 size-4" /> Terapkan
                  </Button>
                ) : null}
                {exercise.status !== "archived" ? (
                  <Button onClick={() => void archiveExercise(exercise)} type="button" variant="ghost">
                    <Trash2 className="mr-2 size-4" /> Hapus
                  </Button>
                ) : null}
              </div>
            </CardContent>
          </Card>
        ))}
      </section>

      <Modal className="max-w-2xl" onClose={() => setModalOpen(false)} open={modalOpen} title={editingExercise ? "Edit Template Speaking" : "Tambah Template Speaking"}>
        <form className="flex min-h-0 flex-col gap-4" onSubmit={submit}>
          {modalError ? <Alert tone="error">{modalError}</Alert> : null}
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
            <Input accept="audio/*" disabled={isUploading || isSubmitting} onChange={chooseAudio} type="file" />
            {audioName || editingExercise?.reference_audio?.url ? (
              <div className="mt-3 rounded-xl border-2 border-border bg-surface-muted p-3">
                <p className="text-sm font-black text-ink">{audioName || "Audio lama"}</p>
                {editingExercise?.reference_audio?.url && !audioName ? <audio className="mt-2 w-full" controls src={editingExercise.reference_audio.url} /> : null}
                <p className="mt-1 text-xs font-bold text-muted">Boleh unggah ulang untuk mengganti audio.</p>
              </div>
            ) : null}
            {audioError ? <p className="mt-2 text-sm font-black text-danger">{audioError}</p> : null}
            {isUploading ? <p className="mt-2 text-sm font-bold text-muted">Mengunggah audio...</p> : null}
          </FormField>
          <div className="sticky bottom-0 mt-2 flex gap-2 border-t-2 border-border bg-surface pt-3">
            <Button className="flex-1" disabled={isSubmitting || isUploading} type="submit">{isSubmitting ? "Menyimpan..." : editingExercise ? "Simpan Perubahan" : "Buat Template"}</Button>
            <Button disabled={isSubmitting} onClick={() => setModalOpen(false)} type="button" variant="ghost">Batal</Button>
          </div>
        </form>
      </Modal>

      <Modal className="max-w-xl" onClose={() => setApplyTarget(null)} open={Boolean(applyTarget)} title={applyTarget ? `Terapkan "${applyTarget.title}" ke Kelas` : "Terapkan ke Kelas"}>
        <form className="flex min-h-0 flex-col gap-4" onSubmit={submitApply}>
          {applyError ? <Alert tone="error">{applyError}</Alert> : null}
          <Alert tone="info">Target kelas akan dibuat sebagai draft. Guru kelas dapat mengedit sebelum dipublikasikan ke siswa.</Alert>
          {applyLoading ? <LoadingState title="Memuat daftar kelas" /> : null}
          {!applyLoading && classes.length === 0 ? <EmptyState description="Tidak ada kelas aktif yang dapat menerima template." title="Kelas aktif kosong" /> : null}
          {!applyLoading && classes.length > 0 ? (
            <div className="flex max-h-80 flex-col gap-2 overflow-auto rounded-xl border-2 border-border bg-surface-muted p-3">
              {classes.map((schoolClass) => (
                <label className="flex cursor-pointer items-center gap-3 rounded-lg bg-surface p-3" key={schoolClass.id}>
                  <input checked={applyClassIds.includes(schoolClass.id)} onChange={() => toggleClass(schoolClass.id)} type="checkbox" />
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-black text-ink">{schoolClass.name}</p>
                    <p className="text-xs font-semibold text-muted">{schoolClass.school?.name ?? ""} · {schoolClass.academic_year}</p>
                  </div>
                </label>
              ))}
            </div>
          ) : null}
          <label className="flex cursor-pointer items-center gap-2 text-sm font-semibold text-ink">
            <input checked={applySync} onChange={(event) => setApplySync(event.target.checked)} type="checkbox" />
            Sync ulang kelas yang sudah pernah diterapkan
          </label>
          <div className="sticky bottom-0 mt-2 flex gap-2 border-t-2 border-border bg-surface pt-3">
            <Button className="flex-1" disabled={applySubmitting || applyClassIds.length === 0} type="submit">{applySubmitting ? "Menerapkan..." : "Terapkan Template"}</Button>
            <Button disabled={applySubmitting} onClick={() => setApplyTarget(null)} type="button" variant="ghost">Batal</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
