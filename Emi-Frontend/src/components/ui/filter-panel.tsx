import type { ReactNode } from "react";

import { cn } from "@/lib/utils";

export function FilterPanel({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <section
      className={cn(
        "grid gap-3 rounded-[var(--radius-card)] border-2 border-border bg-surface-muted p-4 md:grid-cols-3",
        className,
      )}
    >
      {children}
    </section>
  );
}
