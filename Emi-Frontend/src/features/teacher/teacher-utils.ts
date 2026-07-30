export function formatOptional(value: string | number | null | undefined) {
  if (value === null || value === undefined || value === "") {
    return "Belum tersedia";
  }

  return String(value);
}

export function formatCount(value: number | null | undefined) {
  return typeof value === "number" ? String(value) : "Belum tersedia";
}

export function formatPercent(value: number | null | undefined) {
  return typeof value === "number" ? `${Math.round(value)}%` : "Belum tersedia";
}

export function formatScoreOutOf100(value: number | null | undefined) {
  if (typeof value !== "number") {
    return "Belum tersedia";
  }

  return `${Number.isInteger(value) ? value : value.toFixed(2)}/100`;
}

export function formatDate(value: string | null | undefined) {
  if (!value) {
    return "Belum tersedia";
  }

  return new Intl.DateTimeFormat("id-ID", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}

export function statusLabel(status: string | null | undefined) {
  if (status === "active") {
    return "Aktif";
  }

  if (status === "inactive") {
    return "Nonaktif";
  }

  if (status === "draft") {
    return "Draft";
  }

  if (status === "published") {
    return "Terbit";
  }

  if (status === "archived") {
    return "Arsip";
  }

  return formatOptional(status);
}

export function contentTypeLabel(type: string | null | undefined) {
  if (type === "text") {
    return "Teks";
  }

  if (type === "image") {
    return "Gambar";
  }

  if (type === "audio") {
    return "Audio";
  }

  if (type === "pdf") {
    return "PDF";
  }

  if (type === "video") {
    return "Video";
  }

  if (type === "link") {
    return "Link";
  }

  return "Materi";
}

export function questionTypeLabel(type: string | null | undefined) {
  if (type === "multiple_choice") {
    return "Pilihan ganda";
  }

  if (type === "short_answer") {
    return "Isian singkat";
  }

  return formatOptional(type);
}

export function activityLabel(type: string | null | undefined) {
  if (type === "module_completed") {
    return "Modul selesai";
  }

  if (type === "quiz_submitted") {
    return "Kuis dikumpulkan";
  }

  if (type === "quiz_expired") {
    return "Kuis berakhir";
  }

  return "Aktivitas";
}
