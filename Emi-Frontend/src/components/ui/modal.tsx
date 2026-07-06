"use client";

import { cn } from "@/lib/utils";
import { Button } from "./button";

export function Modal({
  title,
  children,
  open,
  onClose,
  className,
}: {
  title: string;
  children: React.ReactNode;
  open: boolean;
  onClose: () => void;
  className?: string;
}) {
  if (!open) {
    return null;
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <section className={cn("flex max-h-[calc(100vh-2rem)] w-full max-w-lg flex-col overflow-hidden rounded-[var(--radius-card)] border-2 border-border bg-surface shadow-emi", className)}>
        <header className="shrink-0 flex items-center justify-between border-b-2 border-border p-4">
          <h2 className="text-lg font-black text-ink">{title}</h2>
          <Button aria-label="Tutup modal" onClick={onClose} variant="ghost">
            Tutup
          </Button>
        </header>
        <div className="min-h-0 flex-1 overflow-y-auto p-4">{children}</div>
      </section>
    </div>
  );
}
