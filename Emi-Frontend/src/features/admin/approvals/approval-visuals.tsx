import type { ReactNode } from "react";

import { Badge } from "@/components/ui";
import { cn, getInitials } from "@/lib/utils";

import { roleLabel, statusLabel } from "./approval-utils";
import type { RegistrationRequest, RegistrationRequestedRole } from "./types";

export function ApprovalPageShell({ children }: { children: ReactNode }) {
  return (
    <div className="grid gap-6 rounded-[18px] bg-surface p-1">
      <div
        aria-hidden="true"
        className="pointer-events-none fixed inset-0 bg-[radial-gradient(var(--color-border)_1.4px,transparent_1.4px)] bg-[length:24px_24px] opacity-[0.04]"
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
        <p className="text-sm font-black uppercase text-primary">Admin EMI</p>
        <h1 className="mt-2 text-4xl font-black leading-tight text-ink md:text-5xl">
          {title}
        </h1>
        <p className="mt-2 max-w-3xl text-base font-medium leading-7 text-muted">
          {description}
        </p>
      </div>
      {action ? <div className="shrink-0">{action}</div> : null}
    </header>
  );
}

export function ApprovalInfoBox({ children }: { children: ReactNode }) {
  return (
    <section className="flex gap-4 rounded-[12px] border-2 border-border bg-[var(--color-primary-muted)] p-4 text-ink shadow-emi">
      <span className="grid size-11 shrink-0 place-items-center rounded-full border-2 border-border bg-surface text-lg font-black text-ink shadow-emi">
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
        "grid size-11 shrink-0 place-items-center rounded-full border-2 border-border text-sm font-black shadow-emi",
        role === "student"
          ? "bg-success text-success-foreground"
          : "bg-primary text-primary-foreground",
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
        "inline-flex items-center rounded-full border-2 border-border px-3 py-1 text-xs font-black shadow-emi",
        isStudent
          ? "bg-success text-success-foreground"
          : "bg-primary text-primary-foreground",
      )}
    >
      {roleLabel(role)}
    </span>
  );
}

export function ApprovalStatusBadge({ status }: { status?: string }) {
  const tone = status === "approved" ? "blue" : status === "rejected" ? "orange" : "neutral";

  return (
    <Badge
      className={cn(
        "border-2 border-border px-3 py-1 font-black shadow-emi",
        tone === "blue" && "bg-success text-success-foreground",
        tone === "orange" && "bg-danger text-danger-foreground",
        tone === "neutral" && "bg-surface text-ink",
      )}
      tone={tone}
    >
      {statusLabel(status)}
    </Badge>
  );
}

export function DetailCell({ label, value }: { label: string; value?: ReactNode }) {
  return (
    <div className="min-h-24 border-border p-5 odd:border-r-2 even:border-b-2 max-sm:border-b-2 sm:[&:nth-child(3)]:border-b-0 sm:[&:nth-child(4)]:border-b-0">
      <p className="text-xs font-black uppercase text-muted">{label}</p>
      <div className="mt-2 text-base font-black leading-7 text-ink">{value ?? "-"}</div>
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
