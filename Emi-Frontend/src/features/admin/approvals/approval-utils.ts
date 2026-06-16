import type {
  RegistrationRequestStatus,
  RegistrationRequestedRole,
} from "./types";

export function roleLabel(role?: RegistrationRequestedRole) {
  if (role === "teacher") {
    return "Guru";
  }

  if (role === "student") {
    return "Siswa";
  }

  return "-";
}

export function statusLabel(status?: RegistrationRequestStatus | string) {
  if (status === "pending") {
    return "Menunggu";
  }

  if (status === "approved") {
    return "Disetujui";
  }

  if (status === "rejected") {
    return "Ditolak";
  }

  return status ?? "-";
}

export function statusTone(status?: RegistrationRequestStatus | string) {
  if (status === "pending") {
    return "yellow" as const;
  }

  if (status === "approved") {
    return "blue" as const;
  }

  if (status === "rejected") {
    return "orange" as const;
  }

  return "neutral" as const;
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
