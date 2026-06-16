import Link from "next/link";

import { Alert, Card, CardContent, CardHeader } from "@/components/ui";

export default function PendingApprovalPage() {
  return (
    <Card>
      <CardHeader>
        <h2 className="text-2xl font-black text-ink">Menunggu Persetujuan</h2>
        <p className="mt-2 text-sm text-slate-600">
          Pendaftaran berhasil dikirim dan akan diperiksa Admin EMI.
        </p>
      </CardHeader>
      <CardContent>
        <Alert tone="warning">
          Akun pending belum menerima token login. Silakan masuk kembali setelah
          disetujui Admin.
        </Alert>
        <Link
          className="mt-5 inline-flex rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-black text-ink shadow-brutal"
          href="/login"
        >
          Ke Halaman Login
        </Link>
      </CardContent>
    </Card>
  );
}
