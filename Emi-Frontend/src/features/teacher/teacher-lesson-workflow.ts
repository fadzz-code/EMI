import { getFirstApiError } from "@/lib/api-client";

import type { TeacherLessonContentType, TeacherLessonMediaPurpose, TeacherMediaFile } from "./types";

const mediaConfig: Partial<Record<TeacherLessonContentType, { accept: string; extensions: string[]; mimeTypes: string[]; purpose: TeacherLessonMediaPurpose; label: string }>> = {
  pdf: {
    accept: ".pdf,application/pdf",
    extensions: ["pdf"],
    mimeTypes: ["application/pdf"],
    purpose: "document",
    label: "PDF",
  },
  image: {
    accept: ".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp",
    extensions: ["jpg", "jpeg", "png", "webp"],
    mimeTypes: ["image/jpeg", "image/png", "image/webp"],
    purpose: "lesson_image",
    label: "gambar JPEG, PNG, atau WebP",
  },
  audio: {
    accept: ".mp3,.wav,.m4a,.ogg,.webm,audio/mpeg,audio/mp3,audio/wav,audio/x-wav,audio/mp4,audio/ogg,audio/webm",
    extensions: ["mp3", "wav", "m4a", "ogg", "webm"],
    mimeTypes: ["audio/mpeg", "audio/mp3", "audio/wav", "audio/x-wav", "audio/mp4", "audio/ogg", "audio/webm"],
    purpose: "audio",
    label: "audio MP3, WAV, M4A, OGG, atau WebM",
  },
};

export function lessonMediaConfig(contentType: TeacherLessonContentType) {
  return mediaConfig[contentType] ?? null;
}

export function validateLessonMedia(file: Pick<File, "name" | "type">, contentType: TeacherLessonContentType) {
  const config = lessonMediaConfig(contentType);
  if (!config) return "Tipe materi ini tidak menggunakan lampiran file.";
  const extension = file.name.split(".").pop()?.toLowerCase() ?? "";
  if (!config.extensions.includes(extension) || (file.type !== "" && !config.mimeTypes.includes(file.type.toLowerCase()))) {
    return `File tidak sesuai. Pilih file ${config.label}.`;
  }
  return null;
}

export function friendlyLessonMediaError(error: unknown) {
  const message = error instanceof Error && error.name !== "ApiError" ? error.message : getFirstApiError(error);
  if (/validation\.in|selected .* is invalid|must be one of/i.test(message)) {
    return "File tidak sesuai dengan tipe materi. Pilih format file yang benar.";
  }
  return message;
}

export function attachmentAfterReplacement<T extends TeacherMediaFile | null>(current: T, replacement: TeacherMediaFile, succeeded: boolean) {
  return succeeded ? replacement : current;
}
