import type { ReactNode } from "react";

export function FilterPanel({ children }: { children: ReactNode }) {
  return (
    <section className="grid gap-3 rounded-lg border-2 border-ink bg-blue-50 p-4 md:grid-cols-3">
      {children}
    </section>
  );
}
