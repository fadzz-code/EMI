import type { EntityStatus, ManagedUser, SchoolClass, UserStatus } from "./types";

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

export function entityStatusLabel(status?: EntityStatus | string) {
  if (status === "active") {
    return "Aktif";
  }

  if (status === "inactive") {
    return "Nonaktif";
  }

  return status ?? "-";
}

export function userStatusLabel(status?: UserStatus | string) {
  if (status === "approved") {
    return "Disetujui";
  }

  if (status === "inactive") {
    return "Nonaktif";
  }

  if (status === "pending") {
    return "Pending";
  }

  if (status === "rejected") {
    return "Ditolak";
  }

  return status ?? "-";
}

export function roleLabel(role?: string) {
  if (role === "teacher") {
    return "Guru";
  }

  if (role === "student") {
    return "Siswa";
  }

  if (role === "admin") {
    return "Admin";
  }

  return "-";
}

export function classLabel(schoolClass?: Pick<SchoolClass, "name" | "academic_year"> | null) {
  if (!schoolClass) {
    return "-";
  }

  return `${schoolClass.name}${schoolClass.academic_year ? ` - ${schoolClass.academic_year}` : ""}`;
}

export function activeClassLabel(user?: ManagedUser | null) {
  return classLabel(user?.active_class);
}

export function statusTone(status?: string) {
  if (status === "active" || status === "approved") {
    return "blue" as const;
  }

  if (status === "pending") {
    return "yellow" as const;
  }

  if (status === "inactive" || status === "rejected") {
    return "orange" as const;
  }

  return "neutral" as const;
}

export function normalizeNullable(value: string) {
  const trimmed = value.trim();

  return trimmed ? trimmed : null;
}
