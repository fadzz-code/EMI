import { describe, expect, it } from "vitest";

import { teacherStatusTone } from "./teacher-utils";

describe("teacherStatusTone", () => {
  it.each([
    ["published", "green"],
    ["draft", "yellow"],
    ["archived", "neutral"],
    [undefined, "neutral"],
  ])("maps %s to %s", (status, tone) => {
    expect(teacherStatusTone(status)).toBe(tone);
  });
});
