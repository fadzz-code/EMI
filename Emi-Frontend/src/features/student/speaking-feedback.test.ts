import { describe, expect, it } from "vitest";

import { aiConfidence, charDiff, scoreLevel, speakingTips, wordPairs } from "./speaking-feedback";

describe("charDiff", () => {
  it("marks all chars ok when identical", () => {
    const { target, detected } = charDiff("mekongga", "mekongga");
    expect(target.every((c) => c.ok)).toBe(true);
    expect(detected.every((c) => c.ok)).toBe(true);
  });
  it("highlights substitution e -> o", () => {
    const { target, detected } = charDiff("mekongga", "mokongga");
    expect(target.filter((c) => !c.ok).map((c) => c.char).join("")).toBe("e");
    expect(detected.filter((c) => !c.ok).map((c) => c.char).join("")).toBe("o");
  });
  it("handles insertion and deletion", () => {
    expect(charDiff("abc", "abcd").detected.filter((c) => !c.ok).map((c) => c.char).join("")).toBe("d");
    expect(charDiff("abcd", "abc").target.filter((c) => !c.ok).map((c) => c.char).join("")).toBe("d");
  });
});

describe("wordPairs", () => {
  it("uses backend alignment ops when available", () => {
    const pairs = wordPairs({
      target_text: "ari tolaki",
      ai_transcription: "ari tolake",
      ai_alignment: [
        { operation: "equal", target: "ari", transcription: "ari" },
        { operation: "substitute", target: "tolaki", transcription: "tolake" },
      ],
    });
    expect(pairs).toHaveLength(2);
    expect(pairs[0].target.every((c) => c.ok)).toBe(true);
    expect(pairs[1].target.filter((c) => !c.ok).map((c) => c.char).join("")).toBe("i");
  });
  it("falls back to char diff without alignment", () => {
    const pairs = wordPairs({ target_text: "mekongga", ai_transcription: "mokongga", ai_alignment: null });
    expect(pairs).toHaveLength(1);
  });
  it("returns empty when no transcription", () => {
    expect(wordPairs({ target_text: "ari", ai_transcription: null, ai_alignment: null })).toEqual([]);
  });
});

describe("aiConfidence", () => {
  it("averages record alignment scores", () => expect(aiConfidence({ "1_me": 80, "2_kong": 100 })).toBe(90));
  it("returns null for array alignment", () => expect(aiConfidence([{ operation: "equal" }])).toBeNull());
  it("returns null for empty record", () => expect(aiConfidence({})).toBeNull());
});

describe("scoreLevel", () => {
  it("maps tiers", () => {
    expect(scoreLevel(95).label).toBe("Luar Biasa!");
    expect(scoreLevel(82).label).toBe("Bagus!");
    expect(scoreLevel(60).label).toBe("Cukup");
    expect(scoreLevel(20).label).toBe("Perlu Latihan");
    expect(scoreLevel(null).label).toBe("Belum Dinilai");
  });
});

describe("speakingTips", () => {
  it("builds substitution tip from diff", () => {
    const tips = speakingTips([charDiff("mekongga", "mokongga")]);
    expect(tips[0]).toContain('"e"');
    expect(tips[0]).toContain('"o"');
  });
  it("includes teacher feedback first", () => {
    expect(speakingTips([charDiff("a", "a")], "Ulangi vokal")[0]).toContain("Ulangi vokal");
  });
  it("praises when perfect", () => {
    expect(speakingTips([charDiff("ari", "ari")])[0]).toContain("sudah tepat");
  });
});
