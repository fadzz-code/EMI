import { describe, expect, it } from "vitest";

import { shouldUseMicrophone, speakingResult } from "./speaking-result";

describe("speaking result helpers", () => {
  it("hardware mode never selects microphone path", () => expect(shouldUseMicrophone("esp32")).toBe(false));
  it("microphone mode selects microphone path", () => expect(shouldUseMicrophone("microphone")).toBe(true));
  it("returns completed score transcription alignment and warnings", () => expect(speakingResult({
    id: "1", exercise_id: "e", target_text: "ari", status: "completed", ai_score: 88,
    ai_transcription: "ari", ai_alignment: [{ operation: "equal", target: "ari", transcription: "ari" }], ai_warnings: ["Perkiraan"],
  })).toEqual({ score: "88/100", transcription: "ari", alignment: [{ operation: "equal", target: "ari", transcription: "ari" }], warnings: ["Perkiraan"], failure: null }));
  it("returns friendly failed reason", () => expect(speakingResult({ id: "1", exercise_id: "e", target_text: "ari", status: "failed" }).failure).toContain("Analisis belum berhasil"));
  it("returns backend failed reason", () => expect(speakingResult({ id: "1", exercise_id: "e", target_text: "ari", status: "failed", ai_error: "Coba ulang" }).failure).toBe("Coba ulang"));
  it("formats absent score", () => expect(speakingResult({ id: "1", exercise_id: "e", target_text: "ari", status: "pending" }).score).toBe("-"));
});
