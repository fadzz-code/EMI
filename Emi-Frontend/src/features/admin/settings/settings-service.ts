import { apiClient } from "@/lib/api-client";

import type { AdminSettings, LoginBanner, SettingsProfilePayload, SettingsUser } from "./types";

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
  async updateBanner(token: string, payload: FormData) {
    const response = await apiClient.post<LoginBanner>("/admin/settings/banner", payload, { token });
    if (!response.data) throw new Error("Response banner tidak tersedia.");
    return response.data;
  },
  async updatePassword(token: string, payload: { current_password: string; password: string; password_confirmation: string }) {
    const response = await apiClient.put<SettingsUser>("/auth/password", payload, { token });
    if (!response.data) throw new Error("Response password tidak tersedia.");
    return response.data;
  },
  async publicBranding() {
    const response = await apiClient.get<LoginBanner>("/public/login-branding");
    return response.data ?? null;
  },
};
