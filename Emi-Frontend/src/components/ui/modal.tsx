"use client";

import { Button } from "./button";

export function Modal({
  title,
  children,
  open,
  onClose,
}: {
  title: string;
  children: React.ReactNode;
  open: boolean;
  onClose: () => void;
}) {
  if (!open) {
    return null;
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <section className="w-full max-w-lg rounded-[var(--radius-card)] border-2 border-border bg-surface shadow-emi">
        <header className="flex items-center justify-between border-b-2 border-border p-4">
          <h2 className="text-lg font-black text-ink">{title}</h2>
          <Button aria-label="Tutup modal" onClick={onClose} variant="ghost">
            Tutup
          </Button>
        </header>
        <div className="p-4">{children}</div>
      </section>
    </div>
  );
}
