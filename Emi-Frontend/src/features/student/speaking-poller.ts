export const SPEAKING_TERMINAL_STATUSES = new Set(["completed", "failed", "reviewed"]);

export function createSpeakingPoller<T extends { id: string; status: string }>(options: {
  attempt: T;
  fetch: (id: string) => Promise<T>;
  update: (attempt: T) => void;
  fail: (message: string) => void;
  delay?: number;
  maxFailures?: number;
}) {
  let current = options.attempt;
  let timer: ReturnType<typeof setTimeout> | undefined;
  let stopped = false;
  let failures = 0;
  const delay = options.delay ?? 2500;
  const maxFailures = options.maxFailures ?? 3;
  const schedule = () => { if (!stopped && !SPEAKING_TERMINAL_STATUSES.has(current.status)) timer = setTimeout(run, delay); };
  const run = async () => {
    if (stopped) return;
    const id = current.id;
    try {
      const result = await options.fetch(id);
      if (stopped || result.id !== id) return;
      failures = 0;
      current = result;
      options.update(result);
      schedule();
    } catch {
      if (stopped) return;
      failures += 1;
      if (failures >= maxFailures) {
        stopped = true;
        if (timer) clearTimeout(timer);
        options.fail("Hasil belum dapat dimuat. Coba lagi beberapa saat.");
      } else schedule();
    }
  };
  schedule();
  return { stop() { stopped = true; if (timer) clearTimeout(timer); } };
}
