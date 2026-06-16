import { Card, CardContent, CardHeader, EmptyState, PageHeader, StatsCard } from "@/components/ui";

export default function TeacherDashboardPage() {
  return (
    <div className="grid gap-6">
      <PageHeader
        badge="Guru"
        description="Dashboard Guru akan memakai GET /api/v1/teacher/dashboard/summary dan dibatasi assignment aktif."
        title="Beranda Kelas"
      />
      <section className="grid gap-4 md:grid-cols-3">
        <StatsCard helper="Scope dari assignment aktif." label="Kelas" value="-" />
        <StatsCard helper="Dihitung backend." label="Progress Rata-rata" value="-" />
        <StatsCard helper="Report speaking belum tersedia." label="Speaking" value="Nonaktif" />
      </section>
      <Card>
        <CardHeader>
          <h2 className="text-lg font-black text-ink">Status Kelas</h2>
        </CardHeader>
        <CardContent>
          <EmptyState
            description="Jika Guru belum memiliki assignment aktif, backend akan mengembalikan data kosong sesuai aturan Fase 3."
            title="Belum ada data kelas ditampilkan"
          />
        </CardContent>
      </Card>
    </div>
  );
}
