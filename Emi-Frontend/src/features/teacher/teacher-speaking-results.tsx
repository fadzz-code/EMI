"use client";

import Link from "next/link";

import { Badge, Card, CardContent, CardHeader, EmptyState, PageHeader } from "@/components/ui";
import { teacherRoutes } from "@/lib/routes";

export function TeacherSpeakingResults() {
  return (
    <div className="grid gap-6">
      <PageHeader badge="Placeholder" description="Endpoint backend speaking assessment untuk guru belum tersedia pada fase ini." title="Hasil Speaking" />

      <Card>
        <CardHeader>
          <div className="flex flex-wrap items-center gap-2">
            <Badge tone="yellow">Belum tersedia</Badge>
            <Badge tone="neutral">Backend endpoint belum ada</Badge>
          </div>
          <h2 className="mt-3 text-xl font-black text-ink">Hasil Speaking belum dapat ditampilkan</h2>
        </CardHeader>
        <CardContent>
          <p className="text-sm leading-6 text-slate-700">
            Hasil Speaking belum tersedia karena endpoint/backend speaking assessment belum tersedia. Halaman ini tidak memanggil API palsu dan tidak menampilkan data contoh.
          </p>
          <div className="mt-5 grid gap-3 md:grid-cols-2">
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
              <h3 className="font-black text-ink">Data yang akan tampil nanti</h3>
              <ul className="mt-2 list-disc space-y-1 pl-5 text-sm text-slate-600">
                <li>Nama siswa dan kelas</li>
                <li>Skor pelafalan dan status penilaian</li>
                <li>Rekaman/audio latihan jika backend mengembalikan media</li>
                <li>Tanggal latihan dan feedback guru/sistem</li>
              </ul>
            </div>
            <EmptyState description="Belum ada endpoint speaking result untuk guru, sehingga tidak ada data real yang bisa dimuat." title="Data speaking kosong" />
          </div>
          <div className="mt-5 flex flex-wrap gap-3">
            <Link className="rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-black text-ink shadow-brutal hover:bg-yellow-200" href={teacherRoutes.dashboard}>Dashboard</Link>
            <Link className="rounded-lg border-2 border-ink bg-white px-4 py-2 text-sm font-black text-ink hover:bg-yellow-100" href={teacherRoutes.classes}>Kelas</Link>
            <Link className="rounded-lg border-2 border-ink bg-white px-4 py-2 text-sm font-black text-ink hover:bg-yellow-100" href={teacherRoutes.progressReport}>Progress</Link>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
