import Link from "next/link";

import { isActiveNavItem, type NavItem } from "@/lib/routes";
import { cn } from "@/lib/utils";

import { Badge } from "./badge";

export function Sidebar({
  items,
  activePath,
  className,
  label = "Navigasi role",
}: {
  items: NavItem[];
  activePath: string;
  className?: string;
  label?: string;
}) {
  return (
    <nav
      aria-label={label}
      className={cn(
        "rounded-[var(--radius-card)] border-2 border-border bg-surface p-3 shadow-emi",
        className,
      )}
    >
      <div className="mb-3 border-b-2 border-border px-2 pb-3">
        <p className="text-xs font-black uppercase tracking-[0.08em] text-muted-foreground">
          Menu EMI
        </p>
      </div>
      <div className="grid gap-2">
      {items.map((item) => {
        const isActive = isActiveNavItem(activePath, item.href);

        return (
          <Link
            aria-current={isActive ? "page" : undefined}
            className={cn(
              "flex min-h-11 items-center justify-between gap-3 rounded-[var(--radius-control)] border-2 border-transparent bg-surface px-3 py-2 text-sm font-black text-ink transition hover:border-border hover:bg-surface-muted",
              isActive && "border-border bg-accent text-accent-foreground shadow-emi",
            )}
            href={item.href}
            key={item.href}
          >
            <span className="min-w-0 truncate">{item.label}</span>
            {item.status === "next" ? <Badge>Segera</Badge> : null}
          </Link>
        );
      })}
      </div>
    </nav>
  );
}
