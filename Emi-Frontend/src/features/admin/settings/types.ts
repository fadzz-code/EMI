import type { AuthUser } from "@/features/auth/auth-types";

export type SettingsProfilePayload = {
  full_name: string;
  phone?: string | null;
};

export type SettingsUser = AuthUser;
