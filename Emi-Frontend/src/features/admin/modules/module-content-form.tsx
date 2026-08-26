"use client";

import { type ChangeEvent, type FormEvent, useMemo, useRef, useState } from "react";

import {
  Alert,
  Button,
  MutationAlert,
  FilePreview,
  FormField,
  Input,
  Select,
  Textarea,
  UploadComponent,
} from "@/components/ui";
import { getFirstApiError } from "@/lib/api-client";

import { lessonTemplateService } from "./module-service";
import {
  acceptForContentType,
  contentTypeLabel,
  mediaPurposeForContentType,
  normalizeNullable,
} from "./module-utils";
import {
  INVALID_MEDIA_TYPE_MESSAGE,
  isValidMediaFile,
  mediaUploadSuccessMessage,
  PUBLIC_MEDIA_VISIBILITY,
} from "./module-workflow";
import type {
  LessonContentType,
  LessonTemplate,
  LessonTemplatePayload,
  ModuleTemplateStatus,
} from "./types";

type LessonFormState = {
  title: string;
  description: string;
  content_type: LessonContentType;
  content_body: string;
  media_id: string;
  external_url: string;
  sort_order: string;
  status: ModuleTemplateStatus;
};

function toForm(lesson?: LessonTemplate | null): LessonFormState {
  return {
    title: lesson?.title ?? "",
    description: lesson?.description ?? "",
    content_type: lesson?.content_type ?? "text",
    content_body: lesson?.content_body ?? "",
    media_id: lesson?.media?.id ?? "",
    external_url: lesson?.external_url ?? "",
    sort_order: lesson?.sort_order ? String(lesson.sort_order) : "",
    status: lesson?.status ?? "draft",
  };
}

function toPayload(form: LessonFormState): LessonTemplatePayload {
  const sortOrder = Number.parseInt(form.sort_order, 10);
  const payload: LessonTemplatePayload = {
    title: form.title.trim(),
    description: normalizeNullable(form.description),
    content_type: form.content_type,
    sort_order: Number.isNaN(sortOrder) ? undefined : sortOrder,
    status: form.status,
  };

  if (form.content_type === "text") {
    return {
      ...payload,
      content_body: form.content_body.trim(),
      media_id: null,
      external_url: null,
    };
  }

  if (form.content_type === "video" || form.content_type === "link") {
    return {
      ...payload,
      content_body: null,
      media_id: null,
      external_url: form.external_url.trim(),
    };
  }

  return {
    ...payload,
    content_body: null,
    media_id: form.media_id.trim(),
    external_url: null,
  };
}

export function ModuleContentForm({
  isSubmitting,
  lesson,
  onCancel,
  onSubmit,
  token,
}: {
  isSubmitting: boolean;
  lesson?: LessonTemplate | null;
  onCancel: () => void;
  onSubmit: (payload: LessonTemplatePayload) => void;
  token: string;
}) {
  const [form, setForm] = useState<LessonFormState>(() => toForm(lesson));
  const [mediaFile, setMediaFile] = useState<File | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [uploadSuccess, setUploadSuccess] = useState<string | null>(null);
  const [uploadCounter, setUploadCounter] = useState(0);
  const uploadSequence = useRef(0);

  const mediaPurpose = useMemo(
    () => mediaPurposeForContentType(form.content_type),
    [form.content_type],
  );

  async function handleMediaChange(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0] ?? null;
    const contentType = form.content_type;
    const sequence = uploadSequence.current + 1;
    uploadSequence.current = sequence;
    setUploadCounter((current) => current + 1);
    setMediaFile(file);
    setForm((current) => ({ ...current, media_id: "" }));
    setUploadError(null);
    setUploadSuccess(null);

    if (!file) {
      setIsUploading(false);
      return;
    }

    if (!isValidMediaFile(contentType, file)) {
      setMediaFile(null);
      setUploadError(INVALID_MEDIA_TYPE_MESSAGE);
      setIsUploading(false);
      event.target.value = "";
      return;
    }

    setIsUploading(true);

    try {
      const media = await lessonTemplateService.uploadMedia(
        token,
        contentType,
        file,
        PUBLIC_MEDIA_VISIBILITY,
      );

      if (sequence !== uploadSequence.current) {
        return;
      }

      if (!media.id) {
        throw new Error("Response upload media tidak valid.");
      }

      setForm((current) => ({ ...current, media_id: media.id }));
      setUploadSuccess(mediaUploadSuccessMessage(contentType));
    } catch (error) {
      if (sequence === uploadSequence.current) {
        setUploadError(getFirstApiError(error));
      }
    } finally {
      if (sequence === uploadSequence.current) {
        setIsUploading(false);
      }
    }
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!isUploading) {
      onSubmit(toPayload(form));
    }
  }

  const isExternal = form.content_type === "video" || form.content_type === "link";
  const isText = form.content_type === "text";

  return (
    <form className="grid gap-4" onSubmit={handleSubmit}>
      <MutationAlert eventKey={uploadCounter} tone="error" visible={Boolean(uploadError)}>{uploadError}</MutationAlert>
      <MutationAlert eventKey={uploadCounter} tone="success" visible={Boolean(uploadSuccess)}>{uploadSuccess}</MutationAlert>

      <FormField label="Judul materi">
        <Input
          maxLength={255}
          onChange={(event) => setForm((current) => ({ ...current, title: event.target.value }))}
          required
          value={form.title}
        />
      </FormField>
      <div className="grid gap-4 md:grid-cols-[minmax(0,1fr)_150px]">
        <FormField label="Jenis materi">
          <Select
            disabled={isUploading}
            onChange={(event) => {
              uploadSequence.current += 1;
              setMediaFile(null);
              setUploadError(null);
              setUploadSuccess(null);
              setIsUploading(false);
              setForm((current) => ({
                ...current,
                content_type: event.target.value as LessonContentType,
                content_body: "",
                external_url: "",
                media_id: "",
              }));
            }}
            value={form.content_type}
          >
            <option value="text">Teks</option>
            <option value="image">Gambar</option>
            <option value="audio">Audio</option>
            <option value="pdf">PDF</option>
            <option value="video">Video</option>
            <option value="link">Link</option>
          </Select>
        </FormField>
        <FormField label="Urutan">
          <Input
            min={1}
            onChange={(event) =>
              setForm((current) => ({ ...current, sort_order: event.target.value }))
            }
            placeholder="Auto"
            type="number"
            value={form.sort_order}
          />
        </FormField>
      </div>

      <FormField label="Deskripsi">
        <Textarea
          onChange={(event) =>
            setForm((current) => ({ ...current, description: event.target.value }))
          }
          value={form.description}
        />
      </FormField>

      {isText ? (
        <FormField label="Isi materi teks">
          <Textarea
            className="min-h-40"
            onChange={(event) =>
              setForm((current) => ({ ...current, content_body: event.target.value }))
            }
            required
            value={form.content_body}
          />
        </FormField>
      ) : null}

      {isExternal ? (
        <FormField label="URL HTTPS">
          <Input
            onChange={(event) =>
              setForm((current) => ({ ...current, external_url: event.target.value }))
            }
            placeholder="https://..."
            required
            type="url"
            value={form.external_url}
          />
        </FormField>
      ) : null}

      {mediaPurpose ? (
        <div className="grid gap-4">
          <FormField label={`Unggah ${contentTypeLabel(form.content_type)}`}>
            <UploadComponent
              accept={acceptForContentType(form.content_type)}
              disabled={isUploading}
              onChange={(event) => void handleMediaChange(event)}
            />
          </FormField>
          {isUploading ? <Alert tone="info">Mengunggah media...</Alert> : null}
          {mediaFile ? (
            <FilePreview
              name={mediaFile.name}
              size={`${Math.ceil(mediaFile.size / 1024)} KB`}
              type={mediaFile.type || contentTypeLabel(form.content_type)}
            />
          ) : null}
        </div>
      ) : null}

      <FormField label="Status">
        <Select
          onChange={(event) =>
            setForm((current) => ({
              ...current,
              status: event.target.value as ModuleTemplateStatus,
            }))
          }
          value={form.status}
        >
          <option value="draft">Draft</option>
          <option value="published">Terbit</option>
          <option value="archived">Diarsipkan</option>
        </Select>
      </FormField>

      <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
        <Button onClick={onCancel} type="button" variant="ghost">
          Batal
        </Button>
        <Button disabled={isSubmitting || isUploading} type="submit">
          {isUploading ? "Mengunggah..." : "Simpan Materi"}
        </Button>
      </div>
    </form>
  );
}
