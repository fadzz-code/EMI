import { StatsCard } from "@/components/ui";

import { formatNumber, formatPercent } from "./progress-utils";
import type { DashboardSummary } from "./types";

export function ProgressSummaryCards({ summary }: { summary?: DashboardSummary | null }) {
  return (
    <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
      <StatsCard
        helper="Akun siswa approved dengan membership aktif."
        label="Total Siswa Aktif"
        value={formatNumber(summary?.overview.active_students)}
      />
      <StatsCard
        helper="Rata-rata module progress backend."
        label="Rata-rata Progress Modul"
        value={formatPercent(summary?.learning.average_learning_progress_percent)}
      />
      <StatsCard
        helper="Best final attempt dari report kuis."
        label="Rata-rata Nilai Kuis"
        value={formatPercent(summary?.quizzes.average_score_percent)}
      />
      <StatsCard
        helper="Speaking report belum aktif pada backend."
        label="Latihan Speaking"
        value={summary?.capabilities.speaking_reports ? "Aktif" : "Belum tersedia"}
      />
    </section>
  );
}

export function ProgressBar({ value }: { value?: number | null }) {
  const percent = Math.max(0, Math.min(100, value ?? 0));

  return (
    <div className="grid gap-2">
      <div className="h-3 overflow-hidden rounded-full border-2 border-ink bg-white">
        <div className="h-full bg-blue-500" style={{ width: `${percent}%` }} />
      </div>
      <span className="text-xs font-black text-ink">{formatPercent(value)}</span>
    </div>
  );
}
