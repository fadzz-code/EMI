import { apiClient } from "@/lib/api-client";

import type { AdminSettings, SecuritySettingsPayload, SettingsProfilePayload, SettingsUser, ApplicationSettingsPayload } from "./types";

export const settingsService = {
  async currentUser(token: string) {
    const response = await apiClient.get<SettingsUser>("/auth/me", { token });
    if (!response.data) throw new Error("Profil admin tidak tersedia.");
    return response.data;
  },
  async updateProfile(token: string, payload: SettingsProfilePayload) {
    const response = await apiClient.patch<SettingsUser>("/auth/me", payload, { token });
    if (!response.data) throw new Error("Response update profil tidak tersedia.");
    return response.data;
  },
  async settings(token: string) {
    const response = await apiClient.get<AdminSettings>("/admin/settings", { token });
    if (!response.data) throw new Error("Pengaturan admin tidak tersedia.");
    return response.data;
  },
  async updateApplication(token: string, payload: ApplicationSettingsPayload) {
    const response = await apiClient.put<ApplicationSettingsPayload>("/admin/settings/application", payload, { token });
    if (!response.data) throw new Error("Response pengaturan aplikasi tidak tersedia.");
    return response.data;
  },
  async updateBanner(token: string, payload: FormData) {
    const response = await apiClient.post<AdminSettings["banner"]>("/admin/settings/banner", payload, { token });
    if (!response.data) throw new Error("Response banner tidak tersedia.");
    return response.data;
  },
  async updateSecurity(token: string, payload: SecuritySettingsPayload) {
    const response = await apiClient.put<SecuritySettingsPayload>("/admin/settings/security", payload, { token });
    if (!response.data) throw new Error("Response keamanan tidak tersedia.");
    return response.data;
  },
  async updatePassword(token: string, payload: { current_password: string; password: string; password_confirmation: string }) {
    const response = await apiClient.put<SettingsUser>("/auth/password", payload, { token });
    if (!response.data) throw new Error("Response password tidak tersedia.");
    return response.data;
  },
  async publicBranding() {
    const response = await apiClient.get<AdminSettings["banner"]>("/public/login-branding");
    return response.data ?? null;
  },
};
