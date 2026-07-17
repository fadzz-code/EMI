import type { QuestionType, QuizTemplatePayload, QuizTemplateStatus } from "./types";

const QUESTION_IMAGE_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);
const QUESTION_IMAGE_MAX_BYTES = 5 * 1024 * 1024;

export function newQuizDraft(): QuizTemplatePayload {
  return {
    title: "Kuis Baru",
    duration_minutes: 30,
    max_attempts: 1,
    status: "draft",
  };
}

export function validateQuestionImage(file: Pick<File, "size" | "type">) {
  if (!QUESTION_IMAGE_TYPES.has(file.type)) {
    return "Format gambar harus JPEG, PNG, atau WebP.";
  }

  if (file.size > QUESTION_IMAGE_MAX_BYTES) {
    return "Ukuran gambar maksimal 5 MB.";
  }

  return null;
}

export function normalizeNullable(value: string) {
  const trimmed = value.trim();
  return trimmed === "" ? null : trimmed;
}

export function statusLabel(status: QuizTemplateStatus) {
  const labels: Record<QuizTemplateStatus, string> = {
    draft: "Draft",
    published: "Terbit",
    archived: "Diarsipkan",
  };

  return labels[status];
}

export function statusTone(status: QuizTemplateStatus) {
  const tones: Record<QuizTemplateStatus, "blue" | "yellow" | "orange" | "neutral"> = {
    draft: "neutral",
    published: "blue",
    archived: "orange",
  };

  return tones[status];
}

export function questionTypeLabel(type: QuestionType) {
  const labels: Record<QuestionType, string> = {
    multiple_choice: "Pilihan Ganda",
    short_answer: "Isian Singkat",
  };

  return labels[type];
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
