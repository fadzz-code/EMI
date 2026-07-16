import type { SpeakingAttempt } from "./types";

export function shouldUseMicrophone(source: "microphone" | "esp32") {
  return source === "microphone";
}

export function latestSpeakingAttempt(attempts: SpeakingAttempt[]) {
  return attempts.reduce<SpeakingAttempt | undefined>((latest, attempt) => {
    if (!latest) return attempt;
    const latestTime = Date.parse(latest.created_at ?? "") || 0;
    const attemptTime = Date.parse(attempt.created_at ?? "") || 0;
    return attemptTime > latestTime || (attemptTime === latestTime && attempt.id > latest.id) ? attempt : latest;
  }, undefined);
}

export function speakingResult(attempt: SpeakingAttempt) {
  return {
    score: attempt.ai_score == null ? "-" : `${attempt.ai_score}/100`,
    transcription: attempt.ai_transcription ?? null,
    alignment: attempt.ai_alignment ?? null,
    warnings: attempt.ai_warnings ?? [],
    failure: attempt.status === "failed" ? attempt.ai_error || "Analisis belum berhasil. Audio tetap tersimpan dan dapat dicoba lagi." : null,
  };
}
