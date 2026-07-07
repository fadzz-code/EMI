import type { AuthUser } from "@/features/auth/auth-types";

export type SettingsProfilePayload = {
  full_name: string;
  phone?: string | null;
};

export type ApplicationSettingsPayload = {
  name: string;
  subtitle: string;
  active_academic_year: string;
  timezone: string;
};

export type SecuritySettingsPayload = {
  new_login_alert: boolean;
  weekly_report_email: boolean;
};

export type AdminActivityLog = {
  id: string;
  created_at: string;
  admin: string;
  title: string;
  status: boolean;
};

export type AdminSettings = {
  application: ApplicationSettingsPayload;
  banner: {
    enabled: boolean;
    image_media_id?: string | null;
    image_url?: string | null;
  };
  security: SecuritySettingsPayload;
  activity_logs: AdminActivityLog[];
};

export type SettingsUser = AuthUser;
