import type { ReactNode } from "react";

import { Badge } from "@/components/ui";
import { cn, getInitials } from "@/lib/utils";

import { roleLabel, statusLabel, statusTone } from "./approval-utils";
import type { RegistrationRequest, RegistrationRequestedRole } from "./types";

export function ApprovalPageShell({ children }: { children: ReactNode }) {
  return (
    <div className="grid gap-6 rounded-[18px] bg-[#fff8f6] p-1">
      <div
        aria-hidden="true"
        className="pointer-events-none fixed inset-0 opacity-[0.04]"
        style={{
          backgroundImage: "radial-gradient(#241914 1.4px, transparent 1.4px)",
          backgroundSize: "24px 24px",
        }}
      />
      <div className="relative grid gap-6">{children}</div>
    </div>
  );
}

export function ApprovalHero({
  title,
  description,
  action,
}: {
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <header className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
      <div>
        <p className="text-sm font-black uppercase text-[#9a4600]">Admin EMI</p>
        <h1 className="mt-2 text-4xl font-black leading-tight text-[#241914] md:text-5xl">
          {title}
        </h1>
        <p className="mt-2 max-w-3xl text-base font-medium leading-7 text-[#564338]">
          {description}
        </p>
      </div>
      {action ? <div className="shrink-0">{action}</div> : null}
    </header>
  );
}

export function ApprovalInfoBox({ children }: { children: ReactNode }) {
  return (
    <section className="flex gap-4 rounded-[12px] border-2 border-[#241914] bg-[#fdd758] p-4 text-[#735d00] shadow-[4px_4px_0_#241914]">
      <span className="grid size-11 shrink-0 place-items-center rounded-full border-2 border-[#241914] bg-[#fff8f6] text-lg font-black text-[#241914] shadow-[2px_2px_0_#241914]">
        i
      </span>
      <div className="grid gap-1">
        <h2 className="text-lg font-black">Informasi Penting</h2>
        <p className="text-sm font-semibold leading-6">{children}</p>
      </div>
    </section>
  );
}

export function ApprovalAvatar({ name, role }: { name?: string | null; role?: RegistrationRequestedRole }) {
  return (
    <span
      className={cn(
        "grid size-11 shrink-0 place-items-center rounded-full border-2 border-[#241914] text-sm font-black shadow-[2px_2px_0_#241914]",
        role === "student" ? "bg-[#94f990] text-[#004910]" : "bg-[#ffb68d] text-[#321200]",
      )}
    >
      {getInitials(name)}
    </span>
  );
}

export function ApprovalRoleBadge({ role }: { role?: RegistrationRequestedRole }) {
  const isStudent = role === "student";

  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full border-2 border-[#241914] px-3 py-1 text-xs font-black shadow-[2px_2px_0_#241914]",
        isStudent ? "bg-[#5bbe5d] text-[#004910]" : "bg-[#ff8a3d] text-[#682d00]",
      )}
    >
      {roleLabel(role)}
    </span>
  );
}

export function ApprovalStatusBadge({ status }: { status?: string }) {
  const tone = statusTone(status);

  return (
    <Badge
      className={cn(
        "border-2 border-[#241914] px-3 py-1 font-black shadow-[2px_2px_0_#241914]",
        tone === "yellow" && "bg-[#fdd758] text-[#735d00]",
        tone === "blue" && "bg-[#087a2f] text-white",
        tone === "orange" && "bg-[#ba1a1a] text-white",
        tone === "neutral" && "bg-[#fff8f6] text-[#241914]",
      )}
      tone={tone}
    >
      {statusLabel(status)}
    </Badge>
  );
}

export function DetailCell({ label, value }: { label: string; value?: ReactNode }) {
  return (
    <div className="min-h-24 border-[#241914] p-5 odd:border-r-2 even:border-b-2 max-sm:border-b-2 sm:[&:nth-child(3)]:border-b-0 sm:[&:nth-child(4)]:border-b-0">
      <p className="text-xs font-black uppercase text-[#564338]">{label}</p>
      <div className="mt-2 text-base font-black leading-7 text-[#241914]">{value ?? "-"}</div>
    </div>
  );
}

export function getClassName(request?: RegistrationRequest) {
  if (!request?.school_class) {
    return "-";
  }

  return `${request.school_class.name}${
    request.school_class.academic_year ? ` - ${request.school_class.academic_year}` : ""
  }`;
}
