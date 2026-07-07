"use client";

import Link from "next/link";
import { Menu, X } from "lucide-react";
import { useEffect, useState } from "react";

import { isActiveNavItem, type NavItem } from "@/lib/routes";
import { cn } from "@/lib/utils";

import { Badge } from "./badge";

function getNavMarker(label: string): string {
  const words = label.replace("&", " ").split(/\s+/).filter(Boolean);

  if (words.length >= 2) {
    return words
      .slice(0, 2)
      .map((word) => word[0])
      .join("")
      .toUpperCase();
  }

  return label.slice(0, 2).toUpperCase();
}

export function MobileRoleNavigation({
  items,
  primaryItems,
  activePath,
}: {
  items: NavItem[];
  primaryItems: NavItem[];
  activePath: string;
}) {
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    if (!isOpen) return;

    function closeOnEscape(event: KeyboardEvent) {
      if (event.key === "Escape") setIsOpen(false);
    }

    document.addEventListener("keydown", closeOnEscape);
    return () => document.removeEventListener("keydown", closeOnEscape);
  }, [isOpen]);

  return (
    <>
      <div className="sticky top-[58px] z-30 border-b-2 border-border bg-paper px-4 py-3 lg:hidden">
        <button
          aria-expanded={isOpen}
          aria-label="Buka menu navigasi"
          className="inline-flex min-h-11 items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink shadow-emi transition-colors hover:bg-surface-muted"
          onClick={() => setIsOpen(true)}
          type="button"
        >
          <Menu className="size-5" strokeWidth={3} />
          Menu
        </button>
      </div>

      {isOpen ? (
        <div className="fixed inset-0 z-50 lg:hidden" role="dialog" aria-modal="true">
          <button
            aria-label="Tutup menu navigasi"
            className="absolute inset-0 bg-ink/45"
            onClick={() => setIsOpen(false)}
            type="button"
          />
          <aside className="relative flex h-full w-[min(20rem,85vw)] flex-col border-r-2 border-border bg-paper p-4 shadow-[8px_0_0_var(--border)]">
            <div className="mb-4 flex items-center justify-between gap-3 border-b-2 border-border/50 pb-3">
              <div>
                <p className="text-[10px] font-black uppercase tracking-widest text-muted">Menu EMI</p>
                <p className="text-lg font-black text-ink">Navigasi</p>
              </div>
              <button
                aria-label="Tutup menu navigasi"
                className="grid size-10 place-items-center rounded-[var(--radius-control)] border-2 border-border bg-surface shadow-emi"
                onClick={() => setIsOpen(false)}
                type="button"
              >
                <X className="size-5" strokeWidth={3} />
              </button>
            </div>
            <nav aria-label="Menu navigasi mobile" className="grid gap-2 overflow-y-auto pr-1">
              {items.map((item) => {
                const isActive = isActiveNavItem(activePath, item.href);
                const Icon = item.icon;

                return (
                  <Link
                    aria-current={isActive ? "page" : undefined}
                    className={cn(
                      "flex min-h-11 items-center justify-between gap-3 rounded-[var(--radius-control)] border-2 border-transparent bg-surface px-3 py-2 text-sm font-black transition-all",
                      isActive
                        ? "border-border bg-accent text-accent-foreground shadow-emi"
                        : "text-muted hover:border-border/50 hover:bg-surface-muted hover:text-ink",
                    )}
                    href={item.href}
                    key={item.href}
                    onClick={() => setIsOpen(false)}
                  >
                    <span className="flex min-w-0 items-center gap-3 truncate">
                      {Icon ? <Icon className={cn("size-5 shrink-0", isActive ? "text-primary" : "text-muted")} strokeWidth={isActive ? 3 : 2} /> : null}
                      <span className="truncate">{item.label}</span>
                    </span>
                    {item.status === "next" ? <Badge>Segera</Badge> : null}
                  </Link>
                );
              })}
            </nav>
          </aside>
        </div>
      ) : null}

      <nav
        aria-label="Navigasi utama mobile"
        className="fixed inset-x-0 bottom-0 z-40 border-t-2 border-border bg-surface px-2 pb-[max(0.5rem,env(safe-area-inset-bottom))] pt-2 lg:hidden"
      >
        <div className="mx-auto grid max-w-md grid-cols-5 gap-1">
          {primaryItems.map((item) => {
            const isActive = isActiveNavItem(activePath, item.href);
            const label = item.shortLabel ?? item.label;
            const Icon = item.icon;

            return (
              <Link
                aria-current={isActive ? "page" : undefined}
                className={cn(
                  "flex min-h-14 flex-col items-center justify-center gap-1 rounded-[16px] border-2 border-transparent px-2 py-1 text-center text-[10px] font-black leading-tight transition",
                  isActive
                    ? "border-border bg-accent text-accent-foreground shadow-[2px_2px_0_var(--border)]"
                    : "text-muted hover:bg-surface-muted",
                )}
                href={item.href}
                key={item.href}
              >
                <span
                  aria-hidden="true"
                  className={cn(
                    "flex size-6 items-center justify-center rounded-full transition-colors",
                    isActive ? "text-primary" : "text-muted",
                  )}
                >
                  {Icon ? <Icon className="size-5" strokeWidth={isActive ? 3 : 2} /> : getNavMarker(label)}
                </span>
                <span className="max-w-full truncate">{label}</span>
              </Link>
            );
          })}
        </div>
      </nav>
    </>
  );
}
