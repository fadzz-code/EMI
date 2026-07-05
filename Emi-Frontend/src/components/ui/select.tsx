import type { SelectHTMLAttributes } from "react";

import { cn } from "@/lib/utils";

export function Select({
  className,
  ...props
}: SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select
      className={cn(
        "min-h-11 w-full rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 py-2 text-sm font-medium text-ink outline-none focus:ring-4 focus:ring-accent/40",
        className,
      )}
      {...props}
    />
  );
}
