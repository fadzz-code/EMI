import type { InputHTMLAttributes } from "react";

import { cn } from "@/lib/utils";

export function Input({ className, ...props }: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={cn(
        "min-h-11 w-full rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 py-2 text-sm text-ink outline-none transition placeholder:text-muted-foreground focus:ring-4 focus:ring-accent/40",
        className,
      )}
      {...props}
    />
  );
}
