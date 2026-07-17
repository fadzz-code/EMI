import { describe, expect, it } from "vitest";

import { ApiError } from "@/lib/api-client";

import { attachmentAfterReplacement, friendlyLessonError, isValidLessonMedia, lessonPayload, mediaPurposeForLesson } from "./teacher-lesson-workflow";
import type { TeacherLessonContentType, TeacherLessonForm } from "./types";

const form = (content_type: TeacherLessonContentType): TeacherLessonForm => ({ title: " Materi ", description: " ", content_type, content_body: " Isi ", media_id: "media-1", external_url: "https://example.com/video", sort_order: "2" });

describe("teacher lesson workflow", () => {
  it("maps every content type to upload purpose", () => {
    expect(["text", "image", "audio", "pdf", "video", "link"].map((type) => mediaPurposeForLesson(type as TeacherLessonContentType))).toEqual([null, "lesson_image", "audio", "document", null, null]);
  });

  it("accepts valid PDF and rejects wrong files", () => {
    expect(isValidLessonMedia("pdf", { name: "materi.pdf", type: "application/pdf" })).toBe(true);
    expect(isValidLessonMedia("pdf", { name: "materi.png", type: "image/png" })).toBe(false);
    expect(isValidLessonMedia("image", { name: "materi.pdf", type: "application/pdf" })).toBe(false);
  });

  it("builds type-aware payloads", () => {
    expect(lessonPayload(form("text"))).toMatchObject({ content_body: "Isi", media_id: null, external_url: null });
    expect(lessonPayload(form("image"))).toMatchObject({ content_body: null, media_id: "media-1", external_url: null });
    expect(lessonPayload(form("audio"))).toMatchObject({ media_id: "media-1", external_url: null });
    expect(lessonPayload(form("pdf"))).toMatchObject({ media_id: "media-1", external_url: null });
    expect(lessonPayload(form("video"))).toMatchObject({ content_body: null, media_id: null, external_url: "https://example.com/video" });
    expect(lessonPayload(form("link"))).toMatchObject({ content_body: null, media_id: null, external_url: "https://example.com/video" });
  });

  it("translates backend media validation errors", () => {
    expect(friendlyLessonError(new ApiError({ message: "Media materi tidak valid", status: 422 }))).toBe("File tidak cocok dengan jenis materi. Pilih file yang sesuai lalu coba lagi.");
    expect(friendlyLessonError(new ApiError({ message: "Invalid", status: 422, errors: { purpose: ["validation.in"] } }))).toBe("File tidak cocok dengan jenis materi. Pilih file yang sesuai lalu coba lagi.");
  });

  it("keeps old attachment when replacement update fails", () => {
    expect(attachmentAfterReplacement("old-media", "new-media", false)).toBe("old-media");
    expect(attachmentAfterReplacement("old-media", "new-media", true)).toBe("new-media");
  });
});
