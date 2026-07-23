import { describe, expect, it, vi } from "vitest";

import { AnswerSaveQueue, createAttemptFinalizer } from "./student-quiz-attempt-flow";

describe("quiz attempt save flow", () => {
  it("awaits pending multiple choice save before timeout submit", async () => {
    const calls: string[] = [];
    let release: () => void = () => undefined;
    const pending = new Promise<void>((resolve) => { release = resolve; });
    const queue = new AnswerSaveQueue();
    queue.enqueue({ questionId: "mc", optionId: "a" }, async () => { await pending; calls.push("save"); });
    const finalization = createAttemptFinalizer(queue, async () => { calls.push("submit"); })();
    expect(calls).toEqual([]);
    release();
    await finalization;
    expect(calls).toEqual(["save", "submit"]);
  });

  it("does not duplicate blurred answer during timeout", async () => {
    const save = vi.fn(async () => undefined);
    const answer = { questionId: "short", answerText: "jawaban" };
    const queue = new AnswerSaveQueue();
    await queue.enqueue(answer, save);
    await createAttemptFinalizer(queue, async () => undefined)(answer, save);
    expect(save).toHaveBeenCalledOnce();
  });

  it("double finalize submits once", async () => {
    const submit = vi.fn(async () => undefined);
    const finalize = createAttemptFinalizer(new AnswerSaveQueue(), submit);
    await Promise.all([finalize(), finalize()]);
    expect(submit).toHaveBeenCalledOnce();
  });

  it("blocks submit when pending save fails", async () => {
    const submit = vi.fn();
    const queue = new AnswerSaveQueue();
    const failed = queue.enqueue({ questionId: "short", answerText: "x" }, async () => { throw new Error("save failed"); });
    await expect(failed).rejects.toThrow("save failed");
    await expect(createAttemptFinalizer(queue, submit)()).rejects.toThrow("save failed");
    expect(submit).not.toHaveBeenCalled();
  });

  it("retries finalization with same submit function after failure", async () => {
    const submit = vi.fn().mockRejectedValueOnce(new Error("submit failed")).mockResolvedValueOnce(undefined);
    const finalize = createAttemptFinalizer(new AnswerSaveQueue(), submit);
    await expect(finalize()).rejects.toThrow("submit failed");
    await finalize();
    expect(submit).toHaveBeenCalledTimes(2);
  });
});
