import Link from "next/link";

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
  return (
    <>
      <details className="border-b-2 border-border bg-paper px-4 py-3 lg:hidden">
        <summary className="flex min-h-11 cursor-pointer list-none items-center justify-between rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 py-2 text-sm font-black text-ink shadow-emi">
          <span>Menu navigasi</span>
          <span aria-hidden="true" className="text-lg leading-none">
            +
          </span>
        </summary>
        <nav aria-label="Menu navigasi lengkap" className="mt-4 grid gap-2">
          {items.map((item) => {
            const isActive = isActiveNavItem(activePath, item.href);

            return (
              <Link
                aria-current={isActive ? "page" : undefined}
                className={cn(
                  "flex min-h-11 items-center justify-between gap-3 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 py-2 text-sm font-black text-ink",
                  isActive && "bg-accent text-accent-foreground shadow-emi",
                )}
                href={item.href}
                key={item.href}
              >
                <span className="min-w-0 truncate">{item.label}</span>
                {item.status === "next" ? <Badge>Segera</Badge> : null}
              </Link>
            );
          })}
        </nav>
      </details>

      <nav
        aria-label="Navigasi utama mobile"
        className="fixed inset-x-0 bottom-0 z-40 border-t-2 border-border bg-surface px-2 pb-[max(0.5rem,env(safe-area-inset-bottom))] pt-2 lg:hidden"
      >
        <div className="mx-auto grid max-w-md grid-cols-5 gap-1">
          {primaryItems.map((item) => {
            const isActive = isActiveNavItem(activePath, item.href);
            const label = item.shortLabel ?? item.label;

            return (
              <Link
                aria-current={isActive ? "page" : undefined}
                className={cn(
                  "flex min-h-14 flex-col items-center justify-center gap-1 rounded-full border-2 border-transparent px-2 py-1 text-center text-[11px] font-black leading-tight text-muted transition",
                  isActive
                    ? "border-border bg-accent text-accent-foreground shadow-[2px_2px_0_var(--border)]"
                    : "hover:border-border hover:bg-surface-muted",
                )}
                href={item.href}
                key={item.href}
              >
                <span
                  aria-hidden="true"
                  className={cn(
                    "flex size-6 items-center justify-center rounded-full border-2 border-border bg-surface text-[10px] leading-none",
                    isActive && "bg-primary text-primary-foreground",
                  )}
                >
                  {getNavMarker(label)}
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
