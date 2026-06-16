import Link from "next/link";

import { env } from "@/lib/env";

export function AuthLayoutShell({ children }: { children: React.ReactNode }) {
  return (
    <main className="min-h-screen bg-paper text-ink">
      <div className="mx-auto grid min-h-screen w-full max-w-6xl gap-8 px-4 py-8 lg:grid-cols-[0.9fr_1.1fr] lg:items-center">
        <section className="space-y-6">
          <Link className="inline-flex items-center gap-3 font-black text-ink" href="/">
            <span className="grid size-12 place-items-center rounded-lg border-2 border-ink bg-yellow-300 shadow-brutal">
              EMI
            </span>
            <span>{env.appName}</span>
          </Link>
          <div className="max-w-xl">
            <p className="text-sm font-black uppercase text-blue-700">Belajar Bahasa Mekongga</p>
            <h1 className="mt-3 text-4xl font-black tracking-normal text-ink md:text-5xl">
              LMS budaya lokal yang ringan, aman, dan siap bertumbuh.
            </h1>
            <p className="mt-4 text-base leading-7 text-slate-700">
              Fase awal web fokus pada autentikasi, role layout, dan fondasi
              integrasi API Laravel yang sudah selesai pada Fase 1 sampai 8.
            </p>
          </div>
        </section>
        <section>{children}</section>
      </div>
    </main>
  );
}
