import { describe, expect, it } from "vitest";

import { newQuizDraft, validateQuestionImage } from "./quiz-utils";

describe("admin quiz workflow", () => {
  it("creates a minimal valid draft", () => {
    expect(newQuizDraft()).toEqual({
      title: "Kuis Baru",
      duration_minutes: 30,
      max_attempts: 1,
      status: "draft",
    });
  });

  it("accepts only supported images up to 5 MB", () => {
    expect(validateQuestionImage({ type: "image/webp", size: 5 * 1024 * 1024 })).toBeNull();
    expect(validateQuestionImage({ type: "image/gif", size: 100 })).toBe(
      "Format gambar harus JPEG, PNG, atau WebP.",
    );
    expect(validateQuestionImage({ type: "image/png", size: 5 * 1024 * 1024 + 1 })).toBe(
      "Ukuran gambar maksimal 5 MB.",
    );
  });
});
