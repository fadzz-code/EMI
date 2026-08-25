import type { AuthUser } from "@/features/auth/auth-types";

export type SettingsProfilePayload = {
  full_name: string;
  phone?: string | null;
};

export type LoginBanner = {
  enabled: boolean;
  image_media_id?: string | null;
  image_url?: string | null;
};

export type AdminActivityLog = {
  id: string;
  created_at: string;
  admin: string;
  title: string;
  status: boolean;
};

export type AdminSettings = {
  banner: LoginBanner;
  activity_logs: AdminActivityLog[];
};

export type SettingsUser = AuthUser;
