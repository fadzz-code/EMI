import type { DictionaryImportStatus, DictionaryStatus, DuplicateStrategy } from "./types";

export function statusLabel(status?: DictionaryStatus | string) {
  if (status === "active") {
    return "Aktif";
  }

  if (status === "inactive") {
    return "Nonaktif";
  }

  return status ?? "-";
}

export function statusTone(status?: string) {
  const normalized = status
    ?.trim()
    .replace(/([a-z])([A-Z])/g, "$1_$2")
    .replace(/[\s-]+/g, "_")
    .toLowerCase();

  if (normalized === "active" || normalized === "completed" || normalized === "preview_ready") {
    return "blue" as const;
  }

  if (normalized === "queued" || normalized === "processing" || normalized === "previewing") {
    return "yellow" as const;
  }

  if (
    normalized === "inactive" ||
    normalized === "failed" ||
    normalized === "cancelled" ||
    normalized === "completed_with_errors"
  ) {
    return "orange" as const;
  }

  return "neutral" as const;
}

export function importStatusLabel(status?: DictionaryImportStatus | string) {
  const normalized = status
    ?.trim()
    .replace(/([a-z])([A-Z])/g, "$1_$2")
    .replace(/[\s-]+/g, "_")
    .toLowerCase();
  const labels: Record<string, string> = {
    previewing: "Membuat Pratinjau",
    preview_ready: "Siap Diimpor",
    queued: "Dalam Antrean",
    processing: "Diproses",
    completed: "Selesai",
    completed_with_errors: "Selesai dengan Error",
    failed: "Gagal",
    cancelled: "Dibatalkan",
  };

  return normalized ? labels[normalized] ?? status ?? "-" : "-";
}

export function duplicateStrategyLabel(strategy?: DuplicateStrategy | string) {
  if (strategy === "skip") {
    return "Lewati duplikat";
  }

  if (strategy === "update") {
    return "Perbarui duplikat";
  }

  if (strategy === "reject") {
    return "Tolak jika duplikat";
  }

  return strategy ?? "-";
}

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

export function formatBytes(value?: number | null) {
  if (!value) {
    return "-";
  }

  if (value < 1024) {
    return `${value} B`;
  }

  if (value < 1024 * 1024) {
    return `${(value / 1024).toFixed(1)} KB`;
  }

  return `${(value / (1024 * 1024)).toFixed(1)} MB`;
}

export function normalizeNullable(value: string) {
  const trimmed = value.trim();

  return trimmed ? trimmed : null;
}
