import { describe, expect, it } from "vitest";

import { cultureFileMatches, cultureFields, cultureMediaAccept, cultureTypeTransition } from "./culture-content";

describe("culture content contract", () => {
  it("keeps only field allowed by content type", () => {
    expect(cultureFields("video", "media-1", "https://stale.test")).toEqual({ media_id: "media-1", external_url: null });
    expect(cultureFields("link", "stale-media", "https://example.test")).toEqual({ media_id: null, external_url: "https://example.test" });
  });

  it("clears stale fields on type transition", () => {
    expect(cultureTypeTransition("image", "video", "old-media")).toEqual({ file: null, mediaId: null, externalUrl: "" });
    expect(cultureTypeTransition("link", "image", null)).toEqual({ file: null, mediaId: null, externalUrl: "" });
    expect(cultureTypeTransition("image", "image", "current-media").mediaId).toBe("current-media");
  });

  it("accepts canonical safe local video formats", () => {
    expect(cultureFileMatches("video", { type: "video/mp4" })).toBe(true);
    expect(cultureFileMatches("video", { type: "video/webm" })).toBe(true);
    expect(cultureFileMatches("video", { type: "video/quicktime" })).toBe(false);
    expect(cultureMediaAccept("video")).toBe("video/mp4,video/webm");
  });
});
