import type { LearningStatus } from "./types";

export function formatDateTime(value?: string | null) {
  if (!value) {
    return "-";
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return "-";
  }

  return new Intl.DateTimeFormat("id-ID", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(date);
}

export function formatPercent(value?: number | null) {
  if (value === null || value === undefined || Number.isNaN(value)) {
    return "Belum tersedia";
  }

  return `${new Intl.NumberFormat("id-ID", {
    maximumFractionDigits: 2,
  }).format(value)}%`;
}

export function formatNumber(value?: number | null) {
  if (value === null || value === undefined || Number.isNaN(value)) {
    return "Belum tersedia";
  }

  return new Intl.NumberFormat("id-ID").format(value);
}

export function learningStatus(row: {
  published_modules: number;
  completed_modules: number;
  started_modules: number;
}): LearningStatus {
  if (row.published_modules > 0 && row.completed_modules >= row.published_modules) {
    return "completed";
  }

  if (row.started_modules > 0) {
    return "in_progress";
  }

  return "not_started";
}

export function learningStatusLabel(status: LearningStatus | string | null | undefined) {
  if (status === "completed") {
    return "Selesai";
  }

  if (status === "in_progress") {
    return "Berjalan";
  }

  if (status === "not_started") {
    return "Belum mulai";
  }

  return "Belum tersedia";
}

export function statusTone(status: LearningStatus | string | null | undefined) {
  if (status === "completed" || status === "submitted") {
    return "blue" as const;
  }

  if (status === "in_progress") {
    return "yellow" as const;
  }

  if (status === "expired") {
    return "orange" as const;
  }

  return "neutral" as const;
}

export function latestActivity(row: {
  last_learning_activity_at?: string | null;
  last_quiz_activity_at?: string | null;
}) {
  const dates = [row.last_learning_activity_at, row.last_quiz_activity_at]
    .filter(Boolean)
    .map((value) => new Date(value as string))
    .filter((date) => !Number.isNaN(date.getTime()))
    .sort((a, b) => b.getTime() - a.getTime());

  return dates[0]?.toISOString() ?? null;
}
