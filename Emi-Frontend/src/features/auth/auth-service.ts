import { ApiError, apiClient, apiRequest } from "@/lib/api-client";
import { isUserRole } from "@/lib/roles";

import type {
  AuthUser,
  LoginPayload,
  LoginResult,
  PublicSchool,
  PublicSchoolClass,
  RegisterPayload,
  RegisterResult,
} from "./auth-types";

function assertApprovedUser(user: AuthUser) {
  if (!isUserRole(user.role)) {
    throw new ApiError({
      message: "Role akun tidak dikenali oleh frontend EMI.",
      status: 403,
      code: "INVALID_ROLE",
    });
  }

  if (user.status !== "approved") {
    throw new ApiError({
      message: "Akun belum aktif. Silakan tunggu persetujuan Admin.",
      status: 403,
      code: "ACCOUNT_NOT_APPROVED",
    });
  }
}

export const authService = {
  async login(payload: LoginPayload) {
    const response = await apiClient.post<LoginResult>("/auth/login", payload);

    if (!response.data) {
      throw new Error("Response login tidak memuat data pengguna.");
    }

    assertApprovedUser(response.data.user);

    return response.data;
  },

  async logout(token: string) {
    await apiClient.post<null>("/auth/logout", undefined, { token });
  },

  async getCurrentUser(token: string) {
    const response = await apiClient.get<AuthUser>("/auth/me", { token });

    if (!response.data) {
      throw new Error("Response profil tidak memuat data pengguna.");
    }

    assertApprovedUser(response.data);

    return response.data;
  },

  async updateProfile(token: string, payload: { full_name: string; phone: string | null }) {
    const response = await apiClient.patch<AuthUser>("/auth/me", payload, { token });
    if (!response.data) throw new Error("Response profil tidak tersedia.");
    return response.data;
  },

  async updatePassword(token: string, payload: { current_password: string; password: string; password_confirmation: string }) {
    await apiClient.put<AuthUser>("/auth/password", payload, { token });
  },

  async uploadAvatar(token: string, avatar: File) {
    const body = new FormData();
    body.append("avatar", avatar);
    const response = await apiClient.post<AuthUser>("/auth/me/avatar", body, { token });
    if (!response.data) throw new Error("Response avatar tidak tersedia.");
    return response.data;
  },

  async deleteAvatar(token: string) {
    await apiClient.delete<AuthUser>("/auth/me/avatar", { token });
  },

  async deleteAccount(token: string, currentPassword: string) {
    await apiRequest<null>("/auth/account", { method: "DELETE", token, body: { current_password: currentPassword } });
  },

  async registerTeacher(payload: Omit<RegisterPayload, "requested_role">) {
    return this.register({
      ...payload,
      requested_role: "teacher",
    });
  },

  async registerStudent(payload: Omit<RegisterPayload, "requested_role">) {
    return this.register({
      ...payload,
      requested_role: "student",
    });
  },

  async register(payload: RegisterPayload) {
    const response = await apiClient.post<RegisterResult>("/auth/register", payload);

    if (!response.data) {
      throw new Error("Response pendaftaran tidak memuat status akun.");
    }

    return response.data;
  },

  async listPublicSchools(query?: { search?: string; page?: number; per_page?: number }) {
    const response = await apiClient.get<PublicSchool[]>("/public/schools", {
      query: {
        per_page: 100,
        ...query,
      },
    });

    return response.data ?? [];
  },

  async listPublicClasses(
    schoolId: string,
    query?: { search?: string; page?: number; per_page?: number },
  ) {
    const response = await apiClient.get<PublicSchoolClass[]>(
      `/public/schools/${schoolId}/classes`,
      {
        query: {
          per_page: 100,
          ...query,
        },
      },
    );

    return response.data ?? [];
  },
};
