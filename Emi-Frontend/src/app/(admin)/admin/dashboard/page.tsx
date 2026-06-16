import { Card, CardContent, CardHeader, PageHeader, StatsCard } from "@/components/ui";

export default function AdminDashboardPage() {
  return (
    <div className="grid gap-6">
      <PageHeader
        badge="Admin"
        description="Fondasi dashboard siap mengarah ke GET /api/v1/admin/dashboard/summary."
        title="Beranda Admin"
      />
      <section className="grid gap-4 md:grid-cols-3">
        <StatsCard helper="Diambil dari summary backend." label="Sekolah" value="-" />
        <StatsCard helper="Menunggu integrasi layar detail." label="Kelas Aktif" value="-" />
        <StatsCard helper="Speaking belum aktif di Fase 9." label="Speaking" value="Nonaktif" />
      </section>
      <Card>
        <CardHeader>
          <h2 className="text-lg font-black text-ink">Prioritas Integrasi</h2>
        </CardHeader>
        <CardContent>
          <p className="text-sm leading-6 text-slate-700">
            Halaman ini adalah rangka awal. Data produksi tetap berasal dari
            Laravel REST API dan akan dihubungkan melalui TanStack Query pada
            layar dashboard berikutnya.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
