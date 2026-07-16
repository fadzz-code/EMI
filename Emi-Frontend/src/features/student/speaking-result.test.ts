import { describe, expect, it } from "vitest";

import { latestSpeakingAttempt, shouldUseMicrophone, speakingResult, STUDENT_AI_GUIDANCE, studentAiWarnings, TEACHER_AI_GUIDANCE } from "./speaking-result";

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
  it("maps technical warning to friendly Indonesian guidance", () => {
    const warnings = studentAiWarnings(["Model is Indonesian STT; Mekongga pronunciation scoring is approximate."]);
    expect(warnings).toEqual([STUDENT_AI_GUIDANCE]);
    expect(warnings.join(" ")).not.toContain("Indonesian STT");
    expect(TEACHER_AI_GUIDANCE).toBe("Analisis AI merupakan penilaian awal. Guru tetap menentukan nilai akhir.");
  });
  it("selects new completed attempt instead of stale failed attempt", () => expect(latestSpeakingAttempt([
    { id: "old", exercise_id: "e", target_text: "ari", status: "failed", created_at: "2026-07-16T10:00:00Z" },
    { id: "new", exercise_id: "e", target_text: "ari", status: "completed", ai_score: 0, created_at: "2026-07-16T10:01:00Z" },
  ])).toMatchObject({ id: "new", status: "completed", ai_score: 0 }));
});
