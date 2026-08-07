import type { SpeakingAttempt } from "./types";

export type DiffChar = { char: string; ok: boolean };
export type WordPair = { target: DiffChar[]; detected: DiffChar[] };

function chars(text: string, ok: boolean): DiffChar[] {
  return [...text].map((char) => ({ char, ok }));
}

export function charDiff(target: string, detected: string): WordPair {
  const a = [...target];
  const b = [...detected];
  const m = a.length;
  const n = b.length;
  const dp: number[][] = Array.from({ length: m + 1 }, () => new Array<number>(n + 1).fill(0));
  for (let i = m - 1; i >= 0; i -= 1) {
    for (let j = n - 1; j >= 0; j -= 1) {
      dp[i][j] = a[i] === b[j] ? dp[i + 1][j + 1] + 1 : Math.max(dp[i + 1][j], dp[i][j + 1]);
    }
  }
  const targetChars: DiffChar[] = [];
  const detectedChars: DiffChar[] = [];
  let i = 0;
  let j = 0;
  while (i < m && j < n) {
    if (a[i] === b[j]) {
      targetChars.push({ char: a[i], ok: true });
      detectedChars.push({ char: b[j], ok: true });
      i += 1;
      j += 1;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      targetChars.push({ char: a[i], ok: false });
      i += 1;
    } else {
      detectedChars.push({ char: b[j], ok: false });
      j += 1;
    }
  }
  while (i < m) targetChars.push({ char: a[i++], ok: false });
  while (j < n) detectedChars.push({ char: b[j++], ok: false });
  return { target: targetChars, detected: detectedChars };
}

export function wordPairs(attempt: Pick<SpeakingAttempt, "target_text" | "ai_transcription" | "ai_alignment">): WordPair[] {
  const alignment = attempt.ai_alignment;
  if (Array.isArray(alignment) && alignment.length > 0) {
    return alignment.map((op) => {
      const target = op.target ?? "";
      const detected = op.transcription ?? "";
      if (op.operation === "equal" || (target && target === detected)) {
        return { target: chars(target, true), detected: chars(detected, true) };
      }
      if (target && detected) return charDiff(target, detected);
      return { target: chars(target, false), detected: chars(detected, false) };
    }).filter((pair) => pair.target.length > 0 || pair.detected.length > 0);
  }
  const detected = attempt.ai_transcription ?? "";
  if (!detected) return [];
  return [charDiff(attempt.target_text, detected)];
}

export function aiConfidence(alignment: SpeakingAttempt["ai_alignment"]): number | null {
  if (!alignment || Array.isArray(alignment)) return null;
  const values = Object.values(alignment).filter((value): value is number => typeof value === "number");
  if (values.length === 0) return null;
  return Math.round(values.reduce((sum, value) => sum + value, 0) / values.length);
}

export type ScoreLevel = { label: string; hint: string; cardBg: string };

export function scoreLevel(score?: number | null): ScoreLevel {
  if (score === null || score === undefined) {
    return { label: "Belum Dinilai", hint: "Skor muncul setelah analisis selesai.", cardBg: "bg-surface-muted" };
  }
  if (score >= 90) return { label: "Luar Biasa!", hint: "Pelafalanmu hampir sempurna.", cardBg: "bg-success" };
  if (score >= 70) return { label: "Bagus!", hint: "Perlu sedikit perbaikan pada vokal.", cardBg: "bg-success/40" };
  if (score >= 50) return { label: "Cukup", hint: "Beberapa bunyi perlu dilatih lagi.", cardBg: "bg-accent" };
  return { label: "Perlu Latihan", hint: "Dengarkan penutur asli, lalu coba lagi.", cardBg: "bg-danger-muted" };
}

export function speakingTips(pairs: WordPair[], teacherFeedback?: string | null): string[] {
  const tips: string[] = [];
  if (teacherFeedback) tips.push(`Feedback guru: ${teacherFeedback}`);
  const wrongTarget = pairs.flatMap((pair) => pair.target).filter((item) => !item.ok).map((item) => item.char).join("");
  const wrongDetected = pairs.flatMap((pair) => pair.detected).filter((item) => !item.ok).map((item) => item.char).join("");
  if (wrongTarget && wrongDetected) {
    tips.push(`Perhatikan bunyi "${wrongTarget}". Ucapkan "${wrongTarget}", bukan "${wrongDetected}".`);
    if (/[aiueo]/.test(wrongTarget)) tips.push("Buka mulut sedikit lebih lebar saat mengucapkan vokal.");
  } else if (wrongTarget) {
    tips.push(`Bunyi "${wrongTarget}" belum terdengar. Ucapkan lebih jelas dan perlahan.`);
  } else if (wrongDetected) {
    tips.push(`Ada bunyi tambahan "${wrongDetected}" yang tidak perlu. Ucapkan kata sesuai target.`);
  }
  if (tips.length === 0) tips.push("Pelafalanmu sudah tepat. Pertahankan dan lanjutkan ke kata berikutnya!");
  return tips.slice(0, 3);
}
