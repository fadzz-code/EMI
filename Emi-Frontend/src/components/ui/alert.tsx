import type { HTMLAttributes } from "react";

import { cn } from "@/lib/utils";

type AlertTone = "info" | "warning" | "error" | "success";

const tones: Record<AlertTone, string> = {
  info: "border-blue-900 bg-blue-50 text-blue-950",
  warning: "border-yellow-900 bg-yellow-100 text-yellow-950",
  error: "border-orange-900 bg-orange-100 text-orange-950",
  success: "border-emerald-900 bg-emerald-50 text-emerald-950",
};

type AlertProps = HTMLAttributes<HTMLDivElement> & {
  tone?: AlertTone;
};

export function Alert({ className, tone = "info", ...props }: AlertProps) {
  return (
    <div
      className={cn("rounded-lg border-2 px-4 py-3 text-sm font-medium", tones[tone], className)}
      role="status"
      {...props}
    />
  );
}
