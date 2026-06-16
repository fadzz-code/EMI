import Link from "next/link";
import type { ReactNode } from "react";

import { env } from "@/lib/env";
import { cn } from "@/lib/utils";

const ink = "#1b1b1b";

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
    <section className="hidden lg:block">
      <div className="relative mx-auto max-w-[520px]">
        <div className="rounded-[12px] border-4 border-[#1b1b1b] bg-[#ffd167] p-8 shadow-[8px_8px_0_#1b1b1b]">
          <div className="rounded-[10px] border-4 border-[#1b1b1b] bg-white p-6 shadow-[4px_4px_0_#1b1b1b]">
            <div className="grid min-h-[300px] place-items-center rounded-[8px] bg-[#fcf9f8] p-6">
              <div className="w-full max-w-[320px] rounded-[10px] border-4 border-[#1b1b1b] bg-white p-5 shadow-[6px_6px_0_#1b1b1b]">
                <div className="mb-4 h-5 w-24 rounded-full border-2 border-[#1b1b1b] bg-[#00c291]" />
                <div className="space-y-3">
                  <div className="h-4 rounded-full bg-[#1b1b1b]" />
                  <div className="h-4 w-5/6 rounded-full bg-[#ff8c42]" />
                  <div className="h-4 w-2/3 rounded-full bg-[#ffd167]" />
                </div>
                <div className="mt-6 grid grid-cols-3 gap-3">
                  {["A", "B", "C"].map((item) => (
                    <div
                      className="grid aspect-square place-items-center rounded-[8px] border-4 border-[#1b1b1b] bg-[#ffdf9b] text-lg font-black text-[#9b4500]"
                      key={item}
                    >
                      {item}
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="mx-auto mt-6 max-w-[430px] rounded-[12px] border-4 border-[#1b1b1b] bg-white p-5 shadow-[6px_6px_0_#1b1b1b]">
          <p className="text-sm font-black uppercase text-[#9b4500]">Informasi Penting</p>
          <p className="mt-2 text-sm leading-6 text-[#564338]">
            Akun guru dan siswa dapat masuk setelah data sekolah dan kelas disetujui Admin EMI.
          </p>
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
