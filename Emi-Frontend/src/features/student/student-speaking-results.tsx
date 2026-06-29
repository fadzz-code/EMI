import Link from "next/link";

import { Badge, Card, CardContent, CardHeader, EmptyState, PageHeader, StatsCard } from "@/components/ui";

export function StudentSpeakingResults() {
  return (
    <div className="grid gap-6">
      <PageHeader badge="Segera tersedia" description="Riwayat dan hasil latihan speaking Anda akan muncul di sini." title="Hasil Speaking" />

      <Card>
        <CardContent>
          <EmptyState
            description="Fitur penilaian speaking akan tersedia pada tahap berikutnya."
            title="Belum ada hasil speaking."
          />
        </CardContent>
      </Card>

      <section className="grid gap-4 md:grid-cols-3">
        <StatsCard helper="Belum tersedia sampai backend speaking aktif" label="Akurasi Pelafalan" value="Segera tersedia" />
        <StatsCard helper="Belum tersedia sampai backend speaking aktif" label="Kelancaran" value="Segera tersedia" />
        <StatsCard helper="Belum tersedia sampai backend speaking aktif" label="Catatan Guru" value="Segera tersedia" />
      </section>

      <Card>
        <CardHeader>
          <div className="flex items-start justify-between gap-3">
            <h2 className="text-xl font-black text-ink">Status fitur</h2>
            <Badge tone="yellow">Segera tersedia</Badge>
          </div>
        </CardHeader>
        <CardContent>
          <p className="text-sm leading-6 text-slate-600">Halaman ini tidak menampilkan skor atau riwayat palsu. Data hasil speaking akan memakai backend saat fitur tersedia.</p>
          <Link className="mt-4 inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-ink bg-white px-4 py-2 text-sm font-black text-ink shadow-brutal hover:bg-yellow-100" href="/student/speaking">
            Kembali ke Latihan Speaking
          </Link>
        </CardContent>
      </Card>
    </div>
  );
}
