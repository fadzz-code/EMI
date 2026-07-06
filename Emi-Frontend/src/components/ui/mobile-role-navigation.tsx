import Link from "next/link";
import { ChevronDown } from "lucide-react";

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
      <details className="group border-b-2 border-border bg-paper px-4 py-3 lg:hidden">
        <summary className="flex min-h-11 cursor-pointer list-none items-center justify-between rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-ink shadow-emi transition-colors hover:bg-surface-muted">
          <span>Menu navigasi</span>
          <ChevronDown className="size-5 transition-transform duration-200 group-open:rotate-180" strokeWidth={3} />
        </summary>
        <nav aria-label="Menu navigasi lengkap" className="mt-4 grid gap-2">
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
                    : "text-muted hover:border-border/50 hover:bg-surface-muted hover:text-ink"
                )}
                href={item.href}
                key={item.href}
              >
                <span className="flex items-center gap-3 min-w-0 truncate">
                  {Icon && <Icon className={cn("size-5 shrink-0", isActive ? "text-primary" : "text-muted")} strokeWidth={isActive ? 3 : 2} />}
                  <span className="truncate">{item.label}</span>
                </span>
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
                    isActive ? "text-primary" : "text-muted"
                  )}
                >
                  {Icon ? (
                    <Icon className="size-5" strokeWidth={isActive ? 3 : 2} />
                  ) : (
                    getNavMarker(label)
                  )}
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
