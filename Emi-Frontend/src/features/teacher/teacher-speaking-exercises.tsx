"use client";

import { type FormEvent, useEffect, useMemo, useState } from "react";
import { ListChecks, Pencil, Plus, Archive } from "lucide-react";

import { Alert, Badge, Button, Card, CardContent, EmptyState, ErrorState, FormField, Input, LoadingState, Modal, Select, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { teacherService } from "./teacher-service";
import type { TeacherClass, TeacherSpeakingExercise, TeacherSpeakingExercisePayload } from "./types";

type FormState = {
  classroom_id: string;
  title: string;
  target_text: string;
  target_translation: string;
  prompt_text: string;
  difficulty: string;
  status: "draft" | "published";
};

const defaultForm: FormState = {
  classroom_id: "",
  title: "",
  target_text: "",
  target_translation: "",
  prompt_text: "",
  difficulty: "beginner",
  status: "draft",
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
    classroom_id: exercise.classroom_id ?? fallbackClassId,
    title: exercise.title ?? "",
    target_text: exercise.target_text ?? "",
    target_translation: exercise.target_translation ?? "",
    prompt_text: exercise.prompt_text ?? "",
    difficulty: exercise.difficulty ?? "beginner",
    status: exercise.status === "published" ? "published" : "draft",
  };
}

function toPayload(form: FormState): TeacherSpeakingExercisePayload {
  return {
    classroom_id: form.classroom_id,
    title: form.title.trim(),
    target_text: form.target_text.trim(),
    target_translation: form.target_translation.trim() || null,
    prompt_text: form.prompt_text.trim() || null,
    difficulty: form.difficulty || null,
    language_code: "mekongga",
    status: form.status,
  };
}

export function TeacherSpeakingExercises() {
  const { token } = useAuth();
  const [classes, setClasses] = useState<TeacherClass[]>([]);
  const [exercises, setExercises] = useState<TeacherSpeakingExercise[]>([]);
  const [selectedClassId, setSelectedClassId] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [editingExercise, setEditingExercise] = useState<TeacherSpeakingExercise | null>(null);
  const [form, setForm] = useState<FormState>(defaultForm);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [modalOpen, setModalOpen] = useState(false);

  const classNameById = useMemo(() => new Map(classes.map((item) => [item.id, item.name])), [classes]);
  const onlyClass = classes.length === 1 ? classes[0] : null;
  const hasNoClass = !isLoading && classes.length === 0;

  useEffect(() => {
    if (!token) return;
    let ignore = false;
    Promise.all([
      teacherService.classes(token),
      teacherService.speakingExercises(token),
    ]).then(([classResult, exerciseResult]) => {
      if (ignore) return;
      const classItems = classResult.items;
      setClasses(classItems);
      setExercises(exerciseResult.items);
      setSelectedClassId((current) => current || classItems[0]?.id || "");
      setForm((current) => ({ ...current, classroom_id: current.classroom_id || classItems[0]?.id || "" }));
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

  async function loadInitial() {
    if (!token) return;
    setIsLoading(true);
    try {
      const [classResult, exerciseResult] = await Promise.all([
        teacherService.classes(token),
        teacherService.speakingExercises(token),
      ]);
      const classItems = classResult.items;
      setClasses(classItems);
      setExercises(exerciseResult.items);
      setSelectedClassId((current) => current || classItems[0]?.id || "");
      setForm((current) => ({ ...current, classroom_id: current.classroom_id || classItems[0]?.id || "" }));
      setError(null);
    } catch (err) {
      setError(getFirstApiError(err));
    } finally {
      setIsLoading(false);
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
    setModalOpen(true);
  }

  function openEdit(exercise: TeacherSpeakingExercise) {
    setEditingExercise(exercise);
    setForm(toForm(exercise, selectedClassId || classes[0]?.id || ""));
    setModalOpen(true);
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token) return;
    setIsSubmitting(true);
    try {
      if (editingExercise) {
        await teacherService.updateSpeakingExercise(token, editingExercise.id, toPayload(form));
        setMessage("Target speaking berhasil diperbarui.");
      } else {
        await teacherService.createSpeakingExercise(token, toPayload(form));
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

  async function archiveExercise(exercise: TeacherSpeakingExercise) {
    if (!token) return;
    if (!window.confirm(`Arsipkan target speaking "${exercise.title}"?`)) return;
    try {
      await teacherService.archiveSpeakingExercise(token, exercise.id);
      setMessage("Target speaking berhasil diarsipkan.");
      await reloadExercises({ classroom_id: selectedClassId || undefined, status: statusFilter || undefined });
    } catch (err) {
      setError(getFirstApiError(err));
    }
  }

  async function applyFilters(classroom_id: string, status: string) {
    setSelectedClassId(classroom_id);
    setStatusFilter(status);
    await reloadExercises({ classroom_id: classroom_id || undefined, status: status || undefined });
  }

  return (
    <div className="grid gap-6">
      <section className="flex flex-col gap-2">
        <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">Kelola Target Speaking</p>
        <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">Target bacaan per kelas</h1>
        <p className="max-w-3xl text-sm font-semibold leading-6 text-muted">
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
          <Card key={exercise.id} className="overflow-hidden">
            <CardContent>
              <div className="flex items-start justify-between gap-3">
                <span className="flex size-11 items-center justify-center rounded-full border-2 border-border bg-accent text-accent-foreground shadow-[2px_2px_0_var(--border)]">
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
            <Button className="w-full" disabled={isSubmitting} type="submit">{isSubmitting ? "Menyimpan..." : editingExercise ? "Simpan Perubahan" : "Buat Target"}</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
