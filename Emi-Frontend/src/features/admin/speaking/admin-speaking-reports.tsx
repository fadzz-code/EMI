"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";

import { Card, CardContent, CardHeader, EmptyState, ErrorState, Input, Pagination, Select, Table, TableCell, TableHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { formatNumber } from "@/features/admin/progress/progress-utils";

import { adminSpeakingService } from "./speaking-service";

function score(value: number | null) {
  return value === null ? "Belum tersedia" : new Intl.NumberFormat("id-ID", { maximumFractionDigits: 2 }).format(value);
}

export function AdminSpeakingReports() {
  const { token } = useAuth();
  const [studentPage, setStudentPage] = useState(1);
  const [classPage, setClassPage] = useState(1);
  const [schoolId, setSchoolId] = useState("");
  const [classId, setClassId] = useState("");
  const [analysisStatus, setAnalysisStatus] = useState("");
  const [reviewStatus, setReviewStatus] = useState("");
  const filters = { school_id: schoolId, class_id: classId, analysis_status: analysisStatus, review_status: reviewStatus };
  const studentsQuery = useQuery({ queryKey: ["admin", "speaking", "reports", "students", filters, studentPage], queryFn: () => adminSpeakingService.studentReports(token ?? "", { ...filters, page: studentPage }), enabled: Boolean(token) });
  const classesQuery = useQuery({ queryKey: ["admin", "speaking", "reports", "classes", filters, classPage], queryFn: () => adminSpeakingService.classReports(token ?? "", { ...filters, page: classPage }), enabled: Boolean(token) });

  return <section className="grid gap-6">
    <Card><CardHeader><h2 className="text-xl font-black text-ink">Laporan Speaking</h2></CardHeader><CardContent><div className="grid gap-3 md:grid-cols-4"><Input aria-label="ID sekolah" onChange={(event) => { setSchoolId(event.target.value); setStudentPage(1); setClassPage(1); }} placeholder="ID sekolah" value={schoolId} /><Input aria-label="ID kelas" onChange={(event) => { setClassId(event.target.value); setStudentPage(1); setClassPage(1); }} placeholder="ID kelas" value={classId} /><Select aria-label="Status analisis" onChange={(event) => { setAnalysisStatus(event.target.value); setStudentPage(1); setClassPage(1); }} value={analysisStatus}><option value="">Semua status analisis</option><option value="pending">Pending</option><option value="processing">Processing</option><option value="completed">Completed</option><option value="failed">Failed</option></Select><Select aria-label="Status review" onChange={(event) => { setReviewStatus(event.target.value); setStudentPage(1); setClassPage(1); }} value={reviewStatus}><option value="">Semua status review</option><option value="pending">Pending</option><option value="reviewed">Reviewed</option></Select></div></CardContent></Card>
    <ReportTable error={studentsQuery.error} loading={studentsQuery.isLoading} onRetry={() => void studentsQuery.refetch()} title="Per Siswa" empty={studentsQuery.data?.items.length === 0} pagination={<Pagination onPageChange={setStudentPage} page={studentsQuery.data?.meta?.current_page ?? studentPage} totalPages={studentsQuery.data?.meta?.last_page ?? 1} />}><Table><TableHeader><tr><th className="px-4 py-3">Siswa</th><th className="px-4 py-3">Attempt</th><th className="px-4 py-3">Dianalisis</th><th className="px-4 py-3">Direview</th><th className="px-4 py-3">Rata-rata AI</th><th className="px-4 py-3">Rata-rata Guru</th></tr></TableHeader><tbody>{studentsQuery.data?.items.map((row) => <tr key={row.student_id}><TableCell>{row.full_name}</TableCell><TableCell>{formatNumber(row.attempt_count)}</TableCell><TableCell>{formatNumber(row.analyzed_attempts)}</TableCell><TableCell>{formatNumber(row.reviewed_attempts)}</TableCell><TableCell>{score(row.average_ai_score)}</TableCell><TableCell>{score(row.average_teacher_score)}</TableCell></tr>)}</tbody></Table></ReportTable>
    <ReportTable error={classesQuery.error} loading={classesQuery.isLoading} onRetry={() => void classesQuery.refetch()} title="Per Kelas" empty={classesQuery.data?.items.length === 0} pagination={<Pagination onPageChange={setClassPage} page={classesQuery.data?.meta?.current_page ?? classPage} totalPages={classesQuery.data?.meta?.last_page ?? 1} />}><Table><TableHeader><tr><th className="px-4 py-3">Kelas</th><th className="px-4 py-3">Sekolah</th><th className="px-4 py-3">Attempt</th><th className="px-4 py-3">Siswa</th><th className="px-4 py-3">Rata-rata AI</th><th className="px-4 py-3">Rata-rata Guru</th></tr></TableHeader><tbody>{classesQuery.data?.items.map((row) => <tr key={row.class_id}><TableCell>{row.class_name}</TableCell><TableCell>{row.school_name}</TableCell><TableCell>{formatNumber(row.attempt_count)}</TableCell><TableCell>{formatNumber(row.participating_students)}</TableCell><TableCell>{score(row.average_ai_score)}</TableCell><TableCell>{score(row.average_teacher_score)}</TableCell></tr>)}</tbody></Table></ReportTable>
  </section>;
}

function ReportTable({ children, empty, error, loading, onRetry, pagination, title }: { children: React.ReactNode; empty: boolean; error: Error | null; loading: boolean; onRetry: () => void; pagination: React.ReactNode; title: string }) {
  return <Card><CardHeader><h2 className="text-xl font-black text-ink">{title}</h2></CardHeader><CardContent>{error ? <ErrorState description={getFirstApiError(error)} onRetry={onRetry} title={`Gagal memuat laporan ${title.toLowerCase()}`} /> : loading ? <p className="font-bold text-muted">Memuat laporan...</p> : empty ? <EmptyState description="Belum ada data speaking sesuai filter." title="Laporan kosong" /> : <div className="grid gap-4">{children}{pagination}</div>}</CardContent></Card>;
}
