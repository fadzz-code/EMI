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

  if (status === "approved") {
    return "Disetujui";
  }

  if (status === "pending") {
    return "Menunggu persetujuan";
  }

  if (status === "rejected") {
    return "Ditolak";
  }

  if (status === "not_started") {
    return "Belum mulai";
  }

  if (status === "in_progress") {
    return "Sedang dikerjakan";
  }

  if (status === "completed") {
    return "Selesai";
  }

  return formatOptional(status);
}

export function contentTypeLabel(type: string | null | undefined) {
  const labels: Record<string, string> = {
    article: "Artikel",
    audio: "Audio",
    image: "Gambar",
    link: "Tautan",
    pdf: "PDF",
    text: "Teks",
    video: "Video",
    youtube: "YouTube",
  };

  return type ? labels[type] ?? "Konten" : "Konten";
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
