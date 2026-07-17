import { describe, expect, it } from "vitest";

import { ApiError } from "@/lib/api-client";

import { attachmentAfterReplacement, friendlyLessonMediaError, lessonMediaConfig, validateLessonMedia } from "./teacher-lesson-workflow";

const file = (name: string, type: string) => ({ name, type }) as File;

describe("teacher lesson media workflow", () => {
  it("accepts PDF and maps its upload purpose to document", () => {
    expect(validateLessonMedia(file("materi.pdf", "application/pdf"), "pdf")).toBeNull();
    expect(lessonMediaConfig("pdf")?.purpose).toBe("document");
  });

  it("rejects non-PDF for PDF lessons", () => {
    expect(validateLessonMedia(file("materi.png", "image/png"), "pdf")).toBe("File tidak sesuai. Pilih file PDF.");
  });

  it("maps raw validation.in errors to friendly Indonesian", () => {
    const error = new ApiError({
      message: "Data yang diberikan tidak valid.",
      status: 422,
      errors: { purpose: ["validation.in"] },
    });
    expect(friendlyLessonMediaError(error)).toBe("File tidak sesuai dengan tipe materi. Pilih format file yang benar.");
  });

  it("keeps old attachment unless replacement operation succeeds", () => {
    const oldMedia = { id: "old" };
    const replacement = { id: "new" };
    expect(attachmentAfterReplacement(oldMedia, replacement, false)).toBe(oldMedia);
    expect(attachmentAfterReplacement(oldMedia, replacement, true)).toBe(replacement);
  });
});
