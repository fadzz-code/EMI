"use client";

import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Paperclip } from "lucide-react";
import {
  type ChangeEvent,
  type FormEvent,
  useEffect,
  useRef,
  useState,
} from "react";

import {
  Badge,
  MutationAlert,
  Button,
  Card,
  CardContent,
  CardHeader,
  ErrorState,
  FormField,
  Input,
  LoadingState,
  PageHeader,
  Select,
  Textarea,
  UploadComponent,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { teacherRoutes } from "@/lib/routes";

import {
  acceptForLesson,
  attachmentAfterReplacement,
  friendlyLessonError,
  INVALID_LESSON_MEDIA_MESSAGE,
  isValidLessonMedia,
  lessonPayload,
  mediaPurposeForLesson,
  validateLessonForm,
} from "./teacher-lesson-workflow";
import { teacherService } from "./teacher-service";
import { statusLabel, teacherStatusTone } from "./teacher-utils";
import type {
  TeacherClassLesson,
  TeacherLessonContentType,
  TeacherLessonForm,
} from "./types";

const labels: Record<TeacherLessonContentType, string> = {
  text: "Teks",
  image: "Gambar",
  audio: "Audio",
  pdf: "PDF",
  video: "Video",
  link: "Link",
};

function lessonForm(lesson: TeacherClassLesson): TeacherLessonForm {
  return {
    title: lesson.title,
    description: lesson.description ?? "",
    content_type: lesson.content_type,
    content_body: lesson.content_body ?? "",
    media_id: lesson.media?.id ?? "",
    external_url: lesson.external_url ?? "",
    sort_order: String(lesson.sort_order ?? 1),
  };
}

export function TeacherLessonEdit({
  moduleId,
  lessonId,
}: {
  moduleId: string;
  lessonId: string;
}) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [form, setForm] = useState<TeacherLessonForm | null>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [localError, setLocalError] = useState<string | null>(null);
  const initializedLesson = useRef<string | null>(null);
  const [localAttempt, setLocalAttempt] = useState(0);

  const lessonQuery = useQuery({
    queryKey: ["teacher", "class-lessons", lessonId],
    queryFn: () => teacherService.classLessonDetail(token ?? "", lessonId),
    enabled: Boolean(token && lessonId),
  });
  useEffect(() => {
    if (lessonQuery.data && initializedLesson.current !== lessonQuery.data.id) {
      initializedLesson.current = lessonQuery.data.id;
      setForm(lessonForm(lessonQuery.data));
    }
  }, [lessonQuery.data]);

  const saveMutation = useMutation({
    mutationFn: async (current: TeacherLessonForm) => {
      const oldMediaId = lessonQuery.data?.media?.id ?? null;
      let stagedMediaId = current.media_id;
      if (selectedFile) {
        const purpose = mediaPurposeForLesson(current.content_type);
        if (!purpose) throw new Error(INVALID_LESSON_MEDIA_MESSAGE);
        const media = await teacherService.uploadMedia(
          token ?? "",
          selectedFile,
          purpose,
          "private",
        );
        stagedMediaId = media.id;
      }
      try {
        const updated = await teacherService.updateClassLesson(
          token ?? "",
          lessonId,
          lessonPayload({ ...current, media_id: stagedMediaId }),
        );
        return {
          updated,
          mediaId: attachmentAfterReplacement(oldMediaId, stagedMediaId, true),
        };
      } catch (error) {
        setForm((value) =>
          value
            ? {
                ...value,
                media_id: attachmentAfterReplacement(
                  oldMediaId,
                  stagedMediaId,
                  false,
                ),
              }
            : value,
        );
        throw error;
      }
    },
    onSuccess: ({ updated, mediaId }) => {
      setForm({ ...lessonForm(updated), media_id: mediaId });
      setSelectedFile(null);
      setMessage("Materi berhasil disimpan.");
      void queryClient.invalidateQueries({
        queryKey: ["teacher", "class-lessons", lessonId],
      });
      void queryClient.invalidateQueries({
        queryKey: ["teacher", "class-modules", moduleId],
      });
    },
  });
  const publishMutation = useMutation({
    mutationFn: () => teacherService.publishClassLesson(token ?? "", lessonId),
    onSuccess: () => {
      setMessage("Materi berhasil dipublikasikan.");
      void queryClient.invalidateQueries({
        queryKey: ["teacher", "class-lessons", lessonId],
      });
    },
  });
  const busy = saveMutation.isPending || publishMutation.isPending;

  function changeType(type: TeacherLessonContentType) {
    setSelectedFile(null);
    setLocalError(null);
    setMessage(null);
    setForm((current) =>
      current
        ? {
            ...current,
            content_type: type,
            content_body: type === "text" ? current.content_body : "",
            external_url:
              type === "video" || type === "link" ? current.external_url : "",
            media_id:
              type === current.content_type && mediaPurposeForLesson(type)
                ? current.media_id
                : "",
          }
        : current,
    );
  }

  function chooseFile(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0] ?? null;
    setMessage(null);
    setLocalError(null);
    if (file && form && !isValidLessonMedia(form.content_type, file)) {
      setSelectedFile(null);
      setLocalError(INVALID_LESSON_MEDIA_MESSAGE);
      event.target.value = "";
      return;
    }
    setSelectedFile(file);
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLocalAttempt((attempt) => attempt + 1);
    if (!form) return;
    const validationError = validateLessonForm({
      ...form,
      media_id: selectedFile ? "staged" : form.media_id,
    });
    setMessage(null);
    setLocalError(validationError);
    if (!validationError) saveMutation.mutate(form);
  }

  return (
    <div className="grid gap-8">
      <Link
        className="inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-primary transition hover:-translate-y-0.5 hover:bg-[var(--color-primary-muted)] hover:shadow-emi"
        href={teacherRoutes.moduleEdit(moduleId)}
      >
        <ArrowLeft className="size-5" strokeWidth={2.5} /> Kembali ke Modul
      </Link>
      <PageHeader
        badge="Guru"
        description="Ubah konten materi kelas Anda."
        title="Edit Materi (Lesson)"
      />
      {lessonQuery.isLoading ? (
        <LoadingState title="Memuat detail materi" />
      ) : null}
      {lessonQuery.isError ? (
        <ErrorState
          description={friendlyLessonError(lessonQuery.error)}
          onRetry={() => void lessonQuery.refetch()}
          title="Gagal memuat materi"
        />
      ) : null}
      {form && lessonQuery.data ? (
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <h2 className="text-xl font-black text-primary">
                Form Edit Materi
              </h2>
              <Badge tone={teacherStatusTone(lessonQuery.data.status)}>
                {statusLabel(lessonQuery.data.status)}
              </Badge>
            </div>
          </CardHeader>
          <CardContent>
            <form className="grid gap-4" onSubmit={submit}>
              <MutationAlert eventKey={Math.max(saveMutation.submittedAt, publishMutation.submittedAt)} tone="success" visible={Boolean(message)}>{message}</MutationAlert>
              <MutationAlert eventKey={localAttempt} tone="error" visible={Boolean(localError)}>{localError}</MutationAlert>
              <MutationAlert eventKey={saveMutation.submittedAt} tone="error" visible={Boolean(saveMutation.error)}>{friendlyLessonError(saveMutation.error)}</MutationAlert>
              <FormField label="Judul Materi">
                <Input
                  disabled={busy}
                  onChange={(event) =>
                    setForm({ ...form, title: event.target.value })
                  }
                  required
                  value={form.title}
                />
              </FormField>
              <FormField label="Deskripsi Singkat">
                <Textarea
                  disabled={busy}
                  onChange={(event) =>
                    setForm({ ...form, description: event.target.value })
                  }
                  rows={2}
                  value={form.description}
                />
              </FormField>
              <div className="grid gap-4 sm:grid-cols-[1fr_160px]">
                <FormField label="Jenis Materi">
                  <Select
                    disabled={busy}
                    onChange={(event) =>
                      changeType(event.target.value as TeacherLessonContentType)
                    }
                    value={form.content_type}
                  >
                    {Object.entries(labels).map(([value, label]) => (
                      <option key={value} value={value}>
                        {label}
                      </option>
                    ))}
                  </Select>
                </FormField>
                <FormField label="Urutan Tampil">
                  <Input
                    disabled={busy}
                    min={1}
                    onChange={(event) =>
                      setForm({ ...form, sort_order: event.target.value })
                    }
                    required
                    type="number"
                    value={form.sort_order}
                  />
                </FormField>
              </div>
              {form.content_type === "text" ? (
                <FormField label="Isi Materi (Teks)">
                  <Textarea
                    disabled={busy}
                    onChange={(event) =>
                      setForm({ ...form, content_body: event.target.value })
                    }
                    required
                    rows={8}
                    value={form.content_body}
                  />
                </FormField>
              ) : null}
              {form.content_type === "video" || form.content_type === "link" ? (
                <FormField label="URL HTTPS">
                  <Input
                    disabled={busy}
                    onChange={(event) =>
                      setForm({ ...form, external_url: event.target.value })
                    }
                    placeholder="https://..."
                    required
                    type="url"
                    value={form.external_url}
                  />
                </FormField>
              ) : null}
              {mediaPurposeForLesson(form.content_type) ? (
                <div className="grid gap-4 rounded-2xl border-2 border-border bg-surface-muted p-4 sm:p-6">
                  <div className="flex items-center gap-3">
                    <span className="inline-flex size-11 shrink-0 items-center justify-center rounded-xl border-2 border-border bg-surface text-primary">
                      <Paperclip className="size-5" strokeWidth={2.5} />
                    </span>
                    <p className="font-black text-primary">
                      Lampiran {labels[form.content_type]}
                    </p>
                  </div>
                  {selectedFile ? (
                    <div className="text-sm text-muted">
                      <p>File baru: {selectedFile.name}</p>
                      <p>Tipe: {selectedFile.type || "Tidak diketahui"}</p>
                      <p>
                        File baru menggantikan lampiran hanya setelah materi
                        berhasil disimpan.
                      </p>
                    </div>
                  ) : form.media_id ? (
                    <div className="text-sm text-muted">
                      <p>Lampiran saat ini tersedia.</p>
                      <p>
                        Tipe:{" "}
                        {lessonQuery.data.media?.mime_type ??
                          labels[form.content_type]}
                      </p>
                    </div>
                  ) : (
                    <p className="text-sm text-muted">
                      Belum ada lampiran. File wajib dipilih sebelum menyimpan.
                    </p>
                  )}
                  <UploadComponent
                    accept={acceptForLesson(form.content_type)}
                    disabled={busy}
                    onChange={chooseFile}
                  />
                </div>
              ) : null}
              <div className="flex flex-col gap-3 sm:flex-row">
                <Button disabled={busy} type="submit">
                  {saveMutation.isPending
                    ? selectedFile
                      ? "Mengunggah dan menyimpan..."
                      : "Menyimpan..."
                    : "Simpan Perubahan"}
                </Button>
                {lessonQuery.data.status !== "published" ? (
                  <Button
                    disabled={busy}
                    onClick={() => {
                      if (
                        confirm(
                          "Apakah Anda yakin ingin menerbitkan materi ini?",
                        )
                      ) {
                        setMessage(null);
                        publishMutation.mutate();
                      }
                    }}
                    type="button"
                    variant="secondary"
                  >
                    {publishMutation.isPending
                      ? "Menerbitkan..."
                      : "Terbitkan Materi"}
                  </Button>
                ) : null}
              </div>
              <MutationAlert eventKey={publishMutation.submittedAt} tone="error" visible={Boolean(publishMutation.error)}>{friendlyLessonError(publishMutation.error)}</MutationAlert>
            </form>
          </CardContent>
        </Card>
      ) : null}
    </div>
  );
}
