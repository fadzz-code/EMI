import Link from "next/link";
import type { ReactNode } from "react";

import { env } from "@/lib/env";
import { cn } from "@/lib/utils";

const ink = "#1b1b1b";
export const LOGIN_HERO_CONFIG = {
  title: "Belajar Bahasa Mekongga Jadi Lebih Mudah",
  subtitle: "Akses modul, ikuti kuis, cari kosakata di kamus, dan kenali Budaya Mekongga dalam satu platform.",
  infoTitle: "Informasi Penting",
  infoDescription: "Akun siswa dan guru perlu disetujui admin sebelum dapat digunakan.",
  imageUrl: null as string | null,
};

export function LoginLearningPanel() {
  return (
    <section className="relative hidden min-h-[500px] flex-col border-l-4 border-ink bg-[#ffd167] p-8 lg:flex lg:p-12">
      {/* Decorative Accent: Top Right Orange Quarter Circle */}
      <div className="absolute right-0 top-0 size-32 rounded-bl-full border-b-4 border-l-4 border-ink bg-[#ff8c42]" />

      {/* Decorative Accent: Bottom Left Green Shape */}
      <div className="absolute bottom-16 left-0 size-24 rounded-r-full border-y-4 border-r-4 border-ink bg-[#00c291]" />

      <div className="relative z-10 flex h-full flex-col items-center justify-between gap-10">

        {/* Main CSS Illustration Area */}
        <div className="relative mt-8 w-full max-w-[360px] rounded-[16px] border-4 border-ink bg-white p-6 shadow-[8px_8px_0_var(--color-ink)]">
          {LOGIN_HERO_CONFIG.imageUrl ? (
            <div className="mb-4 aspect-video w-full rounded-[8px] border-4 border-ink bg-cover bg-center" style={{ backgroundImage: `url(${LOGIN_HERO_CONFIG.imageUrl})` }} />
          ) : (
            <div className="mb-4 flex justify-center">
              <div className="relative size-32 rounded-full border-4 border-ink bg-[#fcf9f8] shadow-[4px_4px_0_var(--color-ink)]">
                <div className="absolute inset-x-4 bottom-4 top-8 rounded-[8px] border-4 border-ink bg-[#00c291]" />
                <div className="absolute right-4 top-4 size-8 rounded-full border-4 border-ink bg-[#ffdf9b]" />
              </div>
            </div>
          )}

          <div className="flex flex-col items-center gap-4 text-center">
            <h2 className="text-2xl font-black leading-tight text-ink">{LOGIN_HERO_CONFIG.title}</h2>
            <p className="text-sm font-bold text-slate-600 hidden">{LOGIN_HERO_CONFIG.subtitle}</p>

            <div className="mt-2 flex flex-wrap justify-center gap-2">
              {[
                { id: "modul", label: "Modul", color: "bg-[#ffd167]" },
                { id: "kuis", label: "Kuis", color: "bg-[#ff8c42]" },
                { id: "kamus", label: "Kamus", color: "bg-[#fcf9f8]" },
                { id: "budaya", label: "Budaya", color: "bg-[#00c291]" },
              ].map((badge) => (
                <span className={cn("rounded-full border-2 border-ink px-3 py-1 text-xs font-black text-ink shadow-[2px_2px_0_var(--color-ink)]", badge.color)} key={badge.id}>
                  {badge.label}
                </span>
              ))}
            </div>
          </div>
        </div>

        {/* Bottom Information Card */}
        <div className="w-full max-w-[360px] rounded-[12px] border-4 border-ink bg-white p-5 shadow-[4px_4px_0_var(--color-ink)]">
          <p className="text-sm font-black uppercase tracking-wider text-[#9b4500]">{LOGIN_HERO_CONFIG.infoTitle}</p>
          <p className="mt-2 text-sm font-bold leading-6 text-slate-700">
            {LOGIN_HERO_CONFIG.infoDescription}
          </p>
        </div>
      </div>
    </section>
  );
}
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
