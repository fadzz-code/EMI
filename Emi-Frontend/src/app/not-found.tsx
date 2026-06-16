import Link from "next/link";

export default function NotFound() {
  return (
    <main className="grid min-h-screen place-items-center bg-paper px-4">
      <section className="w-full max-w-md rounded-lg border-2 border-ink bg-white p-6 text-center shadow-brutal">
        <h1 className="text-3xl font-black text-ink">Halaman tidak ditemukan</h1>
        <p className="mt-3 text-sm text-slate-600">
          Route ini belum masuk scope implementasi awal Fase 9.
        </p>
        <Link
          className="mt-5 inline-flex rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-black text-ink shadow-brutal"
          href="/"
        >
          Kembali
        </Link>
      </section>
    </main>
  );
}
