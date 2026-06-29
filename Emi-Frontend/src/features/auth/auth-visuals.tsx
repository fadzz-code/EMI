import Link from "next/link";
import type { ReactNode } from "react";

import { env } from "@/lib/env";
import { cn } from "@/lib/utils";

const ink = "#1b1b1b";
const LOGIN_HERO_IMAGE_URL: string | null = null;

export function AuthBrandMark({ className }: { className?: string }) {
  return (
    <Link className={cn("inline-flex items-center gap-3 font-black text-[#1b1b1b]", className)} href="/">
      <span className="grid size-14 place-items-center rounded-[8px] border-4 border-[#1b1b1b] bg-[#ffdf9b] text-xl text-[#9b4500] shadow-[4px_4px_0_#1b1b1b]">
        EMI
      </span>
      <span className="max-w-52 text-base leading-tight">{env.appName}</span>
    </Link>
  );
}

export function AuthBackLink({ href = "/login", label = "Kembali" }: { href?: string; label?: string }) {
  return (
    <Link
      className="inline-flex min-h-11 items-center justify-center rounded-[8px] border-4 border-[#1b1b1b] bg-white px-5 text-sm font-black text-[#1b1b1b] shadow-[4px_4px_0_#1b1b1b] transition hover:-translate-y-0.5 hover:bg-[#f6f3f2] focus:outline-none focus:ring-4 focus:ring-[#ffd167]"
      href={href}
    >
      {label}
    </Link>
  );
}

export function AuthTopBar({ backHref = "/login", backLabel = "Kembali" }: { backHref?: string; backLabel?: string }) {
  return (
    <header className="mx-auto flex w-full max-w-7xl items-center justify-between gap-4 px-4 py-6 sm:px-8">
      <AuthBrandMark />
      <AuthBackLink href={backHref} label={backLabel} />
    </header>
  );
}

export function AuthScreen({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className={cn("relative min-h-screen overflow-hidden bg-[#fcf9f8]", className)}>
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0 opacity-[0.05]"
        style={{
          backgroundImage: `radial-gradient(${ink} 1.5px, transparent 1.5px)`,
          backgroundSize: "28px 28px",
        }}
      />
      <div className="relative">{children}</div>
    </div>
  );
}

export function LoginLearningPanel() {
  return (
    <section className="relative min-h-[420px] overflow-hidden bg-gradient-to-br from-emerald-700 via-sky-700 to-amber-500 p-8 text-white lg:min-h-[640px] lg:p-12">
      {LOGIN_HERO_IMAGE_URL ? (
        <div aria-hidden="true" className="absolute inset-0 bg-cover bg-center opacity-80" style={{ backgroundImage: `url(${LOGIN_HERO_IMAGE_URL})` }} />
      ) : null}
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_20%,rgba(255,255,255,0.28),transparent_28%),radial-gradient(circle_at_80%_0%,rgba(250,204,21,0.24),transparent_24%),radial-gradient(circle_at_80%_80%,rgba(16,185,129,0.28),transparent_30%)]" />
      <div className="relative flex h-full min-h-[360px] flex-col justify-between gap-10 lg:min-h-[544px]">
        <div className="max-w-md">
          <p className="text-sm font-black uppercase tracking-[0.28em] text-amber-100">Belajar Bahasa Mekongga</p>
          <h2 className="mt-4 text-4xl font-black leading-tight tracking-tight lg:text-5xl">Ruang belajar digital untuk budaya, bahasa, dan generasi muda.</h2>
          <p className="mt-5 text-base leading-7 text-white/85">Masuk untuk melanjutkan modul, kamus, kuis, progress belajar, dan konten Budaya Mekongga dari kelas Anda.</p>
        </div>

        <div className="grid gap-4 sm:grid-cols-3">
          {[
            ["Modul", "Materi kelas"],
            ["Kamus", "Kosakata"],
            ["Kuis", "Latihan"],
          ].map(([title, subtitle]) => (
            <div className="rounded-3xl border border-white/25 bg-white/15 p-4 shadow-xl shadow-slate-900/10 backdrop-blur" key={title}>
              <p className="text-lg font-black">{title}</p>
              <p className="mt-1 text-sm text-white/75">{subtitle}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

export function RegistrationSteps({ active = 2 }: { active?: 1 | 2 | 3 }) {
  const steps = [
    { id: 1, label: "Pilih role" },
    { id: 2, label: "Isi data" },
    { id: 3, label: "Persetujuan" },
  ];

  return (
    <div className="grid gap-3 rounded-[12px] border-4 border-[#1b1b1b] bg-white p-4 shadow-[4px_4px_0_#1b1b1b] sm:grid-cols-3">
      {steps.map((step) => {
        const isDone = step.id < active;
        const isActive = step.id === active;

        return (
          <div className="flex items-center gap-3" key={step.id}>
            <span
              className={cn(
                "grid size-10 shrink-0 place-items-center rounded-full border-4 border-[#1b1b1b] text-sm font-black",
                isDone ? "bg-[#00c291] text-[#003c2f]" : isActive ? "bg-[#ffd167] text-[#765900]" : "bg-[#f0eded] text-[#564338]",
              )}
            >
              {isDone ? "OK" : step.id}
            </span>
            <span className="text-sm font-black text-[#1b1b1b]">{step.label}</span>
          </div>
        );
      })}
    </div>
  );
}

export function PendingApprovalIllustration() {
  return (
    <div className="grid aspect-square w-full max-w-[260px] place-items-center rounded-full border-4 border-[#1b1b1b] bg-[#f6f3f2] p-5 shadow-[6px_6px_0_#1b1b1b]">
      <div className="grid size-40 place-items-center rounded-full border-4 border-[#1b1b1b] bg-[#ffdf9b]">
        <div className="rounded-[10px] border-4 border-[#1b1b1b] bg-white px-6 py-5 text-center shadow-[4px_4px_0_#1b1b1b]">
          <div className="mx-auto mb-3 h-7 w-20 rounded-t-[8px] border-4 border-b-0 border-[#9b4500] bg-[#ffd167]" />
          <p className="text-4xl font-black text-[#9b4500]">...</p>
        </div>
      </div>
    </div>
  );
}
