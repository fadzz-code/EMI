import { formatCount, formatDate, formatOptional, formatPercent, statusLabel } from "./teacher-utils";
import type { TeacherProgressClassSummary, TeacherProgressStudentRow, TeacherQuizResultRow } from "./types";

function printedAt() {
  return new Intl.DateTimeFormat("id-ID", {
    dateStyle: "full",
    timeStyle: "short",
  }).format(new Date());
}

function ReportShell({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section aria-hidden className="progress-print-area">
      <PrintStyles />
      <header className="print-header">
        <p className="print-kicker">EMI — E-Learning Mekongga Indonesia</p>
        <h1>{title}</h1>
        <p>Tanggal cetak: {printedAt()}</p>
      </header>
      {children}
      <footer className="print-footer">Dicetak dari Guru EMI</footer>
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

export function TeacherStudentPrintReport({
  student,
  className,
  quizRows,
}: {
  student?: TeacherProgressStudentRow | null;
  className?: string | null;
  quizRows: TeacherQuizResultRow[];
}) {
  return (
    <ReportShell title="Rapor Progress Siswa">
      <h2>Identitas Siswa</h2>
      <div className="print-summary">
        <SummaryItem label="Nama" value={formatOptional(student?.full_name)} />
        <SummaryItem label="Email" value={formatOptional(student?.email)} />
        <SummaryItem label="Kelas" value={formatOptional(className ?? student?.class?.name)} />
        <SummaryItem label="Status akun" value={statusLabel(student?.student_status)} />
      </div>

      <h2>Ringkasan Progress</h2>
      <div className="print-summary">
        <SummaryItem label="Progress modul" value={formatPercent(student?.overall_learning_progress_percent)} />
        <SummaryItem label="Modul selesai" value={`${formatCount(student?.completed_modules)} dari ${formatCount(student?.published_modules)}`} />
        <SummaryItem label="Kuis selesai" value={`${formatCount(student?.quizzes_completed)} dari ${formatCount(student?.published_quizzes)}`} />
      </div>

      <h2>Riwayat Kuis</h2>
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
                <td>{statusLabel(row.latest_status)}</td>
                <td>{formatDate(row.latest_submitted_at)}</td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </ReportShell>
  );
}

export function TeacherClassProgressPrintReport({
  className,
  summary,
  students,
}: {
  className?: string | null;
  summary?: TeacherProgressClassSummary | null;
  students: TeacherProgressStudentRow[];
}) {
  return (
    <ReportShell title="Laporan Progress Kelas">
      <h2>Identitas Kelas</h2>
      <div className="print-summary">
        <SummaryItem label="Nama kelas" value={formatOptional(className)} />
        <SummaryItem label="Jumlah siswa" value={formatCount(summary?.active_students)} />
        <SummaryItem label="Siswa belum mulai" value={formatCount(summary?.not_started_students)} />
      </div>

      <h2>Ringkasan Progress Kelas</h2>
      <div className="print-summary">
        <SummaryItem label="Rata-rata progress modul" value={formatPercent(summary?.average_module_progress_percent)} />
        <SummaryItem label="Rata-rata nilai kuis" value={formatPercent(summary?.average_best_final_quiz_score_percent)} />
        <SummaryItem label="Siswa selesai modul" value={formatCount(summary?.completed_students)} />
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
          </tr>
        </thead>
        <tbody>
          {students.length === 0 ? (
            <tr>
              <td colSpan={5}>Belum ada data progress siswa di kelas ini.</td>
            </tr>
          ) : (
            students.map((student, index) => (
              <tr key={student.student_id}>
                <td>{index + 1}</td>
                <td>{student.full_name}</td>
                <td>{formatPercent(student.overall_learning_progress_percent)}</td>
                <td>{formatPercent(student.average_best_quiz_score_percent)}</td>
                <td>
                  {formatCount(student.quizzes_completed)}/{formatCount(student.published_quizzes)}
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </ReportShell>
  );
}
