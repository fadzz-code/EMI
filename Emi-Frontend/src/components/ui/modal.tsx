"use client";

import { useEffect, useId, useRef } from "react";

import { cn } from "@/lib/utils";
import { Button } from "./button";

export function Modal({
  title,
  children,
  open,
  onClose,
  className,
  closeDisabled = false,
  size = "default",
}: {
  title: string;
  children: React.ReactNode;
  open: boolean;
  onClose: () => void;
  className?: string;
  closeDisabled?: boolean;
  size?: "default" | "editor";
}) {
  const titleId = useId();
  const dialogRef = useRef<HTMLElement>(null);
  const closeDisabledRef = useRef(closeDisabled);
  const onCloseRef = useRef(onClose);

  useEffect(() => {
    closeDisabledRef.current = closeDisabled;
    onCloseRef.current = onClose;
  }, [closeDisabled, onClose]);

  useEffect(() => {
    if (!open) return;
    const previousFocus = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    const dialog = dialogRef.current;
    const focusable = () => Array.from(dialog?.querySelectorAll<HTMLElement>('button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])') ?? []);
    (focusable()[0] ?? dialog)?.focus();

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") {
        if (!closeDisabledRef.current) onCloseRef.current();
        return;
      }
      if (event.key !== "Tab") return;
      const items = focusable();
      if (!items.length) {
        event.preventDefault();
        dialog?.focus();
        return;
      }
      const first = items[0];
      const last = items[items.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    }

    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
      previousFocus?.focus();
    };
  }, [open]);

  if (!open) {
    return null;
  }

  const editor = size === "editor";

  return (
    <div className={cn("fixed inset-0 z-50 flex items-center justify-center overflow-hidden bg-black/40 p-2 sm:p-4", editor && "max-md:p-0")}>
      <section
        aria-labelledby={titleId}
        aria-modal="true"
        className={cn(
          "flex max-h-[calc(100dvh-1rem)] min-w-0 w-full max-w-lg flex-col overflow-hidden rounded-[var(--radius-card)] border-2 border-border bg-surface shadow-emi sm:max-h-[calc(100dvh-2rem)]",
          editor && "h-[92vh] max-h-[92vh] max-w-[min(1400px,94vw)] max-md:h-[100dvh] max-md:max-h-[100dvh] max-md:max-w-none max-md:rounded-none md:max-lg:h-[94dvh] md:max-lg:max-h-[94dvh] md:max-lg:max-w-[96vw]",
          className,
        )}
        ref={dialogRef}
        role="dialog"
        tabIndex={-1}
      >
        <header className="sticky top-0 z-10 flex shrink-0 items-center justify-between gap-3 border-b-2 border-border bg-surface p-4">
          <h2 className="min-w-0 text-lg font-black text-ink" id={titleId}>{title}</h2>
          <Button aria-label="Tutup modal" disabled={closeDisabled} onClick={onClose} variant="ghost">
            Tutup
          </Button>
        </header>
        <div className={cn("min-h-0 min-w-0 flex-1 overflow-auto p-4", editor && "p-3 sm:p-5")}>
          <div className={cn("min-w-0", editor && "mx-auto w-full max-w-[1160px]")}>{children}</div>
        </div>
      </section>
    </div>
  );
}
