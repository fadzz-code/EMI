import Link from "next/link";

import { Card, CardContent, CardHeader } from "@/components/ui";

export default function UnauthorizedPage() {
  return (
    <main className="grid min-h-screen place-items-center bg-paper px-4 py-10">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <h1 className="text-2xl font-black text-ink">Akses Ditolak</h1>
          <p className="mt-2 text-sm text-slate-600">
            Role akun Anda tidak memiliki izin untuk membuka halaman ini.
          </p>
        </CardHeader>
        <CardContent>
          <Link
            className="inline-flex rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-black text-ink shadow-brutal"
            href="/"
          >
            Kembali ke Beranda
          </Link>
        </CardContent>
      </Card>
    </main>
  );
}
