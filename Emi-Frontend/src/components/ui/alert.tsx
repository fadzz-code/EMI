import type { HTMLAttributes } from "react";

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

export function Alert({ className, tone = "info", ...props }: AlertProps) {
  return (
    <div
      className={cn("rounded-[var(--radius-control)] border-2 px-4 py-3 text-sm font-medium", tones[tone], className)}
      role="status"
      {...props}
    />
  );
}
