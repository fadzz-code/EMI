import type {
  LessonContentType,
  MediaVisibility,
  ModuleTemplatePayload,
  ModuleTemplateStatus,
} from "./types";

export const PUBLIC_MEDIA_VISIBILITY: MediaVisibility = "public";
export const INVALID_MEDIA_TYPE_MESSAGE = "Jenis file tidak sesuai dengan tujuan unggahan.";

const mediaTypes: Partial<Record<LessonContentType, Set<string>>> = {
  image: new Set(["image/jpeg", "image/png", "image/webp"]),
  audio: new Set(["audio/mpeg", "audio/wav", "audio/x-wav", "audio/mp4", "audio/ogg", "audio/webm"]),
  pdf: new Set(["application/pdf"]),
};

const mediaExtensions: Partial<Record<LessonContentType, Set<string>>> = {
  image: new Set(["jpg", "jpeg", "png", "webp"]),
  audio: new Set(["mp3", "wav", "m4a", "ogg", "webm"]),
  pdf: new Set(["pdf"]),
};

export function newModuleDraft(): ModuleTemplatePayload {
  return { title: "Modul Baru", status: "draft" };
}

export function canPublishModule(lessons: Array<{ status: ModuleTemplateStatus }>): boolean {
  return lessons.some((lesson) => lesson.status === "published");
}

export function isValidMediaFile(
  contentType: LessonContentType,
  file: Pick<File, "name" | "type">,
): boolean {
  const allowedTypes = mediaTypes[contentType];
  const allowedExtensions = mediaExtensions[contentType];

  if (!allowedTypes || !allowedExtensions) {
    return false;
  }

  if (file.type) {
    return allowedTypes.has(file.type.toLowerCase());
  }

  const extension = file.name.split(".").pop()?.toLowerCase() ?? "";
  return allowedExtensions.has(extension);
}

export function mediaUploadSuccessMessage(contentType: LessonContentType): string {
  const labels: Partial<Record<LessonContentType, string>> = {
    image: "gambar",
    pdf: "PDF",
    audio: "audio",
  };

  return `Media ${labels[contentType] ?? ""} berhasil diunggah.`;
}
