import { StatsCard } from "@/components/ui";

import { formatNumber, formatPercent } from "./progress-utils";
import type { DashboardSummary, ProgressSummary } from "./types";

export function ProgressSummaryCards({ summary }: { summary?: DashboardSummary | ProgressSummary | null }) {
  const activeStudents = summary && "overview" in summary ? summary.overview.active_students : summary?.active_students;
  const moduleProgress = summary && "learning" in summary ? summary.learning.average_learning_progress_percent : summary?.average_module_progress_percent;
  const quizScore = summary && "quizzes" in summary ? summary.quizzes.average_score_percent : summary?.average_best_final_quiz_score_percent;
  const speakingReports = summary && "capabilities" in summary ? summary.capabilities.speaking_reports : false;
  return (
    <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
      <StatsCard
        helper="Akun siswa approved dengan membership aktif."
        label="Total Siswa Aktif"
        value={formatNumber(activeStudents)}
      />
      <StatsCard
        helper="Rata-rata module progress backend."
        label="Rata-rata Progress Modul"
        value={formatPercent(moduleProgress)}
      />
      <StatsCard
        helper="Best final attempt dari report kuis."
        label="Rata-rata Nilai Kuis"
        value={formatPercent(quizScore)}
      />
      <StatsCard
        helper="Speaking report belum aktif pada backend."
        label="Latihan Speaking"
        value={speakingReports ? "Aktif" : "Belum tersedia"}
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
