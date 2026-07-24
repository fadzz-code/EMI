import { describe, expect, it } from "vitest";

import {
  canPublishModule,
  INVALID_MEDIA_TYPE_MESSAGE,
  isValidMediaFile,
  mediaUploadSuccessMessage,
  newModuleDraft,
  PUBLIC_MEDIA_VISIBILITY,
} from "./module-workflow";

describe("admin module workflow", () => {
  it("always creates a friendly draft", () => {
    expect(newModuleDraft()).toEqual({ title: "Modul Baru", status: "draft" });
  });

  it("requires at least one published lesson before publishing", () => {
    expect(canPublishModule([])).toBe(false);
    expect(canPublishModule([{ status: "draft" }])).toBe(false);
    expect(canPublishModule([{ status: "published" }])).toBe(true);
  });

  it("keeps lesson media public internally", () => {
    expect(PUBLIC_MEDIA_VISIBILITY).toBe("public");
  });

  it("accepts only media matching the selected content type", () => {
    expect(isValidMediaFile("image", { name: "materi.png", type: "image/png" })).toBe(true);
    expect(isValidMediaFile("audio", { name: "materi.pdf", type: "application/pdf" })).toBe(false);
    expect(isValidMediaFile("pdf", { name: "materi.pdf", type: "" })).toBe(true);
    expect(INVALID_MEDIA_TYPE_MESSAGE).toBe("Jenis file tidak sesuai dengan tujuan unggahan.");
  });

  it("returns the requested upload success messages", () => {
    expect(mediaUploadSuccessMessage("image")).toBe("Media gambar berhasil diunggah.");
    expect(mediaUploadSuccessMessage("pdf")).toBe("Media PDF berhasil diunggah.");
    expect(mediaUploadSuccessMessage("audio")).toBe("Media audio berhasil diunggah.");
  });
});
