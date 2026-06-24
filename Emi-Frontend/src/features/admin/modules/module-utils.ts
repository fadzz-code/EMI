import type {
  LessonContentType,
  MediaPurpose,
  ModuleTemplateStatus,
} from "./types";

export function normalizeNullable(value: string) {
  const trimmed = value.trim();
  return trimmed === "" ? null : trimmed;
}

export function statusLabel(status: ModuleTemplateStatus) {
  const labels: Record<ModuleTemplateStatus, string> = {
    draft: "Draft",
    published: "Terbit",
    archived: "Diarsipkan",
  };

  return labels[status];
}

export function statusTone(status: ModuleTemplateStatus) {
  const tones: Record<ModuleTemplateStatus, "blue" | "yellow" | "orange" | "neutral"> = {
    draft: "neutral",
    published: "blue",
    archived: "orange",
  };

  return tones[status];
}

export function contentTypeLabel(type: LessonContentType) {
  const labels: Record<LessonContentType, string> = {
    text: "Teks",
    image: "Gambar",
    audio: "Audio",
    pdf: "PDF",
    video: "Video",
    link: "Link",
  };

  return labels[type];
}

export function mediaPurposeForContentType(type: LessonContentType): MediaPurpose | null {
  if (type === "image") {
    return "lesson_image";
  }

  if (type === "audio") {
    return "audio";
  }

  if (type === "pdf") {
    return "document";
  }

  return null;
}

export function acceptForContentType(type: LessonContentType) {
  if (type === "image") {
    return ".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp";
  }

  if (type === "audio") {
    return ".mp3,.wav,.m4a,.ogg,.webm,audio/mpeg,audio/wav,audio/x-wav,audio/mp4,audio/ogg,audio/webm,application/octet-stream";
  }

  if (type === "pdf") {
    return ".pdf,application/pdf";
  }

  return undefined;
}

export function formatDate(value?: string | null) {
  if (!value) {
    return "-";
  }

  return new Intl.DateTimeFormat("id-ID", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}

export function publicMediaContentUrl(apiBaseUrl: string, mediaId: string) {
  return `${apiBaseUrl}/public/media/${mediaId}/content`;
}
