import { afterEach, describe, expect, it, vi } from "vitest";

import { createSpeakingPoller } from "./speaking-poller";

type Attempt = { id: string; status: string; score?: number };

function deferred<T>() {
  let resolve!: (value: T) => void;
  let reject!: (reason?: unknown) => void;
  const promise = new Promise<T>((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}

describe("createSpeakingPoller", () => {
  afterEach(() => vi.useRealTimers());

  it.each(["completed", "failed", "reviewed"])("does not poll terminal %s", async (status) => {
    vi.useFakeTimers();
    const fetch = vi.fn();
    createSpeakingPoller({ attempt: { id: "1", status }, fetch, update: vi.fn(), fail: vi.fn(), delay: 10 });
    await vi.advanceTimersByTimeAsync(100);
    expect(fetch).not.toHaveBeenCalled();
  });

  it("updates completed result and stops", async () => {
    vi.useFakeTimers();
    const update = vi.fn();
    const fetch = vi.fn(async () => ({ id: "1", status: "completed", score: 90 }));
    createSpeakingPoller({ attempt: { id: "1", status: "pending" }, fetch, update, fail: vi.fn(), delay: 10 });
    await vi.advanceTimersByTimeAsync(100);
    expect(update).toHaveBeenCalledWith({ id: "1", status: "completed", score: 90 });
    expect(fetch).toHaveBeenCalledOnce();
  });

  it("stops and reports friendly error after bounded failures", async () => {
    vi.useFakeTimers();
    const fail = vi.fn();
    const fetch = vi.fn(async () => { throw new Error("network"); });
    createSpeakingPoller({ attempt: { id: "1", status: "pending" }, fetch, update: vi.fn(), fail, delay: 10, maxFailures: 2 });
    await vi.advanceTimersByTimeAsync(100);
    expect(fetch).toHaveBeenCalledTimes(2);
    expect(fail).toHaveBeenCalledWith("Hasil belum dapat dimuat. Coba lagi beberapa saat.");
    expect(vi.getTimerCount()).toBe(0);
  });

  it("cleanup cancels timer", () => {
    vi.useFakeTimers();
    const poller = createSpeakingPoller({ attempt: { id: "1", status: "pending" }, fetch: vi.fn(), update: vi.fn(), fail: vi.fn(), delay: 10 });
    poller.stop();
    expect(vi.getTimerCount()).toBe(0);
  });

  it("ignores stale response after cleanup", async () => {
    vi.useFakeTimers();
    const pending = deferred<Attempt>();
    const update = vi.fn();
    const poller = createSpeakingPoller({ attempt: { id: "old", status: "pending" }, fetch: () => pending.promise, update, fail: vi.fn(), delay: 10 });
    await vi.advanceTimersByTimeAsync(10);
    poller.stop();
    pending.resolve({ id: "old", status: "completed" });
    await Promise.resolve();
    expect(update).not.toHaveBeenCalled();
  });

  it("rejects mismatched attempt ID", async () => {
    vi.useFakeTimers();
    const update = vi.fn();
    createSpeakingPoller({ attempt: { id: "old", status: "pending" }, fetch: async () => ({ id: "new", status: "completed" }), update, fail: vi.fn(), delay: 10 });
    await vi.advanceTimersByTimeAsync(10);
    expect(update).not.toHaveBeenCalled();
  });
});
