import type { ManagedUser, SchoolClass } from "@/features/admin/management/types";
import { userStatusLabel } from "@/features/admin/management/management-utils";

import {
  formatDateTime,
  formatNumber,
  formatPercent,
  latestActivity,
  learningStatus,
  learningStatusLabel,
} from "./progress-utils";
import type {
  DashboardSummary,
  QuizResultRow,
  StudentProgressRow,
} from "./types";

type FilterLine = {
  label: string;
  value?: string | null;
};

function printedAt() {
  return new Intl.DateTimeFormat("id-ID", {
    dateStyle: "full",
    timeStyle: "short",
  }).format(new Date());
}

function unavailable(value?: string | number | null) {
  if (value === null || value === undefined || value === "") {
    return "-";
  }

  return value;
}

function ReportShell({
  title,
  filters,
  children,
}: {
  title: string;
  filters?: FilterLine[];
  children: React.ReactNode;
}) {
  return (
    <section aria-hidden className="progress-print-area">
      <PrintStyles />
      <header className="print-header">
        <p className="print-kicker">EMI — E-Learning Mekongga Indonesia</p>
        <h1>{title}</h1>
        <p>Tanggal cetak: {printedAt()}</p>
        {filters && filters.length > 0 ? (
          <div className="print-filters">
            {filters.map((filter) => (
              <span key={filter.label}>
                {filter.label}: <strong>{unavailable(filter.value)}</strong>
              </span>
            ))}
          </div>
        ) : null}
      </header>
      {children}
      <footer className="print-footer">Dicetak dari Admin EMI</footer>
    </section>
  );
}

function PrintStyles() {
  return (
    <style>{`
      .progress-print-area {
        display: none;
      }

      @media print {
        @page {
          size: A4;
          margin: 14mm;
        }

        body * {
          visibility: hidden !important;
        }

        .progress-print-area,
        .progress-print-area * {
          visibility: visible !important;
        }

        .progress-print-area {
          background: #ffffff !important;
          color: #111111 !important;
          display: block !important;
          font-family: Arial, sans-serif;
          font-size: 10px;
          left: 0;
          line-height: 1.35;
          padding: 0;
          position: absolute;
          top: 0;
          width: 100%;
        }

        .progress-print-area h1 {
          font-size: 22px;
          margin: 4px 0 6px;
        }

        .progress-print-area h2 {
          border-bottom: 1px solid #111111;
          font-size: 14px;
          margin: 18px 0 8px;
          padding-bottom: 4px;
        }

        .print-kicker {
          font-size: 11px;
          font-weight: 700;
          margin: 0;
        }

        .print-header {
          border-bottom: 2px solid #111111;
          margin-bottom: 12px;
          padding-bottom: 10px;
        }

        .print-header p {
          margin: 2px 0;
        }

        .print-filters {
          display: grid;
          gap: 3px;
          grid-template-columns: repeat(2, minmax(0, 1fr));
          margin-top: 8px;
        }

        .print-summary {
          display: grid;
          gap: 6px;
          grid-template-columns: repeat(3, minmax(0, 1fr));
          margin-bottom: 12px;
        }

        .print-summary div {
          border: 1px solid #111111;
          padding: 7px;
        }

        .print-summary span {
          display: block;
          font-size: 9px;
          font-weight: 700;
          text-transform: uppercase;
        }

        .print-summary strong {
          display: block;
          font-size: 15px;
          margin-top: 3px;
        }

        .print-table {
          border-collapse: collapse;
          page-break-inside: auto;
          width: 100%;
        }

        .print-table th,
        .print-table td {
          border: 1px solid #111111;
          padding: 5px;
          text-align: left;
          vertical-align: top;
        }

        .print-table th {
          background: #eeeeee !important;
          font-weight: 700;
        }

        .print-table tr {
          page-break-inside: avoid;
        }

        .print-note {
          border: 1px solid #111111;
          margin-top: 10px;
          padding: 8px;
        }

        .print-footer {
          border-top: 1px solid #111111;
          font-size: 9px;
          margin-top: 16px;
          padding-top: 6px;
        }
      }
    `}</style>
  );
}

function SummaryItem({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div>
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

export function ProgressOverviewPrintReport({
  summary,
  students,
  filters,
}: {
  summary?: DashboardSummary | null;
  students: StudentProgressRow[];
  filters: FilterLine[];
}) {
  const completedQuizCount = students.reduce((total, student) => total + student.quizzes_completed, 0);

  return (
    <ReportShell filters={filters} title="Laporan Progress Siswa">
      <h2>Ringkasan</h2>
      <div className="print-summary">
        <SummaryItem label="Total siswa" value="Belum tersedia" />
        <SummaryItem label="Siswa aktif" value={formatNumber(summary?.overview.active_students)} />
        <SummaryItem
          label="Rata-rata progress modul"
          value={formatPercent(summary?.learning.average_learning_progress_percent)}
        />
        <SummaryItem
          label="Rata-rata nilai kuis"
          value={formatPercent(summary?.quizzes.average_score_percent)}
        />
        <SummaryItem label="Kuis selesai" value={formatNumber(completedQuizCount)} />
        <SummaryItem
          label="Speaking"
          value={summary?.capabilities.speaking_reports ? "Aktif" : "Belum tersedia"}
        />
      </div>

      <h2>Tabel Progress Siswa</h2>
      <table className="print-table">
        <thead>
          <tr>
            <th>No</th>
            <th>Nama siswa</th>
            <th>Email</th>
            <th>Sekolah</th>
            <th>Kelas</th>
            <th>Progress modul</th>
            <th>Rata-rata nilai kuis</th>
            <th>Kuis selesai</th>
            <th>Status belajar</th>
            <th>Aktivitas terakhir</th>
          </tr>
        </thead>
        <tbody>
          {students.length === 0 ? (
            <tr>
              <td colSpan={10}>Belum ada data progress siswa sesuai filter.</td>
            </tr>
          ) : (
            students.map((student, index) => (
              <tr key={student.student_id}>
                <td>{index + 1}</td>
                <td>{student.full_name}</td>
                <td>-</td>
                <td>{student.school.name}</td>
                <td>{student.class.name}</td>
                <td>{formatPercent(student.overall_learning_progress_percent)}</td>
                <td>{formatPercent(student.average_best_quiz_score_percent)}</td>
                <td>
                  {student.quizzes_completed}/{student.published_quizzes}
                </td>
                <td>{learningStatusLabel(learningStatus(student))}</td>
                <td>{formatDateTime(latestActivity(student))}</td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </ReportShell>
  );
}

export function ClassProgressPrintReport({
  schoolClass,
  summary,
  students,
  completedStudents,
  notStartedStudents,
}: {
  schoolClass?: SchoolClass | null;
  summary?: DashboardSummary | null;
  students: StudentProgressRow[];
  completedStudents?: number | null;
  notStartedStudents?: number | null;
}) {
  return (
    <ReportShell title="Laporan Progress Kelas">
      <h2>Identitas Kelas</h2>
      <div className="print-summary">
        <SummaryItem label="Nama kelas" value={unavailable(schoolClass?.name)} />
        <SummaryItem label="Sekolah" value={unavailable(schoolClass?.school?.name)} />
        <SummaryItem label="Tahun ajaran" value={unavailable(schoolClass?.academic_year)} />
        <SummaryItem
          label="Guru"
          value={unavailable(schoolClass?.active_teacher_assignment?.teacher?.full_name)}
        />
        <SummaryItem label="Jumlah siswa" value={formatNumber(summary?.overview.active_students)} />
        <SummaryItem label="Siswa belum mulai" value={formatNumber(notStartedStudents)} />
      </div>

      <h2>Ringkasan Progress Kelas</h2>
      <div className="print-summary">
        <SummaryItem
          label="Rata-rata progress modul"
          value={formatPercent(summary?.learning.average_learning_progress_percent)}
        />
        <SummaryItem
          label="Rata-rata nilai kuis"
          value={formatPercent(summary?.quizzes.average_score_percent)}
        />
        <SummaryItem label="Siswa selesai modul" value={formatNumber(completedStudents)} />
      </div>

      <h2>Tabel Siswa</h2>
      <table className="print-table">
        <thead>
          <tr>
            <th>No</th>
            <th>Nama siswa</th>
            <th>Progress modul</th>
            <th>Nilai kuis</th>
            <th>Kuis selesai</th>
            <th>Status belajar</th>
          </tr>
        </thead>
        <tbody>
          {students.length === 0 ? (
            <tr>
              <td colSpan={6}>Belum ada data progress siswa di kelas ini.</td>
            </tr>
          ) : (
            students.map((student, index) => (
              <tr key={student.student_id}>
                <td>{index + 1}</td>
                <td>{student.full_name}</td>
                <td>{formatPercent(student.overall_learning_progress_percent)}</td>
                <td>{formatPercent(student.average_best_quiz_score_percent)}</td>
                <td>
                  {student.quizzes_completed}/{student.published_quizzes}
                </td>
                <td>{learningStatusLabel(learningStatus(student))}</td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </ReportShell>
  );
}

export function StudentProgressPrintReport({
  user,
  progress,
  quizRows,
}: {
  user?: ManagedUser | null;
  progress?: StudentProgressRow | null;
  quizRows: QuizResultRow[];
}) {
  const status = progress ? learningStatus(progress) : null;

  return (
    <ReportShell title="Laporan Progress Siswa">
      <h2>Identitas Siswa</h2>
      <div className="print-summary">
        <SummaryItem label="Nama" value={unavailable(user?.full_name)} />
        <SummaryItem label="Email" value={unavailable(user?.email)} />
        <SummaryItem label="Sekolah" value={unavailable(user?.active_school?.name)} />
        <SummaryItem label="Kelas" value={unavailable(user?.active_class?.name)} />
        <SummaryItem label="Status akun" value={userStatusLabel(user?.status)} />
        <SummaryItem label="Status belajar" value={learningStatusLabel(status)} />
      </div>

      <h2>Progress Modul</h2>
      <div className="print-summary">
        <SummaryItem
          label="Progress modul"
          value={formatPercent(progress?.overall_learning_progress_percent)}
        />
        <SummaryItem
          label="Modul selesai"
          value={
            progress
              ? `${progress.completed_modules}/${progress.published_modules}`
              : "Belum tersedia"
          }
        />
        <SummaryItem
          label="Pelajaran selesai"
          value={
            progress
              ? `${progress.completed_lessons}/${progress.total_published_lessons}`
              : "Belum tersedia"
          }
        />
        <SummaryItem
          label="Rata-rata nilai kuis"
          value={formatPercent(progress?.average_best_quiz_score_percent)}
        />
        <SummaryItem
          label="Kuis selesai"
          value={
            progress
              ? `${progress.quizzes_completed}/${progress.published_quizzes}`
              : "Belum tersedia"
          }
        />
        <SummaryItem
          label="Aktivitas terakhir"
          value={formatDateTime(progress ? latestActivity(progress) : null)}
        />
      </div>

      <h2>Riwayat Kuis / Attempt</h2>
      <table className="print-table">
        <thead>
          <tr>
            <th>No</th>
            <th>Kuis</th>
            <th>Attempt</th>
            <th>Nilai terbaik</th>
            <th>Status terakhir</th>
            <th>Submit terakhir</th>
          </tr>
        </thead>
        <tbody>
          {quizRows.length === 0 ? (
            <tr>
              <td colSpan={6}>Belum ada riwayat kuis untuk siswa ini.</td>
            </tr>
          ) : (
            quizRows.map((row, index) => (
              <tr key={row.quiz.id}>
                <td>{index + 1}</td>
                <td>{row.quiz.title}</td>
                <td>
                  {row.attempt_count}
                  {row.best_attempt_number ? `, terbaik #${row.best_attempt_number}` : ""}
                </td>
                <td>{formatPercent(row.best_score_percent)}</td>
                <td>{row.latest_status ?? "Belum mulai"}</td>
                <td>{formatDateTime(row.latest_submitted_at)}</td>
              </tr>
            ))
          )}
        </tbody>
      </table>

      <div className="print-note">
        Speaking report belum aktif di backend fase ini, sehingga riwayat speaking tidak
        ditampilkan sebagai data palsu.
      </div>
    </ReportShell>
  );
}
