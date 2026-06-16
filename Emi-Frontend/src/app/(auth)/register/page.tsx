import Link from "next/link";

import { Card, CardContent, CardHeader } from "@/components/ui";

export default function RegisterPage() {
  return (
    <Card>
      <CardHeader>
        <h2 className="text-2xl font-black text-ink">Pilih jenis akun</h2>
        <p className="mt-2 text-sm text-slate-600">
          Admin menyetujui pendaftaran Guru dan Siswa sebelum akun dapat login.
        </p>
      </CardHeader>
      <CardContent>
        <div className="grid gap-4 sm:grid-cols-2">
          <Link
            className="rounded-lg border-2 border-ink bg-yellow-200 p-5 font-black text-ink shadow-brutal transition hover:bg-yellow-100"
            href="/register/teacher"
          >
            Daftar Guru
          </Link>
          <Link
            className="rounded-lg border-2 border-ink bg-blue-100 p-5 font-black text-ink shadow-brutal transition hover:bg-blue-50"
            href="/register/student"
          >
            Daftar Siswa
          </Link>
        </div>
        <p className="mt-6 text-sm font-medium text-slate-700">
          Sudah punya akun?{" "}
          <Link className="font-black text-blue-700 underline" href="/login">
            Masuk
          </Link>
        </p>
      </CardContent>
    </Card>
  );
}
