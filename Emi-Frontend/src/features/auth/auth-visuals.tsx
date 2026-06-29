import Link from "next/link";
import type { ReactNode } from "react";

import { env } from "@/lib/env";
import { cn } from "@/lib/utils";

const ink = "#1b1b1b";
export const LOGIN_HERO_CONFIG = {
  imageUrl: null as string | null,
};

export function LoginLearningPanel() {
  return (
    <section className="relative hidden min-h-[420px] flex-col border-l-4 border-ink bg-[#00c291] p-8 lg:flex lg:min-h-[640px] lg:p-12">
      {LOGIN_HERO_CONFIG.imageUrl ? (
        <div aria-hidden="true" className="absolute inset-0 bg-cover bg-center" style={{ backgroundImage: `url(${LOGIN_HERO_CONFIG.imageUrl})` }} />
      ) : (
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_20%,rgba(255,255,255,0.2),transparent_28%),radial-gradient(circle_at_80%_80%,rgba(0,0,0,0.05),transparent_30%)]" />
      )}
      <div className="relative flex h-full flex-col justify-center gap-10 text-[#003c2f]">
        <div className="max-w-md">
          <h2 className="text-4xl font-black leading-tight tracking-tight lg:text-5xl">Belajar Bahasa Mekongga Jadi Lebih Mudah</h2>
          <p className="mt-5 text-base font-bold leading-7 text-[#004d3e]">Akses modul, ikuti kuis, cari kosakata di kamus, dan kenali Budaya Mekongga dalam satu platform.</p>
        </div>

        <div className="grid grid-cols-2 gap-4">
          {[
            { id: "modul", label: "Modul", color: "bg-[#ffd167]", text: "text-[#765900]" },
            { id: "kuis", label: "Kuis", color: "bg-[#ff8c42]", text: "text-[#6a2d00]" },
            { id: "kamus", label: "Kamus", color: "bg-white", text: "text-ink" },
            { id: "budaya", label: "Budaya", color: "bg-[#ffdf9b]", text: "text-[#9b4500]" },
          ].map((badge) => (
            <div className={cn("rounded-[12px] border-4 border-ink p-4 shadow-[4px_4px_0_var(--color-ink)]", badge.color)} key={badge.id}>
              <p className={cn("text-lg font-black", badge.text)}>{badge.label}</p>
            </div>
          ))}
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
