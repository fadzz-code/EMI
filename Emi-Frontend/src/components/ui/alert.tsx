"use client";

import { forwardRef, useEffect, useRef, type HTMLAttributes, type ReactNode } from "react";

import { cn } from "@/lib/utils";

type AlertTone = "info" | "warning" | "error" | "success";

const tones: Record<AlertTone, string> = {
  info: "border-info-foreground bg-blue-50 text-info-foreground",
  warning: "border-accent-foreground bg-yellow-100 text-accent-foreground",
  error: "border-danger bg-danger-muted text-danger",
  success: "border-success-foreground bg-green-50 text-success-foreground",
};

type AlertProps = HTMLAttributes<HTMLDivElement> & {
  tone?: AlertTone;
};

export const Alert = forwardRef<HTMLDivElement, AlertProps>(function Alert({ className, tone = "info", ...props }, ref) {
  return (
    <div
      className={cn("rounded-[var(--radius-control)] border-2 px-4 py-3 text-sm font-medium", tones[tone], className)}
      ref={ref}
      role="status"
      {...props}
    />
  );
});

type MutationAlertProps = Omit<AlertProps, "role"> & {
  children: ReactNode;
  eventKey: unknown;
  visible?: boolean;
};

export function MutationAlert({ children, eventKey, tone = "info", visible = true, ...props }: MutationAlertProps) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!visible || eventKey == null || !ref.current) return;
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    ref.current.focus({ preventScroll: true });
    ref.current.scrollIntoView({ behavior: reducedMotion ? "auto" : "smooth", block: "center" });
  }, [eventKey, visible]);

  if (!visible) return null;

  return (
    <Alert
      aria-atomic="true"
      aria-live={tone === "error" ? "assertive" : "polite"}
      ref={ref}
      role={tone === "error" ? "alert" : "status"}
      tabIndex={-1}
      tone={tone}
      {...props}
    >
      {children}
    </Alert>
  );
}
