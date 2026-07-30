"use client";

import { Info } from "lucide-react";
import { type ReactNode, useEffect, useRef, useState } from "react";

import { cn } from "@/lib/utils";

export function InfoPopover({
  label = "Info",
  children,
  className,
  align = "center",
}: {
  label?: string;
  children: ReactNode;
  className?: string;
  align?: "start" | "center" | "end";
}) {
  const [open, setOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) {
      return;
    }

    function handlePointerDown(event: PointerEvent) {
      if (!containerRef.current?.contains(event.target as Node)) {
        setOpen(false);
      }
    }

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setOpen(false);
      }
    }

    document.addEventListener("pointerdown", handlePointerDown);
    document.addEventListener("keydown", handleKeyDown);

    return () => {
      document.removeEventListener("pointerdown", handlePointerDown);
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [open]);

  const alignClass = align === "start" ? "left-0" : align === "end" ? "right-0" : "left-1/2 -translate-x-1/2";

  return (
    <div className="relative inline-flex" ref={containerRef}>
      <button
        aria-label={label}
        className="inline-flex size-5 shrink-0 items-center justify-center rounded-full border-2 border-border bg-surface text-primary transition hover:-translate-y-0.5 hover:bg-[var(--color-primary-muted)]"
        onClick={() => setOpen((current) => !current)}
        type="button"
      >
        <Info className="size-3.5" strokeWidth={2.5} />
      </button>
      {open ? (
        <div
          className={cn(
            "absolute top-full z-40 mt-2 w-72 rounded-xl border-2 border-border bg-surface p-4 text-xs font-semibold leading-5 text-ink shadow-emi",
            alignClass,
            className,
          )}
          role="tooltip"
        >
          {children}
        </div>
      ) : null}
    </div>
  );
}
