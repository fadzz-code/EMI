import { afterEach, describe, expect, it, vi } from "vitest";

vi.mock("./env", () => ({ env: { apiBaseUrl: "https://api.example.com" } }));

import { apiRequest, onUnauthorized } from "./api-client";

describe("API unauthorized session invalidation", () => {
  afterEach(() => vi.unstubAllGlobals());

  it("notifies listeners for authenticated 401 only", async () => {
    const listener = vi.fn();
    const unsubscribe = onUnauthorized(listener);
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response(JSON.stringify({ success: false, message: "Unauthorized" }), {
      status: 401,
      headers: { "content-type": "application/json" },
    })));

    await expect(apiRequest("/auth/me", { token: "active-token" })).rejects.toMatchObject({ status: 401 });
    expect(listener).toHaveBeenCalledOnce();
    unsubscribe();
  });

  it("does not invalidate session for expected login 401", async () => {
    const listener = vi.fn();
    const unsubscribe = onUnauthorized(listener);
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response(JSON.stringify({ success: false, message: "Wrong", code: "INVALID_CREDENTIALS" }), {
      status: 401,
      headers: { "content-type": "application/json" },
    })));

    await expect(apiRequest("/auth/login", { method: "POST", body: {} })).rejects.toMatchObject({ status: 401 });
    expect(listener).not.toHaveBeenCalled();
    unsubscribe();
  });
});
