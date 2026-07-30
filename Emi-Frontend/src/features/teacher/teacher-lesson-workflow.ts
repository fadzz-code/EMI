import { ApiError, getFirstApiError } from "@/lib/api-client";

import type { TeacherLessonContentType, TeacherLessonForm, TeacherLessonPayload, TeacherMediaPurpose } from "./types";

export const MEDIA_CONTENT_TYPES: TeacherLessonContentType[] = ["text", "image", "audio", "pdf", "video", "link"];
export const INVALID_LESSON_MEDIA_MESSAGE = "File tidak sesuai dengan jenis materi yang dipilih.";

const mediaMimeTypes: Partial<Record<TeacherLessonContentType, Set<string>>> = {
  image: new Set(["image/jpeg", "image/png", "image/webp"]),
  audio: new Set(["audio/mpeg", "audio/wav", "audio/x-wav", "audio/mp4", "audio/ogg", "audio/webm"]),
  pdf: new Set(["application/pdf"]),
};

const mediaExtensions: Partial<Record<TeacherLessonContentType, Set<string>>> = {
  image: new Set(["jpg", "jpeg", "png", "webp"]),
  audio: new Set(["mp3", "wav", "m4a", "ogg", "webm"]),
  pdf: new Set(["pdf"]),
};

export function mediaPurposeForLesson(type: TeacherLessonContentType): TeacherMediaPurpose | null {
  if (type === "image") return "lesson_image";
  if (type === "audio") return "audio";
  if (type === "pdf") return "document";
  return null;
}

export function acceptForLesson(type: TeacherLessonContentType): string | undefined {
  if (type === "image") return ".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp";
  if (type === "audio") return ".mp3,.wav,.m4a,.ogg,.webm,audio/mpeg,audio/wav,audio/x-wav,audio/mp4,audio/ogg,audio/webm";
  if (type === "pdf") return ".pdf,application/pdf";
}

export function isValidLessonMedia(type: TeacherLessonContentType, file: Pick<File, "name" | "type">): boolean {
  const mimeTypes = mediaMimeTypes[type];
  const extensions = mediaExtensions[type];
  if (!mimeTypes || !extensions) return false;
  if (file.type) return mimeTypes.has(file.type.toLowerCase());
  return extensions.has(file.name.split(".").pop()?.toLowerCase() ?? "");
}

export function lessonPayload(form: TeacherLessonForm): TeacherLessonPayload {
  const parsedSortOrder = Number.parseInt(form.sort_order, 10);
  const base = {
    title: form.title.trim(),
    description: form.description.trim() || null,
    content_type: form.content_type,
    sort_order: Number.isNaN(parsedSortOrder) ? undefined : parsedSortOrder,
  };
  if (form.content_type === "text") return { ...base, content_body: form.content_body.trim(), media_id: null, external_url: null };
  if (form.content_type === "video" || form.content_type === "link") return { ...base, content_body: null, media_id: null, external_url: form.external_url.trim() };
  return { ...base, content_body: null, media_id: form.media_id || null, external_url: null };
}

export function validateLessonForm(form: TeacherLessonForm): string | null {
  if (!form.title.trim()) return "Judul materi wajib diisi.";
  if (form.content_type === "text" && !form.content_body.trim()) return "Isi materi teks wajib diisi.";
  if ((form.content_type === "video" || form.content_type === "link") && !/^https:\/\//i.test(form.external_url.trim())) return "URL materi wajib menggunakan HTTPS.";
  if (mediaPurposeForLesson(form.content_type) && !form.media_id) return "Unggah file yang sesuai sebelum menyimpan materi.";
  if (form.sort_order.trim() !== "" && (!Number.isInteger(Number(form.sort_order)) || Number(form.sort_order) < 1)) return "Urutan tampil minimal 1.";
  return null;
}

export function friendlyLessonError(error: unknown): string {
  const message = getFirstApiError(error);
  if (message.includes("validation.in") || message.toLowerCase().includes("media materi tidak valid")) return "File tidak cocok dengan jenis materi. Pilih file yang sesuai lalu coba lagi.";
  if (error instanceof ApiError && Object.values(error.errors ?? {}).flat().some((value) => value.includes("validation.in"))) return "File tidak cocok dengan jenis materi. Pilih file yang sesuai lalu coba lagi.";
  return message;
}

export function attachmentAfterReplacement(oldMediaId: string | null, newMediaId: string, updateSucceeded: boolean): string {
  return updateSucceeded ? newMediaId : oldMediaId ?? "";
}
