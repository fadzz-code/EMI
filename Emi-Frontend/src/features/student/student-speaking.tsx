import Link from "next/link";

import { Badge, Card, CardContent, CardHeader, PageHeader } from "@/components/ui";

const speakingSections = [
  {
    title: "Pilih Latihan",
    description: "Daftar kosakata dan kalimat latihan akan tersedia setelah backend speaking aktif.",
  },
  {
    title: "Latihan Pelafalan",
    description: "Panduan pengucapan Bahasa Mekongga akan ditampilkan sebagai latihan bertahap.",
  },
  {
    title: "Rekam Suara",
    description: "Perekaman suara belum diaktifkan. Halaman ini tidak meminta akses mikrofon.",
  },
  {
    title: "Hasil Terakhir",
    description: "Skor dan catatan latihan terakhir akan muncul saat fitur penilaian tersedia.",
  },
];

export function StudentSpeaking() {
  return (
    <div className="grid gap-6">
      <PageHeader badge="Segera tersedia" description="Latih pelafalan kosakata Bahasa Mekongga melalui latihan berbicara." title="Latihan Speaking" />

      <section className="grid gap-4 md:grid-cols-2">
        {speakingSections.map((section) => (
          <Card key={section.title}>
            <CardHeader>
              <div className="flex items-start justify-between gap-3">
                <h2 className="text-xl font-black text-ink">{section.title}</h2>
                <Badge tone="yellow">Segera tersedia</Badge>
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-sm leading-6 text-slate-600">{section.description}</p>
            </CardContent>
          </Card>
        ))}
      </section>

      <Card>
        <CardContent>
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <h2 className="text-xl font-black text-ink">Riwayat latihan speaking</h2>
              <p className="mt-2 text-sm text-slate-600">Belum ada hasil speaking karena fitur penilaian belum aktif.</p>
            </div>
            <Link className="inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-ink bg-blue-600 px-4 py-2 text-sm font-black text-white shadow-brutal hover:bg-blue-700" href="/student/speaking/results">
              Lihat Hasil Speaking
            </Link>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
