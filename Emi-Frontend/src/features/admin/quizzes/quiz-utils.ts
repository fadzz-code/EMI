import type { QuestionType, QuizTemplateStatus } from "./types";

export function normalizeNullable(value: string) {
  const trimmed = value.trim();
  return trimmed === "" ? null : trimmed;
}

export function statusLabel(status: QuizTemplateStatus) {
  const labels: Record<QuizTemplateStatus, string> = {
    draft: "Draft",
    published: "Published",
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
