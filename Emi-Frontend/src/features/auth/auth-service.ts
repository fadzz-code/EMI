import { apiRequest } from "@/lib/api-client";

import type {
  AuthUser,
  LoginPayload,
  LoginResult,
  RegisterPayload,
  RegisterResult,
} from "./auth-types";

export const authService = {
  async login(payload: LoginPayload) {
    const response = await apiRequest<LoginResult>("/auth/login", {
      method: "POST",
      body: payload,
    });

    if (!response.data) {
      throw new Error("Response login tidak memuat data pengguna.");
    }

    return response.data;
  },

  async logout(token: string) {
    await apiRequest<null>("/auth/logout", {
      method: "POST",
      token,
    });
  },

  async me(token: string) {
    const response = await apiRequest<AuthUser>("/auth/me", {
      method: "GET",
      token,
    });

    if (!response.data) {
      throw new Error("Response profil tidak memuat data pengguna.");
    }

    return response.data;
  },

  async register(payload: RegisterPayload) {
    const response = await apiRequest<RegisterResult>("/auth/register", {
      method: "POST",
      body: payload,
    });

    if (!response.data) {
      throw new Error("Response pendaftaran tidak memuat status akun.");
    }

    return response.data;
  },
};
