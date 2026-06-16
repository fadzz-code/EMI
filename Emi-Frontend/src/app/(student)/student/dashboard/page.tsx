import { Card, CardContent, CardHeader, PageHeader, StatsCard } from "@/components/ui";

export default function StudentDashboardPage() {
  return (
    <div className="grid gap-6">
      <PageHeader
        badge="Siswa"
        description="Dashboard Siswa akan memakai GET /api/v1/student/dashboard/summary dan menghormati membership aktif."
        title="Beranda Belajar"
      />
      <section className="grid gap-4 md:grid-cols-3">
        <StatsCard helper="Dihitung backend." label="Progress Modul" value="-" />
        <StatsCard helper="Menghormati hidden result." label="Hasil Kuis" value="-" />
        <StatsCard helper="Belum dikerjakan." label="Speaking" value="Nonaktif" />
      </section>
      <Card>
        <CardHeader>
          <h2 className="text-lg font-black text-ink">Lanjut Belajar</h2>
        </CardHeader>
        <CardContent>
          <p className="text-sm leading-6 text-slate-700">
            Modul, lesson, progress, dan kuis akan dihubungkan ke endpoint Fase
            6 sampai 8 setelah fondasi auth dan layout stabil.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
