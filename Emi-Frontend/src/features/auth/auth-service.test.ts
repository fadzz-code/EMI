import { beforeEach, describe, expect, it, vi } from "vitest";

const { apiRequest, post } = vi.hoisted(() => ({ apiRequest: vi.fn(), post: vi.fn() }));

vi.mock("@/lib/api-client", () => ({
  ApiError: class extends Error {},
  apiClient: { post },
  apiRequest,
}));

import { authService } from "./auth-service";

describe("authService", () => {
  beforeEach(() => {
    apiRequest.mockReset();
    post.mockReset();
  });

  it("sends privacy consent through registration API contract", async () => {
    const payload = {
      full_name: "Siswa Test",
      email: "siswa@example.com",
      password: "password1",
      password_confirmation: "password1",
      requested_role: "student" as const,
      school_id: "00000000-0000-0000-0000-000000000001",
      class_id: "00000000-0000-0000-0000-000000000002",
      privacy_policy_accepted: true,
      privacy_policy_version: "2026-08-11",
    };
    post.mockResolvedValue({ data: { user_id: "user-1", status: "pending" } });

    await authService.register(payload);
    expect(post).toHaveBeenCalledWith("/auth/register", payload);
  });

  it("sends password through account deletion API contract", async () => {
    await authService.deleteAccount("token-1", { current_password: "secret" });

    expect(apiRequest).toHaveBeenCalledWith("/auth/account", {
      method: "DELETE",
      token: "token-1",
      body: { current_password: "secret" },
    });
  });
});
