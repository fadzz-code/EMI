"use client";

import {
  type ButtonHTMLAttributes,
  type ReactNode,
  useEffect,
  useRef,
  useState,
} from "react";

import { cn } from "@/lib/utils";

export function DropdownMenu({
  trigger,
  children,
  align = "end",
  className,
}: {
  trigger: ReactNode;
  children: ReactNode;
  align?: "start" | "end";
  className?: string;
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

  return (
    <div className="relative inline-block" ref={containerRef}>
      <span onClick={() => setOpen((current) => !current)}>{trigger}</span>
      {open ? (
        <div
          className={cn(
            "absolute top-full z-40 mt-2 w-48 rounded-lg border-2 border-border bg-surface p-1.5 shadow-emi",
            align === "end" ? "right-0" : "left-0",
            className,
          )}
          onClick={() => setOpen(false)}
          role="menu"
        >
          {children}
        </div>
      ) : null}
    </div>
  );
}

type DropdownMenuItemProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  icon?: ReactNode;
  danger?: boolean;
};

export function DropdownMenuItem({
  icon,
  danger,
  className,
  children,
  type = "button",
  ...props
}: DropdownMenuItemProps) {
  return (
    <button
      className={cn(
        "flex w-full items-center gap-2 rounded-md px-2.5 py-2 text-left text-sm font-bold transition disabled:cursor-not-allowed disabled:opacity-50",
        danger ? "text-danger hover:bg-red-50" : "text-ink hover:bg-surface-muted",
        className,
      )}
      role="menuitem"
      type={type}
      {...props}
    >
      {icon ? <span className="size-4 shrink-0">{icon}</span> : null}
      {children}
    </button>
  );
}
