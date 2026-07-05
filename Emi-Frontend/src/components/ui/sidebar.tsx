import Link from "next/link";

import type { NavItem } from "@/lib/routes";
import { cn } from "@/lib/utils";

import { Badge } from "./badge";

export function Sidebar({
  items,
  activePath,
}: {
  items: NavItem[];
  activePath: string;
}) {
  return (
    <nav className="grid gap-2">
      {items.map((item) => {
        const isActive = activePath === item.href || activePath.startsWith(`${item.href}/`);

        return (
          <Link
            className={cn(
              "flex min-h-11 items-center justify-between rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 py-2 text-sm font-black text-ink transition hover:bg-surface-muted",
              isActive && "bg-accent text-accent-foreground shadow-emi",
            )}
            href={item.href}
            key={item.href}
          >
            <span>{item.label}</span>
            {item.status === "next" ? <Badge>Next</Badge> : null}
          </Link>
        );
      })}
    </nav>
  );
}
