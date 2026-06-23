import { apiClient } from "@/lib/api-client";

import type { SettingsProfilePayload, SettingsUser } from "./types";

export const settingsService = {
  async currentUser(token: string) {
    const response = await apiClient.get<SettingsUser>("/auth/me", { token });

    if (!response.data) {
      throw new Error("Profil admin tidak tersedia.");
    }

    return response.data;
  },

  async updateProfile(token: string, payload: SettingsProfilePayload) {
    const response = await apiClient.patch<SettingsUser>("/auth/me", payload, { token });

    if (!response.data) {
      throw new Error("Response update profil tidak tersedia.");
    }

    return response.data;
  },
};
